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
  TOfflineBrowserShare = class(TObject)
  private
    FID : Integer;
    FHostId : Integer;
    FName : string;
    FComment : string;
  public
    property ID : Integer read FID write FID;
    property HostID : Integer read FHostId write FHostId;
    property Name : string read FName write FName;
    property Comment : string read FComment write FComment;
  end;

  TOfflineBrowserShareList = class
    private
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
  private
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

var
  OfflineBrowserHostList : TOfflineBrowserHostArray = nil;
  OfflineBrowserCritSect : TRTLCriticalSection;

  OfflineBrowserSharesCritSect : TRTLCriticalSection;

function GetHostByID(HostList : TOfflineBrowserHostArray; HostId : integer) : TOfflineBrowserHost;
procedure UpdateOfflineBrowsingHostList;
function GetHostShares(Host : TOfflineBrowserHost) : TOfflineBrowserShareList;

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
    Host.SharesFetched := True;
  finally
    LeaveCriticalSection(OfflineBrowserSharesCritSect);
  OutputDebugStringFacade('GetHostShares Ends');
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

initialization
  InitializeCriticalSection(OfflineBrowserCritSect);
  InitializeCriticalSection(OfflineBrowserSharesCritSect);

finalization
  DeleteCriticalSection(OfflineBrowserCritSect);
  DeleteCriticalSection(OfflineBrowserSharesCritSect);

end.
