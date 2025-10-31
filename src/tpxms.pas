(****************************************************************************

          TPXMS.PAS  v1.00   Written by Vernon E. Davis   07/30/89

          for use with HIMEM.SYS, an Extended Memory Device Driver


 NOTE: The current version of HIMEM.SYS ( v2.06 ), as of this release, does
       not support the following Function Calls:

                 $0F : Reallocate Extended Memory Block
                 $10 : Request Upper Memory Block
                 $11 : Release Upper Memory Block

       This source code is written with these functions available, so when
       HIMEM.SYS does support them, no recompilation will be necessary.
 ****************************************************************************)

Unit TPXMS;
{$O+,F+}
Interface
Uses
   DOS;
Type
   Bit32Struct = LongInt;

   ExtMemMoveStruct =
   Record
      Length       : Bit32Struct;
      SourceHandle : Word;
      SourceOffset : Bit32Struct;
      DestHandle   : Word;
      DestOffset   : Bit32Struct
   End;

   EMBHandleStruct =
   Record
      LockCount   : Byte;
      FreeHandles : Byte;
      BlockLenKB  : Word
   End;

   UMBSegmentStruct =
   Record
      Segment   : Word;
      UMBSizeKB : Word
   End;

Var
   przenies:ExtMemMoveStruct;

   isXMS       : Boolean;
   XMSResult   : Word;
   XMSError    : Byte;
   XMM_Control : Array[0..1] of Word;

(* Procedure/Function Declarations *)

   Function  XMSErrorMsg : String;
   Function  EXISTXMS : Boolean;
   Procedure GetVerHiMem;
   Procedure GetRevHiMem;
   Procedure GetMemHMA(malloc : Word);
   Procedure FreeMemHMA;
   Procedure GlobalEnableA20;
   Procedure GlobalDisableA20;
   Procedure LocalEnableA20;
   Procedure LocalDisableA20;
   Procedure QueryA20;
   Procedure QueryFreeMemXMS;
   Procedure QueryFreeBlockXMS;
   Function  AllocExtMemBlockXMS(malloc : Word) : Word;
   Procedure FreeExtMemBlockXMS(handle : Word);
   Procedure MoveExtMemBlockXMS(Var MoveStructure : ExtMemMoveStruct);
   Function  LockExtMemBlockXMS(handle : Word) : Bit32Struct;
   Procedure UnlockExtMemBlockXMS(handle : Word);
   Procedure EMBHandleInfoXMS(handle : Word; Var HStructure : EMBHandleStruct);
   Procedure ReallocExtMemBlockXMS(handle,KBsize : Word);
   Procedure ReqUpperMemBlockUMB(malloc : Word; Var USeg : UMBSegmentStruct);
   Procedure RelUpperMemBlockUMB(segment : Word);

Implementation

Function XMSErrorMsg : String;
Var
   XMSMsg : String;
Begin
   XMSMsg := '';
   Case XMSError of
   $00 : XMSMsg := '';
   $80 : XMSMsg := '80 : XMS Function not implemented';
   $81 : XMSMsg := '81 : VDISK detected';
   $82 : XMSMsg := '82 : A20 Error';
   $8E : XMSMsg := '8E : General Driver Error';
   $8F : XMSMsg := '8F : Unrecoverable Driver Error';
   $90 : XMSMsg := '90 : HMA does not exist';
   $91 : XMSMsg := '91 : HMA in use by another process';
   $92 : XMSMsg := '92 : Memory requested less than /HMAMIN= parameter';
   $93 : XMSMsg := '93 : HMA not allocated';
   $94 : XMSMsg := '94 : A20 is enabled';
   $A0 : XMSMsg := 'A0 : All of Extended Memory is allocated';
   $A1 : XMSMsg := 'A1 : No Extended Memory Handles available';
   $A2 : XMSMsg := 'A2 : Extended Memory Handle is invalid';
   $A3 : XMSMsg := 'A3 : Extended Move Structure: Source Handle is invalid';
   $A4 : XMSMsg := 'A4 : Extended Move Structure: Source Offset is invalid';
   $A5 : XMSMsg := 'A5 : Extended Move Structure: Destination Handle is invalid';
   $A6 : XMSMsg := 'A6 : Extended Move Structure: Destination Offset is invalid';
   $A7 : XMSMsg := 'A7 : Extended Move Structure: Length is invalid';
   $A8 : XMSMsg := 'A8 : Extended Move Structure: Move has invalid overlap';
   $A9 : XMSMsg := 'A9 : Parity Error';
   $AA : XMSMsg := 'AA : Block is not locked';
   $AB : XMSMsg := 'AB : Block is locked';
   $AC : XMSMsg := 'AC : Block Lock Count has overflowed';
   $AD : XMSMsg := 'AD : Block Lock has failed';
   $B0 : XMSMsg := 'B0 : A smaller Upper Memory Block is available';
   $B1 : XMSMsg := 'B1 : No Upper Memory Blocks are available';
   $B2 : XMSMsg := 'B2 : Upper Memory Block Segment Number is invalid'
   Else
      XMSMsg := 'Unknown Error has occured'
   End;
   If XMSMsg <> '' Then
      XMSErrorMsg := 'XMS Error $' + XMSMsg
End;

Function EXISTXMS : Boolean;
Var
   regs : Registers;
Begin
   regs.AX := $4300;
   Intr($2F,regs);
   If regs.al = $80 Then
   Begin
      regs.AX := $4310;
      Intr($2F,regs);
      XMM_Control[0] := regs.bx;
      XMM_Control[1] := regs.es;
      EXISTXMS := TRUE
   End
   Else
      EXISTXMS := FALSE
End;

Procedure GetVerHiMem;
(* XMSResult = Version level in BCD *)
Var
   ax : Word;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $B8/$00/$00/                         {  MOV  AX,0000               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax                           {  MOV  ax[BP],AX             }
   );
   XMSResult := ax
End;

Procedure GetRevHiMem;
(* XMSResult = Internal Revision level in BCD *)
Var
   bx : Word;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $B8/$00/$00/                         {  MOV  AX,0000               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$9E/bx                           {  MOV  bx[BP],BX             }
   );
   XMSResult := bx
End;

Procedure GetMemHMA(malloc : Word);
Var
   ax : Word;
   bl : Byte;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $8B/$96/malloc/                      {  MOV  DX,malloc[BP]         }
      $B8/$00/$01/                         {  MOV  AX,0100               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $88/$9E/bl                           {  MOV  bl[BP],BL             }
   );
   XMSResult := ax;
   XMSError  := bl
End;

Procedure FreeMemHMA;
Var
   ax : Word;
   bl : Byte;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $B8/$00/$02/                         {  MOV  AX,0200               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $88/$9E/bl                           {  MOV  bl[BP],BL             }
   );
   XMSResult := ax;
   XMSError  := bl
End;

Procedure GlobalEnableA20;
Var
   ax : Word;
   bl : Byte;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $B8/$00/$03/                         {  MOV  AX,0300               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $88/$9E/bl                           {  MOV  bl[BP],BL             }
   );
   XMSResult := ax;
   XMSError  := bl
End;

Procedure GlobalDisableA20;
Var
   ax : Word;
   bl : Byte;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $B8/$00/$04/                         {  MOV  AX,0400               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $88/$9E/bl                           {  MOV  bl[BP],BL             }
   );
   XMSResult := ax;
   XMSError  := bl
End;

Procedure LocalEnableA20;
Var
   ax : Word;
   bl : Byte;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $B8/$00/$05/                         {  MOV  AX,0500               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $88/$9E/bl                           {  MOV  bl[BP],BL             }
   );
   XMSResult := ax;
   XMSError  := bl
End;

Procedure LocalDisableA20;
Var
   ax : Word;
   bl : Byte;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $B8/$00/$06/                         {  MOV  AX,0600               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $88/$9E/bl                           {  MOV  bl[BP],BL             }
   );
   XMSResult := ax;
   XMSError  := bl
End;

Procedure QueryA20;
(* XMSResult = 1 if A20 is physically enabled, else 0 *)
Var
   ax : Word;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $B8/$00/$07/                         {  MOV  AX,0700               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax                           {  MOV  ax[BP],AX             }
   );
   XMSResult := ax
End;

Procedure QueryFreeMemXMS;
(* XMSResult = total free Extended Memory in kilobytes *)
Var
   ax : Word;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $B8/$00/$08/                         {  MOV  AX,0800               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax                           {  MOV  ax[BP],AX             }
   );
   XMSResult := ax
End;

Procedure QueryFreeBlockXMS;
(* XMSResult = largest free block of Extended Memory in kilobytes *)
Var
   dx : Word;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $B8/$00/$08/                         {  MOV  AX,0800               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$96/dx                           {  MOV  dx[BP],DX             }
   );
   XMSResult := dx
End;

Function AllocExtMemBlockXMS(malloc : Word) : Word;
(* If successful, returns handle to Extended Memory Block *)
Var
   ax : Word;
   dx : Word;
   bl : Byte;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      AllocExtMemBlockXMS := 0;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $8B/$96/malloc/                      {  MOV  DX,malloc[BP]         }
      $B8/$00/$09/                         {  MOV  AX,0900               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $88/$9E/bl/                          {  MOV  bl[BP],BL             }
      $89/$96/dx                           {  MOV  dx[BP],DX             }
   );
   XMSResult := ax;
   XMSError  := bl;
   AllocExtMemBlockXMS := dx
End;

Procedure FreeExtMemBlockXMS(handle : Word);
Var
   ax : Word;
   bl : Byte;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $8B/$96/handle/                      {  MOV  DX,handle[BP]         }
      $B8/$00/$0A/                         {  MOV  AX,0A00               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $88/$9E/bl                           {  MOV  bl[BP],BL             }
   );
   XMSResult := ax;
   XMSError  := bl
End;

Procedure MoveExtMemBlockXMS(Var MoveStructure : ExtMemMoveStruct);
(* NOTE: This procedure assumes that the ExtMemMove structure is valid *)
Var
   ax,
   segs,
   ofss : Word;
   bl   : Byte;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   segs := Seg(MoveStructure);
   ofss := Ofs(MoveStructure);
   Inline
   (  $1E/                                 {  PUSH DS                    }
      $8B/$86/segs/                        {  MOV  AX,segs[BP]           }
      $8E/$D8/                             {  MOV  DS,AX                 }
      $8B/$B6/ofss/                        {  MOV  SI,ofss[BP]           }
      $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $B8/$00/$0B/                         {  MOV  AX,0B00               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $1F/                                 {  POP  DS                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $88/$9E/bl                           {  MOV  bl[BP],BL             }
   );
   XMSResult := ax;
   XMSError  := bl
End;

Function LockExtMemBlockXMS(handle : Word) : Bit32Struct;
Var
   ax,bx,dx : Word;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      LockExtMemBlockXMS := 0;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $8B/$96/handle/                      {  MOV  DX,handle[BP]         }
      $B8/$00/$0C/                         {  MOV  AX,0C00               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $89/$9E/bx/                          {  MOV  bx[BP],BX             }
      $89/$96/dx                           {  MOV  dx[BP],DX             }
   );
   XMSResult := ax;
   LockExtMemBlockXMS := (dx SHL 8) + bx
End;

Procedure UnlockExtMemBlockXMS(handle : Word);
Var
   ax : Word;
   bl : Byte;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $8B/$96/handle/                      {  MOV  DX,handle[BP]         }
      $B8/$00/$0D/                         {  MOV  AX,0D00               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $88/$9E/bl                           {  MOV  bl[BP],BL             }
   );
   XMSResult := ax;
   XMSError  := bl
End;

Procedure EMBHandleInfoXMS(handle : Word; Var HStructure : EMBHandleStruct);
Var
   ax,bx,dx : Word;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $8B/$96/handle/                      {  MOV  DX,handle[BP]         }
      $B8/$00/$0E/                         {  MOV  AX,0E00               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $89/$9E/bx/                          {  MOV  bx[BP],BX             }
      $89/$96/dx                           {  MOV  dx[BP],DX             }
   );
   XMSResult := ax;
   With HStructure Do
   Begin
      LockCount   := Hi(bx);
      FreeHandles := Lo(bx);
      BlockLenKB  := dx
   End
End;

Procedure ReallocExtMemBlockXMS(handle,KBsize : Word);
Var
   ax : Word;
   bl : Byte;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $8B/$96/handle/                      {  MOV  DX,handle[BP]         }
      $8B/$9E/KBSize/                      {  MOV  BX,KBSize[BP]         }
      $B8/$00/$0F/                         {  MOV  AX,0F00               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $88/$9E/bl                           {  MOV  bl[BP],BL             }
   );
   XMSResult := ax;
   XMSError  := bl
End;

Procedure ReqUpperMemBlockUMB(malloc : Word; Var USeg : UMBSegmentStruct);
Var
   ax,bx,dx : Word;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $8B/$96/malloc/                      {  MOV  DX,malloc[BP]         }
      $B8/$00/$10/                         {  MOV  AX,1000               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $89/$9E/bx/                          {  MOV  bx[BP],BX             }
      $89/$96/dx                           {  MOV  dx[BP],DX             }
   );
   XMSResult := ax;
   With USeg Do
   Begin
      Segment := bx;
      If XMSResult = 1 Then
         UMBSizeKB := malloc
      Else
         UMBSizeKB := dx
   End
End;

Procedure RelUpperMemBlockUMB(segment : Word);
Var
   ax : Word;
   bl : Byte;
Begin
   XMSResult := 1;
   XMSError  := 0;
   If NOT isXMS Then
   Begin
      XMSResult := 0;
      XMSError  := $80;
      Exit
   End;
   Inline
   (  $BF/XMM_Control/                     {  MOV  DI,XMM_Control        }
      $8B/$96/segment/                     {  MOV  DX,segment[BP]        }
      $B8/$00/$11/                         {  MOV  AX,1100               }
      $55/                                 {  PUSH BP                    }
      $FF/$1D/                             {  CALL FAR[DI] (XMM_Control) }
      $5D/                                 {  POP  BP                    }
      $89/$86/ax/                          {  MOV  ax[BP],AX             }
      $88/$9E/bl                           {  MOV  bl[BP],BL             }
   );
   XMSResult := ax;
   XMSError  := bl
End;

Begin
   XMM_Control[0] := 0;
   XMM_Control[1] := 0;
   XMSResult      := 1;
   XMSError       := 0;
   isXMS          := EXISTXMS;
End.
