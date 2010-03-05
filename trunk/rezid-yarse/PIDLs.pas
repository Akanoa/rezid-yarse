unit PIDLs;

interface

uses Windows, ShlObj, ActiveX, SysUtils;

type
  PPIDLStructure = ^TPIDLStructure;
  TPIDLStructure = record
    ItemType : byte;
    ItemInfo1 : cardinal;
    ItemInfo2 : cardinal;
    ItemInfo3 : cardinal;
  end;

  TStrRetType = (
    srtPIDLOffset,
    srtOLEStr,
    srtANSIStr
  );

function TPIDLStructure_To_PIDl(input : TPIDLStructure) : PItemIDList;
function PIDL_To_TPIDLStructure(input : PItemIDList) : TPIDLStructure;

function PIDLSize(APIDL: PItemIDList): integer;
function NextID(APIDL: PItemIDList): PItemIDList;
function IDCount(APIDL: PItemIDList): integer;
function GetPointerToLastID(IDList: PItemIDList): PItemIDList;
function CopyPIDL(APIDL: PItemIDList): PItemIDList;
function AllocShellString(SourceStr: WideString): POLEStr;
function FillStrRet(var AStrRet: TStrRet; AType: TStrRetType;
  AString: WideString; PIDLOffset: Integer): HRESULT;
function AppendPIDL(DestPIDL, SrcPIDL: PItemIDList): PItemIDList;
procedure FreeAndNilPIDL(var PIDL: PItemIDList);
procedure FreePIDL(PIDL: PItemIDList);

var
  FMalloc : IMalloc;

implementation

function TPIDLStructure_To_PIDl(input : TPIDLStructure) : PItemIDList;
var
  iSize : word;
  bb : ^byte;
  pp : pointer;
begin
  iSize := 13 + 2;
  pp := FMalloc.Alloc(iSize + 2);

  bb := pp;
  bb^ := iSize and $FF;
  inc(bb);
  bb^ := (iSize shr 8) and $FF;

  inc(bb);
  bb^ := input.ItemType and $FF;

  inc(bb);
  bb^ := (input.ItemInfo1) and $FF;
  inc(bb);
  bb^ := (input.ItemInfo1 shr 8) and $FF;
  inc(bb);
  bb^ := (input.ItemInfo1 shr 16) and $FF;
  inc(bb);
  bb^ := (input.ItemInfo1 shr 24) and $FF;

  inc(bb);
  bb^ := (input.ItemInfo2) and $FF;
  inc(bb);
  bb^ := (input.ItemInfo2 shr 8) and $FF;
  inc(bb);
  bb^ := (input.ItemInfo2 shr 16) and $FF;
  inc(bb);
  bb^ := (input.ItemInfo2 shr 24) and $FF;

  inc(bb);
  bb^ := (input.ItemInfo3) and $FF;
  inc(bb);
  bb^ := (input.ItemInfo3 shr 8) and $FF;
  inc(bb);
  bb^ := (input.ItemInfo3 shr 16) and $FF;
  inc(bb);
  bb^ := (input.ItemInfo3 shr 24) and $FF;

  inc(bb);
  bb^ := $00;
  inc(bb);
  bb^ := $00;

  Result := pp;
end;

function PIDL_To_TPIDLStructure(input : PItemIDList) : TPIDLStructure;
var
  pp : pointer;
  pb : ^byte;
  bc : cardinal;
begin
  pp := input;
  pb := pp;

  inc(pb, 2);
  Result.ItemType := pb^;

  inc(pb);
  bc := pb^;
  inc(pb);
  bc := bc or (pb^ shl 8);
  inc(pb);
  bc := bc or (pb^ shl 16);
  inc(pb);
  bc := bc or (pb^ shl 24);
  Result.ItemInfo1 := bc;

  inc(pb);
  bc := pb^;
  inc(pb);
  bc := bc or (pb^ shl 8);
  inc(pb);
  bc := bc or (pb^ shl 16);
  inc(pb);
  bc := bc or (pb^ shl 24);
  Result.ItemInfo2 := bc;

  inc(pb);
  bc := pb^;
  inc(pb);
  bc := bc or (pb^ shl 8);
  inc(pb);
  bc := bc or (pb^ shl 16);
  inc(pb);
  bc := bc or (pb^ shl 24);
  Result.ItemInfo3 := bc;
end;

function NextID(APIDL: PItemIDList): PItemIDList;
// Returns a pointer to the next Simple PIDL in a Complex PIDL.
begin
  Result := APIDL;
  Inc(PByte(Result), APIDL^.mkid.cb);
end;

function IDCount(APIDL: PItemIDList): integer;
// Counts the number of Simple PIDLs contained in a Complex PIDL.
var
  Next: PItemIDList;
begin
  Result := 0;
  Next := APIDL;
  if Assigned(Next) then
  begin
    while Next^.mkid.cb <> 0 do
    begin
      Inc(Result);
      Next := NextID(Next);
    end
  end
end;

function PIDLSize(APIDL: PItemIDList): integer;
// Returns the total Memory in bytes the PIDL occupies.
begin
  Result := 0;
  if Assigned(APIDL) then
  begin
    Result := SizeOf( Word);  // add the null terminating last ItemID
    while APIDL.mkid.cb <> 0 do
    begin
      Result := Result + APIDL.mkid.cb;
      APIDL := NextID(APIDL);
    end;
  end;
end;

function CopyPIDL(APIDL: PItemIDList): PItemIDList;
// Copies the PIDL and returns a newly allocated PIDL. It is not associated
// with any instance of TEasyPIDLManager so it may be assigned to any instance.
var
  Size: integer;
begin
  if Assigned(APIDL) then
  begin
    Size := PIDLSize(APIDL);
    Result := FMalloc.Alloc(Size);
    if Result <> nil then
      CopyMemory(Result, APIDL, Size);
  end else
    Result := nil
end;

function GetPointerToLastID(IDList: PItemIDList): PItemIDList;
// Return a pointer to the last PIDL in the complex PIDL passed to it.
// Useful to overlap an Absolute complex PIDL with the single level
// Relative PIDL.
var
  Count, i: integer;
  PIDIndex: PItemIDList;
begin
  if Assigned(IDList) then
  begin
    PIDIndex := IDList;
    Count := IDCount(IDList);
    if Count > 1 then
      for i := 0 to Count - 2 do
       PIDIndex := NextID(PIDIndex);
    Result := PIDIndex;
  end else
    Result := nil
end;

function AllocShellString(SourceStr: WideString): POLEStr;
var
  Malloc: IMalloc;
begin
  SHGetMalloc(Malloc);
  Result := Malloc.Alloc((Length(SourceStr) + 1) * 2); // Add the null
  if Result <> nil then
    CopyMemory(Result, PWideChar(SourceStr), (Length(SourceStr) + 1) * 2);
end;

function FillStrRet(var AStrRet: TStrRet; AType: TStrRetType;
  AString: WideString; PIDLOffset: Integer): HRESULT;
var
  Str: string;
begin
  FillChar(AStrRet, SizeOf(AStrRet), #0);
  case AType of
    srtPIDLOffset:
      begin
        AStrRet.uType := STRRET_OFFSET;
        AStrRet.uOffset := PIDLOffset;
      end;
    srtOLEStr:
      begin
        AStrRet.uType := STRRET_WSTR;
        AStrRet.pOleStr := AllocShellString(AString)
      end;
    srtANSIStr:
      begin
        AStrRet.uType := STRRET_CSTR;
        Str := AString;
        StrLCopy(AStrRet.cStr, PAnsiChar(AnsiString(Str)), MAX_PATH - 1);
      end;
  end;
  Result := S_OK
end;

function AppendPIDL(DestPIDL, SrcPIDL: PItemIDList): PItemIDList;
// Returns the concatination of the two PIDLs. Neither passed PIDLs are
// freed so it is up to the caller to free them.
  function IsDesktopFolder(APIDL: PItemIDList): Boolean;
  // Tests the passed PIDL to see if it is the root Desktop Folder
  begin
    if Assigned(APIDL) then
      Result := APIDL.mkid.cb = 0
    else
      Result := False
  end;
var
  DestPIDLSize, SrcPIDLSize: integer;
begin
  DestPIDLSize := 0;
  SrcPIDLSize := 0;
  // Appending a PIDL to the DesktopPIDL is invalid so don't allow it.
  if Assigned(DestPIDL) then
    if not IsDesktopFolder(DestPIDL) then
      DestPIDLSize := PIDLSize(DestPIDL) - SizeOf(DestPIDL^.mkid.cb);

  if Assigned(SrcPIDL) then
    SrcPIDLSize := PIDLSize(SrcPIDL);

  Result := FMalloc.Alloc(DestPIDLSize + SrcPIDLSize);
  if Assigned(Result) then
  begin
    if Assigned(DestPIDL) then
      CopyMemory(Result, DestPIDL, DestPIDLSize);
    if Assigned(SrcPIDL) then
      CopyMemory(PByte(Result) + DestPIDLSize, SrcPIDL, SrcPIDLSize);
  end;
end;

procedure FreeAndNilPIDL(var PIDL: PItemIDList);
var
  OldPIDL: PItemIDList;
begin
  OldPIDL := PIDL;
  PIDL := nil;
  FreePIDL(OldPIDL)
end;

procedure FreePIDL(PIDL: PItemIDList);
// Frees the PIDL using the shell memory allocator
begin
  if Assigned(PIDL) then
    FMalloc.Free(PIDL)
end;

initialization
  SHGetMalloc(FMalloc);

end.
