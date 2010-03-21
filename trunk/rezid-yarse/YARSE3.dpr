library YARSE3;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

{
  YARSE, Yet Another REZID Search Engine
  Version 3.x
  ZeWaren / Erwan Martin
  Copyright 2010
  http://zewaren.net ; http://rezid.org
}


uses
  ExceptionLog,
  ComServ,
  SysUtils,
  Classes,
  Windows,
  ShellFolder in 'ShellFolder.pas',
  ShellFolderView in 'ShellFolderView.pas',
  ConstsAndVars in 'ConstsAndVars.pas',
  ShellFolderD in 'ShellFolderD.pas',
  PIDLs in 'PIDLs.pas',
  ShellFolderMainMenu in 'ShellFolders\ShellFolderMainMenu.pas',
  SearchEngineFacade in 'SearchEngineFacade.pas',
  IndexeurBleuSearchEngine in 'Facades\IndexeurBleuSearchEngine.pas',
  Searching in 'Searching.pas',
  OfflineBrowsing in 'OfflineBrowsing.pas',
  ItemProp in 'Includes\ItemProp.pas',
  mysql in 'Includes\mysql.pas',
  NewSearch in 'Forms\NewSearch.pas' {FNewSearch},
  ShellFolderOfflineBrowserRoot in 'ShellFolders\ShellFolderOfflineBrowserRoot.pas',
  ShellFolderOfflineBrowserHost in 'ShellFolders\ShellFolderOfflineBrowserHost.pas',
  ShellFolderOfflineBrowserFolder in 'ShellFolders\ShellFolderOfflineBrowserFolder.pas',
  ShellIcons in 'ShellIcons.pas',
  ShellFolderNewSearch in 'ShellFolders\ShellFolderNewSearch.pas',
  ShellFolderSearchResults in 'ShellFolders\ShellFolderSearchResults.pas',
  ShellFolderSearchResultsHostsFolder in 'ShellFolders\ShellFolderSearchResultsHostsFolder.pas',
  ShellFolderSearchResultsHostsRoot in 'ShellFolders\ShellFolderSearchResultsHostsRoot.pas',
  ShellFolderSearchResultsHostsHost in 'ShellFolders\ShellFolderSearchResultsHostsHost.pas',
  ShellFolderSearchResultsTypesRoot in 'ShellFolders\ShellFolderSearchResultsTypesRoot.pas',
  ShellFolderSearchResultsTypesType in 'ShellFolders\ShellFolderSearchResultsTypesType.pas';

{$R *.res}
{$R AdditionalRessources.res}

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer;

begin

end.

