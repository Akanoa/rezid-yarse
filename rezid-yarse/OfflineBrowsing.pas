unit OfflineBrowsing;

{
  YARSE, Yet Another REZID Search Engine
  Version 3.x
  ZeWaren / Erwan Martin
  Copyright 2010
  http://zewaren.net ; http://rezid.org
}

interface

uses ShlObj, ConstsAndVars, Windows, Classes;

type
  TOfflineBrowserFolder = class;

  TOfflineBrowserFile = class(TObject)
    protected
      FId : Integer;
      FName : string;
      FPath : string;
      FSize : Integer;
      FParentFolder : TOfflineBrowserFolder;
      FHostId : Integer;
    public
      property Id : Integer read FId write FId;
      property Name : string read FName write FName;
      property Path : string read FPath write FPath;
      property Size : Integer read FSize write FSize;
      property ParentFolder : TOfflineBrowserFolder read FParentFolder write FParentFolder;
      property HostId : Integer read FHostId write FHostId;
  end;
  TOfflineBrowserFileArray = array of TOfflineBrowserFile;

  TOfflineBrowserFolderArray = array of TOfflineBrowserFolder;
  TOfflineBrowserFolder = class(TObject)
    protected
      FId : Integer;
      FName : string;
      FPath : string;
      FSize : Integer;
      FParentFolder : TOfflineBrowserFolder;
      FHostId : Integer;
      FSubFolders : TOfflineBrowserFolderArray;
      FFiles : TOfflineBrowserFileArray;
      FContentFetched : boolean;
    public
      property Id : Integer read FId write FId;
      property Name : string read FName write FName;
      property Path : string read FPath write FPath;
      property Size : Integer read FSize write FSize;
      property ParentFolder : TOfflineBrowserFolder read FParentFolder write FParentFolder;
      property HostId : Integer read FHostId write FHostId;
      property SubFolders : TOfflineBrowserFolderArray read FSubFolders write FSubFolders;
      property Files : TOfflineBrowserFileArray read FFiles write FFiles;
      property ContentFetched : boolean read FContentFetched write FContentFetched;
      constructor Create;
      destructor Destroy; override;
      function FindFileById(FileID : Integer) : TOfflineBrowserFile;
      function FindSubFolderById(FolderID : Integer) : TOfflineBrowserFolder;
      procedure AddFolder(Folder : TOfflineBrowserFolder);
      procedure AddFile(aFile : TOfflineBrowserFile);
  end;

  TOfflineBrowserShare = class(TObject)
  protected
    FID : Integer;
    FHostId : Integer;
    FName : string;
    FComment : string;
    FSelfAsFolder : TOfflineBrowserFolder;
  public
    property ID : Integer read FID write FID;
    property HostID : Integer read FHostId write FHostId;
    property Name : string read FName write FName;
    property Comment : string read FComment write FComment;
    property SelfAsFolder : TOfflineBrowserFolder read FSelfAsFolder write FSelfAsFolder;
    constructor Create;
    destructor Destroy; override;
  end;

  TOfflineBrowserShareList = class
    protected
      FList : TList;
    public
      procedure Add(aShare : TOfflineBrowserShare);
      procedure Clear;
      procedure Remove(aShare : TOfflineBrowserShare);
      function Count : Cardinal;
      function Item(Index : Cardinal) : TOfflineBrowserShare;
      function GetByID(ShareID : Integer) : TOfflineBrowserShare;
//      procedure MergeWith(MWith : TOfflineBrowserShareList);
      constructor Create;
      destructor Destroy; override;
  end;

  TOfflineBrowserHost = class (TObject)
  protected
    FID : Integer;
    FName: string;
    FIP : string;
    FComment : string;
    FOnline : boolean;
    FShareCount : word;
    FShares : TOfflineBrowserShareList;
    FSharesFetched : Boolean;
  public
    property ID : Integer read FID write FID;
    property Name : string read FName write FName;
    property IP : string read FIP write FIP;
    property Comment : string read FComment write FComment;
    property Online : boolean read FOnline write FOnline;
    property ShareCount : word read FShareCount write FShareCount;
    property Shares : TOfflineBrowserShareList read FShares write FShares;
    property SharesFetched : Boolean read FSharesFetched write FSharesFetched;
    constructor Create;
    constructor CreateEmpty;
    destructor Destroy; override;
  end;

  TOfflineBrowserHostArray = array of TOfflineBrowserHost;

  TOfflineBrowserFolderIDIndexElement = class
    protected
      FFolderId : Integer;
      FFolderRef : TOfflineBrowserFolder;
    public
      property FolderId : Integer read FFolderId write FFolderId;
      property FolderRef : TOfflineBrowserFolder read FFolderRef write FFolderRef;
  end;

var
  OfflineBrowserHostList : TOfflineBrowserHostArray = nil;
  OfflineBrowserCritSect : TRTLCriticalSection;
  OfflineBrowserSharesCritSect : TRTLCriticalSection;
  OfflineBrowserFolderCritSect : TRTLCriticalSection;
  OfflineBrowserFolderIDIndex : TList;

function GetHostByID(HostList : TOfflineBrowserHostArray; HostId : integer) : TOfflineBrowserHost;
procedure UpdateOfflineBrowsingHostList;
function GetHostShares(Host : TOfflineBrowserHost) : TOfflineBrowserShareList;
procedure FetchOfflineBrowserFolderContent(var Folder : TOfflineBrowserFolder);
procedure AddFolderToIndex(Folder : TOfflineBrowserFolder);
function FindFolderInIndex(FolderID : Integer) : TOfflineBrowserFolder;

implementation

uses SearchEngineFacade, Dialogs, Forms, Controls, SysUtils;

function GetHostByID(HostList : TOfflineBrowserHostArray; HostId : integer) : TOfflineBrowserHost;
var
  a_host : TOfflineBrowserHost;
begin
  EnterCriticalSection(OfflineBrowserCritSect);
  try
    Result := nil;
    for a_host in HostList do
      begin
        if a_host.ID = HostId then
          begin
            Result := a_host;
            Break;
          end;
      end;
  finally
    LeaveCriticalSection(OfflineBrowserCritSect);
  end;
end;

procedure UpdateOfflineBrowsingHostList;
var
  YARSEFacade : IAbstractSearchEngineFacade;
begin
  EnterCriticalSection(OfflineBrowserCritSect);
  try
    if Assigned(OfflineBrowserHostList) then
      Exit;
    YARSEFacade := GetConcreteSearchEngineFacade;
    OfflineBrowserHostList := YARSEFacade.GetOfflineBrowserComputerList;
  finally
    LeaveCriticalSection(OfflineBrowserCritSect);
  end;
end;

function GetHostShares(Host : TOfflineBrowserHost) : TOfflineBrowserShareList;
var
  YARSEFacade : IAbstractSearchEngineFacade;
  i : word;
  aFolder : TOfflineBrowserFolder;
begin
  EnterCriticalSection(OfflineBrowserSharesCritSect);
  OutputDebugStringFacade('GetHostShares Starts');
  try
    if Host.FSharesFetched then
      begin
        Result := Host.Shares;
        Exit;
      end;
    YARSEFacade := GetConcreteSearchEngineFacade;
    if Assigned(Host.Shares) then
      Host.Shares.Free;
    OutputDebugStringFacade('GetHostShares Fetches');
    Host.Shares := YARSEFacade.GetOfflineBrowserShareList(Host.ID);
    OutputDebugStringFacade('GetHostShares Fetched: '+inttostr(Host.Shares.Count));
    Result := Host.Shares;
    if Host.Shares.Count > 0 then
      for i := 0 to Host.Shares.Count - 1 do
        begin
          aFolder := TOfflineBrowserFolder.Create;
          aFolder.Id := Host.Shares.Item(i).ID;
          aFolder.Name := Host.Shares.Item(i).Name;
          AddFolderToIndex(aFolder);
        end;
    Host.SharesFetched := True;
  finally
    LeaveCriticalSection(OfflineBrowserSharesCritSect);
  OutputDebugStringFacade('GetHostShares Ends');
  end;
end;

procedure FetchOfflineBrowserFolderContent(var Folder : TOfflineBrowserFolder);
var
  YARSEFacade : IAbstractSearchEngineFacade;
  i : word;
begin
  EnterCriticalSection(OfflineBrowserFolderCritSect);
  try
    if Folder.ContentFetched then
      Exit;
    YARSEFacade := GetConcreteSearchEngineFacade;
    YARSEFacade.FetchOfflineBrowserFolderContent(Folder);
    if Length(Folder.SubFolders) > 0 then
      for i := 0 to Length(Folder.SubFolders) - 1 do
        begin
          AddFolderToIndex(Folder.SubFolders[i]);
        end;
  finally
    LeaveCriticalSection(OfflineBrowserFolderCritSect);
  end;
end;

procedure AddFolderToIndex(Folder : TOfflineBrowserFolder);
var
  aIndex : TOfflineBrowserFolderIDIndexElement;
begin
  aIndex := TOfflineBrowserFolderIDIndexElement.Create;
  aIndex.FolderId := Folder.Id;
  aIndex.FFolderRef := Folder;
  OfflineBrowserFolderIDIndex.Add(aIndex);
end;

function FindFolderInIndex(FolderID : Integer) : TOfflineBrowserFolder;
var
  i : Cardinal;
begin
  Result := nil;
  if OfflineBrowserFolderIDIndex.Count > 0 then
    for i := 0 to OfflineBrowserFolderIDIndex.Count - 1 do
      begin
        if TOfflineBrowserFolderIDIndexElement(OfflineBrowserFolderIDIndex[i]).FFolderId = FolderID then
          begin
            Result := TOfflineBrowserFolderIDIndexElement(OfflineBrowserFolderIDIndex[i]).FFolderRef;
            Break;
          end;
      end;
end;

{ TOfflineBrowserShareList }

procedure TOfflineBrowserShareList.Add(aShare: TOfflineBrowserShare);
begin
  if Assigned(GetByID(aShare.ID)) then
    Exit;
  FList.Add(aShare);
end;

procedure TOfflineBrowserShareList.Clear;
begin
  FList.Clear;
end;

function TOfflineBrowserShareList.Count: Cardinal;
begin
  Result := FList.Count;
end;

constructor TOfflineBrowserShareList.Create;
begin
  inherited;
  FList := TList.Create;
end;

destructor TOfflineBrowserShareList.Destroy;
begin
  FList.Free;
  inherited;
end;


function TOfflineBrowserShareList.GetByID(
  ShareID: Integer): TOfflineBrowserShare;
var
  aShare : Pointer;
begin
  Result := nil;
  for aShare in FList do
  begin
    if TOfflineBrowserShare(aShare).FID = ShareID then
      begin
        Result := aShare;
        Break;
      end;
  end;
end;

function TOfflineBrowserShareList.Item(Index: Cardinal): TOfflineBrowserShare;
begin
  Result := TOfflineBrowserShare(FList[Index]);
end;

//procedure TOfflineBrowserShareList.MergeWith(MWith: TOfflineBrowserShareList);
//var
//  aShare : Pointer;
//begin
//  for aShare in MWith.FList do
//  begin
//    Self.Add(aShare);
//  end;
//end;

procedure TOfflineBrowserShareList.Remove(aShare: TOfflineBrowserShare);
begin
  FList.Remove(aShare);
end;

{ TOfflineBrowserHost }

constructor TOfflineBrowserHost.Create;
begin
  FSharesFetched := False;
  FShares := TOfflineBrowserShareList.Create;
end;

constructor TOfflineBrowserHost.CreateEmpty;
begin
  Create;
  FName := 'Unknown Host';
end;

destructor TOfflineBrowserHost.Destroy;
begin
  FShares.Free;
  inherited;
end;

{ TOfflineBrowserShare }

constructor TOfflineBrowserShare.Create;
begin
  inherited;
  SelfAsFolder := TOfflineBrowserFolder.Create;
end;

destructor TOfflineBrowserShare.Destroy;
begin
  FSelfAsFolder.Free;
  inherited;
end;

{ TOfflineBrowserFolder }

procedure TOfflineBrowserFolder.AddFile(aFile: TOfflineBrowserFile);
begin
  SetLength(FFiles, length(FFiles)+1);
  FFiles[Length(FFiles)-1] := aFile;
end;

procedure TOfflineBrowserFolder.AddFolder(Folder: TOfflineBrowserFolder);
begin
  SetLength(FSubFolders, length(FSubFolders)+1);
  FSubFolders[Length(FSubFolders)-1] := Folder;
end;

constructor TOfflineBrowserFolder.Create;
begin
  FFiles := nil;
  FSubFolders := nil;
  FContentFetched := False;
end;

destructor TOfflineBrowserFolder.Destroy;
begin

  inherited;
end;

function TOfflineBrowserFolder.FindFileById(
  FileID: Integer): TOfflineBrowserFile;
var
  i : Cardinal;
begin
  Result := nil;
  if not Self.ContentFetched then
    Exit;
  if length(Self.FFiles) > 0 then
    for i := 0 to length(self.Files) - 1 do
      if TOfflineBrowserFile(Self.Files[i]).Id = FileID then
        begin
          Result := Self.FFiles[i];
          Break;
        end;
end;

function TOfflineBrowserFolder.FindSubFolderById(
  FolderID: Integer): TOfflineBrowserFolder;
var
  i : Cardinal;
begin
  Result := nil;
  if not Self.ContentFetched then
    Exit;
  if length(Self.FSubFolders) > 0 then
    for i := 0 to length(self.Files) - 1 do
      if TOfflineBrowserFolder(Self.FSubFolders[i]).Id = FolderID then
        begin
          Result := Self.FSubFolders[i];
          Break;
        end;
end;

initialization
  InitializeCriticalSection(OfflineBrowserCritSect);
  InitializeCriticalSection(OfflineBrowserSharesCritSect);
  InitializeCriticalSection(OfflineBrowserFolderCritSect);
  OfflineBrowserFolderIDIndex := TList.Create;

finalization
  OfflineBrowserFolderIDIndex.Free;
  DeleteCriticalSection(OfflineBrowserFolderCritSect);
  DeleteCriticalSection(OfflineBrowserSharesCritSect);
  DeleteCriticalSection(OfflineBrowserCritSect);

end.
