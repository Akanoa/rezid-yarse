unit IndexeurBleuSearchEngine;

{
  YARSE, Yet Another REZID Search Engine
  Version 3.x
  ZeWaren / Erwan Martin
  Copyright 2010
  http://zewaren.net ; http://rezid.org
}

interface

uses SearchEngineFacade, Classes, SysUtils, OfflineBrowsing, Windows;

type
  TIndexeurBleuSearchEngineFacade = class(TInterfacedObject, IAbstractSearchEngineFacade)
   private
    FCurrentComputerList : TOnlineHostList;
    FCallbackTextInformation : TSearchEngineCallbackTextInformation;
    function GetCallbackTextInformation : TSearchEngineCallbackTextInformation;
    procedure SetCallbackTextInformation(new_value : TSearchEngineCallbackTextInformation);
   public
    constructor Create;
    function GetCurrentComputerList() : TOnlineHostList;
    function MakeSearch(search_string : string; search_in : TSearchInEnum) : TSearch;
    property CallbackTextInformation : TSearchEngineCallbackTextInformation read GetCallbackTextInformation write SetCallbackTextInformation;
    function GetOfflineBrowserComputerList : TOfflineBrowserHostArray;
    function GetOfflineBrowserShareList(HostId : Integer) : TOfflineBrowserShareList;
    procedure FetchOfflineBrowserFolderContent(var Folder : TOfflineBrowserFolder);

    private function MakeSQLQuery(search_string : string; search_in : TSearchInEnum): string;
  end;

const
  config_mysql_server = '10.4.49.7';
  config_mysql_user = 'indexeur-client';
  config_mysql_password = '';
  config_mysql_db = 'indexeur_bleu';

function DoubleAsteriks(input : string) : string;
function UnixToDateTime(USec: Longint): TDateTime;

implementation

uses WinInet, MySQL, Dialogs, ConstsAndVars, URLMon;

function DoubleAsteriks(input : string) : string;
var
  BS : string;
  i : word;
  BSf : string;
begin
  BS := input;
  BSf := '';
    for i := 0 to Length(BS) - 1 do
      begin
        if copy(BS, i+1, 1) = '''' then
          BSf := BSf + ''''''
        else
          BSf := BSf + copy(BS, i+1, 1);
      end;
  Result := BSf;
end;

function DownloadFile(SourceFile, DestFile: string): Boolean;
begin
  try
    Result := UrlDownloadToFile(nil, PChar(SourceFile), PChar(DestFile), 0, nil) = 0;
  except
    Result := False;
  end;
end;


{ MysqlSearchEngineFacade }

constructor TIndexeurBleuSearchEngineFacade.Create;
begin
  inherited Create;
  FCurrentComputerList := nil;
end;

function TIndexeurBleuSearchEngineFacade.GetCallbackTextInformation: TSearchEngineCallbackTextInformation;
begin
  Result := FCallbackTextInformation;
end;

function TIndexeurBleuSearchEngineFacade.GetCurrentComputerList: TOnlineHostList;
  function DateTimeToMilliseconds(DateTime: TDateTime): Int64;
  { Converts a TDateTime variable to Int64 milliseconds from 0001-01-01.}
  var ts: SysUtils.TTimeStamp;
  begin
  { Call DateTimeToTimeStamp to convert DateTime to TimeStamp: }
    ts  := SysUtils.DateTimeToTimeStamp(DateTime);
  { Multiply and add to complete the conversion: }
    Result  := Int64(ts.Date)*MSecsPerDay + ts.Time;
  end;

  function MillisecondsToDateTime(Milliseconds: Int64): TDateTime;
  { Converts an Int64 milliseconds from 0001-01-01 to TDateTime variable.}
  var ts: SysUtils.TTimeStamp;
  begin
  { Divide and mod the milliseconds into the TimeStamp record: }
    ts.Date := Milliseconds div MSecsPerDay;
    ts.Time := Milliseconds mod MSecsPerDay;
  { Call TimeStampToDateTime to complete the conversion: }
    Result := SysUtils.TimeStampToDateTime(ts);
  end;
var
  bsl : TStrings;
  file_name : string;
  DResult : TOnlineHostList;
  i : word;
  a_host : TOnlineHost;
  BSL2 : TStrings;
  OnlineListDatAge : TDateTime;
  OnlineListDatAgeMilliSeconds : int64;
begin
  if Assigned(FCurrentComputerList) then
    begin
      Result := FCurrentComputerList;
      Exit;
    end;
  file_name := ExtractFilePath(Sto_GetModuleName())+'online_list.dat';
  FileAge(file_name, OnlineListDatAge);
  OnlineListDatAgeMilliSeconds := DateTimeToMilliseconds(OnlineListDatAge);
  if (OnlineListDatAgeMilliSeconds - (1000 * 60 * 10)) < DateTimeToMilliseconds(Now) then
    begin
      //Nous avons un fichier récent en cache
    end
  else
    try
      DeleteFile(PWideChar(file_name));
      DownloadFile('http://rezid.org/clist/clist.php', file_name);
    except on E: Exception do
      begin
        Result := TOnlineHostList.Create;
        Exit;
      end;
    end;

  bsl := TStringList.Create;
  if not FileExists(file_name) then
    begin
      Result := TOnlineHostList.Create;
      Exit;
    end;
  bsl.LoadFromFile(file_name);
  DResult := TOnlineHostList.Create;
  BSL2 := TStringList.Create;
  BSL2.Delimiter := ',';
  if BSL.Count > 0 then
    for i := 0 to BSL.Count - 1 do
      begin
        a_host := TOnlineHost.Create;
        BSL2.DelimitedText := BSL[i];
        a_host.Name := BSL2[0];//Copy(BSL[i], 0, Pos(',', BSL[i])-1);
        a_host.IP := BSL2[1];
        a_host.Comment := BSL2[2];
        a_host.Online := True;
        a_host.ShareCount := 0;
        DResult.Add(a_host);
      end;
  BSL.Free;
  FCurrentComputerList := DResult;
  Result := DResult;
end;

function TIndexeurBleuSearchEngineFacade.GetOfflineBrowserComputerList: TOfflineBrowserHostArray;
var
  mysql_connection : PMYSQL;
  mysql_res : PMYSQL_RES;
  mysql_row : PMYSQL_ROW;
  sql : string;
  sql_ansi : AnsiString;
  i : cardinal;
  current_computer_list : TOnlineHostList;
  a_online_host : TOnlineHost;
begin
  SetLength(Result, 0);
  try
    if libmysql_load(nil) = LIBMYSQL_MISSING then
      begin
        MessageDlg('LIBMYSQL_MISSING', mtError, [mbOK], 0);
        Exit;
      end;
    mysql_connection := mysql_init(nil);
      if not (mysql_real_connect(mysql_connection, PAnsiChar(config_mysql_server), PAnsiChar(config_mysql_user), PAnsiChar(config_mysql_password), PAnsiChar(config_mysql_db), 0, nil, 0) <> nil) then
        begin
          MessageDlg('Impossible de se connecter au serveur!', mtError, [mbOK], 0);
          Exit;
        end;
    sql := 'SELECT computers.id as computer_id, computers.name as computer_name, (SELECT COUNT(1) FROM folders WHERE folders.computerId = computers.id AND folders.parentFolderId IS NULL) AS share_count FROM computers ORDER BY computers.name';
    sql_ansi := AnsiString(sql);
      if mysql_real_query(mysql_connection, PAnsiChar(sql_ansi), length(sql_ansi)) = 0 then
        begin
          mysql_res := mysql_store_result(mysql_connection);
        end
      else
        begin
          MessageDlg('Ca chie!!', mtError, [mbOK], 0);
          Exit;
        end;

    if mysql_num_rows(mysql_res) > 0 then
      begin
        current_computer_list := Self.GetCurrentComputerList;
        SetLength(Result, mysql_num_rows(mysql_res));
        for i := 0 to mysql_num_rows(mysql_res) - 1 do
          begin
            mysql_row := mysql_fetch_row(mysql_res);
            Result[i] := TOfflineBrowserHost.Create;

            with Result[i] do
              begin
                ID := strtointdef(string(mysql_row^[0]), 0);
                Name := string(mysql_row^[1]);
                ShareCount := strtointdef(string(mysql_row^[2]), 0);
                a_online_host := current_computer_list.GetByHostName(Name);
                if Assigned(a_online_host) then
                  begin
                    IP := a_online_host.IP;
                    Comment := a_online_host.Comment;
                  end;
                Online := current_computer_list.IsHostNameOnline(Name);
              end;
          end;
      end;
  finally

  end;
  mysql_free_result(mysql_res);
end;

procedure TIndexeurBleuSearchEngineFacade.FetchOfflineBrowserFolderContent(var Folder : TOfflineBrowserFolder);
var
  mysql_connection : PMYSQL;
  mysql_res : PMYSQL_RES;
  mysql_row : PMYSQL_ROW;
  sql : string;
  sql_ansi : AnsiString;
  i : cardinal;
  bs : string;
  a_folder : TOfflineBrowserFolder;
  a_file : TOfflineBrowserFile;
begin
  try
    if libmysql_load(nil) = LIBMYSQL_MISSING then
      begin
        MessageDlg('LIBMYSQL_MISSING', mtError, [mbOK], 0);
        Exit;
      end;
    mysql_connection := mysql_init(nil);
      if not (mysql_real_connect(mysql_connection, PAnsiChar(config_mysql_server), PAnsiChar(config_mysql_user), PAnsiChar(config_mysql_password), PAnsiChar(config_mysql_db), 0, nil, 0) <> nil) then
        begin
          MessageDlg('Impossible de se connecter au serveur!', mtError, [mbOK], 0);
          Exit;
        end;
    sql := 'SELECT id, name, path, size, ''file'' AS type FROM files WHERE parentFolderId = '+DoubleAsteriks(inttostr(Folder.Id))+' UNION SELECT id, name, path, size, ''folder'' AS type FROM folders WHERE parentFolderId = '+DoubleAsteriks(inttostr(Folder.Id))+'';
    OutputDebugStringFacade(sql);
    sql_ansi := AnsiString(sql);
      if mysql_real_query(mysql_connection, PAnsiChar(sql_ansi), length(sql_ansi)) = 0 then
        begin
          mysql_res := mysql_store_result(mysql_connection);
        end
      else
        begin
          MessageDlg('Ca chie!!', mtError, [mbOK], 0);
          Exit;
        end;

    OutputDebugStringFacade('Num rows: '+inttostr(mysql_num_rows(mysql_res)));
    if mysql_num_rows(mysql_res) > 0 then
      begin
        for i := 0 to mysql_num_rows(mysql_res) - 1 do
          begin
            mysql_row := mysql_fetch_row(mysql_res);
            bs := string(mysql_row^[4]);
            if bs = 'folder' then
              begin
                a_folder := TOfflineBrowserFolder.Create;
                a_folder.Id := strtointdef(string(mysql_row^[0]), 0);
                a_folder.Name := string(mysql_row^[1]);
                a_folder.Path := string(mysql_row^[2]);
                a_folder.Size := strtointdef(string(mysql_row^[3]), 0);
                Folder.AddFolder(a_folder);
              end
            else if bs = 'file' then
              begin
                a_file := TOfflineBrowserFile.Create;
                a_file.Id := strtointdef(string(mysql_row^[0]), 0);
                a_file.Name := string(mysql_row^[1]);
                a_file.Path := string(mysql_row^[2]);
                a_file.Size := strtointdef(string(mysql_row^[3]), 0);
                Folder.AddFile(a_file);
              end;
          end;
        Folder.ContentFetched := True;
      end;
  finally

  end;
  mysql_free_result(mysql_res);
end;

function TIndexeurBleuSearchEngineFacade.GetOfflineBrowserShareList(
  HostId: Integer): TOfflineBrowserShareList;
var
  mysql_connection : PMYSQL;
  mysql_res : PMYSQL_RES;
  mysql_row : PMYSQL_ROW;
  sql : string;
  sql_ansi : AnsiString;
  i : cardinal;
  a_share : TOfflineBrowserShare;
begin
  OutputDebugStringFacade('TIndexeurBleuSearchEngineFacade.GetOfflineBrowserShareList starts');
  Result := TOfflineBrowserShareList.Create;
  try
    if libmysql_load(nil) = LIBMYSQL_MISSING then
      begin
        MessageDlg('LIBMYSQL_MISSING', mtError, [mbOK], 0);
        Exit;
      end;
    mysql_connection := mysql_init(nil);
      if not (mysql_real_connect(mysql_connection, PAnsiChar(config_mysql_server), PAnsiChar(config_mysql_user), PAnsiChar(config_mysql_password), PAnsiChar(config_mysql_db), 0, nil, 0) <> nil) then
        begin
          MessageDlg('Impossible de se connecter au serveur!', mtError, [mbOK], 0);
          Exit;
        end;
    sql := 'SELECT id, name FROM folders WHERE computerId = '''+DoubleAsteriks(inttostr(HostId))+''' AND parentFolderId IS NULL';
    OutputDebugStringFacade('   '+sql);
    sql_ansi := AnsiString(sql);
      if mysql_real_query(mysql_connection, PAnsiChar(sql_ansi), length(sql_ansi)) = 0 then
        begin
          mysql_res := mysql_store_result(mysql_connection);
        end
      else
        begin
          MessageDlg('Ca chie!!', mtError, [mbOK], 0);
          Exit;
        end;

    OutputDebugStringFacade('Num rows: '+inttostr(mysql_num_rows(mysql_res)));
    if mysql_num_rows(mysql_res) > 0 then
      begin
        for i := 0 to mysql_num_rows(mysql_res) - 1 do
          begin
            mysql_row := mysql_fetch_row(mysql_res);
            a_share := TOfflineBrowserShare.Create;
            a_share.ID := strtointdef(string(mysql_row^[0]), 0);
            a_share.Name := string(mysql_row^[1]);
            a_share.HostID := HostId;
            OutputDebugStringFacade('Share: '+a_share.Name+' ('+inttostr(a_share.ID)+')');
            Result.Add(a_share);
          end;
      end;
  finally

  end;
  mysql_free_result(mysql_res);
end;

function TIndexeurBleuSearchEngineFacade.MakeSQLQuery(search_string : string; search_in : TSearchInEnum): string;
  procedure FullTextToListOfKeywords(fulltext : string; var outStringList : TStringList);
  var
    i : word;
    bs : string;
    inquote : boolean;
  begin
    outStringList := TStringList.Create;
    outStringList.Clear;
    bs := '';
    inquote := false;
    for i := 1 to length(fulltext) do
      begin
        if fulltext[i] = '"' then
          inquote := not inquote
        else if (fulltext[i] = ' ') and (not inquote) then
          begin
            outStringList.Add(bs);
            bs := '';
          end
        else
          bs := bs + fulltext[i];
      end;
    if bs <> '' then
      outStringList.Add(bs);
  end;
const
  regexp_video =  '^avi$|^mpg$|^wmv$|^rm$|^ra$|^mpeg$|^mp4$|^mov$';
  regexp_audio =  '^mp3$|^wma$|^ogg$|^rm$|^mid$|^midi$|^gp4$|^wav$';
  regexp_images = '^jpg$|^bmp$|^jpeg$|^gif$|^tga$|^png$|^tif$|^tiff$|^psd$';
var
  s : string;
  bsl : TStringList;
  regexpstring : string;
begin
  //UPDATE files SET ext = SUBSTRING(name, CHAR_LENGTH(name) - LOCATE('.', REVERSE(name)) + 2);
//  s := 'SELECT `nom`, `path`, `size`, `type`, `file_c_time`, `file_m_time` FROM `elements` WHERE `nom` REGEXP '''+DoubleAsteriks(searched_string)+''';';
  s := search_string;
  bsl := TStringList.Create;
  bsl.Clear;
//  FullTextToListOfKeywords(s, bsl);
//  ShowMessage('"'+bsl.Text+'"');
//  s := 'SELECT computers.name, files.name, files.size, files.path, files.modificationDate FROM files LEFT JOIN computers ON (computers.id = files.computerId) WHERE MATCH(files.name) AGAINST(''*'+DoubleAsteriks(search_string)+'*'' IN BOOLEAN MODE) ';
//SELECT computers.name, files.name, files.size, REPLACE(files.path, '/', '\\'), files.modificationDate FROM files LEFT JOIN computers ON (computers.id = files.computerId) WHERE files.name LIKE '%LOL%'
  s := 'SELECT computers.name, files.name, files.size, REPLACE(files.path, ''/'', ''\\''), files.modificationDate FROM files LEFT JOIN computers ON (computers.id = files.computerId) WHERE files.name LIKE ''%'+DoubleAsteriks(search_string)+'%'' ';

{  for i := 0 to bsl.Count - 1 do
    if bsl[i] <> '' then
      begin
        s := s + ' AND `'+charfield+'` LIKE ''%'+DoubleAsteriks(bsl[i])+'%''';
      end;}
  if siEveryFile in search_in then
    begin

    end
  else if siFolders in search_in then
    begin
//      s := s + ' AND `type` = 1 ';
    end
  else
    begin
      regexpstring := '';
      if siVideo in search_in then
        regexpstring := regexpstring + regexp_video;
      if siAudio in search_in then
        begin
          if regexpstring <> '' then
            regexpstring := regexpstring + '|';
          regexpstring := regexpstring + regexp_audio;
        end;
      if siImage in search_in then
        begin
          if regexpstring <> '' then
            regexpstring := regexpstring + '|';
          regexpstring := regexpstring + regexp_images;
        end;
        s := s + ' AND `ext` REGEXP ''('+regexpstring+')''';
    end;
  s := s + ';';
//  ShowMessage(s);
  Result := s;
  bsl.Free;
end;

procedure TIndexeurBleuSearchEngineFacade.SetCallbackTextInformation(
  new_value: TSearchEngineCallbackTextInformation);
begin
  FCallbackTextInformation := new_value;
end;

function TIndexeurBleuSearchEngineFacade.MakeSearch(search_string : string; search_in : TSearchInEnum): TSearch;
var
  mysql_connection : PMYSQL;
  mysql_res : PMYSQL_RES;
  mysql_row : PMYSQL_ROW;
  sql : string;
  sql_ansi : AnsiString;
  i : cardinal;
begin
  CallbackTextInformation('Début de la recherche: "'+search_string+'"');
  CallbackTextInformation('Connexion au serveur: '+'127.0.0.1');
  Result := nil;
  if libmysql_load(nil) = LIBMYSQL_MISSING then
    begin
      MessageDlg('LIBMYSQL_MISSING', mtError, [mbOK], 0);
      Exit;
    end;
  mysql_connection := mysql_init(nil);
    if not (mysql_real_connect(mysql_connection, PAnsiChar(config_mysql_server), PAnsiChar(config_mysql_user), PAnsiChar(config_mysql_password), PAnsiChar(config_mysql_db), 0, nil, 0) <> nil) then
      begin
        CallbackTextInformation('Impossible de se connecter au serveur!');
        Exit;
      end;
  CallbackTextInformation('Serveur atteint, recherche en cours...');
  sql := self.MakeSQLQuery(search_string, search_in); //'SELECT computers.name, files.name, files.size, files.path, files.modificationDate FROM files LEFT JOIN computers ON (computers.id = files.computerId) WHERE MATCH(files.name) AGAINST(''*'+search_string+'*'' IN BOOLEAN MODE);';
  sql_ansi := AnsiString(sql);
//  sqlstring := MakeSQLQuery(searched_string);
    if mysql_real_query(mysql_connection, PAnsiChar(sql_ansi), length(sql_ansi)) = 0 then
      begin
        mysql_res := mysql_store_result(mysql_connection);
      end
    else
      begin
        MessageDlg('Ca chie!!', mtError, [mbOK], 0);
        Exit;
      end;

  CallbackTextInformation('Traitements des résultats...');

  Result := TSearch.Create;
  Result.Searched_string := search_string;
  Result.SearchDate := Now();
  if mysql_num_rows(mysql_res) > 0 then
    begin
      SetLength(Result.Search_Results, mysql_num_rows(mysql_res));
      for i := 0 to mysql_num_rows(mysql_res) - 1 do
        begin
          mysql_row := mysql_fetch_row(mysql_res);
          Result.Search_Results[i] := TSearchResult.Create;
            //Pas oublié de faire ça avant le nom
//            if mysql_row^[3] = '1' then
//              Result.Search_Results[i].ItemType := itFolder
//            else
              Result.Search_Results[i].ItemType := itFile;
          Result.Search_Results[i].Name := string(mysql_row^[1]);

          with Result.Search_Results[i] do
            begin
              Host := string(mysql_row^[0]);
              Size := int64(StrToInt64Def(string(mysql_row^[2]), 0));
              Path := string(mysql_row^[3]);
//              DateCreation := UnixToDateTime(strtointdef(mysql_row^[4], 0));
              DateModification := UnixToDateTime(strtointdef(string(mysql_row^[4]), 0));
            end;
        end;
    end;

//      DataModule1.AddNewResultToDisplay(rindex);
  CallbackTextInformation('Done!');
  mysql_free_result(mysql_res);

end;

function UnixToDateTime(USec: Longint): TDateTime;
const
  // Sets UnixStartDate to TDateTime of 01/01/1970
  UnixStartDate: TDateTime = 25569.0;
begin
  Result := (Usec / 86400) + UnixStartDate;
end;

end.
