unit NewSearch;

{
  YARSE, Yet Another REZID Search Engine
  Version 3.x
  ZeWaren / Erwan Martin
  Copyright 2010
  http://zewaren.net ; http://rezid.org
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, ConstsAndVars, ShellAPI,
  ImgList, ShlObj, SearchEngineFacade, ShellFolderView;

type
  TFNewSearch = class(TShellViewForm)
    ScrollBox1: TScrollBox;
    gbMainSearch: TGroupBox;
    leSearchTerm: TLabeledEdit;
    pOkCancel: TPanel;
    bOK: TButton;
    StatusBar1: TStatusBar;
    lbInformation: TListBox;
    gbSearchInNamesOrPath: TGroupBox;
    rbSearchInNames: TRadioButton;
    rbSearchInFullPath: TRadioButton;
    gbSearchWhat: TGroupBox;
    iVideoFiles: TImage;
    iAllFiles: TImage;
    iAudioFiles: TImage;
    iFolders: TImage;
    iImages: TImage;
    cbFileVideo: TCheckBox;
    cbFileAudio: TCheckBox;
    cbFileImage: TCheckBox;
    rbEveryFiles: TRadioButton;
    rbFileFolders: TRadioButton;
    rbCustom: TRadioButton;
    SysIco_Small: TImageList;
    SysIco_Big: TImageList;
    procedure bCancelClick(Sender: TObject);
    procedure leSearchTermKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure cbFileFolderClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
    MainMenuPIDL : PItemIDList;
    procedure AdaptPicturesFromSystem;
    procedure CheckForOkButtonToBeEnable;
  end;

var
  FNewSearch: TFNewSearch = nil;

procedure Callback(text: string);

implementation

uses Searching, ShellFolder, PIDLs;

{$R *.dfm}


procedure TFNewSearch.cbFileFolderClick(Sender: TObject);
begin
  if Sender is TCheckBox then
    rbCustom.Checked := true;
  CheckForOkButtonToBeEnable;
end;

procedure TFNewSearch.CheckForOkButtonToBeEnable;
var
  BB : boolean;
  BB2 : boolean;
begin
  BB := true;
  BB := BB and (length(leSearchTerm.Text) > 0);
  BB2 := true;  
  if rbCustom.Checked then
    begin                        
      BB2 := false;
      BB2 := BB2 or cbFileVideo.Checked;
      BB2 := BB2 or cbFileAudio.Checked;
      BB2 := BB2 or cbFileImage.Checked;
    end;
//  BB2 := BB2 or cbFileFolder.Checked;
  BB := BB and BB2;
  bOK.Enabled := BB;
end;

procedure TFNewSearch.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Free;
end;

procedure TFNewSearch.FormShow(Sender: TObject);
begin
  AdaptPicturesFromSystem;
  CheckForOkButtonToBeEnable;
end;

procedure TFNewSearch.AdaptPicturesFromSystem;
  function GetIconIndex(Extension: String; Attribus: DWORD):Integer;
  var SHFileInfo: TSHFileInfo;
  begin
    if length(Extension) = 0 then
      Extension := '.'
    else if Extension[1] <> '.' then Extension := '.' + Extension;   //Il faut le "." avant

    SHGetFileInfo(PChar(Extension), Attribus, SHFileInfo, SizeOf(TSHFileInfo),
                       SHGFI_SYSICONINDEX OR SHGFI_USEFILEATTRIBUTES);
    Result := SHFileInfo.iIcon; //index de l'icone dans l'image list du systeme
  end;
  function GetDirIndex():Integer;
  var SHFileInfo: TSHFileInfo;
  begin
  {On récolte les info pour l'extension}
     SHGetFileInfo('', FILE_ATTRIBUTE_DIRECTORY, SHFileInfo, SizeOf(TSHFileInfo),
                   SHGFI_SYSICONINDEX or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES);

     Result := SHFileInfo.iIcon; //index de l'icone dans l'image list du systeme
  end;
var
  BB : TBitmap;
  SHFileInfo :TSHFileINfo;
begin
//  ShowMessage(inttostr(TMainView(aMainView).SysIco_Small.Count));

  SysIco_Big.Handle := SHGetFileInfo('', 0, SHFileInfo, SizeOF(SHFileInfo), SHGFI_SYSICONINDEX );
  SysIco_Small.Handle := SHGetFileInfo('', 0, SHFileInfo, SizeOF(SHFileInfo), SHGFI_SYSICONINDEX or SHGFI_SMALLICON );

  //Au niveau du principe si je m'amuse pas à recréer BB à chaque fois pour une raison mystérieuse ça plante.

  BB := TBitmap.Create;
  BB.Width := 16;
  BB.Height := 16;
  SysIco_Small.Draw(BB.Canvas, 0, 0, GetIconIndex('.avi', 0));
  iVideoFiles.Picture.Bitmap.Assign(BB);
  BB.Free;

  BB := TBitmap.Create;
  BB.Width := 16;
  BB.Height := 16;
  SysIco_Small.Draw(BB.Canvas, 0, 0, GetIconIndex('.mp3', 0));
  iAudioFiles.Picture.Bitmap.Assign(BB);
  BB.Free;

  BB := TBitmap.Create;
  BB.Width := 16;
  BB.Height := 16;
  SysIco_Small.Draw(BB.Canvas, 0, 0, GetIconIndex('.', 0));
  iAllFiles.Picture.Bitmap.Assign(BB);
  BB.Free;

  BB := TBitmap.Create;
  BB.Width := 16;
  BB.Height := 16;
  SysIco_Small.Draw(BB.Canvas, 0, 0, GetDirIndex);
  iFolders.Picture.Bitmap.Assign(BB);
  BB.Free;

  BB := TBitmap.Create;
  BB.Width := 16;
  BB.Height := 16;
  SysIco_Small.Draw(BB.Canvas, 0, 0, GetIconIndex('.jpg', 0));
  iImages.Picture.Bitmap.Assign(BB);
  BB.Free;

{  SysIco_Small.GetBitmap(GetIconIndex('.mp3', 0) ,BB);
  iAudioFiles.Picture.Bitmap.Assign(BB);

  SysIco_Small.GetBitmap(TMainView(aMainView).GetDirIndex() ,BB);
  iAudioFiles.Picture.Bitmap.Assign(BB);

  SysIco_Small.GetBitmap(GetIconIndex('.', 0) ,BB);
  iAllFiles.Picture.Bitmap.Assign(BB);}  
end;

procedure TFNewSearch.bCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TFNewSearch.bOKClick(Sender: TObject);
var
  SearchEngine : IAbstractSearchEngineFacade;
  SearchIn : TSearchInEnum;
  Search : TSearch;
begin
  if bOK.Tag = 1 then
    begin
      Exit;
    end;
  Screen.Cursor := crHourGlass;
  try
    SearchEngine := GetConcreteSearchEngineFacade();
    SearchEngine.CallbackTextInformation := Callback;
    SearchIn := [];
    if rbEveryFiles.Checked then
      SearchIn := SearchIn + [siEveryFile]
    else if rbFileFolders.Checked then
      SearchIn := SearchIn + [siFolders]
    else
      begin
        if cbFileVideo.Checked then
          SearchIn := SearchIn + [siVideo];
        if cbFileAudio.Checked then
          SearchIn := SearchIn + [siAudio];
        if cbFileImage.Checked then
          SearchIn := SearchIn + [siImage];
      end;
    try
      Search := SearchEngine.MakeSearch(leSearchTerm.Text, SearchIn);
      Search.CreateVirtualFolders;
    except
      Exit;
    end;
    AllSearches.Add(Search);
    if Assigned(ShellBrowser) then
      begin
//        aPidl := CopyPIDL(TCustomShellFolder(ShellFolder).SeInitPIDL);
//        aPidl := StripLastID(aPidl);
        ShellBrowser.BrowseObject(nil, SBSP_PARENT);
      end;
//    SHChangeNotify(SHCNE_UPDATEDIR, SHCNF_IDLIST or SHCNF_FLUSHNOWAIT, MainMenuPIDL, nil);
    bOk.Tag := 1;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure Callback(text: string);
begin
  if Assigned(FNewSearch) then
    FNewSearch.lbInformation.Items.Add(text);
end;

procedure TFNewSearch.leSearchTermKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  CheckForOkButtonToBeEnable;
end;



end.
