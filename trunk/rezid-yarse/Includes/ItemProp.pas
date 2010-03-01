{$I DFS.INC}  { Standard defines for all Delphi Free Stuff components }

{$Define DFS_NO_COM_CLEANUP}
{$Define DFS_COMPILER_3_UP}
{$Define DFS_COMPILER_4_UP}
{$Define DFS_DELPHI}
{ -----------------------------------------------------------------------------}
{ ItemProp v3.12                                                               }
{ -----------------------------------------------------------------------------}
{ A unit to provide access to a file's context menu, properties dialog, and    }
{ default action.                                                              }
{                                                                              }
{ Copyright 1999, Brad Stowers.  All Rights Reserved.                          }
{                                                                              }
{ Copyright:                                                                   }
{ All Delphi Free Stuff (hereafter "DFS") source code is copyrighted by        }
{ Bradley D. Stowers (hereafter "author"), and shall remain the exclusive      }
{ property of the author.                                                      }
{                                                                              }
{ Distribution Rights:                                                         }
{ You are granted a non-exlusive, royalty-free right to produce and distribute }
{ compiled binary files (executables, DLLs, etc.) that are built with any of   }
{ the DFS source code unless specifically stated otherwise.                    }
{ You are further granted permission to redistribute any of the DFS source     }
{ code in source code form, provided that the original archive as found on the }
{ DFS web site (http://www.delphifreestuff.com) is distributed unmodified. For }
{ example, if you create a descendant of TDFSColorButton, you must include in  }
{ the distribution package the colorbtn.zip file in the exact form that you    }
{ downloaded it from http://www.delphifreestuff.com/mine/files/colorbtn.zip.   }
{                                                                              }
{ Restrictions:                                                                }
{ Without the express written consent of the author, you may not:              }
{   * Distribute modified versions of any DFS source code by itself. You must  }
{     include the original archive as you found it at the DFS site.            }
{   * Sell or lease any portion of DFS source code. You are, of course, free   }
{     to sell any of your own original code that works with, enhances, etc.    }
{     DFS source code.                                                         }
{   * Distribute DFS source code for profit.                                   }
{                                                                              }
{ Warranty:                                                                    }
{ There is absolutely no warranty of any kind whatsoever with any of the DFS   }
{ source code (hereafter "software"). The software is provided to you "AS-IS", }
{ and all risks and losses associated with it's use are assumed by you. In no  }
{ event shall the author of the softare, Bradley D. Stowers, be held           }
{ accountable for any damages or losses that may occur from use or misuse of   }
{ the software.                                                                }
{                                                                              }
{ Support:                                                                     }
{ Support is provided via the DFS Support Forum, which is a web-based message  }
{ system.  You can find it at http://www.delphifreestuff.com/discus/           }
{ All DFS source code is provided free of charge. As such, I can not guarantee }
{ any support whatsoever. While I do try to answer all questions that I        }
{ receive, and address all problems that are reported to me, you must          }
{ understand that I simply can not guarantee that this will always be so.      }
{                                                                              }
{ Clarifications:                                                              }
{ If you need any further information, please feel free to contact me directly.}
{ This agreement can be found online at my site in the "Miscellaneous" section.}
{------------------------------------------------------------------------------}
{ The lateset version of my components are always available on the web at:     }
{   http://www.delphifreestuff.com/                                            }
{ See ItemProp.txt for notes, known issues, and revision history.              }
{ -----------------------------------------------------------------------------}
{ Date last modified:  August 20, 1999                                         }
{ -----------------------------------------------------------------------------}

unit ItemProp;

interface

// See the included ShellFix.txt file if you get a compile error on 'MyShlObj'.
uses Windows, Classes,
     {$IFDEF DFS_COMPILER_2}
     MyShlObj, OLE2;
     {$ELSE}
     ShlObj, ActiveX;
     {$ENDIF}


type
  DFS_HWND = {$IFDEF DFS_DELPHI} HWND {$ELSE} pointer {$ENDIF};


//------------------------------------------------------------------------------
// You must pass fully qualified path names to all of these functions.  No
// guarantees are made as to what will happen for relative pathnames.
// If you are calling for a subdirectory (i.e. no filename), it is your
// responsibility to insure that there is *NO* trailing backslash.
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// DisplayContextMenu displays the right click menu for the given file or
// directory and processes the item selected, if any.  Parent is the window
// handle for the owning window of any error messages that may need to be
// displayed by the system, MyForm.Handle is generally fine.  Pos is the X, Y
// position to display the menu at given in screen (absolute) coordinates.
//------------------------------------------------------------------------------

{$IFDEF DFS_COMPILER_4_UP}
function DisplayContextMenu(const Filename: string; Parent: DFS_HWND;
   Pos: TPoint): boolean; overload;

function DisplayContextMenu(const Directory: string; Items: TStringList;
   Parent: DFS_HWND; Pos: TPoint): boolean; overload;

function DisplayContextMenu(AParent: IShellFolder; var APIDL: PItemIDList;
   Attr: ULONG; Parent: DFS_HWND; Pos: TPoint; PidlCount: integer): boolean; overload;

{$ELSE}

function DisplayContextMenu(const Filename: string;
   Parent: DFS_HWND; Pos: TPoint): boolean;

function DisplayContextMenuList(const Directory: string; Items: TStringList;
   Parent: DFS_HWND; Pos: TPoint): boolean;

function DisplayContextMenuPIDL(AParent: IShellFolder; var APIDL: PItemIDList;
   Attr: ULONG; Parent: DFS_HWND; Pos: TPoint; PidlCount: integer): boolean;

{$ENDIF}

//------------------------------------------------------------------------------
// DisplayPropertiesDialog displays, oddly enough, the properties dialog for
// the given file or directory.  Parent is the window handle for the owning
// window of any error messages that may need to be displayed by the system,
// MyForm.Handle is generally fine.
//------------------------------------------------------------------------------
{$IFDEF DFS_COMPILER_4_UP}
function DisplayPropertiesDialog(const Filename: string;
   Parent: DFS_HWND): boolean; overload;

function DisplayPropertiesDialog(const Directory: string; Items: TStringList;
   Parent: DFS_HWND): boolean; overload;

function DisplayPropertiesDialog(AParent: IShellFolder; var APIDL: PItemIDList;
   Attr: ULONG; Parent: DFS_HWND; PidlCount: integer): boolean; overload;

{$ELSE}

function DisplayPropertiesDialog(const Filename: string; Parent: DFS_HWND): boolean;

function DisplayPropertiesDialogList(const Directory: string; Items: TStringList;
   Parent: DFS_HWND): boolean;

function DisplayPropertiesDialogPIDL(AParent: IShellFolder; var APIDL: PItemIDList;
   Attr: ULONG; Parent: DFS_HWND; PidlCount: integer): boolean;

{$ENDIF}

//------------------------------------------------------------------------------
// PerformDefaultAction causes the item's double-click action to be taken.
// Parent is the window handle for the owning window of any error messages
// that may need to be displayed by the system, MyForm.Handle is generally fine.
//------------------------------------------------------------------------------
{$IFDEF DFS_COMPILER_4_UP}
function PerformDefaultAction(const Filename: string;
   Parent: DFS_HWND): boolean; overload;

function PerformDefaultAction(const Directory: string; Items: TStringList;
   Parent: DFS_HWND): boolean; overload;

function PerformDefaultAction(AParent: IShellFolder; var APIDL: PItemIDList;
   Attr: ULONG; Parent: DFS_HWND; PidlCount: integer): boolean; overload;

{$ELSE}

function PerformDefaultAction(const Filename: string;
   Parent: DFS_HWND): boolean;

function PerformDefaultActionList(const Directory: string; Items: TStringList;
   Parent: DFS_HWND): boolean;

function PerformDefaultActionPIDL(AParent: IShellFolder; var APIDL: PItemIDList;
   Attr: ULONG; Parent: DFS_HWND; PidlCount: integer): boolean;
   
{$ENDIF}


//------------------------------------------------------------------------------
// PerformVerb causes executes the given verb for the item.  Common verbs are
// 'delete', 'cut', 'copy', 'paste', etc. Parent is the window handle for the
// owning window of any error messages that may need to be displayed by the
// system, MyForm.Handle is generally fine.
//------------------------------------------------------------------------------
{$IFDEF DFS_COMPILER_4_UP}
function PerformVerb(const Verb, Filename: string;
   Parent: DFS_HWND): boolean; overload;

function PerformVerb(const Verb, Directory: string; Items: TStringList;
   Parent: DFS_HWND): boolean; overload;

function PerformVerb(const Verb: string; AParent: IShellFolder;
   var APIDL: PItemIDList; Attr: ULONG; Parent: DFS_HWND;
   PidlCount: integer): boolean; overload;

{$ELSE}

function PerformVerb(const Verb, Filename: string; Parent: DFS_HWND): boolean;

function PerformVerbList(const Verb, Directory: string; Items: TStringList;
   Parent: DFS_HWND): boolean;

function PerformVerbPIDL(const Verb: string; AParent: IShellFolder;
   var APIDL: PItemIDList; Attr: ULONG; Parent: DFS_HWND;
   PidlCount: integer): boolean;
{$ENDIF}


//------------------------------------------------------------------------------
// Utility function that you probably won't need, but included just in case.
// Caller is responsible for calling shell malloc Free for PIDL param when done.
//------------------------------------------------------------------------------
function GetPIDLAndShellFolder(Path: string;
   {$IFDEF DFS_COMPILER_4_UP} out {$ELSE} var {$ENDIF} Folder: IShellFolder;
   var PIDL: PItemIDList; ShellMalloc: IMalloc;
   Parent: DFS_HWND): boolean;

type
  PPIDLArray = ^TPIDLArray;
  TPIDLArray = array[0..0] of PItemIDList;

  
implementation

uses SysUtils, Forms, Controls, Messages;


const
  IID_IContextMenu3: TGUID = (
    D1:$BCFCE0A0; D2:$EC17; D3:$11D0; D4:($8D,$10,$00,$A0,$C9,$0F,$27,$19));

{$IFDEF DFS_COMPILER_3}
const
  SID_IContextMenu3      = '{BCFCE0A0-EC17-11d0-8D10-00A0C90F2719}';

type
  { D3 and C3 got the declaration of IContextMenu2 wrong in ShlObj.pas unit. }
  IContextMenu2 = interface(IContextMenu)
    [SID_IContextMenu2]
    function HandleMenuMsg(uMsg: UINT; wParam: WPARAM; lParam: LPARAM): HResult;
       stdcall;
  end;

  { Only D4 has this one }
  IContextMenu3 = interface(IContextMenu2)
    [SID_IContextMenu3]
    function HandleMenuMsg2(uMsg: UINT; wParam: WPARAM; lParam: LPARAM;
      var Result: longint): HResult; stdcall;
  end;

{$ELSE} {$IFDEF DFS_COMPILER_2}
  { D2 and C1 don't have IContextMenu2 declared at all... }
const
  IID_IContextMenu2: TGUID = (
    D1:$000214F4; D2:$0000; D3:$0000; D4:($C0,$00,$00,$00,$00,$00,$00,$46));

type
  IContextMenu2 = class(IContextMenu)
    function HandleMenuMsg(uMsg: UINT; wParam: WPARAM; lParam: LPARAM): HResult;
       virtual; stdcall; abstract;
  end;

  { Only D4 has this one }
  IContextMenu3 = class(IContextMenu2)
    function HandleMenuMsg2(uMsg: UINT; wParam: WPARAM; lParam: LPARAM;
      var Result: longint): HResult; virtual; stdcall; abstract;
  end;
{$ENDIF} {$ENDIF}

var
  IsCM3: boolean;

function MenuCallbackProc(Wnd: HWND; Msg: UINT; wParam: WPARAM;
   lParam: LPARAM): LResult; stdcall; export;
var
  CM2: IContextMenu2;
  CM3: IContextMenu3;
begin
  case Msg of
    WM_CREATE:
      begin
        if IsCM3 then
        begin
          // get pointer to the IContextMenu3 on whose behalf we're acting
          CM3 := IContextMenu3(PCreateStruct(lParam).lpCreateParams);
          // Save it in window info
          SetWindowLong(Wnd, GWL_USERDATA, LongInt(CM3));
        end else begin
          // get pointer to the IContextMenu2 on whose behalf we're acting
          CM2 := IContextMenu2(PCreateStruct(lParam).lpCreateParams);
          // Save it in window info
          SetWindowLong(Wnd, GWL_USERDATA, LongInt(CM2));
        end;
        Result := DefWindowProc(Wnd, Msg, wParam, lParam);
      end;

    // these are the biggies -- the messages that IContextMenu2::HandlMenuMsg is
    // supposed to handle.
    WM_DRAWITEM,
    WM_MEASUREITEM,
    WM_INITMENUPOPUP:
      begin
        if IsCM3 then
        begin
          // grab object pointer from window data -- we put it there in WM_CREATE
          CM3 := IContextMenu3(GetWindowLong(Wnd, GWL_USERDATA));

          {$IFDEF DFS_COMPILER_3_UP}
          Assert(CM3 <> NIL, 'NIL Context Menu!');
          {$ENDIF}

          // pass along to context menu
          CM3.HandleMenuMsg2(Msg, wParam, lParam, Result);
        end else begin
          // grab object pointer from window data -- we put it there in WM_CREATE
          CM2 := IContextMenu2(GetWindowLong(Wnd, GWL_USERDATA));

          {$IFDEF DFS_COMPILER_3_UP}
          Assert(CM2 <> NIL, 'NIL Context Menu!');
          {$ENDIF}

          // pass along to context menu
          CM2.HandleMenuMsg(Msg, wParam, lParam);
        end;

        if Msg = WM_INITMENUPOPUP then
          Result := 0
        else
          Result := 1;
      end;
  else
    Result := DefWindowProc(Wnd, Msg, wParam, lParam);
  end;
end;


type
  TInterfaceCommand = (icContextMenu, icProperties, icDefaultAction, icVerb);

// Internal function used by all others as they share a lot of common
// functionality.
function InvokeInterfaceElement(Filename: string; AFolder: IShellFolder;
   var APIDL: PItemIDList; AnAttr: ULONG; Cmd: TInterfaceCommand;
   const Verb: string; Parent: HWND; Pos: TPoint; PidlCount: integer): boolean;

  function HandleContextMenu(const CtxMenu: IContextMenu; Attr: ULONG;
     HaveCM2: boolean): boolean;
  var
    Popup: HMenu;
    ICI: TCMInvokeCommandInfo;
    MenuCmd: Cardinal;
//    CmdString: string;
    CallbackWnd: HWnd;
    Temp: HWnd;
    AWndClass: TWndClass;
  begin
    Result := FALSE;
    CallbackWnd := 0;
    FillChar(ICI, SizeOf(TCMInvokeCommandInfo), #0);
    with ICI do
    begin
      cbSize := SizeOf(TCMInvokeCommandInfo);
      hWnd := Parent;
      nShow := SW_SHOWNORMAL;
    end;
    case Cmd of
      icContextMenu:
        begin
          Popup := CreatePopupMenu;
          try
            // Add "or CMF_CANRENAME" if you want the rename item
            if Succeeded(CtxMenu.QueryContextMenu(Popup, 0, 1, $7FFF,
               CMF_EXPLORE)) then begin
              if HaveCM2 then
              begin
                FillChar(AWndClass, SizeOf(AWndClass), #0);
                AWndClass.lpszClassName := 'ItemPropMenuCallbackHelper';
                AWndClass.Style := CS_PARENTDC;
                AWndClass.lpfnWndProc := @MenuCallbackProc;
                AWndClass.hInstance := HInstance;
                Windows.RegisterClass(AWndClass);
                CallbackWnd := CreateWindow('ItemPropMenuCallbackHelper',
                   'ItemPropCallbackProcessor', WS_POPUPWINDOW, 0, 0, 0, 0, 0,
                   0, HInstance, Pointer(CtxMenu));
              end;

              Result := TRUE; // We displayed the menu, that's it unless they
                              // make a selection.
              if CallbackWnd = 0 then
                Temp := Parent
              else
                Temp := CallbackWnd;

              MenuCmd := Cardinal(TrackPopupMenuEx(Popup, TPM_LEFTALIGN or
                 TPM_RETURNCMD or TPM_RIGHTBUTTON, Pos.x, Pos.y, Temp, NIL));
              if MenuCmd <> 0 then
              begin
(*
                SetLength(CmdString, 255);
                if Succeeded(CtxMenu.GetCommandString(MenuCmd-1, GCS_VERB, NIL,
                   PChar(CmdString), 255)) then
                  ICI.lpVerb := PChar(CmdString)
                else
                  ICI.lpVerb := MakeIntResource(MenuCmd-1);
*)
                ICI.lpVerb := PAnsiChar(MakeIntResource(MenuCmd-1));
                Result := Succeeded(CtxMenu.InvokeCommand(ICI));
              end;
            end;
          finally
            DestroyMenu(Popup);
            if CallbackWnd <> 0 then
              DestroyWindow(CallbackWnd);
          end;
        end;
      icVerb:
        begin
          ICI.lpVerb := PAnsiChar(Verb);
          Result := Succeeded(CtxMenu.InvokeCommand(ICI));
        end;
      icProperties:
        begin
          // does it have a property sheet?
          if (Attr and SFGAO_HASPROPSHEET) <> 0 then
          begin
            ICI.lpVerb := 'properties'; // Built-in verb for all items, I think
            Result := Succeeded(CtxMenu.InvokeCommand(ICI));
          end;
        end;
      icDefaultAction:
        begin
          Popup := CreatePopupMenu;
          try
            if Succeeded(CtxMenu.QueryContextMenu(Popup, 0, 1, $7FFF,
               CMF_DEFAULTONLY)) then
            begin
              MenuCmd := GetMenuDefaultItem(Popup, 0, 0);
              if MenuCmd <> $FFFFFFFF then
              begin
                ICI.lpVerb := PAnsiChar(MakeIntResource(MenuCmd-1));
                Result := Succeeded(CtxMenu.InvokeCommand(ICI));
              end;
            end;
          finally
            DestroyMenu(Popup);
          end;
        end;
    end;
  end; { InvokeInterfaceElement }

  function HandleFromPIDLs(Parent: HWND; SubFolder: IShellFolder;
     var ItemID: PItemIDList; Attr: ULONG; PidlCount: integer): boolean;
  var
    HaveCM2: boolean;
    ContextMenu: IContextMenu;
    ContextMenu2: IContextMenu2;
    ContextMenu3: IContextMenu3;
  begin
    Result := FALSE;
    HaveCM2 := FALSE;

    if Succeeded(SubFolder.GetUIObjectOf(Parent, PidlCount, ItemID,
       IID_IContextMenu, NIL, pointer(ContextMenu))) then
    begin
      if Succeeded(ContextMenu.QueryInterface(IID_IContextMenu2,
         pointer(ContextMenu2))) then
      begin
{$IFNDEF DFS_NO_COM_CLEANUP}
        ContextMenu.Release ; // Delphi 3 does this for you.
{$ENDIF}
        ContextMenu := ContextMenu2;
        HaveCM2 := TRUE;

        if Succeeded(ContextMenu.QueryInterface(IID_IContextMenu3,
           pointer(ContextMenu3))) then
        begin
{$IFNDEF DFS_NO_COM_CLEANUP}
          ContextMenu.Release; // Delphi 3 does this for you.
{$ENDIF}
          ContextMenu := ContextMenu3;
          IsCM3 := TRUE;
        end;
      end;
      try
        Result := HandleContextMenu(ContextMenu, Attr, HaveCM2);
      finally
{$IFNDEF DFS_NO_COM_CLEANUP}
        ContextMenu.Release; // Delphi 3 does this for you.
{$ENDIF}
      end;
    end;
  end;

  function HasWildcards(const s: string): boolean;
  begin
    Result := (StrScan(PChar(s), '*') <> NIL) or (StrScan(PChar(s), '?') <> NIL);
  end;

var
  ShellMalloc: IMalloc;
  SubFolder,
  ShellFolder: IShellFolder;
  FolderID,
  ItemID: pItemIDList;
  Eaten,Attr: ULONG;
{$IFDEF DFS_COMPILER_3_UP}
  oleWild,
  oleAll,
  oleSubDir,
  oleFilename: widestring;
{$ELSE}
  oleWild,
  oleAll,
  oleSubDir,
  oleFilename: PWideChar;
{$ENDIF}
  OldCursor: TCursor;
  JustName: string;
  EnumList: IEnumIDList;
  CompID: pItemIDList;
  CompFolder: IShellFolder;
{$IFDEF DFS_CPPB}
  Fetched: Cardinal;
  Dummy: UINT absolute 0;
{$ELSE}
  Fetched: ULONG;
{$ENDIF}
  SR: TSearchRec;
  WildFiles: TStringList;
  WildPIDLs: PPIDLArray;
  Count,
  x: integer;
begin
  IsCM3 := FALSE;
  Result := FALSE;
  OldCursor := Screen.Cursor;
  Screen.Cursor := crHourglass;
  try
    if (APIDL <> NIL) then
    begin
      Result := HandleFromPIDLs(Parent, AFolder, APIDL, AnAttr, PidlCount);
    end else
    begin
      SHGetMalloc(ShellMalloc);
      // I'm extra liberal with my try-finally blocks when dealing with system
      // resources like these.  Last thing I want to do is make the shell itself
      // unstable.
      try
        JustName := ExtractFileName(FileName);
{$IFDEF DFS_COMPILER_3_UP}
        oleSubDir := ExtractFilePath(Filename);
        try
          oleFilename := JustName;
          try
{$ELSE}
        oleSubDir := StringToOLEStr(ExtractFilePath(Filename));
        if assigned(oleSubDir) then
        try
          oleFilename := StringToOLEStr(JustName);
          if assigned(oleFilename) then
          try
{$ENDIF}
            if Succeeded(SHGetDesktopFolder(ShellFolder)) then
            try
              if Succeeded(ShellFolder.ParseDisplayName(Parent, NIL,
                 PWideChar(oleSubDir), Eaten, FolderID, Attr)) then
              try
                if Succeeded(ShellFolder.BindToObject(FolderID, NIL,
                   IID_IShellFolder, pointer(SubFolder))) then
                try
                  if HasWildcards(JustName) then
                  begin
                    WildFiles := TStringList.Create;
                    try
                      if FindFirst(Filename, faAnyFile, SR) = 0 then
                      begin
                        WildFiles.Add(SR.Name);
                        while FindNext(SR) = 0 do
                          WildFiles.Add(SR.Name);
                        FindClose(SR);
                      end;

                      if WildFiles.Count > 0 then
                      begin
                        Count := 0;
                        GetMem(WildPIDLs, SizeOf(PItemIDList) * WildFiles.Count);
                        try
                          for x := 0 to WildFiles.Count-1 do
                          begin
{$IFDEF DFS_COMPILER_3_UP}
                            oleWild := WildFiles[x];
                            try
{$ELSE}
                            oleWild := StringToOLEStr(WildFiles[x]);
                            if assigned(oleSubDir) then
                            try
{$ENDIF}
{ Turn off range checking because WildPILDs is typed as an array of 0..0.}
{$IFOPT R+} {$DEFINE DFS_RESET_RANGE_CHECKING} {$R-} {$ENDIF}
                              if Succeeded(SubFolder.ParseDisplayName(Parent,
                                 NIL, PWideChar(oleWild), Eaten,
                                 WildPIDLs^[Count], Attr)) then
{$IFDEF DFS_RESET_RANGE_CHECKING} {$R+} {$UNDEF DFS_RESET_RANGE_CHECKING} {$ENDIF}
                                Inc(Count);
                            finally
{$IFNDEF DFS_NO_COM_CLEANUP}
                              SysFreeString(oleWild);
{$ENDIF}
                            end;
                          end;

                          Result := HandleFromPIDLS(Parent, SubFolder,
                             WildPIDLs^[0], Attr, Count);
                        finally
                          for x := 0 to Count-1 do
{ Turn off range checking because WildPILDs is typed as an array of 0..0.}
{$IFOPT R+} {$DEFINE DFS_RESET_RANGE_CHECKING} {$R-} {$ENDIF}
                            ShellMalloc.Free(WildPIDLs^[x]);
{$IFDEF DFS_RESET_RANGE_CHECKING} {$R+} {$UNDEF DFS_RESET_RANGE_CHECKING} {$ENDIF}
                          FreeMem(WildPIDLs);
                        end;
                      end;
                    finally
                      WildFiles.Free;
                    end;

                  end else if Succeeded(SubFolder.ParseDisplayName(Parent, NIL,
                     PWideChar(oleFilename), Eaten, ItemID, Attr)) then
                  begin
                    try
                      Result := HandleFromPIDLS(Parent, SubFolder, ItemID, Attr, 1);
  (*
                      if Succeeded(SubFolder.GetUIObjectOf(Parent, 1, ItemID,
                         IID_IContextMenu, NIL, pointer(ContextMenu))) then
                      begin
                        if Succeeded(ContextMenu.QueryInterface(IID_IContextMenu2,
                           pointer(ContextMenu2))) then
                        begin
{$IFNDEF DFS_NO_COM_CLEANUP}
                          ContextMenu.Release; // Delphi 3 does this for you.
{$ENDIF}
                          ContextMenu := ContextMenu2;
                          HaveCM2 := TRUE;
                        end;
                        try
                          HandleContextMenu(ContextMenu, Attr, HaveCM2);
                        finally
{$IFNDEF DFS_NO_COM_CLEANUP}
                          ContextMenu.Release; // Delphi 3 does this for you.
{$ENDIF}
                        end;
                      end;
  *)
                    finally
                      ShellMalloc.Free(ItemID);
                    end;
                  end else begin
                    // No filename, probably a drive.
{$IFDEF DFS_COMPILER_3_UP}
                    oleAll := Filename;
{$ELSE}
                    oleAll := StringToOLEStr(Filename);
{$ENDIF}
                    // This is screwy, but it's the only way I could get it to
                    // work. Basically, the thing is that for drives, the
                    // IShellFolder MUST be the parent of the drive PIDL.  The
                    // Desktop folder won't work. So, I enumerate the Desktop
                    // folder, taking the first child which *SHOULD* be the "My
                    // Computer" item, which is the parent of drives.
                    if Succeeded(ShellFolder.EnumObjects(Parent,
                       SHCONTF_FOLDERS, EnumList)) then
                    try
                      if EnumList.Next(1, CompID, Fetched) = S_OK then
                      begin
                        if Succeeded(ShellFolder.BindToObject(CompID, NIL,
                           IID_IShellFolder, pointer(CompFolder))) then
                        try
                          if Succeeded(CompFolder.ParseDisplayName(Parent, NIL,
                             PWideChar(oleAll),Eaten, ItemID, Attr)) then
                          try
                            Result := HandleFromPIDLS(Parent, CompFolder, ItemID,
                               Attr, 1);
(*
                            if Succeeded(CompFolder.GetUIObjectOf(Parent, 1, ItemID,
                               IID_IContextMenu, NIL, pointer(ContextMenu))) then
                            begin
                              if Succeeded(ContextMenu.QueryInterface(
                                 IID_IContextMenu2, pointer(ContextMenu2))) then
                              begin
{$IFNDEF DFS_NO_COM_CLEANUP}
                                ContextMenu.Release; // Delphi 3 does this for you.
{$ENDIF}
                                ContextMenu := ContextMenu2;
                                HaveCM2 := TRUE;
                              end;
                              try
                                HandleContextMenu(ContextMenu, Attr, HaveCM2);
                              finally
{$IFNDEF DFS_NO_COM_CLEANUP}
                                ContextMenu.Release; // Delphi 3 does this for you.
{$ENDIF}
                              end;
                            end;
*)
                          finally
                            ShellMalloc.Free(ItemID);
                          end;
                        finally
{$IFNDEF DFS_NO_COM_CLEANUP}
                          CompFolder.Release; // Delphi 3 does this for you.
{$ENDIF}
                        end;
                      end;
                    finally
{$IFNDEF DFS_NO_COM_CLEANUP}
                      EnumList.Release; // Delphi 3 does this for you.
{$ENDIF}
                    end;
{$IFNDEF DFS_NO_COM_CLEANUP}
                    SysFreeString(oleAll);
{$ENDIF}
                  end;
                finally
{$IFNDEF DFS_NO_COM_CLEANUP}
                  SubFolder.Release; // Delphi 3 does this for you.
{$ENDIF}
                end;
              finally
                ShellMalloc.Free(FolderID);
              end;
            finally
{$IFNDEF DFS_NO_COM_CLEANUP}
              ShellFolder.Release; // Delphi 3 does this for you.
{$ENDIF}
            end;
          finally
{$IFNDEF DFS_NO_COM_CLEANUP}
            SysFreeString(oleFilename);
{$ENDIF}
          end;
        finally
{$IFNDEF DFS_NO_COM_CLEANUP}
          SysFreeString(oleSubDir);
{$ENDIF}
        end;
      finally
{$IFDEF DFS_COMPILER_3_UP}
        ShellMalloc._Release;
{$ELSE}
        ShellMalloc.Release;
{$ENDIF}
      end;
    end;
  finally
    Screen.Cursor := OldCursor;
  end;
end;

function InvokeListInterfaceElement(const Directory: string; Items: TStringList;
   Parent: HWND; Pos: TPoint; Cmd: TInterfaceCommand; const Verb: string): boolean;
var
  ShellMalloc: IMalloc;
  SubFolder,
  ShellFolder: IShellFolder;
  FolderID: PItemIDList;
  Eaten,Attr: ULONG;
{$IFDEF DFS_COMPILER_3_UP}
  oleSubDir,
  oleFilename: widestring;
{$ELSE}
  oleSubDir,
  oleFilename: PWideChar;
{$ENDIF}
  ItemPIDLs: PPIDLArray;
  Count,
  x: integer;
begin
  Result := FALSE;
  if (Items = NIL) or (Items.Count < 1) then
    exit;

  SHGetMalloc(ShellMalloc);
  try
    if Succeeded(SHGetDesktopFolder(ShellFolder)) then
    try
{$IFDEF DFS_COMPILER_3_UP}
      oleSubDir := Directory;
{$ELSE}
      oleSubDir := StringToOLEStr(Directory);
      if assigned(oleSubDir) then
{$ENDIF}
      try
        if Succeeded(ShellFolder.ParseDisplayName(Parent, NIL,
           PWideChar(oleSubDir), Eaten, FolderID, Attr)) then
        try
          if Succeeded(ShellFolder.BindToObject(FolderID, NIL, IID_IShellFolder,
             pointer(SubFolder))) then
          try
            Count := 0;
            GetMem(ItemPIDLs, SizeOf(PItemIDList) * Items.Count);
            try
              for x := 0 to Items.Count-1 do
              begin
{$IFDEF DFS_COMPILER_3_UP}
                oleFilename := Items[x];
{$ELSE}
                oleFilename := StringToOLEStr(Items[x]);
                if assigned(oleSubDir) then
{$ENDIF}
                try
{ Turn off range checking because WildPILDs is typed as an array of 0..0.}
{$IFOPT R+} {$DEFINE DFS_RESET_RANGE_CHECKING} {$R-} {$ENDIF}
                  if Succeeded(SubFolder.ParseDisplayName(Parent, NIL,
                     PWideChar(oleFilename), Eaten, ItemPIDLs^[Count], Attr)) then
{$IFDEF DFS_RESET_RANGE_CHECKING} {$R+} {$UNDEF DFS_RESET_RANGE_CHECKING} {$ENDIF}
                    Inc(Count);
                finally
{$IFNDEF DFS_NO_COM_CLEANUP}
                  SysFreeString(oleFilename);
{$ENDIF}
                end;
              end;

              Result := InvokeInterfaceElement('', SubFolder, ItemPIDLs^[0],
                 Attr, Cmd, Verb, Parent, Pos, Count);
{              Result := DisplayContextMenu(SubFolder, ItemPIDLs^[0], Attr, Parent,
                 Pos, Count);}
            finally
              for x := 0 to Count-1 do
{ Turn off range checking because WildPILDs is typed as an array of 0..0.}
{$IFOPT R+} {$DEFINE DFS_RESET_RANGE_CHECKING} {$R-} {$ENDIF}
                ShellMalloc.Free(ItemPIDLs^[x]);
{$IFDEF DFS_RESET_RANGE_CHECKING} {$R+} {$UNDEF DFS_RESET_RANGE_CHECKING} {$ENDIF}
              FreeMem(ItemPIDLs);
            end;
          finally
{$IFNDEF DFS_NO_COM_CLEANUP}
            SubFolder.Release; // Delphi 3 does this for you.
{$ENDIF}
          end;
        finally
          ShellMalloc.Free(FolderID);
        end;
      finally
{$IFNDEF DFS_NO_COM_CLEANUP}
        SysFreeString(oleSubDir);
{$ENDIF}
      end;
    finally
{$IFNDEF DFS_NO_COM_CLEANUP}
      ShellFolder.Release; // Delphi 3 does this for you.
{$ENDIF}
    end;
  finally
{$IFDEF DFS_COMPILER_3_UP}
    ShellMalloc._Release;
{$ELSE}
    ShellMalloc.Release;
{$ENDIF}
  end;
end;


// Returns to the next ID in the given list of IDs
function NextPIDL(PIDL: PItemIDList): PItemIDList;
begin
  if PIDL.mkid.cb > 0 then
    Result := PItemIDList(Longint(PIDL) + PIDL.mkid.cb)
  else // At end of list.
    Result := NIL;
end;

function CopyPidl(APidl: PItemIDList; ShellMalloc: IMalloc): PItemIDList;
var
  CB: UINT;
begin
  Result := NIL;
  CB := APidl.mkid.cb + SizeOf(APidl.mkid.cb);
  if NextPidl(APidl)^.mkid.cb <> 0 then
    exit;
  Result := ShellMalloc.Alloc(CB);
  if Result <> NIL then
  begin
    FillChar(Result^, CB, #0); // Initialize the memory to zero
    Move(APidl^, Result^, APidl.mkid.cb);
  end;
end;

function GetPIDLAndShellFolder(Path: string;
   {$IFDEF DFS_COMPILER_4_UP} out {$ELSE} var {$ENDIF} Folder: IShellFolder;
   var PIDL: PItemIDList; ShellMalloc: IMalloc;
   {$IFDEF DFS_DELPHI} Parent: HWND {$ELSE} Parent: pointer {$ENDIF}): boolean;
var
  DF: IShellFolder;
  // translate for D2/D3/C1/C3!!!!
{$IFDEF DFS_COMPILER_3_UP}
  WidePath: WideString;
{$ELSE}
  WidePath: PWideChar;
{$ENDIF}
  Eaten: ULONG;
  pidlNext,
  pidlLast,
  pidlFull: PItemIDList;
  Attrs: ULONG;
  CurFolder, NextFolder: IShellFolder;
  SaveCB: UINT;

begin
  Result := FALSE;
  pidlFull := NIL;
  if Succeeded(SHGetDesktopFolder(DF)) then
  begin
{$IFDEF DFS_COMPILER_3_UP}
    WidePath := Path;
{$ELSE}
    WidePath := StringToOLEStr(Path);
    if assigned(WidePath) then
{$ENDIF}
    try
      if Succeeded(DF.ParseDisplayName({$IFDEF DFS_DELPHI} Parent, {$ELSE}
         HWND(Parent), {$ENDIF} NIL, PWideChar(WidePath), Eaten,
         pidlFull, Attrs)) then
      begin
        if Succeeded(DF.QueryInterface(IID_IShellFolder, CurFolder)) then
        begin
          pidlNext := NextPidl(pidlFull);
          pidlLast := pidlFull;
          while pidlNext^.mkid.cb <> 0 do
          begin
            Result := TRUE;
            SaveCB := pidlNext^.mkid.cb;
            pidlNext^.mkid.cb := 0;
            if not Succeeded(CurFolder.BindToObject(pidlLast, NIL, IID_IShellFolder,
               pointer(NextFolder))) then
            begin
              Result := FALSE;
              break;
            end;
            pidlNext^.mkid.cb := SaveCB;
            CurFolder := NextFolder;
            pidlLast := pidlNext;
            pidlNext := NextPidl(pidlNext);
          end;
          PIDL := CopyPidl(pidlLast, ShellMalloc);
          Folder := CurFolder;
        end;
      end;
    finally
{$IFNDEF DFS_NO_COM_CLEANUP}
      SysFreeString(WidePath);
{$ENDIF}
    end;
  end;
  if pidlFull <> NIL then
    ShellMalloc.Free(pidlFull);
end;


{$IFDEF DFS_COMPILER_4_UP}
function DisplayPropertiesDialog(const Filename: string; Parent: DFS_HWND): boolean;
var
  Dummy: PItemIDList;
begin
  Dummy := NIL;
  Result := InvokeInterfaceElement(Filename, NIL, Dummy, 0, icProperties, '',
     HWND(Parent), Point(0,0), 1);
end;

function DisplayPropertiesDialog(const Directory: string; Items: TStringList;
   Parent: DFS_HWND): boolean; overload;
begin
  Result := InvokeListInterfaceElement(Directory, Items, HWND(Parent), Point(0,0),
     icProperties, '');
end;

function DisplayPropertiesDialog(AParent: IShellFolder; var APIDL: PItemIDList;
   Attr: ULONG; Parent: DFS_HWND; PidlCount: integer): boolean;
begin
  Result := InvokeInterfaceElement('', AParent, APIDL, Attr, icProperties, '',
     HWND(Parent), Point(0,0), PidlCount);
end;

{$ELSE}

function DisplayPropertiesDialog(const Filename: string;
   Parent: DFS_HWND): boolean;
var
  Dummy: PItemIDList;
begin
  Dummy := NIL;
  Result := InvokeInterfaceElement(Filename, NIL, Dummy, 0, icProperties, '',
     HWND(Parent), Point(0,0), 1);
end;

function DisplayPropertiesDialogList(const Directory: string; Items: TStringList;
   Parent: DFS_HWND): boolean;
begin
  Result := InvokeListInterfaceElement(Directory, Items,
     HWND(Parent), Point(0,0), icProperties, '');
end;

function DisplayPropertiesDialogPIDL(AParent: IShellFolder; var APIDL: PItemIDList;
   Attr: ULONG; Parent: DFS_HWND; PidlCount: integer): boolean;
begin
  Result := InvokeInterfaceElement('', AParent, APIDL, Attr, icProperties, '',
     HWND(Parent), Point(0,0), PidlCount);
end;
{$ENDIF}


{$IFDEF DFS_COMPILER_4_UP}

function DisplayContextMenu(const Filename: string; Parent: DFS_HWND;
   Pos: TPoint): boolean;
var
  Dummy: PItemIDList;
begin
  Dummy := NIL;
  Result := InvokeInterfaceElement(Filename, NIL, Dummy, 0, icContextMenu, '',
     HWND(Parent), Pos, 1);
end;

function DisplayContextMenu(const Directory: string; Items: TStringList;
   Parent: DFS_HWND; Pos: TPoint): boolean; overload;
begin
  Result := InvokeListInterfaceElement(Directory, Items, HWND(Parent), Pos,
     icContextMenu, '');
end;

function DisplayContextMenu(AParent: IShellFolder; var APIDL: PItemIDList;
   Attr: ULONG; Parent: DFS_HWND; Pos: TPoint; PidlCount: integer): boolean;
begin
  Result := InvokeInterfaceElement('', AParent, APIDL, Attr, icContextMenu, '',
     HWND(Parent), Pos, PidlCount);
end;

{$ELSE}

function DisplayContextMenu(const Filename: string; Parent: DFS_HWND;
   Pos: TPoint): boolean;
var
  Dummy: PItemIDList;
begin
  Dummy := NIL;
  Result := InvokeInterfaceElement(Filename, NIL, Dummy, 0, icContextMenu, '',
     HWND(Parent), Pos, 1);
end;

function DisplayContextMenuList(const Directory: string; Items: TStringList;
   Parent: DFS_HWND; Pos: TPoint): boolean;
begin
  Result := InvokeListInterfaceElement(Directory, Items,
     HWND(Parent), Pos, icContextMenu, '');
end;

function DisplayContextMenuPIDL(AParent: IShellFolder; var APIDL: PItemIDList;
   Attr: ULONG; Parent: DFS_HWND; Pos: TPoint; PidlCount: integer): boolean;
begin
  Result := InvokeInterfaceElement('', AParent, APIDL, Attr, icContextMenu, '',
     HWND(Parent), Pos, PidlCount);
end;
{$ENDIF}

{$IFDEF DFS_COMPILER_4_UP}
function PerformDefaultAction(const Filename: string; Parent: DFS_HWND): boolean;
var
  Dummy: PItemIDList;
begin
  Dummy := NIL;
  Result := InvokeInterfaceElement(Filename, NIL, Dummy, 0, icDefaultAction, '',
     HWND(Parent), Point(0,0), 1);
end;

function PerformDefaultAction(const Directory: string; Items: TStringList;
   Parent: DFS_HWND): boolean; overload;
begin
  Result := InvokeListInterfaceElement(Directory, Items, HWND(Parent),
     Point(0,0), icDefaultAction, '');
end;

function PerformDefaultAction(AParent: IShellFolder; var APIDL: PItemIDList;
   Attr: ULONG; Parent: DFS_HWND; PidlCount: integer): boolean;
begin
  Result := InvokeInterfaceElement('', AParent, APIDL, Attr, icDefaultAction,
     '', HWND(Parent), Point(0,0), PidlCount);
end;
{$ELSE}

function PerformDefaultAction(const Filename: string; Parent: DFS_HWND): boolean;
var
  Dummy: PItemIDList;
begin
  Dummy := NIL;
  Result := InvokeInterfaceElement(Filename, NIL, Dummy, 0, icDefaultAction, '',
     HWND(Parent), Point(0,0), 1);
end;

function PerformDefaultActionList(const Directory: string; Items: TStringList;
   Parent: DFS_HWND): boolean;
begin
  Result := InvokeListInterfaceElement(Directory, Items,
     HWND(Parent), Point(0,0), icDefaultAction, '');
end;

function PerformDefaultActionPIDL(AParent: IShellFolder; var APIDL: PItemIDList;
   Attr: ULONG; Parent: DFS_HWND; PidlCount: integer): boolean;
begin
  Result := InvokeInterfaceElement('', AParent, APIDL, Attr, icDefaultAction,
     '', HWND(Parent), Point(0,0), PidlCount);
end;
{$ENDIF}


{$IFDEF DFS_COMPILER_4_UP}
function PerformVerb(const Verb, Filename: string; Parent: DFS_HWND): boolean;
var
  Dummy: PItemIDList;
begin
  Dummy := NIL;
  Result := InvokeInterfaceElement(Filename, NIL, Dummy, 0, icVerb, Verb,
     HWND(Parent), Point(0,0), 1);
end;

function PerformVerb(const Verb, Directory: string; Items: TStringList;
   Parent: DFS_HWND): boolean;
begin
  Result := InvokeListInterfaceElement(Directory, Items, HWND(Parent),
     Point(0,0), icVerb, Verb);
end;

function PerformVerb(const Verb: string; AParent: IShellFolder;
   var APIDL: PItemIDList; Attr: ULONG; Parent: DFS_HWND;
   PidlCount: integer): boolean;
begin
  Result := InvokeInterfaceElement('', AParent, APIDL, Attr, icVerb, Verb,
     HWND(Parent), Point(0,0), PidlCount);
end;

{$ELSE}

function PerformVerb(const Verb, Filename: string;
   Parent: DFS_HWND): boolean;
var
  Dummy: PItemIDList;
begin
  Dummy := NIL;
  Result := InvokeInterfaceElement(Filename, NIL, Dummy, 0, icVerb, Verb,
     HWND(Parent), Point(0,0), 1);
end;

function PerformVerbList(const Verb, Directory: string; Items: TStringList;
   Parent: DFS_HWND): boolean;
begin
  Result := InvokeListInterfaceElement(Directory, Items,
     HWND(Parent), Point(0,0), icVerb, Verb);
end;

function PerformVerbPIDL(const Verb: string; AParent: IShellFolder;
   var APIDL: PItemIDList; Attr: ULONG; Parent: DFS_HWND; 
   PidlCount: integer): boolean;
begin
  Result := InvokeInterfaceElement('', AParent, APIDL, Attr, icVerb, Verb,
     HWND(Parent), Point(0,0), PidlCount);
end;
{$ENDIF}


initialization
  OLEInitialize(NIL);
finalization
  OLEUninitialize;
end.


