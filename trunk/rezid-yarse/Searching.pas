unit Searching;

{
  YARSE, Yet Another REZID Search Engine
  Version 3.x
  ZeWaren / Erwan Martin
  Copyright 2010
  http://zewaren.net ; http://rezid.org
}

interface

uses Classes, ConstsAndVars;

type
  TSearchVFFolder = class;
  TSearchVFFolderArray = array of TSearchVFFolder;
  TSearchVFHost = class;
  TSearchVFHostArray = array of TSearchVFHost;
  TSearchVFFileType = class;
  TSearchVFFileTypeArray = array of TSearchVFFileType;

  TSearchIn = (siEveryFile, siFolders, siVideo, siAudio, siImage);
  TSearchInEnum = set of TSearchIn;

  TItemType = (itFile, itFolder);

  TSearchResult = class
  private
    FName: WideString;
    FSize: Int64;
    FPath : WideString;
    FHost : WideString;
    FHostOnline : boolean;
    FType : WideString;
    FItemType : TItemType;
    FDateCreation : TDateTime;
    FDateModification : TDateTime;
    procedure WriteName(input : WideString);
  public
    property Name : WideString read FName write WriteName;
    property Size : Int64 read FSize write FSize;
    property Path : WideString read FPath write FPath;
    property Host : WideString read FHost write FHost;
    property HostOnline : boolean read FHostOnline write FHostOnline;
    property FileType : WideString read FType write FType;
    property ItemType : TItemType read FItemType write FItemType;
    property DateCreation : TDateTime read FDateCreation write FDateCreation;
    property DateModification : TDateTime read FDateModification write FDateModification;
  end;

  TSearchResultArray = array of TSearchResult;

  TSearch = class
     Search_ID : Cardinal;
     Searched_string : string;
     SearchDate : TDateTime;
     Search_Results : TSearchResultArray;
     VFPhysicalTree : TSearchVFHostArray;
     VFPhysicalTreeFoldersIndex : TSearchVFFolderArray;
     VFFileTypes : TSearchVFFileTypeArray;
     constructor Create;
     procedure CreateVirtualFolders;
     function GetVHostByVID(vID : Cardinal) : TSearchVFHost;
     function FindFolderInIndex(vID : Cardinal) : TSearchVFFolder;
     function GetVTypeByVID(vID : Cardinal) : TSearchVFFileType;
  end;

  TSearchEngineCallbackTextInformation = procedure (text : string);

  TOnlineHost = class (TObject)
  private
    FID : Integer;
    FName: string;
    FIP : string;
    FComment : string;
    FOnline : boolean;
    FShareCount : word;
  public
    property ID : Integer read FID write FID;
    property Name : string read FName write FName;
    property IP : string read FIP write FIP;
    property Comment : string read FComment write FComment;
    property Online : boolean read FOnline write FOnline;
    property ShareCount : word read FShareCount write FShareCount;
  end;

  TOnlineHostList = class (TObject)
    private
     FList : TList;
    public
     constructor Create();
     destructor Destroy; override;
     procedure Add(item : TOnlineHost);
     procedure Remove(item : TOnlineHost);
     function Get(Index : integer) : TOnlineHost;
     function Count : integer;
     function IsHostNameOnline(host_name : string) : boolean;
     function GetByHostName(host_name : string) : TOnlineHost;
  end;

  {Search Virtual Folders}

  TSearchVFHost = class(TObject)
    protected
      FName : string;
      FFolders : TSearchVFFolderArray;
      FOnline : boolean;
      FvID : Integer;
    public
      property vID : Integer read FvID write FvID;
      property Name : string read FName write FName;
      property Folders : TSearchVFFolderArray read FFolders write FFolders;
      property Online : boolean read FOnline write FOnline;
      function GetSubFolder(FolderName : string) : TSearchVFFolder; overload;
      function GetSubFolder(vID : Cardinal) : TSearchVFFolder; overload;
      function GetOrCreateSubPath(Path : TStrings; var vID : Cardinal; var Index : TSearchVFFolderArray) : TSearchVFFolder;
  end;

  TSearchVFFileType = class(TObject)
    protected
      FName : string;
      FItems : TSearchResultArray;
      FAExt : string;
      FvID : Integer;
    public
      property vID : Integer read FvID write FvID;
      property Name : string read FName write FName;
      property AExt : string read FAExt write FAExt;
      property Items : TSearchResultArray read FItems write FItems;
  end;

  TSearchVFFolder = class(TObject)
    protected
      FName : string;
      FSubFolders : TSearchVFFolderArray;
      FItems : TSearchResultArray;
      FIsShare : boolean;
      FvID : Integer;
    public
      property vID : Integer read FvID write FvID;
      property Name : string read FName write FName;
      property SubFolders : TSearchVFFolderArray read FSubFolders write FSubFolders;
      property Items : TSearchResultArray read FItems write FItems;
      property IsShare : boolean read FIsShare write FIsShare;
      function GetSubFolder(FolderName : string) : TSearchVFFolder; overload;
      function GetSubFolder(vID : Cardinal) : TSearchVFFolder; overload;
      function GetOrCreateSubPath(Path : TStrings; var vID : Cardinal; var Index : TSearchVFFolderArray) : TSearchVFFolder;
  end;

var
  AllSearches : TList;

function GetFileTypeString(Extension : string) : string;
function GetSearchByID(SearchID : Cardinal) : TSearch;

implementation

uses ShellAPI, SysUtils, Dialogs, SearchEngineFacade;

function GetSearchByID(SearchID : Cardinal) : TSearch;
var
  i : word;
begin
  Result := nil;
  if AllSearches.Count > 0 then
    begin
      for i := 0 to AllSearches.Count - 1 do
        if TSearch(AllSearches[i]).Search_ID = SearchID then
          begin
            Result := TSearch(AllSearches[i]);
            Break;
          end;
    end;
end;

function GetFileTypeString(Extension : string) : string;
var
  SHFileInfo: TSHFileInfo;
begin
   if length(Extension) = 0 then
     Extension := '.'
   else if Extension[1] <> '.' then Extension := '.' + Extension;   //Il faut le "." avant
  SHGetFileInfo(PChar(Extension), 0, SHFileInfo, SizeOf(TSHFileInfo),
                SHGFI_SYSICONINDEX or SHGFI_USEFILEATTRIBUTES or SHGFI_TYPENAME);
  Result := SHFileInfo.szTypeName;
end;

procedure TSearchResult.WriteName(input: WideString);
begin
  FName := input;
  if ItemType = itFolder then
    FileType := 'Folder'
  else
    FileType := GetFileTypeString(ExtractFileExt(FName));
end;

{ TOnlineHost }

procedure TOnlineHostList.Add(
  item: TOnlineHost);
begin
  FList.Add(item);
end;

function TOnlineHostList.Count: integer;
begin
  Result := FList.Count;
end;

constructor TOnlineHostList.Create;
begin
  FList := TList.Create;
end;

destructor TOnlineHostList.Destroy;
begin
  FList.Free;
  inherited;
end;

function TOnlineHostList.Get(
  Index: integer): TOnlineHost;
begin
  Result := FList.Items[Index];
end;

function TOnlineHostList.GetByHostName(host_name: string): TOnlineHost;
var
  i : word;
begin
  if FList.Count = 0 then
    begin
      Result := nil;
      Exit;
    end;
  for i := 0 to FList.Count - 1 do
    begin
      if UpperCase(TOnlineHost(FList[i]).Name) = UpperCase(host_name) then
        begin
          Result := TOnlineHost(FList[i]);
          Exit;
        end;
    end;
  Result := nil;
end;

function TOnlineHostList.IsHostNameOnline(host_name: string): boolean;
var
  i : word;
begin
  if FList.Count = 0 then
    begin
      Result := False;
      Exit;
    end;
  for i := 0 to FList.Count - 1 do
    begin
      if UpperCase(TOnlineHost(FList[i]).Name) = UpperCase(host_name) then
        begin
          Result := TOnlineHost(FList[i]).Online;
          Exit;
        end;
    end;
  Result := False;
end;

procedure TOnlineHostList.Remove(
  item: TOnlineHost);
begin
  FList.Remove(item);
end;

{ TSearch }

{ TSearch }

constructor TSearch.Create;
begin
  inherited;
  VFPhysicalTree := nil;
  VFPhysicalTreeFoldersIndex := nil;
end;

  function SplitStrings(const str: string; const separator: string;
                        Strings: TStrings): TStrings;
  // Fills a string list with the parts of "str" separated by
  // "separator". If Nil is passed instead of a string list,
  // the function creates a TStringList object which has to
  // be freed by the caller
  var
    n: integer;
    p, q, s: PChar;
    item: string;
  begin
    if Strings = nil then
      Result := TStringList.Create
    else
      Result := Strings;
    try
      p := PChar(str);
      s := PChar(separator);
      n := Length(separator);
      repeat
        q := StrPos(p, s);
        if q = nil then q := StrScan(p, #0);
        SetString(item, p, q - p);
        Result.Add(item);
        p := q + n;
      until q^ = #0;
    except
      item := '';
      if Strings = nil then Result.Free;
      raise;
    end;
  end;

function SearchResultComparePath(Item1, Item2: Pointer): Integer;
var
  Path1, Path2 : string;
begin
  Path1 := TSearchResult(Item1).Path;
  Path2 := TSearchResult(Item2).Path;
  Result := CompareStr(Path1, Path2);
end;

function SearchResultCompareType(Item1, Item2: Pointer): Integer;
var
  Type1, Type2 : string;
begin
  Type1 := TSearchResult(Item1).FileType;
  Type2 := TSearchResult(Item2).FileType;
  Result := CompareStr(Type1, Type2);
end;

procedure TSearch.CreateVirtualFolders;
  procedure RemoveEmptyLines(var sl : TStrings);
  var
    i : cardinal;
  begin
    if sl.Count = 0 then
      Exit;
    for i := sl.Count - 1 downto 0 do
      if sl[i] = '' then
        sl.Delete(i);
  end;
var
  AList : TList;
  ASplitList : TStrings;
  i : word;
  aSearchResult : TSearchResult;
  CurrentHost : TSearchVFHost;
  CurrentFolder : TSearchVFFolder;
  vId, vIDFolder : Cardinal;
  Facade : IAbstractSearchEngineFacade;
  OnlineHosts : TOnlineHostList;
  CurrentFileType : TSearchVFFileType;
begin
  AList := TList.Create;
  for aSearchResult in Self.Search_Results do
    begin
      AList.Add(aSearchResult);
    end;
  //Physical Tree
  AList.Sort(SearchResultComparePath);
  vId := 0;
  if AList.Count > 0 then
    begin
      Facade := GetConcreteSearchEngineFacade;
      OnlineHosts := Facade.GetCurrentComputerList;

      ASplitList := TStringList.Create;
      ASplitList.Delimiter := '\';
      ASplitList.StrictDelimiter := True;
      CurrentHost := nil;
      vIDFolder := 0;
      for i := 0 to AList.Count - 1 do
        begin
          ASplitList.Clear;
          aSearchResult := aList[i];
          ASplitList.DelimitedText := aSearchResult.Path;
          RemoveEmptyLines(ASplitList);
          if ASplitList.Count < 2 then
            continue;
          if (not Assigned(CurrentHost)) or (ASplitList[0] <> CurrentHost.Name) then
            begin
              CurrentHost := TSearchVFHost.Create;
              CurrentHost.Name := ASplitList[0];
              CurrentHost.Online := OnlineHosts.IsHostNameOnline(CurrentHost.Name);
              Inc(vId);
              CurrentHost.FvID := vId;
              SetLength(Self.VFPhysicalTree, Length(Self.VFPhysicalTree)+1);
              Self.VFPhysicalTree[Length(Self.VFPhysicalTree)-1] := CurrentHost;
            end;
          ASplitList.Delete(0);
          CurrentFolder := CurrentHost.GetOrCreateSubPath(ASplitList, vIDFolder, Self.VFPhysicalTreeFoldersIndex);
          SetLength(CurrentFolder.FItems, Length(CurrentFolder.FItems)+1);
          CurrentFolder.FItems[Length(CurrentFolder.FItems)-1] := aSearchResult;
        end;
      ASplitList.Free;
    end;

  //Type tree
  AList.Sort(SearchResultCompareType);
  vId := 0;
  CurrentFileType := nil;
  if AList.Count > 0 then
    begin
      for i := 0 to AList.Count - 1 do
        begin
          aSearchResult := aList[i];
          if (not Assigned(CurrentFileType)) or (CurrentFileType.FName <> aSearchResult.FileType) then
            begin
              CurrentFileType := TSearchVFFileType.Create;
              Inc(vId);
              CurrentFileType.vID := vId;
              CurrentFileType.FName := aSearchResult.FileType;
              CurrentFileType.AExt := ExtractFileExt(aSearchResult.FName);
              SetLength(Self.VFFileTypes, Length(Self.VFFileTypes)+1);
              Self.VFFileTypes[Length(Self.VFFileTypes)-1] := CurrentFileType;
            end;
          SetLength(CurrentFileType.FItems, Length(CurrentFileType.FItems)+1);
          CurrentFileType.FItems[Length(CurrentFileType.FItems)-1] := aSearchResult;
        end;
    end;

  AList.Free;
end;

function TSearch.FindFolderInIndex(vID: Cardinal): TSearchVFFolder;
var
  i : Cardinal;
begin
  Result := nil;
  if Length(VFPhysicalTreeFoldersIndex) > 0 then
    for i := 0 to Length(VFPhysicalTreeFoldersIndex) - 1 do
      begin
        if TSearchVFFolder(VFPhysicalTreeFoldersIndex[i]).vID = vID then
          begin
            Result := TSearchVFFolder(VFPhysicalTreeFoldersIndex[i]);
            Break;
          end;
      end;
end;

function TSearch.GetVHostByVID(vID: Cardinal): TSearchVFHost;
var
  aHost : TSearchVFHost;
begin
  Result := nil;
  for aHost in VFPhysicalTree do
  begin
    if aHost.vID = vID then
      begin
        Result := aHost;
        Break;
      end;
  end;
end;

function TSearch.GetVTypeByVID(vID: Cardinal): TSearchVFFileType;
var
  aType : TSearchVFFileType;
begin
  Result := nil;
  for aType in VFFileTypes do
  begin
    if aType.vID = vID then
      begin
        Result := aType;
        Break;
      end;
  end;
end;

{ TSearchVFHost }

function TSearchVFHost.GetOrCreateSubPath(Path: TStrings; var vID : Cardinal; var Index : TSearchVFFolderArray): TSearchVFFolder;
var
  SubFolder : TSearchVFFolder;
  SubPath : TStrings;
begin
  Result := nil;
  if Path.Count = 0 then
    Exit;
  SubFolder := GetSubFolder(Path[0]);
  if not Assigned(SubFolder) then
    begin
      SubFolder := TSearchVFFolder.Create;
      SubFolder.Name := Path[0];
      SubFolder.IsShare := True;
      Inc(vID);
      SubFolder.vID := vID;
      SetLength(FFolders, Length(Self.FFolders)+1);
      FFolders[Length(Self.FFolders)-1] := SubFolder;
      SetLength(Index, Length(Index)+1);
      Index[Length(Index)-1] := SubFolder;
    end;

  if Path.Count > 1 then
    begin
      SubPath := TStringList.Create;
      SubPath.Assign(Path);
      SubPath.Delete(0);
      Result := SubFolder.GetOrCreateSubPath(SubPath, vID, Index);
      SubPath.Free;
    end
  else
    Result := SubFolder;
end;

function TSearchVFHost.GetSubFolder(FolderName: string): TSearchVFFolder;
var
  i : word;
begin
  Result := nil;
  if Length(FFolders) > 0 then
    begin
      for i := 0 to Length(FFolders) - 1 do
        if FFolders[i].FName = FolderName then
          begin
            Result := FFolders[i];
            Break;
          end;
    end;
end;

function TSearchVFFolder.GetOrCreateSubPath(Path: TStrings; var vID : Cardinal; var Index : TSearchVFFolderArray): TSearchVFFolder;
var
  SubFolder : TSearchVFFolder;
  SubPath : TStrings;
begin
  Result := nil;
  if Path.Count = 0 then
    Exit;
  SubFolder := GetSubFolder(Path[0]);
  if not Assigned(SubFolder) then
    begin
      SubFolder := TSearchVFFolder.Create;
      SubFolder.Name := Path[0];
      Inc(vID);
      SubFolder.vID := vID;
      SetLength(FSubFolders, Length(FSubFolders)+1);
      SubFolders[Length(FSubFolders)-1] := SubFolder;
      SetLength(Index, Length(Index)+1);
      Index[Length(Index)-1] := SubFolder;
    end;

  if Path.Count > 1 then
    begin
      SubPath := TStringList.Create;
      SubPath.Assign(Path);
      SubPath.Delete(0);
      Result := SubFolder.GetOrCreateSubPath(SubPath, vID, Index);
      SubPath.Free;
    end
  else
    Result := SubFolder;
end;

function TSearchVFFolder.GetSubFolder(FolderName: string): TSearchVFFolder;
var
  i : word;
begin
  Result := nil;
  if Length(FSubFolders) > 0 then
    begin
      for i := 0 to Length(FSubFolders) - 1 do
        if FSubFolders[i].FName = FolderName then
          begin
            Result := FSubFolders[i];
            Break;
          end;
    end;
end;

function TSearchVFFolder.GetSubFolder(vID: Cardinal): TSearchVFFolder;
var
  i : word;
begin
  Result := nil;
  if Length(FSubFolders) > 0 then
    begin
      for i := 0 to Length(FSubFolders) - 1 do
        if FSubFolders[i].vID = vID then
          begin
            Result := FSubFolders[i];
            Break;
          end;
    end;
end;

function TSearchVFHost.GetSubFolder(vID: Cardinal): TSearchVFFolder;
var
  i : word;
begin
  Result := nil;
  if Length(FFolders) > 0 then
    begin
      for i := 0 to Length(FFolders) - 1 do
        if FFolders[i].vID = vID then
          begin
            Result := FFolders[i];
            Break;
          end;
    end;
end;

initialization
  AllSearches := TList.Create;

finalization
  AllSearches.Free;

end.
