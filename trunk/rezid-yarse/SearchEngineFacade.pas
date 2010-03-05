unit SearchEngineFacade;

{
  YARSE, Yet Another REZID Search Engine
  Version 3.x
  ZeWaren / Erwan Martin
  Copyright 2010
  http://zewaren.net ; http://rezid.org
}

interface

uses Classes, OfflineBrowsing;

type

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

  TSearch = class
     Searched_string : string;
     SearchDate : TDateTime;
     Search_Results : array of TSearchResult;
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

  IAbstractSearchEngineFacade = interface
    function GetCallbackTextInformation : TSearchEngineCallbackTextInformation;
    procedure SetCallbackTextInformation(new_value : TSearchEngineCallbackTextInformation);
    property CallbackTextInformation : TSearchEngineCallbackTextInformation read GetCallbackTextInformation write SetCallbackTextInformation;
    function GetCurrentComputerList() : TOnlineHostList;
    function MakeSearch(search_string : string; search_in : TSearchInEnum) : TSearch;
    function GetOfflineBrowserComputerList : TOfflineBrowserHostArray;
    function GetOfflineBrowserShareList(HostId : Integer) : TOfflineBrowserShareList;
    procedure FetchOfflineBrowserFolderContent(var Folder : TOfflineBrowserFolder);
  end;

function GetFileTypeString(Extension : string) : string;
function GetConcreteSearchEngineFacade : IAbstractSearchEngineFacade;

implementation

uses ShellAPI, SysUtils, IndexeurBleuSearchEngine;

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

function GetConcreteSearchEngineFacade : IAbstractSearchEngineFacade;
begin
  Result := TIndexeurBleuSearchEngineFacade.Create;
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

end.
