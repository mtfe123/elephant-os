;主引导程序 
;------------------------------------------------------------
%include "boot.inc"

SECTION MBR vstart=0x7c00         
   mov ax,cs      
   mov ds,ax
   mov es,ax
   mov ss,ax
   mov fs,ax
   mov sp,0x7c00
   mov ax,0xB800
   mov gs,ax

; 清屏 利用0x06号功能，上卷全部行，则可清屏。
; -----------------------------------------------------------
;INT 0x10   功能号:0x06	   功能描述:上卷窗口
;------------------------------------------------------
;输入：
;AH 功能号= 0x06
;AL = 上卷的行数(如果为0,表示全部)
;BH = 上卷行属性
;(CL,CH) = 窗口左上角的(X,Y)位置
;(DL,DH) = 窗口右下角的(X,Y)位置
;无返回值：
   mov     ax, 0x600
   mov     bx, 0x700
   mov     cx, 0           ; 左上角: (0, 0)
   mov     dx, 0x184f	   ; 右下角: (80,25),
			   ; VGA文本模式中,一行只能容纳80个字符,共25行。
			   ; 下标从0开始,所以0x18=24,0x4f=79
   int     0x10            ; int 0x10

   ;输出字符
   mov byte [gs:0x00],'1'
   mov byte [gs:0x01],0xA4

   mov byte [gs:0x02],' '
   mov byte [gs:0x03],0xA4

   mov byte [gs:0x04],'M'
   mov byte [gs:0x05],0xA4

   mov byte [gs:0x06],'B'
   mov byte [gs:0x07],0xA4

   mov byte [gs:0x08],'R'
   mov byte [gs:0x09],0xA4

   mov eax,LOADER_START_SECTOR;起始扇区的lba地址
   mov bx,LOADER_BASE_ADDR;内核加载器被加载到内存的地址
   mov cx,1;待读入的扇区数
   call rd_disk_m_16

   jmp LOADER_BASE_ADDR

   ;--------------------------------------------------------------------------
   ;功能：
   ;从硬盘第eax个扇区开始，读cx个扇区到起始内存地址为bx的内存中去
   ;参数：
   ;eax=LBA扇区号
   ;bx=将数据写入的内存地址
   ;cx=读入的扇区数
rd_disk_m_16:
   ;--------------------------------------------------------------------------
   
   ;备份eax和cx
   mov esi,eax
   mov di,cx

   ;1.写入待操作的扇区数
   mov dx,0x1F2
   mov al,cl
   out dx,al

   mov eax,esi
   ;2.写入LBA地址
   mov cl,8
   mov dx,0x1F3
   out dx,al

   shr eax,cl
   mov dx,0x1F4
   out dx,al

   shr eax,cl
   mov dx,0x1F5
   out dx,al

   shr eax,cl
   mov dx,0x1F6
   and al,0x0F
   or al,0xE0
   out dx,al

   ;3.写入读命令
   mov dx,0x1F7
   mov al,0x20
   out dx,al

   ;4.判断数据是否读取完毕
   .not_ready:
      nop
      in al,dx
      and al,0x88
      cmp al,0x08
      jnz .not_ready

   ;5.读取数据到内存
   mov ax,256
   mul di
   mov cx,ax
   mov dx,0x1F0
   .go_on_read:
      in ax,dx
      mov [bx],ax
      add bx,2
      loop .go_on_read
   ret
   times 510-($-$$) db 0
   db 0x55,0xaa