unit OfflineBrowsing;

{
  YARSE, Yet Another REZID Search Engine
  Version 3.x
  ZeWaren / Erwan Martin
  Copyright 2010
  http://zewaren.net ; http://rezid.org
}

interface

uses ShlObj, ConstsAndVars, Windows;

type
  TOfflineBrowserHost = class (TObject)
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

  TOfflineBrowserHostArray = array of TOfflineBrowserHost;

var
  OfflineBrowserHostList : TOfflineBrowserHostArray = nil;
  OfflineBrowserCritSect : TRTLCriticalSection;

function GetHostByID(HostList : TOfflineBrowserHostArray; HostId : integer) : TOfflineBrowserHost;
procedure UpdateOfflineBrowsingHostList;

implementation

uses SearchEngineFacade, Dialogs, Forms, Controls;

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

initialization
  InitializeCriticalSection(OfflineBrowserCritSect);

finalization
  DeleteCriticalSection(OfflineBrowserCritSect);

end.
