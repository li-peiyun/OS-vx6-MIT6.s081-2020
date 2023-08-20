
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	86013103          	ld	sp,-1952(sp) # 80008860 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	00c78793          	addi	a5,a5,12 # 80006070 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffcc7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dd678793          	addi	a5,a5,-554 # 80000e84 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	42c080e7          	jalr	1068(ra) # 8000254a <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	78e080e7          	jalr	1934(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7119                	addi	sp,sp,-128
    80000158:	fc86                	sd	ra,120(sp)
    8000015a:	f8a2                	sd	s0,112(sp)
    8000015c:	f4a6                	sd	s1,104(sp)
    8000015e:	f0ca                	sd	s2,96(sp)
    80000160:	ecce                	sd	s3,88(sp)
    80000162:	e8d2                	sd	s4,80(sp)
    80000164:	e4d6                	sd	s5,72(sp)
    80000166:	e0da                	sd	s6,64(sp)
    80000168:	fc5e                	sd	s7,56(sp)
    8000016a:	f862                	sd	s8,48(sp)
    8000016c:	f466                	sd	s9,40(sp)
    8000016e:	f06a                	sd	s10,32(sp)
    80000170:	ec6e                	sd	s11,24(sp)
    80000172:	0100                	addi	s0,sp,128
    80000174:	8b2a                	mv	s6,a0
    80000176:	8aae                	mv	s5,a1
    80000178:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000017e:	00011517          	auipc	a0,0x11
    80000182:	00250513          	addi	a0,a0,2 # 80011180 <cons>
    80000186:	00001097          	auipc	ra,0x1
    8000018a:	a50080e7          	jalr	-1456(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018e:	00011497          	auipc	s1,0x11
    80000192:	ff248493          	addi	s1,s1,-14 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000196:	89a6                	mv	s3,s1
    80000198:	00011917          	auipc	s2,0x11
    8000019c:	08090913          	addi	s2,s2,128 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001a0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001a2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a4:	4da9                	li	s11,10
  while(n > 0){
    800001a6:	07405863          	blez	s4,80000216 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001aa:	0984a783          	lw	a5,152(s1)
    800001ae:	09c4a703          	lw	a4,156(s1)
    800001b2:	02f71463          	bne	a4,a5,800001da <consoleread+0x84>
      if(myproc()->killed){
    800001b6:	00001097          	auipc	ra,0x1
    800001ba:	7f0080e7          	jalr	2032(ra) # 800019a6 <myproc>
    800001be:	591c                	lw	a5,48(a0)
    800001c0:	e7b5                	bnez	a5,8000022c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001c2:	85ce                	mv	a1,s3
    800001c4:	854a                	mv	a0,s2
    800001c6:	00002097          	auipc	ra,0x2
    800001ca:	0cc080e7          	jalr	204(ra) # 80002292 <sleep>
    while(cons.r == cons.w){
    800001ce:	0984a783          	lw	a5,152(s1)
    800001d2:	09c4a703          	lw	a4,156(s1)
    800001d6:	fef700e3          	beq	a4,a5,800001b6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001da:	0017871b          	addiw	a4,a5,1
    800001de:	08e4ac23          	sw	a4,152(s1)
    800001e2:	07f7f713          	andi	a4,a5,127
    800001e6:	9726                	add	a4,a4,s1
    800001e8:	01874703          	lbu	a4,24(a4)
    800001ec:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001f0:	079c0663          	beq	s8,s9,8000025c <consoleread+0x106>
    cbuf = c;
    800001f4:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f8:	4685                	li	a3,1
    800001fa:	f8f40613          	addi	a2,s0,-113
    800001fe:	85d6                	mv	a1,s5
    80000200:	855a                	mv	a0,s6
    80000202:	00002097          	auipc	ra,0x2
    80000206:	2f2080e7          	jalr	754(ra) # 800024f4 <either_copyout>
    8000020a:	01a50663          	beq	a0,s10,80000216 <consoleread+0xc0>
    dst++;
    8000020e:	0a85                	addi	s5,s5,1
    --n;
    80000210:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000212:	f9bc1ae3          	bne	s8,s11,800001a6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000216:	00011517          	auipc	a0,0x11
    8000021a:	f6a50513          	addi	a0,a0,-150 # 80011180 <cons>
    8000021e:	00001097          	auipc	ra,0x1
    80000222:	a6c080e7          	jalr	-1428(ra) # 80000c8a <release>

  return target - n;
    80000226:	414b853b          	subw	a0,s7,s4
    8000022a:	a811                	j	8000023e <consoleread+0xe8>
        release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	f5450513          	addi	a0,a0,-172 # 80011180 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	a56080e7          	jalr	-1450(ra) # 80000c8a <release>
        return -1;
    8000023c:	557d                	li	a0,-1
}
    8000023e:	70e6                	ld	ra,120(sp)
    80000240:	7446                	ld	s0,112(sp)
    80000242:	74a6                	ld	s1,104(sp)
    80000244:	7906                	ld	s2,96(sp)
    80000246:	69e6                	ld	s3,88(sp)
    80000248:	6a46                	ld	s4,80(sp)
    8000024a:	6aa6                	ld	s5,72(sp)
    8000024c:	6b06                	ld	s6,64(sp)
    8000024e:	7be2                	ld	s7,56(sp)
    80000250:	7c42                	ld	s8,48(sp)
    80000252:	7ca2                	ld	s9,40(sp)
    80000254:	7d02                	ld	s10,32(sp)
    80000256:	6de2                	ld	s11,24(sp)
    80000258:	6109                	addi	sp,sp,128
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	000a071b          	sext.w	a4,s4
    80000260:	fb777be3          	bgeu	a4,s7,80000216 <consoleread+0xc0>
        cons.r--;
    80000264:	00011717          	auipc	a4,0x11
    80000268:	faf72a23          	sw	a5,-76(a4) # 80011218 <cons+0x98>
    8000026c:	b76d                	j	80000216 <consoleread+0xc0>

000000008000026e <consputc>:
{
    8000026e:	1141                	addi	sp,sp,-16
    80000270:	e406                	sd	ra,8(sp)
    80000272:	e022                	sd	s0,0(sp)
    80000274:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000276:	10000793          	li	a5,256
    8000027a:	00f50a63          	beq	a0,a5,8000028e <consputc+0x20>
    uartputc_sync(c);
    8000027e:	00000097          	auipc	ra,0x0
    80000282:	564080e7          	jalr	1380(ra) # 800007e2 <uartputc_sync>
}
    80000286:	60a2                	ld	ra,8(sp)
    80000288:	6402                	ld	s0,0(sp)
    8000028a:	0141                	addi	sp,sp,16
    8000028c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000028e:	4521                	li	a0,8
    80000290:	00000097          	auipc	ra,0x0
    80000294:	552080e7          	jalr	1362(ra) # 800007e2 <uartputc_sync>
    80000298:	02000513          	li	a0,32
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	546080e7          	jalr	1350(ra) # 800007e2 <uartputc_sync>
    800002a4:	4521                	li	a0,8
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	53c080e7          	jalr	1340(ra) # 800007e2 <uartputc_sync>
    800002ae:	bfe1                	j	80000286 <consputc+0x18>

00000000800002b0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b0:	1101                	addi	sp,sp,-32
    800002b2:	ec06                	sd	ra,24(sp)
    800002b4:	e822                	sd	s0,16(sp)
    800002b6:	e426                	sd	s1,8(sp)
    800002b8:	e04a                	sd	s2,0(sp)
    800002ba:	1000                	addi	s0,sp,32
    800002bc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002be:	00011517          	auipc	a0,0x11
    800002c2:	ec250513          	addi	a0,a0,-318 # 80011180 <cons>
    800002c6:	00001097          	auipc	ra,0x1
    800002ca:	910080e7          	jalr	-1776(ra) # 80000bd6 <acquire>

  switch(c){
    800002ce:	47d5                	li	a5,21
    800002d0:	0af48663          	beq	s1,a5,8000037c <consoleintr+0xcc>
    800002d4:	0297ca63          	blt	a5,s1,80000308 <consoleintr+0x58>
    800002d8:	47a1                	li	a5,8
    800002da:	0ef48763          	beq	s1,a5,800003c8 <consoleintr+0x118>
    800002de:	47c1                	li	a5,16
    800002e0:	10f49a63          	bne	s1,a5,800003f4 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002e4:	00002097          	auipc	ra,0x2
    800002e8:	2bc080e7          	jalr	700(ra) # 800025a0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ec:	00011517          	auipc	a0,0x11
    800002f0:	e9450513          	addi	a0,a0,-364 # 80011180 <cons>
    800002f4:	00001097          	auipc	ra,0x1
    800002f8:	996080e7          	jalr	-1642(ra) # 80000c8a <release>
}
    800002fc:	60e2                	ld	ra,24(sp)
    800002fe:	6442                	ld	s0,16(sp)
    80000300:	64a2                	ld	s1,8(sp)
    80000302:	6902                	ld	s2,0(sp)
    80000304:	6105                	addi	sp,sp,32
    80000306:	8082                	ret
  switch(c){
    80000308:	07f00793          	li	a5,127
    8000030c:	0af48e63          	beq	s1,a5,800003c8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000310:	00011717          	auipc	a4,0x11
    80000314:	e7070713          	addi	a4,a4,-400 # 80011180 <cons>
    80000318:	0a072783          	lw	a5,160(a4)
    8000031c:	09872703          	lw	a4,152(a4)
    80000320:	9f99                	subw	a5,a5,a4
    80000322:	07f00713          	li	a4,127
    80000326:	fcf763e3          	bltu	a4,a5,800002ec <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000032a:	47b5                	li	a5,13
    8000032c:	0cf48763          	beq	s1,a5,800003fa <consoleintr+0x14a>
      consputc(c);
    80000330:	8526                	mv	a0,s1
    80000332:	00000097          	auipc	ra,0x0
    80000336:	f3c080e7          	jalr	-196(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000033a:	00011797          	auipc	a5,0x11
    8000033e:	e4678793          	addi	a5,a5,-442 # 80011180 <cons>
    80000342:	0a07a703          	lw	a4,160(a5)
    80000346:	0017069b          	addiw	a3,a4,1
    8000034a:	0006861b          	sext.w	a2,a3
    8000034e:	0ad7a023          	sw	a3,160(a5)
    80000352:	07f77713          	andi	a4,a4,127
    80000356:	97ba                	add	a5,a5,a4
    80000358:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000035c:	47a9                	li	a5,10
    8000035e:	0cf48563          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000362:	4791                	li	a5,4
    80000364:	0cf48263          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000368:	00011797          	auipc	a5,0x11
    8000036c:	eb07a783          	lw	a5,-336(a5) # 80011218 <cons+0x98>
    80000370:	0807879b          	addiw	a5,a5,128
    80000374:	f6f61ce3          	bne	a2,a5,800002ec <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000378:	863e                	mv	a2,a5
    8000037a:	a07d                	j	80000428 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000037c:	00011717          	auipc	a4,0x11
    80000380:	e0470713          	addi	a4,a4,-508 # 80011180 <cons>
    80000384:	0a072783          	lw	a5,160(a4)
    80000388:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000038c:	00011497          	auipc	s1,0x11
    80000390:	df448493          	addi	s1,s1,-524 # 80011180 <cons>
    while(cons.e != cons.w &&
    80000394:	4929                	li	s2,10
    80000396:	f4f70be3          	beq	a4,a5,800002ec <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	37fd                	addiw	a5,a5,-1
    8000039c:	07f7f713          	andi	a4,a5,127
    800003a0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003a2:	01874703          	lbu	a4,24(a4)
    800003a6:	f52703e3          	beq	a4,s2,800002ec <consoleintr+0x3c>
      cons.e--;
    800003aa:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ae:	10000513          	li	a0,256
    800003b2:	00000097          	auipc	ra,0x0
    800003b6:	ebc080e7          	jalr	-324(ra) # 8000026e <consputc>
    while(cons.e != cons.w &&
    800003ba:	0a04a783          	lw	a5,160(s1)
    800003be:	09c4a703          	lw	a4,156(s1)
    800003c2:	fcf71ce3          	bne	a4,a5,8000039a <consoleintr+0xea>
    800003c6:	b71d                	j	800002ec <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c8:	00011717          	auipc	a4,0x11
    800003cc:	db870713          	addi	a4,a4,-584 # 80011180 <cons>
    800003d0:	0a072783          	lw	a5,160(a4)
    800003d4:	09c72703          	lw	a4,156(a4)
    800003d8:	f0f70ae3          	beq	a4,a5,800002ec <consoleintr+0x3c>
      cons.e--;
    800003dc:	37fd                	addiw	a5,a5,-1
    800003de:	00011717          	auipc	a4,0x11
    800003e2:	e4f72123          	sw	a5,-446(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e6:	10000513          	li	a0,256
    800003ea:	00000097          	auipc	ra,0x0
    800003ee:	e84080e7          	jalr	-380(ra) # 8000026e <consputc>
    800003f2:	bded                	j	800002ec <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003f4:	ee048ce3          	beqz	s1,800002ec <consoleintr+0x3c>
    800003f8:	bf21                	j	80000310 <consoleintr+0x60>
      consputc(c);
    800003fa:	4529                	li	a0,10
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e72080e7          	jalr	-398(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000404:	00011797          	auipc	a5,0x11
    80000408:	d7c78793          	addi	a5,a5,-644 # 80011180 <cons>
    8000040c:	0a07a703          	lw	a4,160(a5)
    80000410:	0017069b          	addiw	a3,a4,1
    80000414:	0006861b          	sext.w	a2,a3
    80000418:	0ad7a023          	sw	a3,160(a5)
    8000041c:	07f77713          	andi	a4,a4,127
    80000420:	97ba                	add	a5,a5,a4
    80000422:	4729                	li	a4,10
    80000424:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000428:	00011797          	auipc	a5,0x11
    8000042c:	dec7aa23          	sw	a2,-524(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000430:	00011517          	auipc	a0,0x11
    80000434:	de850513          	addi	a0,a0,-536 # 80011218 <cons+0x98>
    80000438:	00002097          	auipc	ra,0x2
    8000043c:	fe0080e7          	jalr	-32(ra) # 80002418 <wakeup>
    80000440:	b575                	j	800002ec <consoleintr+0x3c>

0000000080000442 <consoleinit>:

void
consoleinit(void)
{
    80000442:	1141                	addi	sp,sp,-16
    80000444:	e406                	sd	ra,8(sp)
    80000446:	e022                	sd	s0,0(sp)
    80000448:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000044a:	00008597          	auipc	a1,0x8
    8000044e:	bc658593          	addi	a1,a1,-1082 # 80008010 <etext+0x10>
    80000452:	00011517          	auipc	a0,0x11
    80000456:	d2e50513          	addi	a0,a0,-722 # 80011180 <cons>
    8000045a:	00000097          	auipc	ra,0x0
    8000045e:	6ec080e7          	jalr	1772(ra) # 80000b46 <initlock>

  uartinit();
    80000462:	00000097          	auipc	ra,0x0
    80000466:	330080e7          	jalr	816(ra) # 80000792 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000046a:	0002d797          	auipc	a5,0x2d
    8000046e:	e9678793          	addi	a5,a5,-362 # 8002d300 <devsw>
    80000472:	00000717          	auipc	a4,0x0
    80000476:	ce470713          	addi	a4,a4,-796 # 80000156 <consoleread>
    8000047a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	c7870713          	addi	a4,a4,-904 # 800000f4 <consolewrite>
    80000484:	ef98                	sd	a4,24(a5)
}
    80000486:	60a2                	ld	ra,8(sp)
    80000488:	6402                	ld	s0,0(sp)
    8000048a:	0141                	addi	sp,sp,16
    8000048c:	8082                	ret

000000008000048e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000048e:	7179                	addi	sp,sp,-48
    80000490:	f406                	sd	ra,40(sp)
    80000492:	f022                	sd	s0,32(sp)
    80000494:	ec26                	sd	s1,24(sp)
    80000496:	e84a                	sd	s2,16(sp)
    80000498:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000049a:	c219                	beqz	a2,800004a0 <printint+0x12>
    8000049c:	08054663          	bltz	a0,80000528 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a0:	2501                	sext.w	a0,a0
    800004a2:	4881                	li	a7,0
    800004a4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004aa:	2581                	sext.w	a1,a1
    800004ac:	00008617          	auipc	a2,0x8
    800004b0:	b9460613          	addi	a2,a2,-1132 # 80008040 <digits>
    800004b4:	883a                	mv	a6,a4
    800004b6:	2705                	addiw	a4,a4,1
    800004b8:	02b577bb          	remuw	a5,a0,a1
    800004bc:	1782                	slli	a5,a5,0x20
    800004be:	9381                	srli	a5,a5,0x20
    800004c0:	97b2                	add	a5,a5,a2
    800004c2:	0007c783          	lbu	a5,0(a5)
    800004c6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ca:	0005079b          	sext.w	a5,a0
    800004ce:	02b5553b          	divuw	a0,a0,a1
    800004d2:	0685                	addi	a3,a3,1
    800004d4:	feb7f0e3          	bgeu	a5,a1,800004b4 <printint+0x26>

  if(sign)
    800004d8:	00088b63          	beqz	a7,800004ee <printint+0x60>
    buf[i++] = '-';
    800004dc:	fe040793          	addi	a5,s0,-32
    800004e0:	973e                	add	a4,a4,a5
    800004e2:	02d00793          	li	a5,45
    800004e6:	fef70823          	sb	a5,-16(a4)
    800004ea:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004ee:	02e05763          	blez	a4,8000051c <printint+0x8e>
    800004f2:	fd040793          	addi	a5,s0,-48
    800004f6:	00e784b3          	add	s1,a5,a4
    800004fa:	fff78913          	addi	s2,a5,-1
    800004fe:	993a                	add	s2,s2,a4
    80000500:	377d                	addiw	a4,a4,-1
    80000502:	1702                	slli	a4,a4,0x20
    80000504:	9301                	srli	a4,a4,0x20
    80000506:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000050a:	fff4c503          	lbu	a0,-1(s1)
    8000050e:	00000097          	auipc	ra,0x0
    80000512:	d60080e7          	jalr	-672(ra) # 8000026e <consputc>
  while(--i >= 0)
    80000516:	14fd                	addi	s1,s1,-1
    80000518:	ff2499e3          	bne	s1,s2,8000050a <printint+0x7c>
}
    8000051c:	70a2                	ld	ra,40(sp)
    8000051e:	7402                	ld	s0,32(sp)
    80000520:	64e2                	ld	s1,24(sp)
    80000522:	6942                	ld	s2,16(sp)
    80000524:	6145                	addi	sp,sp,48
    80000526:	8082                	ret
    x = -xx;
    80000528:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000052c:	4885                	li	a7,1
    x = -xx;
    8000052e:	bf9d                	j	800004a4 <printint+0x16>

0000000080000530 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000530:	1101                	addi	sp,sp,-32
    80000532:	ec06                	sd	ra,24(sp)
    80000534:	e822                	sd	s0,16(sp)
    80000536:	e426                	sd	s1,8(sp)
    80000538:	1000                	addi	s0,sp,32
    8000053a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000053c:	00011797          	auipc	a5,0x11
    80000540:	d007a223          	sw	zero,-764(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000544:	00008517          	auipc	a0,0x8
    80000548:	ad450513          	addi	a0,a0,-1324 # 80008018 <etext+0x18>
    8000054c:	00000097          	auipc	ra,0x0
    80000550:	02e080e7          	jalr	46(ra) # 8000057a <printf>
  printf(s);
    80000554:	8526                	mv	a0,s1
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	024080e7          	jalr	36(ra) # 8000057a <printf>
  printf("\n");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	b6a50513          	addi	a0,a0,-1174 # 800080c8 <digits+0x88>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	014080e7          	jalr	20(ra) # 8000057a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000056e:	4785                	li	a5,1
    80000570:	00009717          	auipc	a4,0x9
    80000574:	a8f72823          	sw	a5,-1392(a4) # 80009000 <panicked>
  for(;;)
    80000578:	a001                	j	80000578 <panic+0x48>

000000008000057a <printf>:
{
    8000057a:	7131                	addi	sp,sp,-192
    8000057c:	fc86                	sd	ra,120(sp)
    8000057e:	f8a2                	sd	s0,112(sp)
    80000580:	f4a6                	sd	s1,104(sp)
    80000582:	f0ca                	sd	s2,96(sp)
    80000584:	ecce                	sd	s3,88(sp)
    80000586:	e8d2                	sd	s4,80(sp)
    80000588:	e4d6                	sd	s5,72(sp)
    8000058a:	e0da                	sd	s6,64(sp)
    8000058c:	fc5e                	sd	s7,56(sp)
    8000058e:	f862                	sd	s8,48(sp)
    80000590:	f466                	sd	s9,40(sp)
    80000592:	f06a                	sd	s10,32(sp)
    80000594:	ec6e                	sd	s11,24(sp)
    80000596:	0100                	addi	s0,sp,128
    80000598:	8a2a                	mv	s4,a0
    8000059a:	e40c                	sd	a1,8(s0)
    8000059c:	e810                	sd	a2,16(s0)
    8000059e:	ec14                	sd	a3,24(s0)
    800005a0:	f018                	sd	a4,32(s0)
    800005a2:	f41c                	sd	a5,40(s0)
    800005a4:	03043823          	sd	a6,48(s0)
    800005a8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ac:	00011d97          	auipc	s11,0x11
    800005b0:	c94dad83          	lw	s11,-876(s11) # 80011240 <pr+0x18>
  if(locking)
    800005b4:	020d9b63          	bnez	s11,800005ea <printf+0x70>
  if (fmt == 0)
    800005b8:	040a0263          	beqz	s4,800005fc <printf+0x82>
  va_start(ap, fmt);
    800005bc:	00840793          	addi	a5,s0,8
    800005c0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c4:	000a4503          	lbu	a0,0(s4)
    800005c8:	16050263          	beqz	a0,8000072c <printf+0x1b2>
    800005cc:	4481                	li	s1,0
    if(c != '%'){
    800005ce:	02500a93          	li	s5,37
    switch(c){
    800005d2:	07000b13          	li	s6,112
  consputc('x');
    800005d6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008b97          	auipc	s7,0x8
    800005dc:	a68b8b93          	addi	s7,s7,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	06400c13          	li	s8,100
    800005e8:	a82d                	j	80000622 <printf+0xa8>
    acquire(&pr.lock);
    800005ea:	00011517          	auipc	a0,0x11
    800005ee:	c3e50513          	addi	a0,a0,-962 # 80011228 <pr>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
    800005fa:	bf7d                	j	800005b8 <printf+0x3e>
    panic("null fmt");
    800005fc:	00008517          	auipc	a0,0x8
    80000600:	a2c50513          	addi	a0,a0,-1492 # 80008028 <etext+0x28>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	f2c080e7          	jalr	-212(ra) # 80000530 <panic>
      consputc(c);
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	c62080e7          	jalr	-926(ra) # 8000026e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000614:	2485                	addiw	s1,s1,1
    80000616:	009a07b3          	add	a5,s4,s1
    8000061a:	0007c503          	lbu	a0,0(a5)
    8000061e:	10050763          	beqz	a0,8000072c <printf+0x1b2>
    if(c != '%'){
    80000622:	ff5515e3          	bne	a0,s5,8000060c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000626:	2485                	addiw	s1,s1,1
    80000628:	009a07b3          	add	a5,s4,s1
    8000062c:	0007c783          	lbu	a5,0(a5)
    80000630:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000634:	cfe5                	beqz	a5,8000072c <printf+0x1b2>
    switch(c){
    80000636:	05678a63          	beq	a5,s6,8000068a <printf+0x110>
    8000063a:	02fb7663          	bgeu	s6,a5,80000666 <printf+0xec>
    8000063e:	09978963          	beq	a5,s9,800006d0 <printf+0x156>
    80000642:	07800713          	li	a4,120
    80000646:	0ce79863          	bne	a5,a4,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000064a:	f8843783          	ld	a5,-120(s0)
    8000064e:	00878713          	addi	a4,a5,8
    80000652:	f8e43423          	sd	a4,-120(s0)
    80000656:	4605                	li	a2,1
    80000658:	85ea                	mv	a1,s10
    8000065a:	4388                	lw	a0,0(a5)
    8000065c:	00000097          	auipc	ra,0x0
    80000660:	e32080e7          	jalr	-462(ra) # 8000048e <printint>
      break;
    80000664:	bf45                	j	80000614 <printf+0x9a>
    switch(c){
    80000666:	0b578263          	beq	a5,s5,8000070a <printf+0x190>
    8000066a:	0b879663          	bne	a5,s8,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000066e:	f8843783          	ld	a5,-120(s0)
    80000672:	00878713          	addi	a4,a5,8
    80000676:	f8e43423          	sd	a4,-120(s0)
    8000067a:	4605                	li	a2,1
    8000067c:	45a9                	li	a1,10
    8000067e:	4388                	lw	a0,0(a5)
    80000680:	00000097          	auipc	ra,0x0
    80000684:	e0e080e7          	jalr	-498(ra) # 8000048e <printint>
      break;
    80000688:	b771                	j	80000614 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000068a:	f8843783          	ld	a5,-120(s0)
    8000068e:	00878713          	addi	a4,a5,8
    80000692:	f8e43423          	sd	a4,-120(s0)
    80000696:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000069a:	03000513          	li	a0,48
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	bd0080e7          	jalr	-1072(ra) # 8000026e <consputc>
  consputc('x');
    800006a6:	07800513          	li	a0,120
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bc4080e7          	jalr	-1084(ra) # 8000026e <consputc>
    800006b2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006b4:	03c9d793          	srli	a5,s3,0x3c
    800006b8:	97de                	add	a5,a5,s7
    800006ba:	0007c503          	lbu	a0,0(a5)
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bb0080e7          	jalr	-1104(ra) # 8000026e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c6:	0992                	slli	s3,s3,0x4
    800006c8:	397d                	addiw	s2,s2,-1
    800006ca:	fe0915e3          	bnez	s2,800006b4 <printf+0x13a>
    800006ce:	b799                	j	80000614 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d0:	f8843783          	ld	a5,-120(s0)
    800006d4:	00878713          	addi	a4,a5,8
    800006d8:	f8e43423          	sd	a4,-120(s0)
    800006dc:	0007b903          	ld	s2,0(a5)
    800006e0:	00090e63          	beqz	s2,800006fc <printf+0x182>
      for(; *s; s++)
    800006e4:	00094503          	lbu	a0,0(s2)
    800006e8:	d515                	beqz	a0,80000614 <printf+0x9a>
        consputc(*s);
    800006ea:	00000097          	auipc	ra,0x0
    800006ee:	b84080e7          	jalr	-1148(ra) # 8000026e <consputc>
      for(; *s; s++)
    800006f2:	0905                	addi	s2,s2,1
    800006f4:	00094503          	lbu	a0,0(s2)
    800006f8:	f96d                	bnez	a0,800006ea <printf+0x170>
    800006fa:	bf29                	j	80000614 <printf+0x9a>
        s = "(null)";
    800006fc:	00008917          	auipc	s2,0x8
    80000700:	92490913          	addi	s2,s2,-1756 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000704:	02800513          	li	a0,40
    80000708:	b7cd                	j	800006ea <printf+0x170>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b62080e7          	jalr	-1182(ra) # 8000026e <consputc>
      break;
    80000714:	b701                	j	80000614 <printf+0x9a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b56080e7          	jalr	-1194(ra) # 8000026e <consputc>
      consputc(c);
    80000720:	854a                	mv	a0,s2
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b4c080e7          	jalr	-1204(ra) # 8000026e <consputc>
      break;
    8000072a:	b5ed                	j	80000614 <printf+0x9a>
  if(locking)
    8000072c:	020d9163          	bnez	s11,8000074e <printf+0x1d4>
}
    80000730:	70e6                	ld	ra,120(sp)
    80000732:	7446                	ld	s0,112(sp)
    80000734:	74a6                	ld	s1,104(sp)
    80000736:	7906                	ld	s2,96(sp)
    80000738:	69e6                	ld	s3,88(sp)
    8000073a:	6a46                	ld	s4,80(sp)
    8000073c:	6aa6                	ld	s5,72(sp)
    8000073e:	6b06                	ld	s6,64(sp)
    80000740:	7be2                	ld	s7,56(sp)
    80000742:	7c42                	ld	s8,48(sp)
    80000744:	7ca2                	ld	s9,40(sp)
    80000746:	7d02                	ld	s10,32(sp)
    80000748:	6de2                	ld	s11,24(sp)
    8000074a:	6129                	addi	sp,sp,192
    8000074c:	8082                	ret
    release(&pr.lock);
    8000074e:	00011517          	auipc	a0,0x11
    80000752:	ada50513          	addi	a0,a0,-1318 # 80011228 <pr>
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	534080e7          	jalr	1332(ra) # 80000c8a <release>
}
    8000075e:	bfc9                	j	80000730 <printf+0x1b6>

0000000080000760 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000760:	1101                	addi	sp,sp,-32
    80000762:	ec06                	sd	ra,24(sp)
    80000764:	e822                	sd	s0,16(sp)
    80000766:	e426                	sd	s1,8(sp)
    80000768:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076a:	00011497          	auipc	s1,0x11
    8000076e:	abe48493          	addi	s1,s1,-1346 # 80011228 <pr>
    80000772:	00008597          	auipc	a1,0x8
    80000776:	8c658593          	addi	a1,a1,-1850 # 80008038 <etext+0x38>
    8000077a:	8526                	mv	a0,s1
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	3ca080e7          	jalr	970(ra) # 80000b46 <initlock>
  pr.locking = 1;
    80000784:	4785                	li	a5,1
    80000786:	cc9c                	sw	a5,24(s1)
}
    80000788:	60e2                	ld	ra,24(sp)
    8000078a:	6442                	ld	s0,16(sp)
    8000078c:	64a2                	ld	s1,8(sp)
    8000078e:	6105                	addi	sp,sp,32
    80000790:	8082                	ret

0000000080000792 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000792:	1141                	addi	sp,sp,-16
    80000794:	e406                	sd	ra,8(sp)
    80000796:	e022                	sd	s0,0(sp)
    80000798:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079a:	100007b7          	lui	a5,0x10000
    8000079e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a2:	f8000713          	li	a4,-128
    800007a6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007aa:	470d                	li	a4,3
    800007ac:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007b8:	469d                	li	a3,7
    800007ba:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007be:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c2:	00008597          	auipc	a1,0x8
    800007c6:	89658593          	addi	a1,a1,-1898 # 80008058 <digits+0x18>
    800007ca:	00011517          	auipc	a0,0x11
    800007ce:	a7e50513          	addi	a0,a0,-1410 # 80011248 <uart_tx_lock>
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	374080e7          	jalr	884(ra) # 80000b46 <initlock>
}
    800007da:	60a2                	ld	ra,8(sp)
    800007dc:	6402                	ld	s0,0(sp)
    800007de:	0141                	addi	sp,sp,16
    800007e0:	8082                	ret

00000000800007e2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e2:	1101                	addi	sp,sp,-32
    800007e4:	ec06                	sd	ra,24(sp)
    800007e6:	e822                	sd	s0,16(sp)
    800007e8:	e426                	sd	s1,8(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  push_off();
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	39c080e7          	jalr	924(ra) # 80000b8a <push_off>

  if(panicked){
    800007f6:	00009797          	auipc	a5,0x9
    800007fa:	80a7a783          	lw	a5,-2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fe:	10000737          	lui	a4,0x10000
  if(panicked){
    80000802:	c391                	beqz	a5,80000806 <uartputc_sync+0x24>
    for(;;)
    80000804:	a001                	j	80000804 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080a:	0ff7f793          	andi	a5,a5,255
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dbf5                	beqz	a5,80000806 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f793          	andi	a5,s1,255
    80000818:	10000737          	lui	a4,0x10000
    8000081c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	40a080e7          	jalr	1034(ra) # 80000c2a <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008717          	auipc	a4,0x8
    80000836:	7d673703          	ld	a4,2006(a4) # 80009008 <uart_tx_r>
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7d67b783          	ld	a5,2006(a5) # 80009010 <uart_tx_w>
    80000842:	06e78c63          	beq	a5,a4,800008ba <uartstart+0x88>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	0ff7f793          	andi	a5,a5,255
    8000087c:	0207f793          	andi	a5,a5,32
    80000880:	c785                	beqz	a5,800008a8 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f77793          	andi	a5,a4,31
    80000886:	97d2                	add	a5,a5,s4
    80000888:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000088c:	0705                	addi	a4,a4,1
    8000088e:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	b86080e7          	jalr	-1146(ra) # 80002418 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	6098                	ld	a4,0(s1)
    800008a0:	0009b783          	ld	a5,0(s3)
    800008a4:	fce798e3          	bne	a5,a4,80000874 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	97a50513          	addi	a0,a0,-1670 # 80011248 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	7227a783          	lw	a5,1826(a5) # 80009000 <panicked>
    800008e6:	c391                	beqz	a5,800008ea <uartputc+0x2e>
    for(;;)
    800008e8:	a001                	j	800008e8 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008797          	auipc	a5,0x8
    800008ee:	7267b783          	ld	a5,1830(a5) # 80009010 <uart_tx_w>
    800008f2:	00008717          	auipc	a4,0x8
    800008f6:	71673703          	ld	a4,1814(a4) # 80009008 <uart_tx_r>
    800008fa:	02070713          	addi	a4,a4,32
    800008fe:	02f71b63          	bne	a4,a5,80000934 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000902:	00011a17          	auipc	s4,0x11
    80000906:	946a0a13          	addi	s4,s4,-1722 # 80011248 <uart_tx_lock>
    8000090a:	00008497          	auipc	s1,0x8
    8000090e:	6fe48493          	addi	s1,s1,1790 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00008917          	auipc	s2,0x8
    80000916:	6fe90913          	addi	s2,s2,1790 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85d2                	mv	a1,s4
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	974080e7          	jalr	-1676(ra) # 80002292 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093783          	ld	a5,0(s2)
    8000092a:	6098                	ld	a4,0(s1)
    8000092c:	02070713          	addi	a4,a4,32
    80000930:	fef705e3          	beq	a4,a5,8000091a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00011497          	auipc	s1,0x11
    80000938:	91448493          	addi	s1,s1,-1772 # 80011248 <uart_tx_lock>
    8000093c:	01f7f713          	andi	a4,a5,31
    80000940:	9726                	add	a4,a4,s1
    80000942:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000946:	0785                	addi	a5,a5,1
    80000948:	00008717          	auipc	a4,0x8
    8000094c:	6cf73423          	sd	a5,1736(a4) # 80009010 <uart_tx_w>
      uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee2080e7          	jalr	-286(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    int c = uartgetc();
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	fcc080e7          	jalr	-52(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009ae:	00950763          	beq	a0,s1,800009bc <uartintr+0x22>
      break;
    consoleintr(c);
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	8fe080e7          	jalr	-1794(ra) # 800002b0 <consoleintr>
  while(1){
    800009ba:	b7f5                	j	800009a6 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	88c48493          	addi	s1,s1,-1908 # 80011248 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e64080e7          	jalr	-412(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00031797          	auipc	a5,0x31
    80000a02:	60278793          	addi	a5,a5,1538 # 80032000 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00011917          	auipc	s2,0x11
    80000a22:	86290913          	addi	s2,s2,-1950 # 80011280 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ad8080e7          	jalr	-1320(ra) # 80000530 <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	7c650513          	addi	a0,a0,1990 # 80011280 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00031517          	auipc	a0,0x31
    80000ad2:	53250513          	addi	a0,a0,1330 # 80032000 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	79048493          	addi	s1,s1,1936 # 80011280 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	77850513          	addi	a0,a0,1912 # 80011280 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	74c50513          	addi	a0,a0,1868 # 80011280 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e1a080e7          	jalr	-486(ra) # 8000198a <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	de8080e7          	jalr	-536(ra) # 8000198a <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	ddc080e7          	jalr	-548(ra) # 8000198a <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dc4080e7          	jalr	-572(ra) # 8000198a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d84080e7          	jalr	-636(ra) # 8000198a <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	90e080e7          	jalr	-1778(ra) # 80000530 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d58080e7          	jalr	-680(ra) # 8000198a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8be080e7          	jalr	-1858(ra) # 80000530 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8ae080e7          	jalr	-1874(ra) # 80000530 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	866080e7          	jalr	-1946(ra) # 80000530 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ce09                	beqz	a2,80000cf2 <memset+0x20>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	fff6071b          	addiw	a4,a2,-1
    80000ce0:	1702                	slli	a4,a4,0x20
    80000ce2:	9301                	srli	a4,a4,0x20
    80000ce4:	0705                	addi	a4,a4,1
    80000ce6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000ce8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cec:	0785                	addi	a5,a5,1
    80000cee:	fee79de3          	bne	a5,a4,80000ce8 <memset+0x16>
  }
  return dst;
}
    80000cf2:	6422                	ld	s0,8(sp)
    80000cf4:	0141                	addi	sp,sp,16
    80000cf6:	8082                	ret

0000000080000cf8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfe:	ca05                	beqz	a2,80000d2e <memcmp+0x36>
    80000d00:	fff6069b          	addiw	a3,a2,-1
    80000d04:	1682                	slli	a3,a3,0x20
    80000d06:	9281                	srli	a3,a3,0x20
    80000d08:	0685                	addi	a3,a3,1
    80000d0a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d0c:	00054783          	lbu	a5,0(a0)
    80000d10:	0005c703          	lbu	a4,0(a1)
    80000d14:	00e79863          	bne	a5,a4,80000d24 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d18:	0505                	addi	a0,a0,1
    80000d1a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d1c:	fed518e3          	bne	a0,a3,80000d0c <memcmp+0x14>
  }

  return 0;
    80000d20:	4501                	li	a0,0
    80000d22:	a019                	j	80000d28 <memcmp+0x30>
      return *s1 - *s2;
    80000d24:	40e7853b          	subw	a0,a5,a4
}
    80000d28:	6422                	ld	s0,8(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret
  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	bfe5                	j	80000d28 <memcmp+0x30>

0000000080000d32 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d38:	00a5f963          	bgeu	a1,a0,80000d4a <memmove+0x18>
    80000d3c:	02061713          	slli	a4,a2,0x20
    80000d40:	9301                	srli	a4,a4,0x20
    80000d42:	00e587b3          	add	a5,a1,a4
    80000d46:	02f56563          	bltu	a0,a5,80000d70 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d4a:	fff6069b          	addiw	a3,a2,-1
    80000d4e:	ce11                	beqz	a2,80000d6a <memmove+0x38>
    80000d50:	1682                	slli	a3,a3,0x20
    80000d52:	9281                	srli	a3,a3,0x20
    80000d54:	0685                	addi	a3,a3,1
    80000d56:	96ae                	add	a3,a3,a1
    80000d58:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d5a:	0585                	addi	a1,a1,1
    80000d5c:	0785                	addi	a5,a5,1
    80000d5e:	fff5c703          	lbu	a4,-1(a1)
    80000d62:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d66:	fed59ae3          	bne	a1,a3,80000d5a <memmove+0x28>

  return dst;
}
    80000d6a:	6422                	ld	s0,8(sp)
    80000d6c:	0141                	addi	sp,sp,16
    80000d6e:	8082                	ret
    d += n;
    80000d70:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d72:	fff6069b          	addiw	a3,a2,-1
    80000d76:	da75                	beqz	a2,80000d6a <memmove+0x38>
    80000d78:	02069613          	slli	a2,a3,0x20
    80000d7c:	9201                	srli	a2,a2,0x20
    80000d7e:	fff64613          	not	a2,a2
    80000d82:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d84:	17fd                	addi	a5,a5,-1
    80000d86:	177d                	addi	a4,a4,-1
    80000d88:	0007c683          	lbu	a3,0(a5)
    80000d8c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d90:	fec79ae3          	bne	a5,a2,80000d84 <memmove+0x52>
    80000d94:	bfd9                	j	80000d6a <memmove+0x38>

0000000080000d96 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e406                	sd	ra,8(sp)
    80000d9a:	e022                	sd	s0,0(sp)
    80000d9c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d9e:	00000097          	auipc	ra,0x0
    80000da2:	f94080e7          	jalr	-108(ra) # 80000d32 <memmove>
}
    80000da6:	60a2                	ld	ra,8(sp)
    80000da8:	6402                	ld	s0,0(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret

0000000080000dae <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e422                	sd	s0,8(sp)
    80000db2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000db4:	ce11                	beqz	a2,80000dd0 <strncmp+0x22>
    80000db6:	00054783          	lbu	a5,0(a0)
    80000dba:	cf89                	beqz	a5,80000dd4 <strncmp+0x26>
    80000dbc:	0005c703          	lbu	a4,0(a1)
    80000dc0:	00f71a63          	bne	a4,a5,80000dd4 <strncmp+0x26>
    n--, p++, q++;
    80000dc4:	367d                	addiw	a2,a2,-1
    80000dc6:	0505                	addi	a0,a0,1
    80000dc8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dca:	f675                	bnez	a2,80000db6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dcc:	4501                	li	a0,0
    80000dce:	a809                	j	80000de0 <strncmp+0x32>
    80000dd0:	4501                	li	a0,0
    80000dd2:	a039                	j	80000de0 <strncmp+0x32>
  if(n == 0)
    80000dd4:	ca09                	beqz	a2,80000de6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dd6:	00054503          	lbu	a0,0(a0)
    80000dda:	0005c783          	lbu	a5,0(a1)
    80000dde:	9d1d                	subw	a0,a0,a5
}
    80000de0:	6422                	ld	s0,8(sp)
    80000de2:	0141                	addi	sp,sp,16
    80000de4:	8082                	ret
    return 0;
    80000de6:	4501                	li	a0,0
    80000de8:	bfe5                	j	80000de0 <strncmp+0x32>

0000000080000dea <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dea:	1141                	addi	sp,sp,-16
    80000dec:	e422                	sd	s0,8(sp)
    80000dee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000df0:	872a                	mv	a4,a0
    80000df2:	8832                	mv	a6,a2
    80000df4:	367d                	addiw	a2,a2,-1
    80000df6:	01005963          	blez	a6,80000e08 <strncpy+0x1e>
    80000dfa:	0705                	addi	a4,a4,1
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	fef70fa3          	sb	a5,-1(a4)
    80000e04:	0585                	addi	a1,a1,1
    80000e06:	f7f5                	bnez	a5,80000df2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e08:	00c05d63          	blez	a2,80000e22 <strncpy+0x38>
    80000e0c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e0e:	0685                	addi	a3,a3,1
    80000e10:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e14:	fff6c793          	not	a5,a3
    80000e18:	9fb9                	addw	a5,a5,a4
    80000e1a:	010787bb          	addw	a5,a5,a6
    80000e1e:	fef048e3          	bgtz	a5,80000e0e <strncpy+0x24>
  return os;
}
    80000e22:	6422                	ld	s0,8(sp)
    80000e24:	0141                	addi	sp,sp,16
    80000e26:	8082                	ret

0000000080000e28 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e28:	1141                	addi	sp,sp,-16
    80000e2a:	e422                	sd	s0,8(sp)
    80000e2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e2e:	02c05363          	blez	a2,80000e54 <safestrcpy+0x2c>
    80000e32:	fff6069b          	addiw	a3,a2,-1
    80000e36:	1682                	slli	a3,a3,0x20
    80000e38:	9281                	srli	a3,a3,0x20
    80000e3a:	96ae                	add	a3,a3,a1
    80000e3c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e3e:	00d58963          	beq	a1,a3,80000e50 <safestrcpy+0x28>
    80000e42:	0585                	addi	a1,a1,1
    80000e44:	0785                	addi	a5,a5,1
    80000e46:	fff5c703          	lbu	a4,-1(a1)
    80000e4a:	fee78fa3          	sb	a4,-1(a5)
    80000e4e:	fb65                	bnez	a4,80000e3e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e50:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <strlen>:

int
strlen(const char *s)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e60:	00054783          	lbu	a5,0(a0)
    80000e64:	cf91                	beqz	a5,80000e80 <strlen+0x26>
    80000e66:	0505                	addi	a0,a0,1
    80000e68:	87aa                	mv	a5,a0
    80000e6a:	4685                	li	a3,1
    80000e6c:	9e89                	subw	a3,a3,a0
    80000e6e:	00f6853b          	addw	a0,a3,a5
    80000e72:	0785                	addi	a5,a5,1
    80000e74:	fff7c703          	lbu	a4,-1(a5)
    80000e78:	fb7d                	bnez	a4,80000e6e <strlen+0x14>
    ;
  return n;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e80:	4501                	li	a0,0
    80000e82:	bfe5                	j	80000e7a <strlen+0x20>

0000000080000e84 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e84:	1141                	addi	sp,sp,-16
    80000e86:	e406                	sd	ra,8(sp)
    80000e88:	e022                	sd	s0,0(sp)
    80000e8a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e8c:	00001097          	auipc	ra,0x1
    80000e90:	aee080e7          	jalr	-1298(ra) # 8000197a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e94:	00008717          	auipc	a4,0x8
    80000e98:	18470713          	addi	a4,a4,388 # 80009018 <started>
  if(cpuid() == 0){
    80000e9c:	c139                	beqz	a0,80000ee2 <main+0x5e>
    while(started == 0)
    80000e9e:	431c                	lw	a5,0(a4)
    80000ea0:	2781                	sext.w	a5,a5
    80000ea2:	dff5                	beqz	a5,80000e9e <main+0x1a>
      ;
    __sync_synchronize();
    80000ea4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ea8:	00001097          	auipc	ra,0x1
    80000eac:	ad2080e7          	jalr	-1326(ra) # 8000197a <cpuid>
    80000eb0:	85aa                	mv	a1,a0
    80000eb2:	00007517          	auipc	a0,0x7
    80000eb6:	20650513          	addi	a0,a0,518 # 800080b8 <digits+0x78>
    80000eba:	fffff097          	auipc	ra,0xfffff
    80000ebe:	6c0080e7          	jalr	1728(ra) # 8000057a <printf>
    kvminithart();    // turn on paging
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	0d8080e7          	jalr	216(ra) # 80000f9a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eca:	00002097          	auipc	ra,0x2
    80000ece:	816080e7          	jalr	-2026(ra) # 800026e0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed2:	00005097          	auipc	ra,0x5
    80000ed6:	1de080e7          	jalr	478(ra) # 800060b0 <plicinithart>
  }

  scheduler();        
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	074080e7          	jalr	116(ra) # 80001f4e <scheduler>
    consoleinit();
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	560080e7          	jalr	1376(ra) # 80000442 <consoleinit>
    printfinit();
    80000eea:	00000097          	auipc	ra,0x0
    80000eee:	876080e7          	jalr	-1930(ra) # 80000760 <printfinit>
    printf("\n");
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	1d650513          	addi	a0,a0,470 # 800080c8 <digits+0x88>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	680080e7          	jalr	1664(ra) # 8000057a <printf>
    printf("xv6 kernel is booting\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	19e50513          	addi	a0,a0,414 # 800080a0 <digits+0x60>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	670080e7          	jalr	1648(ra) # 8000057a <printf>
    printf("\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	1b650513          	addi	a0,a0,438 # 800080c8 <digits+0x88>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	660080e7          	jalr	1632(ra) # 8000057a <printf>
    kinit();         // physical page allocator
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	b88080e7          	jalr	-1144(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	310080e7          	jalr	784(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	068080e7          	jalr	104(ra) # 80000f9a <kvminithart>
    procinit();      // process table
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	9a8080e7          	jalr	-1624(ra) # 800018e2 <procinit>
    trapinit();      // trap vectors
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	776080e7          	jalr	1910(ra) # 800026b8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	796080e7          	jalr	1942(ra) # 800026e0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	148080e7          	jalr	328(ra) # 8000609a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	156080e7          	jalr	342(ra) # 800060b0 <plicinithart>
    binit();         // buffer cache
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	008080e7          	jalr	8(ra) # 80002f6a <binit>
    iinit();         // inode cache
    80000f6a:	00002097          	auipc	ra,0x2
    80000f6e:	698080e7          	jalr	1688(ra) # 80003602 <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	64a080e7          	jalr	1610(ra) # 800045bc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	258080e7          	jalr	600(ra) # 800061d2 <virtio_disk_init>
    userinit();      // first user process
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	d22080e7          	jalr	-734(ra) # 80001ca4 <userinit>
    __sync_synchronize();
    80000f8a:	0ff0000f          	fence
    started = 1;
    80000f8e:	4785                	li	a5,1
    80000f90:	00008717          	auipc	a4,0x8
    80000f94:	08f72423          	sw	a5,136(a4) # 80009018 <started>
    80000f98:	b789                	j	80000eda <main+0x56>

0000000080000f9a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f9a:	1141                	addi	sp,sp,-16
    80000f9c:	e422                	sd	s0,8(sp)
    80000f9e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa0:	00008797          	auipc	a5,0x8
    80000fa4:	0807b783          	ld	a5,128(a5) # 80009020 <kernel_pagetable>
    80000fa8:	83b1                	srli	a5,a5,0xc
    80000faa:	577d                	li	a4,-1
    80000fac:	177e                	slli	a4,a4,0x3f
    80000fae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fb0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma
  sfence_vma();
}
    80000fb8:	6422                	ld	s0,8(sp)
    80000fba:	0141                	addi	sp,sp,16
    80000fbc:	8082                	ret

0000000080000fbe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fbe:	7139                	addi	sp,sp,-64
    80000fc0:	fc06                	sd	ra,56(sp)
    80000fc2:	f822                	sd	s0,48(sp)
    80000fc4:	f426                	sd	s1,40(sp)
    80000fc6:	f04a                	sd	s2,32(sp)
    80000fc8:	ec4e                	sd	s3,24(sp)
    80000fca:	e852                	sd	s4,16(sp)
    80000fcc:	e456                	sd	s5,8(sp)
    80000fce:	e05a                	sd	s6,0(sp)
    80000fd0:	0080                	addi	s0,sp,64
    80000fd2:	84aa                	mv	s1,a0
    80000fd4:	89ae                	mv	s3,a1
    80000fd6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd8:	57fd                	li	a5,-1
    80000fda:	83e9                	srli	a5,a5,0x1a
    80000fdc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fde:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fe0:	04b7f263          	bgeu	a5,a1,80001024 <walk+0x66>
    panic("walk");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0ec50513          	addi	a0,a0,236 # 800080d0 <digits+0x90>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	544080e7          	jalr	1348(ra) # 80000530 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ff4:	060a8663          	beqz	s5,80001060 <walk+0xa2>
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	aee080e7          	jalr	-1298(ra) # 80000ae6 <kalloc>
    80001000:	84aa                	mv	s1,a0
    80001002:	c529                	beqz	a0,8000104c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001004:	6605                	lui	a2,0x1
    80001006:	4581                	li	a1,0
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	cca080e7          	jalr	-822(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001010:	00c4d793          	srli	a5,s1,0xc
    80001014:	07aa                	slli	a5,a5,0xa
    80001016:	0017e793          	ori	a5,a5,1
    8000101a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000101e:	3a5d                	addiw	s4,s4,-9
    80001020:	036a0063          	beq	s4,s6,80001040 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001024:	0149d933          	srl	s2,s3,s4
    80001028:	1ff97913          	andi	s2,s2,511
    8000102c:	090e                	slli	s2,s2,0x3
    8000102e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001030:	00093483          	ld	s1,0(s2)
    80001034:	0014f793          	andi	a5,s1,1
    80001038:	dfd5                	beqz	a5,80000ff4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000103a:	80a9                	srli	s1,s1,0xa
    8000103c:	04b2                	slli	s1,s1,0xc
    8000103e:	b7c5                	j	8000101e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001040:	00c9d513          	srli	a0,s3,0xc
    80001044:	1ff57513          	andi	a0,a0,511
    80001048:	050e                	slli	a0,a0,0x3
    8000104a:	9526                	add	a0,a0,s1
}
    8000104c:	70e2                	ld	ra,56(sp)
    8000104e:	7442                	ld	s0,48(sp)
    80001050:	74a2                	ld	s1,40(sp)
    80001052:	7902                	ld	s2,32(sp)
    80001054:	69e2                	ld	s3,24(sp)
    80001056:	6a42                	ld	s4,16(sp)
    80001058:	6aa2                	ld	s5,8(sp)
    8000105a:	6b02                	ld	s6,0(sp)
    8000105c:	6121                	addi	sp,sp,64
    8000105e:	8082                	ret
        return 0;
    80001060:	4501                	li	a0,0
    80001062:	b7ed                	j	8000104c <walk+0x8e>

0000000080001064 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	00b7f463          	bgeu	a5,a1,80001070 <walkaddr+0xc>
    return 0;
    8000106c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000106e:	8082                	ret
{
    80001070:	1141                	addi	sp,sp,-16
    80001072:	e406                	sd	ra,8(sp)
    80001074:	e022                	sd	s0,0(sp)
    80001076:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001078:	4601                	li	a2,0
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	f44080e7          	jalr	-188(ra) # 80000fbe <walk>
  if(pte == 0)
    80001082:	c105                	beqz	a0,800010a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001084:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001086:	0117f693          	andi	a3,a5,17
    8000108a:	4745                	li	a4,17
    return 0;
    8000108c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000108e:	00e68663          	beq	a3,a4,8000109a <walkaddr+0x36>
}
    80001092:	60a2                	ld	ra,8(sp)
    80001094:	6402                	ld	s0,0(sp)
    80001096:	0141                	addi	sp,sp,16
    80001098:	8082                	ret
  pa = PTE2PA(*pte);
    8000109a:	00a7d513          	srli	a0,a5,0xa
    8000109e:	0532                	slli	a0,a0,0xc
  return pa;
    800010a0:	bfcd                	j	80001092 <walkaddr+0x2e>
    return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7fd                	j	80001092 <walkaddr+0x2e>

00000000800010a6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010a6:	715d                	addi	sp,sp,-80
    800010a8:	e486                	sd	ra,72(sp)
    800010aa:	e0a2                	sd	s0,64(sp)
    800010ac:	fc26                	sd	s1,56(sp)
    800010ae:	f84a                	sd	s2,48(sp)
    800010b0:	f44e                	sd	s3,40(sp)
    800010b2:	f052                	sd	s4,32(sp)
    800010b4:	ec56                	sd	s5,24(sp)
    800010b6:	e85a                	sd	s6,16(sp)
    800010b8:	e45e                	sd	s7,8(sp)
    800010ba:	0880                	addi	s0,sp,80
    800010bc:	8aaa                	mv	s5,a0
    800010be:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010c0:	777d                	lui	a4,0xfffff
    800010c2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c6:	167d                	addi	a2,a2,-1
    800010c8:	00b609b3          	add	s3,a2,a1
    800010cc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010d0:	893e                	mv	s2,a5
    800010d2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d6:	6b85                	lui	s7,0x1
    800010d8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010dc:	4605                	li	a2,1
    800010de:	85ca                	mv	a1,s2
    800010e0:	8556                	mv	a0,s5
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	edc080e7          	jalr	-292(ra) # 80000fbe <walk>
    800010ea:	c51d                	beqz	a0,80001118 <mappages+0x72>
    if(*pte & PTE_V)
    800010ec:	611c                	ld	a5,0(a0)
    800010ee:	8b85                	andi	a5,a5,1
    800010f0:	ef81                	bnez	a5,80001108 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010f2:	80b1                	srli	s1,s1,0xc
    800010f4:	04aa                	slli	s1,s1,0xa
    800010f6:	0164e4b3          	or	s1,s1,s6
    800010fa:	0014e493          	ori	s1,s1,1
    800010fe:	e104                	sd	s1,0(a0)
    if(a == last)
    80001100:	03390863          	beq	s2,s3,80001130 <mappages+0x8a>
    a += PGSIZE;
    80001104:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001106:	bfc9                	j	800010d8 <mappages+0x32>
      panic("remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fd050513          	addi	a0,a0,-48 # 800080d8 <digits+0x98>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	420080e7          	jalr	1056(ra) # 80000530 <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x74>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f64080e7          	jalr	-156(ra) # 800010a6 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	f8c50513          	addi	a0,a0,-116 # 800080e0 <digits+0xa0>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3d4080e7          	jalr	980(ra) # 80000530 <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	976080e7          	jalr	-1674(ra) # 80000ae6 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b54080e7          	jalr	-1196(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	628080e7          	jalr	1576(ra) # 8000184c <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      continue;
//      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6a85                	lui	s5,0x1
    80001286:	0735e163          	bltu	a1,s3,800012e8 <uvmunmap+0x8e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e4850513          	addi	a0,a0,-440 # 800080e8 <digits+0xa8>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	288080e7          	jalr	648(ra) # 80000530 <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e5050513          	addi	a0,a0,-432 # 80008100 <digits+0xc0>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	278080e7          	jalr	632(ra) # 80000530 <panic>
      panic("uvmunmap: not a leaf");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e5050513          	addi	a0,a0,-432 # 80008110 <digits+0xd0>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	268080e7          	jalr	616(ra) # 80000530 <panic>
      uint64 pa = PTE2PA(*pte);
    800012d0:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800012d2:	00c79513          	slli	a0,a5,0xc
    800012d6:	fffff097          	auipc	ra,0xfffff
    800012da:	714080e7          	jalr	1812(ra) # 800009ea <kfree>
    *pte = 0;
    800012de:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e2:	9956                	add	s2,s2,s5
    800012e4:	fb3973e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012e8:	4601                	li	a2,0
    800012ea:	85ca                	mv	a1,s2
    800012ec:	8552                	mv	a0,s4
    800012ee:	00000097          	auipc	ra,0x0
    800012f2:	cd0080e7          	jalr	-816(ra) # 80000fbe <walk>
    800012f6:	84aa                	mv	s1,a0
    800012f8:	dd45                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fa:	611c                	ld	a5,0(a0)
    800012fc:	0017f713          	andi	a4,a5,1
    80001300:	d36d                	beqz	a4,800012e2 <uvmunmap+0x88>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001302:	3ff7f713          	andi	a4,a5,1023
    80001306:	fb770de3          	beq	a4,s7,800012c0 <uvmunmap+0x66>
    if(do_free){
    8000130a:	fc0b0ae3          	beqz	s6,800012de <uvmunmap+0x84>
    8000130e:	b7c9                	j	800012d0 <uvmunmap+0x76>

0000000080001310 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001310:	1101                	addi	sp,sp,-32
    80001312:	ec06                	sd	ra,24(sp)
    80001314:	e822                	sd	s0,16(sp)
    80001316:	e426                	sd	s1,8(sp)
    80001318:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000131a:	fffff097          	auipc	ra,0xfffff
    8000131e:	7cc080e7          	jalr	1996(ra) # 80000ae6 <kalloc>
    80001322:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001324:	c519                	beqz	a0,80001332 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001326:	6605                	lui	a2,0x1
    80001328:	4581                	li	a1,0
    8000132a:	00000097          	auipc	ra,0x0
    8000132e:	9a8080e7          	jalr	-1624(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001332:	8526                	mv	a0,s1
    80001334:	60e2                	ld	ra,24(sp)
    80001336:	6442                	ld	s0,16(sp)
    80001338:	64a2                	ld	s1,8(sp)
    8000133a:	6105                	addi	sp,sp,32
    8000133c:	8082                	ret

000000008000133e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000133e:	7179                	addi	sp,sp,-48
    80001340:	f406                	sd	ra,40(sp)
    80001342:	f022                	sd	s0,32(sp)
    80001344:	ec26                	sd	s1,24(sp)
    80001346:	e84a                	sd	s2,16(sp)
    80001348:	e44e                	sd	s3,8(sp)
    8000134a:	e052                	sd	s4,0(sp)
    8000134c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000134e:	6785                	lui	a5,0x1
    80001350:	04f67863          	bgeu	a2,a5,800013a0 <uvminit+0x62>
    80001354:	8a2a                	mv	s4,a0
    80001356:	89ae                	mv	s3,a1
    80001358:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	78c080e7          	jalr	1932(ra) # 80000ae6 <kalloc>
    80001362:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001364:	6605                	lui	a2,0x1
    80001366:	4581                	li	a1,0
    80001368:	00000097          	auipc	ra,0x0
    8000136c:	96a080e7          	jalr	-1686(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001370:	4779                	li	a4,30
    80001372:	86ca                	mv	a3,s2
    80001374:	6605                	lui	a2,0x1
    80001376:	4581                	li	a1,0
    80001378:	8552                	mv	a0,s4
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	d2c080e7          	jalr	-724(ra) # 800010a6 <mappages>
  memmove(mem, src, sz);
    80001382:	8626                	mv	a2,s1
    80001384:	85ce                	mv	a1,s3
    80001386:	854a                	mv	a0,s2
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	9aa080e7          	jalr	-1622(ra) # 80000d32 <memmove>
}
    80001390:	70a2                	ld	ra,40(sp)
    80001392:	7402                	ld	s0,32(sp)
    80001394:	64e2                	ld	s1,24(sp)
    80001396:	6942                	ld	s2,16(sp)
    80001398:	69a2                	ld	s3,8(sp)
    8000139a:	6a02                	ld	s4,0(sp)
    8000139c:	6145                	addi	sp,sp,48
    8000139e:	8082                	ret
    panic("inituvm: more than a page");
    800013a0:	00007517          	auipc	a0,0x7
    800013a4:	d8850513          	addi	a0,a0,-632 # 80008128 <digits+0xe8>
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	188080e7          	jalr	392(ra) # 80000530 <panic>

00000000800013b0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013b0:	1101                	addi	sp,sp,-32
    800013b2:	ec06                	sd	ra,24(sp)
    800013b4:	e822                	sd	s0,16(sp)
    800013b6:	e426                	sd	s1,8(sp)
    800013b8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ba:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013bc:	00b67d63          	bgeu	a2,a1,800013d6 <uvmdealloc+0x26>
    800013c0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013c2:	6785                	lui	a5,0x1
    800013c4:	17fd                	addi	a5,a5,-1
    800013c6:	00f60733          	add	a4,a2,a5
    800013ca:	767d                	lui	a2,0xfffff
    800013cc:	8f71                	and	a4,a4,a2
    800013ce:	97ae                	add	a5,a5,a1
    800013d0:	8ff1                	and	a5,a5,a2
    800013d2:	00f76863          	bltu	a4,a5,800013e2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013d6:	8526                	mv	a0,s1
    800013d8:	60e2                	ld	ra,24(sp)
    800013da:	6442                	ld	s0,16(sp)
    800013dc:	64a2                	ld	s1,8(sp)
    800013de:	6105                	addi	sp,sp,32
    800013e0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013e2:	8f99                	sub	a5,a5,a4
    800013e4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013e6:	4685                	li	a3,1
    800013e8:	0007861b          	sext.w	a2,a5
    800013ec:	85ba                	mv	a1,a4
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	e6c080e7          	jalr	-404(ra) # 8000125a <uvmunmap>
    800013f6:	b7c5                	j	800013d6 <uvmdealloc+0x26>

00000000800013f8 <uvmalloc>:
  if(newsz < oldsz)
    800013f8:	0ab66163          	bltu	a2,a1,8000149a <uvmalloc+0xa2>
{
    800013fc:	7139                	addi	sp,sp,-64
    800013fe:	fc06                	sd	ra,56(sp)
    80001400:	f822                	sd	s0,48(sp)
    80001402:	f426                	sd	s1,40(sp)
    80001404:	f04a                	sd	s2,32(sp)
    80001406:	ec4e                	sd	s3,24(sp)
    80001408:	e852                	sd	s4,16(sp)
    8000140a:	e456                	sd	s5,8(sp)
    8000140c:	0080                	addi	s0,sp,64
    8000140e:	8aaa                	mv	s5,a0
    80001410:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001412:	6985                	lui	s3,0x1
    80001414:	19fd                	addi	s3,s3,-1
    80001416:	95ce                	add	a1,a1,s3
    80001418:	79fd                	lui	s3,0xfffff
    8000141a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000141e:	08c9f063          	bgeu	s3,a2,8000149e <uvmalloc+0xa6>
    80001422:	894e                	mv	s2,s3
    mem = kalloc();
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	6c2080e7          	jalr	1730(ra) # 80000ae6 <kalloc>
    8000142c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000142e:	c51d                	beqz	a0,8000145c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001430:	6605                	lui	a2,0x1
    80001432:	4581                	li	a1,0
    80001434:	00000097          	auipc	ra,0x0
    80001438:	89e080e7          	jalr	-1890(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000143c:	4779                	li	a4,30
    8000143e:	86a6                	mv	a3,s1
    80001440:	6605                	lui	a2,0x1
    80001442:	85ca                	mv	a1,s2
    80001444:	8556                	mv	a0,s5
    80001446:	00000097          	auipc	ra,0x0
    8000144a:	c60080e7          	jalr	-928(ra) # 800010a6 <mappages>
    8000144e:	e905                	bnez	a0,8000147e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	6785                	lui	a5,0x1
    80001452:	993e                	add	s2,s2,a5
    80001454:	fd4968e3          	bltu	s2,s4,80001424 <uvmalloc+0x2c>
  return newsz;
    80001458:	8552                	mv	a0,s4
    8000145a:	a809                	j	8000146c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000145c:	864e                	mv	a2,s3
    8000145e:	85ca                	mv	a1,s2
    80001460:	8556                	mv	a0,s5
    80001462:	00000097          	auipc	ra,0x0
    80001466:	f4e080e7          	jalr	-178(ra) # 800013b0 <uvmdealloc>
      return 0;
    8000146a:	4501                	li	a0,0
}
    8000146c:	70e2                	ld	ra,56(sp)
    8000146e:	7442                	ld	s0,48(sp)
    80001470:	74a2                	ld	s1,40(sp)
    80001472:	7902                	ld	s2,32(sp)
    80001474:	69e2                	ld	s3,24(sp)
    80001476:	6a42                	ld	s4,16(sp)
    80001478:	6aa2                	ld	s5,8(sp)
    8000147a:	6121                	addi	sp,sp,64
    8000147c:	8082                	ret
      kfree(mem);
    8000147e:	8526                	mv	a0,s1
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	56a080e7          	jalr	1386(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001488:	864e                	mv	a2,s3
    8000148a:	85ca                	mv	a1,s2
    8000148c:	8556                	mv	a0,s5
    8000148e:	00000097          	auipc	ra,0x0
    80001492:	f22080e7          	jalr	-222(ra) # 800013b0 <uvmdealloc>
      return 0;
    80001496:	4501                	li	a0,0
    80001498:	bfd1                	j	8000146c <uvmalloc+0x74>
    return oldsz;
    8000149a:	852e                	mv	a0,a1
}
    8000149c:	8082                	ret
  return newsz;
    8000149e:	8532                	mv	a0,a2
    800014a0:	b7f1                	j	8000146c <uvmalloc+0x74>

00000000800014a2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014a2:	7179                	addi	sp,sp,-48
    800014a4:	f406                	sd	ra,40(sp)
    800014a6:	f022                	sd	s0,32(sp)
    800014a8:	ec26                	sd	s1,24(sp)
    800014aa:	e84a                	sd	s2,16(sp)
    800014ac:	e44e                	sd	s3,8(sp)
    800014ae:	e052                	sd	s4,0(sp)
    800014b0:	1800                	addi	s0,sp,48
    800014b2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014b4:	84aa                	mv	s1,a0
    800014b6:	6905                	lui	s2,0x1
    800014b8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ba:	4985                	li	s3,1
    800014bc:	a821                	j	800014d4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014be:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014c0:	0532                	slli	a0,a0,0xc
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	fe0080e7          	jalr	-32(ra) # 800014a2 <freewalk>
      pagetable[i] = 0;
    800014ca:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ce:	04a1                	addi	s1,s1,8
    800014d0:	03248163          	beq	s1,s2,800014f2 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014d4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d6:	00f57793          	andi	a5,a0,15
    800014da:	ff3782e3          	beq	a5,s3,800014be <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014de:	8905                	andi	a0,a0,1
    800014e0:	d57d                	beqz	a0,800014ce <freewalk+0x2c>
      panic("freewalk: leaf");
    800014e2:	00007517          	auipc	a0,0x7
    800014e6:	c6650513          	addi	a0,a0,-922 # 80008148 <digits+0x108>
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	046080e7          	jalr	70(ra) # 80000530 <panic>
    }
  }
  kfree((void*)pagetable);
    800014f2:	8552                	mv	a0,s4
    800014f4:	fffff097          	auipc	ra,0xfffff
    800014f8:	4f6080e7          	jalr	1270(ra) # 800009ea <kfree>
}
    800014fc:	70a2                	ld	ra,40(sp)
    800014fe:	7402                	ld	s0,32(sp)
    80001500:	64e2                	ld	s1,24(sp)
    80001502:	6942                	ld	s2,16(sp)
    80001504:	69a2                	ld	s3,8(sp)
    80001506:	6a02                	ld	s4,0(sp)
    80001508:	6145                	addi	sp,sp,48
    8000150a:	8082                	ret

000000008000150c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000150c:	1101                	addi	sp,sp,-32
    8000150e:	ec06                	sd	ra,24(sp)
    80001510:	e822                	sd	s0,16(sp)
    80001512:	e426                	sd	s1,8(sp)
    80001514:	1000                	addi	s0,sp,32
    80001516:	84aa                	mv	s1,a0
  if(sz > 0)
    80001518:	e999                	bnez	a1,8000152e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000151a:	8526                	mv	a0,s1
    8000151c:	00000097          	auipc	ra,0x0
    80001520:	f86080e7          	jalr	-122(ra) # 800014a2 <freewalk>
}
    80001524:	60e2                	ld	ra,24(sp)
    80001526:	6442                	ld	s0,16(sp)
    80001528:	64a2                	ld	s1,8(sp)
    8000152a:	6105                	addi	sp,sp,32
    8000152c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000152e:	6605                	lui	a2,0x1
    80001530:	167d                	addi	a2,a2,-1
    80001532:	962e                	add	a2,a2,a1
    80001534:	4685                	li	a3,1
    80001536:	8231                	srli	a2,a2,0xc
    80001538:	4581                	li	a1,0
    8000153a:	00000097          	auipc	ra,0x0
    8000153e:	d20080e7          	jalr	-736(ra) # 8000125a <uvmunmap>
    80001542:	bfe1                	j	8000151a <uvmfree+0xe>

0000000080001544 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001544:	c269                	beqz	a2,80001606 <uvmcopy+0xc2>
{
    80001546:	715d                	addi	sp,sp,-80
    80001548:	e486                	sd	ra,72(sp)
    8000154a:	e0a2                	sd	s0,64(sp)
    8000154c:	fc26                	sd	s1,56(sp)
    8000154e:	f84a                	sd	s2,48(sp)
    80001550:	f44e                	sd	s3,40(sp)
    80001552:	f052                	sd	s4,32(sp)
    80001554:	ec56                	sd	s5,24(sp)
    80001556:	e85a                	sd	s6,16(sp)
    80001558:	e45e                	sd	s7,8(sp)
    8000155a:	0880                	addi	s0,sp,80
    8000155c:	8aaa                	mv	s5,a0
    8000155e:	8b2e                	mv	s6,a1
    80001560:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001562:	4481                	li	s1,0
    80001564:	a829                	j	8000157e <uvmcopy+0x3a>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    80001566:	00007517          	auipc	a0,0x7
    8000156a:	bf250513          	addi	a0,a0,-1038 # 80008158 <digits+0x118>
    8000156e:	fffff097          	auipc	ra,0xfffff
    80001572:	fc2080e7          	jalr	-62(ra) # 80000530 <panic>
  for(i = 0; i < sz; i += PGSIZE){
    80001576:	6785                	lui	a5,0x1
    80001578:	94be                	add	s1,s1,a5
    8000157a:	0944f463          	bgeu	s1,s4,80001602 <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    8000157e:	4601                	li	a2,0
    80001580:	85a6                	mv	a1,s1
    80001582:	8556                	mv	a0,s5
    80001584:	00000097          	auipc	ra,0x0
    80001588:	a3a080e7          	jalr	-1478(ra) # 80000fbe <walk>
    8000158c:	dd69                	beqz	a0,80001566 <uvmcopy+0x22>
    if((*pte & PTE_V) == 0)
    8000158e:	6118                	ld	a4,0(a0)
    80001590:	00177793          	andi	a5,a4,1
    80001594:	d3ed                	beqz	a5,80001576 <uvmcopy+0x32>
      continue;
//      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001596:	00a75593          	srli	a1,a4,0xa
    8000159a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000159e:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800015a2:	fffff097          	auipc	ra,0xfffff
    800015a6:	544080e7          	jalr	1348(ra) # 80000ae6 <kalloc>
    800015aa:	89aa                	mv	s3,a0
    800015ac:	c515                	beqz	a0,800015d8 <uvmcopy+0x94>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015ae:	6605                	lui	a2,0x1
    800015b0:	85de                	mv	a1,s7
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	780080e7          	jalr	1920(ra) # 80000d32 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ba:	874a                	mv	a4,s2
    800015bc:	86ce                	mv	a3,s3
    800015be:	6605                	lui	a2,0x1
    800015c0:	85a6                	mv	a1,s1
    800015c2:	855a                	mv	a0,s6
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	ae2080e7          	jalr	-1310(ra) # 800010a6 <mappages>
    800015cc:	d54d                	beqz	a0,80001576 <uvmcopy+0x32>
      kfree(mem);
    800015ce:	854e                	mv	a0,s3
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	41a080e7          	jalr	1050(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015d8:	4685                	li	a3,1
    800015da:	00c4d613          	srli	a2,s1,0xc
    800015de:	4581                	li	a1,0
    800015e0:	855a                	mv	a0,s6
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	c78080e7          	jalr	-904(ra) # 8000125a <uvmunmap>
  return -1;
    800015ea:	557d                	li	a0,-1
}
    800015ec:	60a6                	ld	ra,72(sp)
    800015ee:	6406                	ld	s0,64(sp)
    800015f0:	74e2                	ld	s1,56(sp)
    800015f2:	7942                	ld	s2,48(sp)
    800015f4:	79a2                	ld	s3,40(sp)
    800015f6:	7a02                	ld	s4,32(sp)
    800015f8:	6ae2                	ld	s5,24(sp)
    800015fa:	6b42                	ld	s6,16(sp)
    800015fc:	6ba2                	ld	s7,8(sp)
    800015fe:	6161                	addi	sp,sp,80
    80001600:	8082                	ret
  return 0;
    80001602:	4501                	li	a0,0
    80001604:	b7e5                	j	800015ec <uvmcopy+0xa8>
    80001606:	4501                	li	a0,0
}
    80001608:	8082                	ret

000000008000160a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000160a:	1141                	addi	sp,sp,-16
    8000160c:	e406                	sd	ra,8(sp)
    8000160e:	e022                	sd	s0,0(sp)
    80001610:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001612:	4601                	li	a2,0
    80001614:	00000097          	auipc	ra,0x0
    80001618:	9aa080e7          	jalr	-1622(ra) # 80000fbe <walk>
  if(pte == 0)
    8000161c:	c901                	beqz	a0,8000162c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000161e:	611c                	ld	a5,0(a0)
    80001620:	9bbd                	andi	a5,a5,-17
    80001622:	e11c                	sd	a5,0(a0)
}
    80001624:	60a2                	ld	ra,8(sp)
    80001626:	6402                	ld	s0,0(sp)
    80001628:	0141                	addi	sp,sp,16
    8000162a:	8082                	ret
    panic("uvmclear");
    8000162c:	00007517          	auipc	a0,0x7
    80001630:	b4c50513          	addi	a0,a0,-1204 # 80008178 <digits+0x138>
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	efc080e7          	jalr	-260(ra) # 80000530 <panic>

000000008000163c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000163c:	c6bd                	beqz	a3,800016aa <copyout+0x6e>
{
    8000163e:	715d                	addi	sp,sp,-80
    80001640:	e486                	sd	ra,72(sp)
    80001642:	e0a2                	sd	s0,64(sp)
    80001644:	fc26                	sd	s1,56(sp)
    80001646:	f84a                	sd	s2,48(sp)
    80001648:	f44e                	sd	s3,40(sp)
    8000164a:	f052                	sd	s4,32(sp)
    8000164c:	ec56                	sd	s5,24(sp)
    8000164e:	e85a                	sd	s6,16(sp)
    80001650:	e45e                	sd	s7,8(sp)
    80001652:	e062                	sd	s8,0(sp)
    80001654:	0880                	addi	s0,sp,80
    80001656:	8b2a                	mv	s6,a0
    80001658:	8c2e                	mv	s8,a1
    8000165a:	8a32                	mv	s4,a2
    8000165c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000165e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001660:	6a85                	lui	s5,0x1
    80001662:	a015                	j	80001686 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001664:	9562                	add	a0,a0,s8
    80001666:	0004861b          	sext.w	a2,s1
    8000166a:	85d2                	mv	a1,s4
    8000166c:	41250533          	sub	a0,a0,s2
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	6c2080e7          	jalr	1730(ra) # 80000d32 <memmove>

    len -= n;
    80001678:	409989b3          	sub	s3,s3,s1
    src += n;
    8000167c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000167e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001682:	02098263          	beqz	s3,800016a6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001686:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000168a:	85ca                	mv	a1,s2
    8000168c:	855a                	mv	a0,s6
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	9d6080e7          	jalr	-1578(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    80001696:	cd01                	beqz	a0,800016ae <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001698:	418904b3          	sub	s1,s2,s8
    8000169c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000169e:	fc99f3e3          	bgeu	s3,s1,80001664 <copyout+0x28>
    800016a2:	84ce                	mv	s1,s3
    800016a4:	b7c1                	j	80001664 <copyout+0x28>
  }
  return 0;
    800016a6:	4501                	li	a0,0
    800016a8:	a021                	j	800016b0 <copyout+0x74>
    800016aa:	4501                	li	a0,0
}
    800016ac:	8082                	ret
      return -1;
    800016ae:	557d                	li	a0,-1
}
    800016b0:	60a6                	ld	ra,72(sp)
    800016b2:	6406                	ld	s0,64(sp)
    800016b4:	74e2                	ld	s1,56(sp)
    800016b6:	7942                	ld	s2,48(sp)
    800016b8:	79a2                	ld	s3,40(sp)
    800016ba:	7a02                	ld	s4,32(sp)
    800016bc:	6ae2                	ld	s5,24(sp)
    800016be:	6b42                	ld	s6,16(sp)
    800016c0:	6ba2                	ld	s7,8(sp)
    800016c2:	6c02                	ld	s8,0(sp)
    800016c4:	6161                	addi	sp,sp,80
    800016c6:	8082                	ret

00000000800016c8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016c8:	c6bd                	beqz	a3,80001736 <copyin+0x6e>
{
    800016ca:	715d                	addi	sp,sp,-80
    800016cc:	e486                	sd	ra,72(sp)
    800016ce:	e0a2                	sd	s0,64(sp)
    800016d0:	fc26                	sd	s1,56(sp)
    800016d2:	f84a                	sd	s2,48(sp)
    800016d4:	f44e                	sd	s3,40(sp)
    800016d6:	f052                	sd	s4,32(sp)
    800016d8:	ec56                	sd	s5,24(sp)
    800016da:	e85a                	sd	s6,16(sp)
    800016dc:	e45e                	sd	s7,8(sp)
    800016de:	e062                	sd	s8,0(sp)
    800016e0:	0880                	addi	s0,sp,80
    800016e2:	8b2a                	mv	s6,a0
    800016e4:	8a2e                	mv	s4,a1
    800016e6:	8c32                	mv	s8,a2
    800016e8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016ea:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016ec:	6a85                	lui	s5,0x1
    800016ee:	a015                	j	80001712 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016f0:	9562                	add	a0,a0,s8
    800016f2:	0004861b          	sext.w	a2,s1
    800016f6:	412505b3          	sub	a1,a0,s2
    800016fa:	8552                	mv	a0,s4
    800016fc:	fffff097          	auipc	ra,0xfffff
    80001700:	636080e7          	jalr	1590(ra) # 80000d32 <memmove>

    len -= n;
    80001704:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001708:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000170a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000170e:	02098263          	beqz	s3,80001732 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001712:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001716:	85ca                	mv	a1,s2
    80001718:	855a                	mv	a0,s6
    8000171a:	00000097          	auipc	ra,0x0
    8000171e:	94a080e7          	jalr	-1718(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    80001722:	cd01                	beqz	a0,8000173a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001724:	418904b3          	sub	s1,s2,s8
    80001728:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172a:	fc99f3e3          	bgeu	s3,s1,800016f0 <copyin+0x28>
    8000172e:	84ce                	mv	s1,s3
    80001730:	b7c1                	j	800016f0 <copyin+0x28>
  }
  return 0;
    80001732:	4501                	li	a0,0
    80001734:	a021                	j	8000173c <copyin+0x74>
    80001736:	4501                	li	a0,0
}
    80001738:	8082                	ret
      return -1;
    8000173a:	557d                	li	a0,-1
}
    8000173c:	60a6                	ld	ra,72(sp)
    8000173e:	6406                	ld	s0,64(sp)
    80001740:	74e2                	ld	s1,56(sp)
    80001742:	7942                	ld	s2,48(sp)
    80001744:	79a2                	ld	s3,40(sp)
    80001746:	7a02                	ld	s4,32(sp)
    80001748:	6ae2                	ld	s5,24(sp)
    8000174a:	6b42                	ld	s6,16(sp)
    8000174c:	6ba2                	ld	s7,8(sp)
    8000174e:	6c02                	ld	s8,0(sp)
    80001750:	6161                	addi	sp,sp,80
    80001752:	8082                	ret

0000000080001754 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001754:	c6c5                	beqz	a3,800017fc <copyinstr+0xa8>
{
    80001756:	715d                	addi	sp,sp,-80
    80001758:	e486                	sd	ra,72(sp)
    8000175a:	e0a2                	sd	s0,64(sp)
    8000175c:	fc26                	sd	s1,56(sp)
    8000175e:	f84a                	sd	s2,48(sp)
    80001760:	f44e                	sd	s3,40(sp)
    80001762:	f052                	sd	s4,32(sp)
    80001764:	ec56                	sd	s5,24(sp)
    80001766:	e85a                	sd	s6,16(sp)
    80001768:	e45e                	sd	s7,8(sp)
    8000176a:	0880                	addi	s0,sp,80
    8000176c:	8a2a                	mv	s4,a0
    8000176e:	8b2e                	mv	s6,a1
    80001770:	8bb2                	mv	s7,a2
    80001772:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001774:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001776:	6985                	lui	s3,0x1
    80001778:	a035                	j	800017a4 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000177a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000177e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001780:	0017b793          	seqz	a5,a5
    80001784:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001788:	60a6                	ld	ra,72(sp)
    8000178a:	6406                	ld	s0,64(sp)
    8000178c:	74e2                	ld	s1,56(sp)
    8000178e:	7942                	ld	s2,48(sp)
    80001790:	79a2                	ld	s3,40(sp)
    80001792:	7a02                	ld	s4,32(sp)
    80001794:	6ae2                	ld	s5,24(sp)
    80001796:	6b42                	ld	s6,16(sp)
    80001798:	6ba2                	ld	s7,8(sp)
    8000179a:	6161                	addi	sp,sp,80
    8000179c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000179e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017a2:	c8a9                	beqz	s1,800017f4 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017a4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017a8:	85ca                	mv	a1,s2
    800017aa:	8552                	mv	a0,s4
    800017ac:	00000097          	auipc	ra,0x0
    800017b0:	8b8080e7          	jalr	-1864(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800017b4:	c131                	beqz	a0,800017f8 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017b6:	41790833          	sub	a6,s2,s7
    800017ba:	984e                	add	a6,a6,s3
    if(n > max)
    800017bc:	0104f363          	bgeu	s1,a6,800017c2 <copyinstr+0x6e>
    800017c0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017c2:	955e                	add	a0,a0,s7
    800017c4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017c8:	fc080be3          	beqz	a6,8000179e <copyinstr+0x4a>
    800017cc:	985a                	add	a6,a6,s6
    800017ce:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017d0:	41650633          	sub	a2,a0,s6
    800017d4:	14fd                	addi	s1,s1,-1
    800017d6:	9b26                	add	s6,s6,s1
    800017d8:	00f60733          	add	a4,a2,a5
    800017dc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffcd000>
    800017e0:	df49                	beqz	a4,8000177a <copyinstr+0x26>
        *dst = *p;
    800017e2:	00e78023          	sb	a4,0(a5)
      --max;
    800017e6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017ea:	0785                	addi	a5,a5,1
    while(n > 0){
    800017ec:	ff0796e3          	bne	a5,a6,800017d8 <copyinstr+0x84>
      dst++;
    800017f0:	8b42                	mv	s6,a6
    800017f2:	b775                	j	8000179e <copyinstr+0x4a>
    800017f4:	4781                	li	a5,0
    800017f6:	b769                	j	80001780 <copyinstr+0x2c>
      return -1;
    800017f8:	557d                	li	a0,-1
    800017fa:	b779                	j	80001788 <copyinstr+0x34>
  int got_null = 0;
    800017fc:	4781                	li	a5,0
  if(got_null){
    800017fe:	0017b793          	seqz	a5,a5
    80001802:	40f00533          	neg	a0,a5
}
    80001806:	8082                	ret

0000000080001808 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001808:	1101                	addi	sp,sp,-32
    8000180a:	ec06                	sd	ra,24(sp)
    8000180c:	e822                	sd	s0,16(sp)
    8000180e:	e426                	sd	s1,8(sp)
    80001810:	1000                	addi	s0,sp,32
    80001812:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001814:	fffff097          	auipc	ra,0xfffff
    80001818:	348080e7          	jalr	840(ra) # 80000b5c <holding>
    8000181c:	c909                	beqz	a0,8000182e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    8000181e:	749c                	ld	a5,40(s1)
    80001820:	00978f63          	beq	a5,s1,8000183e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001824:	60e2                	ld	ra,24(sp)
    80001826:	6442                	ld	s0,16(sp)
    80001828:	64a2                	ld	s1,8(sp)
    8000182a:	6105                	addi	sp,sp,32
    8000182c:	8082                	ret
    panic("wakeup1");
    8000182e:	00007517          	auipc	a0,0x7
    80001832:	95a50513          	addi	a0,a0,-1702 # 80008188 <digits+0x148>
    80001836:	fffff097          	auipc	ra,0xfffff
    8000183a:	cfa080e7          	jalr	-774(ra) # 80000530 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000183e:	4c98                	lw	a4,24(s1)
    80001840:	4785                	li	a5,1
    80001842:	fef711e3          	bne	a4,a5,80001824 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001846:	4789                	li	a5,2
    80001848:	cc9c                	sw	a5,24(s1)
}
    8000184a:	bfe9                	j	80001824 <wakeup1+0x1c>

000000008000184c <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    8000184c:	7139                	addi	sp,sp,-64
    8000184e:	fc06                	sd	ra,56(sp)
    80001850:	f822                	sd	s0,48(sp)
    80001852:	f426                	sd	s1,40(sp)
    80001854:	f04a                	sd	s2,32(sp)
    80001856:	ec4e                	sd	s3,24(sp)
    80001858:	e852                	sd	s4,16(sp)
    8000185a:	e456                	sd	s5,8(sp)
    8000185c:	e05a                	sd	s6,0(sp)
    8000185e:	0080                	addi	s0,sp,64
    80001860:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001862:	00010497          	auipc	s1,0x10
    80001866:	e5648493          	addi	s1,s1,-426 # 800116b8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    8000186a:	8b26                	mv	s6,s1
    8000186c:	00006a97          	auipc	s5,0x6
    80001870:	794a8a93          	addi	s5,s5,1940 # 80008000 <etext>
    80001874:	04000937          	lui	s2,0x4000
    80001878:	197d                	addi	s2,s2,-1
    8000187a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000187c:	00022a17          	auipc	s4,0x22
    80001880:	83ca0a13          	addi	s4,s4,-1988 # 800230b8 <tickslock>
    char *pa = kalloc();
    80001884:	fffff097          	auipc	ra,0xfffff
    80001888:	262080e7          	jalr	610(ra) # 80000ae6 <kalloc>
    8000188c:	862a                	mv	a2,a0
    if(pa == 0)
    8000188e:	c131                	beqz	a0,800018d2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001890:	416485b3          	sub	a1,s1,s6
    80001894:	858d                	srai	a1,a1,0x3
    80001896:	000ab783          	ld	a5,0(s5)
    8000189a:	02f585b3          	mul	a1,a1,a5
    8000189e:	2585                	addiw	a1,a1,1
    800018a0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a4:	4719                	li	a4,6
    800018a6:	6685                	lui	a3,0x1
    800018a8:	40b905b3          	sub	a1,s2,a1
    800018ac:	854e                	mv	a0,s3
    800018ae:	00000097          	auipc	ra,0x0
    800018b2:	886080e7          	jalr	-1914(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b6:	46848493          	addi	s1,s1,1128
    800018ba:	fd4495e3          	bne	s1,s4,80001884 <proc_mapstacks+0x38>
}
    800018be:	70e2                	ld	ra,56(sp)
    800018c0:	7442                	ld	s0,48(sp)
    800018c2:	74a2                	ld	s1,40(sp)
    800018c4:	7902                	ld	s2,32(sp)
    800018c6:	69e2                	ld	s3,24(sp)
    800018c8:	6a42                	ld	s4,16(sp)
    800018ca:	6aa2                	ld	s5,8(sp)
    800018cc:	6b02                	ld	s6,0(sp)
    800018ce:	6121                	addi	sp,sp,64
    800018d0:	8082                	ret
      panic("kalloc");
    800018d2:	00007517          	auipc	a0,0x7
    800018d6:	8be50513          	addi	a0,a0,-1858 # 80008190 <digits+0x150>
    800018da:	fffff097          	auipc	ra,0xfffff
    800018de:	c56080e7          	jalr	-938(ra) # 80000530 <panic>

00000000800018e2 <procinit>:
{
    800018e2:	7139                	addi	sp,sp,-64
    800018e4:	fc06                	sd	ra,56(sp)
    800018e6:	f822                	sd	s0,48(sp)
    800018e8:	f426                	sd	s1,40(sp)
    800018ea:	f04a                	sd	s2,32(sp)
    800018ec:	ec4e                	sd	s3,24(sp)
    800018ee:	e852                	sd	s4,16(sp)
    800018f0:	e456                	sd	s5,8(sp)
    800018f2:	e05a                	sd	s6,0(sp)
    800018f4:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    800018f6:	00007597          	auipc	a1,0x7
    800018fa:	8a258593          	addi	a1,a1,-1886 # 80008198 <digits+0x158>
    800018fe:	00010517          	auipc	a0,0x10
    80001902:	9a250513          	addi	a0,a0,-1630 # 800112a0 <pid_lock>
    80001906:	fffff097          	auipc	ra,0xfffff
    8000190a:	240080e7          	jalr	576(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000190e:	00010497          	auipc	s1,0x10
    80001912:	daa48493          	addi	s1,s1,-598 # 800116b8 <proc>
      initlock(&p->lock, "proc");
    80001916:	00007b17          	auipc	s6,0x7
    8000191a:	88ab0b13          	addi	s6,s6,-1910 # 800081a0 <digits+0x160>
      p->kstack = KSTACK((int) (p - proc));
    8000191e:	8aa6                	mv	s5,s1
    80001920:	00006a17          	auipc	s4,0x6
    80001924:	6e0a0a13          	addi	s4,s4,1760 # 80008000 <etext>
    80001928:	04000937          	lui	s2,0x4000
    8000192c:	197d                	addi	s2,s2,-1
    8000192e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001930:	00021997          	auipc	s3,0x21
    80001934:	78898993          	addi	s3,s3,1928 # 800230b8 <tickslock>
      initlock(&p->lock, "proc");
    80001938:	85da                	mv	a1,s6
    8000193a:	8526                	mv	a0,s1
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	20a080e7          	jalr	522(ra) # 80000b46 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001944:	415487b3          	sub	a5,s1,s5
    80001948:	878d                	srai	a5,a5,0x3
    8000194a:	000a3703          	ld	a4,0(s4)
    8000194e:	02e787b3          	mul	a5,a5,a4
    80001952:	2785                	addiw	a5,a5,1
    80001954:	00d7979b          	slliw	a5,a5,0xd
    80001958:	40f907b3          	sub	a5,s2,a5
    8000195c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195e:	46848493          	addi	s1,s1,1128
    80001962:	fd349be3          	bne	s1,s3,80001938 <procinit+0x56>
}
    80001966:	70e2                	ld	ra,56(sp)
    80001968:	7442                	ld	s0,48(sp)
    8000196a:	74a2                	ld	s1,40(sp)
    8000196c:	7902                	ld	s2,32(sp)
    8000196e:	69e2                	ld	s3,24(sp)
    80001970:	6a42                	ld	s4,16(sp)
    80001972:	6aa2                	ld	s5,8(sp)
    80001974:	6b02                	ld	s6,0(sp)
    80001976:	6121                	addi	sp,sp,64
    80001978:	8082                	ret

000000008000197a <cpuid>:
{
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001980:	8512                	mv	a0,tp
}
    80001982:	2501                	sext.w	a0,a0
    80001984:	6422                	ld	s0,8(sp)
    80001986:	0141                	addi	sp,sp,16
    80001988:	8082                	ret

000000008000198a <mycpu>:
mycpu(void) {
    8000198a:	1141                	addi	sp,sp,-16
    8000198c:	e422                	sd	s0,8(sp)
    8000198e:	0800                	addi	s0,sp,16
    80001990:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	slli	a5,a5,0x7
}
    80001996:	00010517          	auipc	a0,0x10
    8000199a:	92250513          	addi	a0,a0,-1758 # 800112b8 <cpus>
    8000199e:	953e                	add	a0,a0,a5
    800019a0:	6422                	ld	s0,8(sp)
    800019a2:	0141                	addi	sp,sp,16
    800019a4:	8082                	ret

00000000800019a6 <myproc>:
myproc(void) {
    800019a6:	1101                	addi	sp,sp,-32
    800019a8:	ec06                	sd	ra,24(sp)
    800019aa:	e822                	sd	s0,16(sp)
    800019ac:	e426                	sd	s1,8(sp)
    800019ae:	1000                	addi	s0,sp,32
  push_off();
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	1da080e7          	jalr	474(ra) # 80000b8a <push_off>
    800019b8:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	slli	a5,a5,0x7
    800019be:	00010717          	auipc	a4,0x10
    800019c2:	8e270713          	addi	a4,a4,-1822 # 800112a0 <pid_lock>
    800019c6:	97ba                	add	a5,a5,a4
    800019c8:	6f84                	ld	s1,24(a5)
  pop_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	260080e7          	jalr	608(ra) # 80000c2a <pop_off>
}
    800019d2:	8526                	mv	a0,s1
    800019d4:	60e2                	ld	ra,24(sp)
    800019d6:	6442                	ld	s0,16(sp)
    800019d8:	64a2                	ld	s1,8(sp)
    800019da:	6105                	addi	sp,sp,32
    800019dc:	8082                	ret

00000000800019de <forkret>:
{
    800019de:	1141                	addi	sp,sp,-16
    800019e0:	e406                	sd	ra,8(sp)
    800019e2:	e022                	sd	s0,0(sp)
    800019e4:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    800019e6:	00000097          	auipc	ra,0x0
    800019ea:	fc0080e7          	jalr	-64(ra) # 800019a6 <myproc>
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	29c080e7          	jalr	668(ra) # 80000c8a <release>
  if (first) {
    800019f6:	00007797          	auipc	a5,0x7
    800019fa:	e1a7a783          	lw	a5,-486(a5) # 80008810 <first.1699>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
  usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	cf8080e7          	jalr	-776(ra) # 800026f8 <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	addi	sp,sp,16
    80001a0e:	8082                	ret
    first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	e007a023          	sw	zero,-512(a5) # 80008810 <first.1699>
    fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	b68080e7          	jalr	-1176(ra) # 80003582 <fsinit>
    80001a22:	bff9                	j	80001a00 <forkret+0x22>

0000000080001a24 <allocpid>:
allocpid() {
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	e04a                	sd	s2,0(sp)
    80001a2e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a30:	00010917          	auipc	s2,0x10
    80001a34:	87090913          	addi	s2,s2,-1936 # 800112a0 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	19c080e7          	jalr	412(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	dd278793          	addi	a5,a5,-558 # 80008814 <nextpid>
    80001a4a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a4c:	0014871b          	addiw	a4,s1,1
    80001a50:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	236080e7          	jalr	566(ra) # 80000c8a <release>
}
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6902                	ld	s2,0(sp)
    80001a66:	6105                	addi	sp,sp,32
    80001a68:	8082                	ret

0000000080001a6a <proc_pagetable>:
{
    80001a6a:	1101                	addi	sp,sp,-32
    80001a6c:	ec06                	sd	ra,24(sp)
    80001a6e:	e822                	sd	s0,16(sp)
    80001a70:	e426                	sd	s1,8(sp)
    80001a72:	e04a                	sd	s2,0(sp)
    80001a74:	1000                	addi	s0,sp,32
    80001a76:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	898080e7          	jalr	-1896(ra) # 80001310 <uvmcreate>
    80001a80:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a82:	c121                	beqz	a0,80001ac2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a84:	4729                	li	a4,10
    80001a86:	00005697          	auipc	a3,0x5
    80001a8a:	57a68693          	addi	a3,a3,1402 # 80007000 <_trampoline>
    80001a8e:	6605                	lui	a2,0x1
    80001a90:	040005b7          	lui	a1,0x4000
    80001a94:	15fd                	addi	a1,a1,-1
    80001a96:	05b2                	slli	a1,a1,0xc
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	60e080e7          	jalr	1550(ra) # 800010a6 <mappages>
    80001aa0:	02054863          	bltz	a0,80001ad0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aa4:	4719                	li	a4,6
    80001aa6:	05893683          	ld	a3,88(s2)
    80001aaa:	6605                	lui	a2,0x1
    80001aac:	020005b7          	lui	a1,0x2000
    80001ab0:	15fd                	addi	a1,a1,-1
    80001ab2:	05b6                	slli	a1,a1,0xd
    80001ab4:	8526                	mv	a0,s1
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	5f0080e7          	jalr	1520(ra) # 800010a6 <mappages>
    80001abe:	02054163          	bltz	a0,80001ae0 <proc_pagetable+0x76>
}
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	60e2                	ld	ra,24(sp)
    80001ac6:	6442                	ld	s0,16(sp)
    80001ac8:	64a2                	ld	s1,8(sp)
    80001aca:	6902                	ld	s2,0(sp)
    80001acc:	6105                	addi	sp,sp,32
    80001ace:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad0:	4581                	li	a1,0
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	a38080e7          	jalr	-1480(ra) # 8000150c <uvmfree>
    return 0;
    80001adc:	4481                	li	s1,0
    80001ade:	b7d5                	j	80001ac2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae0:	4681                	li	a3,0
    80001ae2:	4605                	li	a2,1
    80001ae4:	040005b7          	lui	a1,0x4000
    80001ae8:	15fd                	addi	a1,a1,-1
    80001aea:	05b2                	slli	a1,a1,0xc
    80001aec:	8526                	mv	a0,s1
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	76c080e7          	jalr	1900(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001af6:	4581                	li	a1,0
    80001af8:	8526                	mv	a0,s1
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	a12080e7          	jalr	-1518(ra) # 8000150c <uvmfree>
    return 0;
    80001b02:	4481                	li	s1,0
    80001b04:	bf7d                	j	80001ac2 <proc_pagetable+0x58>

0000000080001b06 <proc_freepagetable>:
{
    80001b06:	1101                	addi	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	e04a                	sd	s2,0(sp)
    80001b10:	1000                	addi	s0,sp,32
    80001b12:	84aa                	mv	s1,a0
    80001b14:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b16:	4681                	li	a3,0
    80001b18:	4605                	li	a2,1
    80001b1a:	040005b7          	lui	a1,0x4000
    80001b1e:	15fd                	addi	a1,a1,-1
    80001b20:	05b2                	slli	a1,a1,0xc
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	738080e7          	jalr	1848(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b2a:	4681                	li	a3,0
    80001b2c:	4605                	li	a2,1
    80001b2e:	020005b7          	lui	a1,0x2000
    80001b32:	15fd                	addi	a1,a1,-1
    80001b34:	05b6                	slli	a1,a1,0xd
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	722080e7          	jalr	1826(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b40:	85ca                	mv	a1,s2
    80001b42:	8526                	mv	a0,s1
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	9c8080e7          	jalr	-1592(ra) # 8000150c <uvmfree>
}
    80001b4c:	60e2                	ld	ra,24(sp)
    80001b4e:	6442                	ld	s0,16(sp)
    80001b50:	64a2                	ld	s1,8(sp)
    80001b52:	6902                	ld	s2,0(sp)
    80001b54:	6105                	addi	sp,sp,32
    80001b56:	8082                	ret

0000000080001b58 <freeproc>:
{
    80001b58:	1101                	addi	sp,sp,-32
    80001b5a:	ec06                	sd	ra,24(sp)
    80001b5c:	e822                	sd	s0,16(sp)
    80001b5e:	e426                	sd	s1,8(sp)
    80001b60:	1000                	addi	s0,sp,32
    80001b62:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b64:	6d28                	ld	a0,88(a0)
    80001b66:	c509                	beqz	a0,80001b70 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	e82080e7          	jalr	-382(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b70:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b74:	68a8                	ld	a0,80(s1)
    80001b76:	c511                	beqz	a0,80001b82 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b78:	64ac                	ld	a1,72(s1)
    80001b7a:	00000097          	auipc	ra,0x0
    80001b7e:	f8c080e7          	jalr	-116(ra) # 80001b06 <proc_freepagetable>
  p->pagetable = 0;
    80001b82:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b86:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b8a:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001b8e:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001b92:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b96:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001b9a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001b9e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001ba2:	0004ac23          	sw	zero,24(s1)
}
    80001ba6:	60e2                	ld	ra,24(sp)
    80001ba8:	6442                	ld	s0,16(sp)
    80001baa:	64a2                	ld	s1,8(sp)
    80001bac:	6105                	addi	sp,sp,32
    80001bae:	8082                	ret

0000000080001bb0 <allocproc>:
{
    80001bb0:	7179                	addi	sp,sp,-48
    80001bb2:	f406                	sd	ra,40(sp)
    80001bb4:	f022                	sd	s0,32(sp)
    80001bb6:	ec26                	sd	s1,24(sp)
    80001bb8:	e84a                	sd	s2,16(sp)
    80001bba:	e44e                	sd	s3,8(sp)
    80001bbc:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bbe:	00010497          	auipc	s1,0x10
    80001bc2:	afa48493          	addi	s1,s1,-1286 # 800116b8 <proc>
    80001bc6:	00021997          	auipc	s3,0x21
    80001bca:	4f298993          	addi	s3,s3,1266 # 800230b8 <tickslock>
    acquire(&p->lock);
    80001bce:	8526                	mv	a0,s1
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	006080e7          	jalr	6(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bd8:	4c9c                	lw	a5,24(s1)
    80001bda:	cf81                	beqz	a5,80001bf2 <allocproc+0x42>
      release(&p->lock);
    80001bdc:	8526                	mv	a0,s1
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	0ac080e7          	jalr	172(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be6:	46848493          	addi	s1,s1,1128
    80001bea:	ff3492e3          	bne	s1,s3,80001bce <allocproc+0x1e>
  return 0;
    80001bee:	4481                	li	s1,0
    80001bf0:	a8bd                	j	80001c6e <allocproc+0xbe>
  p->pid = allocpid();
    80001bf2:	00000097          	auipc	ra,0x0
    80001bf6:	e32080e7          	jalr	-462(ra) # 80001a24 <allocpid>
    80001bfa:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	eea080e7          	jalr	-278(ra) # 80000ae6 <kalloc>
    80001c04:	89aa                	mv	s3,a0
    80001c06:	eca8                	sd	a0,88(s1)
    80001c08:	c93d                	beqz	a0,80001c7e <allocproc+0xce>
  p->pagetable = proc_pagetable(p);
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	e5e080e7          	jalr	-418(ra) # 80001a6a <proc_pagetable>
    80001c14:	89aa                	mv	s3,a0
    80001c16:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c18:	c935                	beqz	a0,80001c8c <allocproc+0xdc>
  memset(&p->context, 0, sizeof(p->context));
    80001c1a:	07000613          	li	a2,112
    80001c1e:	4581                	li	a1,0
    80001c20:	06048513          	addi	a0,s1,96
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	0ae080e7          	jalr	174(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c2c:	00000797          	auipc	a5,0x0
    80001c30:	db278793          	addi	a5,a5,-590 # 800019de <forkret>
    80001c34:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c36:	60bc                	ld	a5,64(s1)
    80001c38:	6705                	lui	a4,0x1
    80001c3a:	97ba                	add	a5,a5,a4
    80001c3c:	f4bc                	sd	a5,104(s1)
  for (int i = 0; i < NVMA; i++) {
    80001c3e:	16848793          	addi	a5,s1,360
    80001c42:	46848913          	addi	s2,s1,1128
    p->vmas[i].valid  = 0;
    80001c46:	0007a023          	sw	zero,0(a5)
    p->vmas[i].addr   = 0;
    80001c4a:	0007b423          	sd	zero,8(a5)
    p->vmas[i].length = 0;
    80001c4e:	0007a823          	sw	zero,16(a5)
    p->vmas[i].prot   = 0;
    80001c52:	0007aa23          	sw	zero,20(a5)
    p->vmas[i].flags  = 0;
    80001c56:	0007ac23          	sw	zero,24(a5)
    p->vmas[i].fd     = 0;
    80001c5a:	0007ae23          	sw	zero,28(a5)
    p->vmas[i].offset = 0;
    80001c5e:	0207a023          	sw	zero,32(a5)
    p->vmas[i].f      = 0;
    80001c62:	0207b423          	sd	zero,40(a5)
  for (int i = 0; i < NVMA; i++) {
    80001c66:	03078793          	addi	a5,a5,48
    80001c6a:	fd279ee3          	bne	a5,s2,80001c46 <allocproc+0x96>
}
    80001c6e:	8526                	mv	a0,s1
    80001c70:	70a2                	ld	ra,40(sp)
    80001c72:	7402                	ld	s0,32(sp)
    80001c74:	64e2                	ld	s1,24(sp)
    80001c76:	6942                	ld	s2,16(sp)
    80001c78:	69a2                	ld	s3,8(sp)
    80001c7a:	6145                	addi	sp,sp,48
    80001c7c:	8082                	ret
    release(&p->lock);
    80001c7e:	8526                	mv	a0,s1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	00a080e7          	jalr	10(ra) # 80000c8a <release>
    return 0;
    80001c88:	84ce                	mv	s1,s3
    80001c8a:	b7d5                	j	80001c6e <allocproc+0xbe>
    freeproc(p);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	eca080e7          	jalr	-310(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	ff2080e7          	jalr	-14(ra) # 80000c8a <release>
    return 0;
    80001ca0:	84ce                	mv	s1,s3
    80001ca2:	b7f1                	j	80001c6e <allocproc+0xbe>

0000000080001ca4 <userinit>:
{
    80001ca4:	1101                	addi	sp,sp,-32
    80001ca6:	ec06                	sd	ra,24(sp)
    80001ca8:	e822                	sd	s0,16(sp)
    80001caa:	e426                	sd	s1,8(sp)
    80001cac:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	f02080e7          	jalr	-254(ra) # 80001bb0 <allocproc>
    80001cb6:	84aa                	mv	s1,a0
  initproc = p;
    80001cb8:	00007797          	auipc	a5,0x7
    80001cbc:	36a7b823          	sd	a0,880(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc0:	03400613          	li	a2,52
    80001cc4:	00007597          	auipc	a1,0x7
    80001cc8:	b5c58593          	addi	a1,a1,-1188 # 80008820 <initcode>
    80001ccc:	6928                	ld	a0,80(a0)
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	670080e7          	jalr	1648(ra) # 8000133e <uvminit>
  p->sz = PGSIZE;
    80001cd6:	6785                	lui	a5,0x1
    80001cd8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cda:	6cb8                	ld	a4,88(s1)
    80001cdc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce0:	6cb8                	ld	a4,88(s1)
    80001ce2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce4:	4641                	li	a2,16
    80001ce6:	00006597          	auipc	a1,0x6
    80001cea:	4c258593          	addi	a1,a1,1218 # 800081a8 <digits+0x168>
    80001cee:	15848513          	addi	a0,s1,344
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	136080e7          	jalr	310(ra) # 80000e28 <safestrcpy>
  p->cwd = namei("/");
    80001cfa:	00006517          	auipc	a0,0x6
    80001cfe:	4be50513          	addi	a0,a0,1214 # 800081b8 <digits+0x178>
    80001d02:	00002097          	auipc	ra,0x2
    80001d06:	2ae080e7          	jalr	686(ra) # 80003fb0 <namei>
    80001d0a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d0e:	4789                	li	a5,2
    80001d10:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d12:	8526                	mv	a0,s1
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	f76080e7          	jalr	-138(ra) # 80000c8a <release>
}
    80001d1c:	60e2                	ld	ra,24(sp)
    80001d1e:	6442                	ld	s0,16(sp)
    80001d20:	64a2                	ld	s1,8(sp)
    80001d22:	6105                	addi	sp,sp,32
    80001d24:	8082                	ret

0000000080001d26 <growproc>:
{
    80001d26:	1101                	addi	sp,sp,-32
    80001d28:	ec06                	sd	ra,24(sp)
    80001d2a:	e822                	sd	s0,16(sp)
    80001d2c:	e426                	sd	s1,8(sp)
    80001d2e:	e04a                	sd	s2,0(sp)
    80001d30:	1000                	addi	s0,sp,32
    80001d32:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	c72080e7          	jalr	-910(ra) # 800019a6 <myproc>
    80001d3c:	892a                	mv	s2,a0
  sz = p->sz;
    80001d3e:	652c                	ld	a1,72(a0)
    80001d40:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d44:	00904f63          	bgtz	s1,80001d62 <growproc+0x3c>
  } else if(n < 0){
    80001d48:	0204cc63          	bltz	s1,80001d80 <growproc+0x5a>
  p->sz = sz;
    80001d4c:	1602                	slli	a2,a2,0x20
    80001d4e:	9201                	srli	a2,a2,0x20
    80001d50:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d54:	4501                	li	a0,0
}
    80001d56:	60e2                	ld	ra,24(sp)
    80001d58:	6442                	ld	s0,16(sp)
    80001d5a:	64a2                	ld	s1,8(sp)
    80001d5c:	6902                	ld	s2,0(sp)
    80001d5e:	6105                	addi	sp,sp,32
    80001d60:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d62:	9e25                	addw	a2,a2,s1
    80001d64:	1602                	slli	a2,a2,0x20
    80001d66:	9201                	srli	a2,a2,0x20
    80001d68:	1582                	slli	a1,a1,0x20
    80001d6a:	9181                	srli	a1,a1,0x20
    80001d6c:	6928                	ld	a0,80(a0)
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	68a080e7          	jalr	1674(ra) # 800013f8 <uvmalloc>
    80001d76:	0005061b          	sext.w	a2,a0
    80001d7a:	fa69                	bnez	a2,80001d4c <growproc+0x26>
      return -1;
    80001d7c:	557d                	li	a0,-1
    80001d7e:	bfe1                	j	80001d56 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d80:	9e25                	addw	a2,a2,s1
    80001d82:	1602                	slli	a2,a2,0x20
    80001d84:	9201                	srli	a2,a2,0x20
    80001d86:	1582                	slli	a1,a1,0x20
    80001d88:	9181                	srli	a1,a1,0x20
    80001d8a:	6928                	ld	a0,80(a0)
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	624080e7          	jalr	1572(ra) # 800013b0 <uvmdealloc>
    80001d94:	0005061b          	sext.w	a2,a0
    80001d98:	bf55                	j	80001d4c <growproc+0x26>

0000000080001d9a <fork>:
{
    80001d9a:	7139                	addi	sp,sp,-64
    80001d9c:	fc06                	sd	ra,56(sp)
    80001d9e:	f822                	sd	s0,48(sp)
    80001da0:	f426                	sd	s1,40(sp)
    80001da2:	f04a                	sd	s2,32(sp)
    80001da4:	ec4e                	sd	s3,24(sp)
    80001da6:	e852                	sd	s4,16(sp)
    80001da8:	e456                	sd	s5,8(sp)
    80001daa:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	bfa080e7          	jalr	-1030(ra) # 800019a6 <myproc>
    80001db4:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80001db6:	00000097          	auipc	ra,0x0
    80001dba:	dfa080e7          	jalr	-518(ra) # 80001bb0 <allocproc>
    80001dbe:	12050363          	beqz	a0,80001ee4 <fork+0x14a>
    80001dc2:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dc4:	0489b603          	ld	a2,72(s3)
    80001dc8:	692c                	ld	a1,80(a0)
    80001dca:	0509b503          	ld	a0,80(s3)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	776080e7          	jalr	1910(ra) # 80001544 <uvmcopy>
    80001dd6:	04054863          	bltz	a0,80001e26 <fork+0x8c>
  np->sz = p->sz;
    80001dda:	0489b783          	ld	a5,72(s3)
    80001dde:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001de2:	033a3023          	sd	s3,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001de6:	0589b683          	ld	a3,88(s3)
    80001dea:	87b6                	mv	a5,a3
    80001dec:	058a3703          	ld	a4,88(s4)
    80001df0:	12068693          	addi	a3,a3,288
    80001df4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001df8:	6788                	ld	a0,8(a5)
    80001dfa:	6b8c                	ld	a1,16(a5)
    80001dfc:	6f90                	ld	a2,24(a5)
    80001dfe:	01073023          	sd	a6,0(a4)
    80001e02:	e708                	sd	a0,8(a4)
    80001e04:	eb0c                	sd	a1,16(a4)
    80001e06:	ef10                	sd	a2,24(a4)
    80001e08:	02078793          	addi	a5,a5,32
    80001e0c:	02070713          	addi	a4,a4,32
    80001e10:	fed792e3          	bne	a5,a3,80001df4 <fork+0x5a>
  np->trapframe->a0 = 0;
    80001e14:	058a3783          	ld	a5,88(s4)
    80001e18:	0607b823          	sd	zero,112(a5)
    80001e1c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e20:	15000913          	li	s2,336
    80001e24:	a03d                	j	80001e52 <fork+0xb8>
    freeproc(np);
    80001e26:	8552                	mv	a0,s4
    80001e28:	00000097          	auipc	ra,0x0
    80001e2c:	d30080e7          	jalr	-720(ra) # 80001b58 <freeproc>
    release(&np->lock);
    80001e30:	8552                	mv	a0,s4
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e58080e7          	jalr	-424(ra) # 80000c8a <release>
    return -1;
    80001e3a:	5afd                	li	s5,-1
    80001e3c:	a851                	j	80001ed0 <fork+0x136>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e3e:	00003097          	auipc	ra,0x3
    80001e42:	810080e7          	jalr	-2032(ra) # 8000464e <filedup>
    80001e46:	009a07b3          	add	a5,s4,s1
    80001e4a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e4c:	04a1                	addi	s1,s1,8
    80001e4e:	01248763          	beq	s1,s2,80001e5c <fork+0xc2>
    if(p->ofile[i])
    80001e52:	009987b3          	add	a5,s3,s1
    80001e56:	6388                	ld	a0,0(a5)
    80001e58:	f17d                	bnez	a0,80001e3e <fork+0xa4>
    80001e5a:	bfcd                	j	80001e4c <fork+0xb2>
  np->cwd = idup(p->cwd);
    80001e5c:	1509b503          	ld	a0,336(s3)
    80001e60:	00002097          	auipc	ra,0x2
    80001e64:	95c080e7          	jalr	-1700(ra) # 800037bc <idup>
    80001e68:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e6c:	4641                	li	a2,16
    80001e6e:	15898593          	addi	a1,s3,344
    80001e72:	158a0513          	addi	a0,s4,344
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	fb2080e7          	jalr	-78(ra) # 80000e28 <safestrcpy>
  pid = np->pid;
    80001e7e:	038a2a83          	lw	s5,56(s4)
  for (int i = 0; i < NVMA; i++) {
    80001e82:	168a0913          	addi	s2,s4,360
    80001e86:	16898493          	addi	s1,s3,360
    80001e8a:	46898993          	addi	s3,s3,1128
    80001e8e:	a025                	j	80001eb6 <fork+0x11c>
      memmove(&np->vmas[i], &p->vmas[i], sizeof(struct vma));
    80001e90:	03000613          	li	a2,48
    80001e94:	85a6                	mv	a1,s1
    80001e96:	854a                	mv	a0,s2
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	e9a080e7          	jalr	-358(ra) # 80000d32 <memmove>
      filedup(p->vmas[i].f);
    80001ea0:	7488                	ld	a0,40(s1)
    80001ea2:	00002097          	auipc	ra,0x2
    80001ea6:	7ac080e7          	jalr	1964(ra) # 8000464e <filedup>
  for (int i = 0; i < NVMA; i++) {
    80001eaa:	03090913          	addi	s2,s2,48
    80001eae:	03048493          	addi	s1,s1,48
    80001eb2:	01348763          	beq	s1,s3,80001ec0 <fork+0x126>
    np->vmas[i].valid = 0;
    80001eb6:	00092023          	sw	zero,0(s2)
    if (p->vmas[i].valid) {
    80001eba:	409c                	lw	a5,0(s1)
    80001ebc:	d7fd                	beqz	a5,80001eaa <fork+0x110>
    80001ebe:	bfc9                	j	80001e90 <fork+0xf6>
  np->state = RUNNABLE;
    80001ec0:	4789                	li	a5,2
    80001ec2:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ec6:	8552                	mv	a0,s4
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	dc2080e7          	jalr	-574(ra) # 80000c8a <release>
}
    80001ed0:	8556                	mv	a0,s5
    80001ed2:	70e2                	ld	ra,56(sp)
    80001ed4:	7442                	ld	s0,48(sp)
    80001ed6:	74a2                	ld	s1,40(sp)
    80001ed8:	7902                	ld	s2,32(sp)
    80001eda:	69e2                	ld	s3,24(sp)
    80001edc:	6a42                	ld	s4,16(sp)
    80001ede:	6aa2                	ld	s5,8(sp)
    80001ee0:	6121                	addi	sp,sp,64
    80001ee2:	8082                	ret
    return -1;
    80001ee4:	5afd                	li	s5,-1
    80001ee6:	b7ed                	j	80001ed0 <fork+0x136>

0000000080001ee8 <reparent>:
{
    80001ee8:	7179                	addi	sp,sp,-48
    80001eea:	f406                	sd	ra,40(sp)
    80001eec:	f022                	sd	s0,32(sp)
    80001eee:	ec26                	sd	s1,24(sp)
    80001ef0:	e84a                	sd	s2,16(sp)
    80001ef2:	e44e                	sd	s3,8(sp)
    80001ef4:	e052                	sd	s4,0(sp)
    80001ef6:	1800                	addi	s0,sp,48
    80001ef8:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	7be48493          	addi	s1,s1,1982 # 800116b8 <proc>
      pp->parent = initproc;
    80001f02:	00007a17          	auipc	s4,0x7
    80001f06:	126a0a13          	addi	s4,s4,294 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f0a:	00021997          	auipc	s3,0x21
    80001f0e:	1ae98993          	addi	s3,s3,430 # 800230b8 <tickslock>
    80001f12:	a029                	j	80001f1c <reparent+0x34>
    80001f14:	46848493          	addi	s1,s1,1128
    80001f18:	03348363          	beq	s1,s3,80001f3e <reparent+0x56>
    if(pp->parent == p){
    80001f1c:	709c                	ld	a5,32(s1)
    80001f1e:	ff279be3          	bne	a5,s2,80001f14 <reparent+0x2c>
      acquire(&pp->lock);
    80001f22:	8526                	mv	a0,s1
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	cb2080e7          	jalr	-846(ra) # 80000bd6 <acquire>
      pp->parent = initproc;
    80001f2c:	000a3783          	ld	a5,0(s4)
    80001f30:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f32:	8526                	mv	a0,s1
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	d56080e7          	jalr	-682(ra) # 80000c8a <release>
    80001f3c:	bfe1                	j	80001f14 <reparent+0x2c>
}
    80001f3e:	70a2                	ld	ra,40(sp)
    80001f40:	7402                	ld	s0,32(sp)
    80001f42:	64e2                	ld	s1,24(sp)
    80001f44:	6942                	ld	s2,16(sp)
    80001f46:	69a2                	ld	s3,8(sp)
    80001f48:	6a02                	ld	s4,0(sp)
    80001f4a:	6145                	addi	sp,sp,48
    80001f4c:	8082                	ret

0000000080001f4e <scheduler>:
{
    80001f4e:	711d                	addi	sp,sp,-96
    80001f50:	ec86                	sd	ra,88(sp)
    80001f52:	e8a2                	sd	s0,80(sp)
    80001f54:	e4a6                	sd	s1,72(sp)
    80001f56:	e0ca                	sd	s2,64(sp)
    80001f58:	fc4e                	sd	s3,56(sp)
    80001f5a:	f852                	sd	s4,48(sp)
    80001f5c:	f456                	sd	s5,40(sp)
    80001f5e:	f05a                	sd	s6,32(sp)
    80001f60:	ec5e                	sd	s7,24(sp)
    80001f62:	e862                	sd	s8,16(sp)
    80001f64:	e466                	sd	s9,8(sp)
    80001f66:	1080                	addi	s0,sp,96
    80001f68:	8792                	mv	a5,tp
  int id = r_tp();
    80001f6a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f6c:	00779c13          	slli	s8,a5,0x7
    80001f70:	0000f717          	auipc	a4,0xf
    80001f74:	33070713          	addi	a4,a4,816 # 800112a0 <pid_lock>
    80001f78:	9762                	add	a4,a4,s8
    80001f7a:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f7e:	0000f717          	auipc	a4,0xf
    80001f82:	34270713          	addi	a4,a4,834 # 800112c0 <cpus+0x8>
    80001f86:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80001f88:	4a89                	li	s5,2
        c->proc = p;
    80001f8a:	079e                	slli	a5,a5,0x7
    80001f8c:	0000fb17          	auipc	s6,0xf
    80001f90:	314b0b13          	addi	s6,s6,788 # 800112a0 <pid_lock>
    80001f94:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f96:	00021a17          	auipc	s4,0x21
    80001f9a:	122a0a13          	addi	s4,s4,290 # 800230b8 <tickslock>
    int nproc = 0;
    80001f9e:	4c81                	li	s9,0
    80001fa0:	a8a1                	j	80001ff8 <scheduler+0xaa>
        p->state = RUNNING;
    80001fa2:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001fa6:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80001faa:	06048593          	addi	a1,s1,96
    80001fae:	8562                	mv	a0,s8
    80001fb0:	00000097          	auipc	ra,0x0
    80001fb4:	69e080e7          	jalr	1694(ra) # 8000264e <swtch>
        c->proc = 0;
    80001fb8:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	ccc080e7          	jalr	-820(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fc6:	46848493          	addi	s1,s1,1128
    80001fca:	01448d63          	beq	s1,s4,80001fe4 <scheduler+0x96>
      acquire(&p->lock);
    80001fce:	8526                	mv	a0,s1
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	c06080e7          	jalr	-1018(ra) # 80000bd6 <acquire>
      if(p->state != UNUSED) {
    80001fd8:	4c9c                	lw	a5,24(s1)
    80001fda:	d3ed                	beqz	a5,80001fbc <scheduler+0x6e>
        nproc++;
    80001fdc:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80001fde:	fd579fe3          	bne	a5,s5,80001fbc <scheduler+0x6e>
    80001fe2:	b7c1                	j	80001fa2 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80001fe4:	013aca63          	blt	s5,s3,80001ff8 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fec:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff0:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001ff4:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ff8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ffc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002000:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002004:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002006:	0000f497          	auipc	s1,0xf
    8000200a:	6b248493          	addi	s1,s1,1714 # 800116b8 <proc>
        p->state = RUNNING;
    8000200e:	4b8d                	li	s7,3
    80002010:	bf7d                	j	80001fce <scheduler+0x80>

0000000080002012 <sched>:
{
    80002012:	7179                	addi	sp,sp,-48
    80002014:	f406                	sd	ra,40(sp)
    80002016:	f022                	sd	s0,32(sp)
    80002018:	ec26                	sd	s1,24(sp)
    8000201a:	e84a                	sd	s2,16(sp)
    8000201c:	e44e                	sd	s3,8(sp)
    8000201e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002020:	00000097          	auipc	ra,0x0
    80002024:	986080e7          	jalr	-1658(ra) # 800019a6 <myproc>
    80002028:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	b32080e7          	jalr	-1230(ra) # 80000b5c <holding>
    80002032:	c93d                	beqz	a0,800020a8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002034:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002036:	2781                	sext.w	a5,a5
    80002038:	079e                	slli	a5,a5,0x7
    8000203a:	0000f717          	auipc	a4,0xf
    8000203e:	26670713          	addi	a4,a4,614 # 800112a0 <pid_lock>
    80002042:	97ba                	add	a5,a5,a4
    80002044:	0907a703          	lw	a4,144(a5)
    80002048:	4785                	li	a5,1
    8000204a:	06f71763          	bne	a4,a5,800020b8 <sched+0xa6>
  if(p->state == RUNNING)
    8000204e:	4c98                	lw	a4,24(s1)
    80002050:	478d                	li	a5,3
    80002052:	06f70b63          	beq	a4,a5,800020c8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002056:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000205a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000205c:	efb5                	bnez	a5,800020d8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000205e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002060:	0000f917          	auipc	s2,0xf
    80002064:	24090913          	addi	s2,s2,576 # 800112a0 <pid_lock>
    80002068:	2781                	sext.w	a5,a5
    8000206a:	079e                	slli	a5,a5,0x7
    8000206c:	97ca                	add	a5,a5,s2
    8000206e:	0947a983          	lw	s3,148(a5)
    80002072:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002074:	2781                	sext.w	a5,a5
    80002076:	079e                	slli	a5,a5,0x7
    80002078:	0000f597          	auipc	a1,0xf
    8000207c:	24858593          	addi	a1,a1,584 # 800112c0 <cpus+0x8>
    80002080:	95be                	add	a1,a1,a5
    80002082:	06048513          	addi	a0,s1,96
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	5c8080e7          	jalr	1480(ra) # 8000264e <swtch>
    8000208e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002090:	2781                	sext.w	a5,a5
    80002092:	079e                	slli	a5,a5,0x7
    80002094:	97ca                	add	a5,a5,s2
    80002096:	0937aa23          	sw	s3,148(a5)
}
    8000209a:	70a2                	ld	ra,40(sp)
    8000209c:	7402                	ld	s0,32(sp)
    8000209e:	64e2                	ld	s1,24(sp)
    800020a0:	6942                	ld	s2,16(sp)
    800020a2:	69a2                	ld	s3,8(sp)
    800020a4:	6145                	addi	sp,sp,48
    800020a6:	8082                	ret
    panic("sched p->lock");
    800020a8:	00006517          	auipc	a0,0x6
    800020ac:	11850513          	addi	a0,a0,280 # 800081c0 <digits+0x180>
    800020b0:	ffffe097          	auipc	ra,0xffffe
    800020b4:	480080e7          	jalr	1152(ra) # 80000530 <panic>
    panic("sched locks");
    800020b8:	00006517          	auipc	a0,0x6
    800020bc:	11850513          	addi	a0,a0,280 # 800081d0 <digits+0x190>
    800020c0:	ffffe097          	auipc	ra,0xffffe
    800020c4:	470080e7          	jalr	1136(ra) # 80000530 <panic>
    panic("sched running");
    800020c8:	00006517          	auipc	a0,0x6
    800020cc:	11850513          	addi	a0,a0,280 # 800081e0 <digits+0x1a0>
    800020d0:	ffffe097          	auipc	ra,0xffffe
    800020d4:	460080e7          	jalr	1120(ra) # 80000530 <panic>
    panic("sched interruptible");
    800020d8:	00006517          	auipc	a0,0x6
    800020dc:	11850513          	addi	a0,a0,280 # 800081f0 <digits+0x1b0>
    800020e0:	ffffe097          	auipc	ra,0xffffe
    800020e4:	450080e7          	jalr	1104(ra) # 80000530 <panic>

00000000800020e8 <exit>:
{
    800020e8:	7139                	addi	sp,sp,-64
    800020ea:	fc06                	sd	ra,56(sp)
    800020ec:	f822                	sd	s0,48(sp)
    800020ee:	f426                	sd	s1,40(sp)
    800020f0:	f04a                	sd	s2,32(sp)
    800020f2:	ec4e                	sd	s3,24(sp)
    800020f4:	e852                	sd	s4,16(sp)
    800020f6:	e456                	sd	s5,8(sp)
    800020f8:	0080                	addi	s0,sp,64
    800020fa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	8aa080e7          	jalr	-1878(ra) # 800019a6 <myproc>
    80002104:	89aa                	mv	s3,a0
  if(p == initproc)
    80002106:	00007797          	auipc	a5,0x7
    8000210a:	f227b783          	ld	a5,-222(a5) # 80009028 <initproc>
    8000210e:	0d050493          	addi	s1,a0,208
    80002112:	15050913          	addi	s2,a0,336
    80002116:	02a79363          	bne	a5,a0,8000213c <exit+0x54>
    panic("init exiting");
    8000211a:	00006517          	auipc	a0,0x6
    8000211e:	0ee50513          	addi	a0,a0,238 # 80008208 <digits+0x1c8>
    80002122:	ffffe097          	auipc	ra,0xffffe
    80002126:	40e080e7          	jalr	1038(ra) # 80000530 <panic>
      fileclose(f);
    8000212a:	00002097          	auipc	ra,0x2
    8000212e:	576080e7          	jalr	1398(ra) # 800046a0 <fileclose>
      p->ofile[fd] = 0;
    80002132:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002136:	04a1                	addi	s1,s1,8
    80002138:	01248563          	beq	s1,s2,80002142 <exit+0x5a>
    if(p->ofile[fd]){
    8000213c:	6088                	ld	a0,0(s1)
    8000213e:	f575                	bnez	a0,8000212a <exit+0x42>
    80002140:	bfdd                	j	80002136 <exit+0x4e>
    80002142:	16898493          	addi	s1,s3,360
    80002146:	46898a93          	addi	s5,s3,1128
    8000214a:	a0b1                	j	80002196 <exit+0xae>
        filewrite(p->vmas[i].f, p->vmas[i].addr, p->vmas[i].length);
    8000214c:	4890                	lw	a2,16(s1)
    8000214e:	648c                	ld	a1,8(s1)
    80002150:	7488                	ld	a0,40(s1)
    80002152:	00002097          	auipc	ra,0x2
    80002156:	74a080e7          	jalr	1866(ra) # 8000489c <filewrite>
      fileclose(p->vmas[i].f);
    8000215a:	02893503          	ld	a0,40(s2)
    8000215e:	00002097          	auipc	ra,0x2
    80002162:	542080e7          	jalr	1346(ra) # 800046a0 <fileclose>
      uvmunmap(p->pagetable, p->vmas[i].addr, p->vmas[i].length / PGSIZE, 1);
    80002166:	01092783          	lw	a5,16(s2)
    8000216a:	41f7d61b          	sraiw	a2,a5,0x1f
    8000216e:	0146561b          	srliw	a2,a2,0x14
    80002172:	9e3d                	addw	a2,a2,a5
    80002174:	4685                	li	a3,1
    80002176:	40c6561b          	sraiw	a2,a2,0xc
    8000217a:	00893583          	ld	a1,8(s2)
    8000217e:	0509b503          	ld	a0,80(s3)
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	0d8080e7          	jalr	216(ra) # 8000125a <uvmunmap>
      p->vmas[i].valid = 0;
    8000218a:	00092023          	sw	zero,0(s2)
  for (int i = 0; i < NVMA; i++) {
    8000218e:	03048493          	addi	s1,s1,48
    80002192:	01548963          	beq	s1,s5,800021a4 <exit+0xbc>
    if (p->vmas[i].valid) {
    80002196:	8926                	mv	s2,s1
    80002198:	409c                	lw	a5,0(s1)
    8000219a:	dbf5                	beqz	a5,8000218e <exit+0xa6>
      if (p->vmas[i].flags & MAP_SHARED) {
    8000219c:	4c9c                	lw	a5,24(s1)
    8000219e:	8b85                	andi	a5,a5,1
    800021a0:	dfcd                	beqz	a5,8000215a <exit+0x72>
    800021a2:	b76d                	j	8000214c <exit+0x64>
  begin_op();
    800021a4:	00002097          	auipc	ra,0x2
    800021a8:	028080e7          	jalr	40(ra) # 800041cc <begin_op>
  iput(p->cwd);
    800021ac:	1509b503          	ld	a0,336(s3)
    800021b0:	00002097          	auipc	ra,0x2
    800021b4:	804080e7          	jalr	-2044(ra) # 800039b4 <iput>
  end_op();
    800021b8:	00002097          	auipc	ra,0x2
    800021bc:	094080e7          	jalr	148(ra) # 8000424c <end_op>
  p->cwd = 0;
    800021c0:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800021c4:	00007497          	auipc	s1,0x7
    800021c8:	e6448493          	addi	s1,s1,-412 # 80009028 <initproc>
    800021cc:	6088                	ld	a0,0(s1)
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a08080e7          	jalr	-1528(ra) # 80000bd6 <acquire>
  wakeup1(initproc);
    800021d6:	6088                	ld	a0,0(s1)
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	630080e7          	jalr	1584(ra) # 80001808 <wakeup1>
  release(&initproc->lock);
    800021e0:	6088                	ld	a0,0(s1)
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	aa8080e7          	jalr	-1368(ra) # 80000c8a <release>
  acquire(&p->lock);
    800021ea:	854e                	mv	a0,s3
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	9ea080e7          	jalr	-1558(ra) # 80000bd6 <acquire>
  struct proc *original_parent = p->parent;
    800021f4:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021f8:	854e                	mv	a0,s3
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	a90080e7          	jalr	-1392(ra) # 80000c8a <release>
  acquire(&original_parent->lock);
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	9d2080e7          	jalr	-1582(ra) # 80000bd6 <acquire>
  acquire(&p->lock);
    8000220c:	854e                	mv	a0,s3
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	9c8080e7          	jalr	-1592(ra) # 80000bd6 <acquire>
  reparent(p);
    80002216:	854e                	mv	a0,s3
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	cd0080e7          	jalr	-816(ra) # 80001ee8 <reparent>
  wakeup1(original_parent);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	5e6080e7          	jalr	1510(ra) # 80001808 <wakeup1>
  p->xstate = status;
    8000222a:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000222e:	4791                	li	a5,4
    80002230:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002234:	8526                	mv	a0,s1
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a54080e7          	jalr	-1452(ra) # 80000c8a <release>
  sched();
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	dd4080e7          	jalr	-556(ra) # 80002012 <sched>
  panic("zombie exit");
    80002246:	00006517          	auipc	a0,0x6
    8000224a:	fd250513          	addi	a0,a0,-46 # 80008218 <digits+0x1d8>
    8000224e:	ffffe097          	auipc	ra,0xffffe
    80002252:	2e2080e7          	jalr	738(ra) # 80000530 <panic>

0000000080002256 <yield>:
{
    80002256:	1101                	addi	sp,sp,-32
    80002258:	ec06                	sd	ra,24(sp)
    8000225a:	e822                	sd	s0,16(sp)
    8000225c:	e426                	sd	s1,8(sp)
    8000225e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	746080e7          	jalr	1862(ra) # 800019a6 <myproc>
    80002268:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	96c080e7          	jalr	-1684(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002272:	4789                	li	a5,2
    80002274:	cc9c                	sw	a5,24(s1)
  sched();
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	d9c080e7          	jalr	-612(ra) # 80002012 <sched>
  release(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	a0a080e7          	jalr	-1526(ra) # 80000c8a <release>
}
    80002288:	60e2                	ld	ra,24(sp)
    8000228a:	6442                	ld	s0,16(sp)
    8000228c:	64a2                	ld	s1,8(sp)
    8000228e:	6105                	addi	sp,sp,32
    80002290:	8082                	ret

0000000080002292 <sleep>:
{
    80002292:	7179                	addi	sp,sp,-48
    80002294:	f406                	sd	ra,40(sp)
    80002296:	f022                	sd	s0,32(sp)
    80002298:	ec26                	sd	s1,24(sp)
    8000229a:	e84a                	sd	s2,16(sp)
    8000229c:	e44e                	sd	s3,8(sp)
    8000229e:	1800                	addi	s0,sp,48
    800022a0:	89aa                	mv	s3,a0
    800022a2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	702080e7          	jalr	1794(ra) # 800019a6 <myproc>
    800022ac:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022ae:	05250663          	beq	a0,s2,800022fa <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	924080e7          	jalr	-1756(ra) # 80000bd6 <acquire>
    release(lk);
    800022ba:	854a                	mv	a0,s2
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	9ce080e7          	jalr	-1586(ra) # 80000c8a <release>
  p->chan = chan;
    800022c4:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800022c8:	4785                	li	a5,1
    800022ca:	cc9c                	sw	a5,24(s1)
  sched();
    800022cc:	00000097          	auipc	ra,0x0
    800022d0:	d46080e7          	jalr	-698(ra) # 80002012 <sched>
  p->chan = 0;
    800022d4:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022d8:	8526                	mv	a0,s1
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	9b0080e7          	jalr	-1616(ra) # 80000c8a <release>
    acquire(lk);
    800022e2:	854a                	mv	a0,s2
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	8f2080e7          	jalr	-1806(ra) # 80000bd6 <acquire>
}
    800022ec:	70a2                	ld	ra,40(sp)
    800022ee:	7402                	ld	s0,32(sp)
    800022f0:	64e2                	ld	s1,24(sp)
    800022f2:	6942                	ld	s2,16(sp)
    800022f4:	69a2                	ld	s3,8(sp)
    800022f6:	6145                	addi	sp,sp,48
    800022f8:	8082                	ret
  p->chan = chan;
    800022fa:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022fe:	4785                	li	a5,1
    80002300:	cd1c                	sw	a5,24(a0)
  sched();
    80002302:	00000097          	auipc	ra,0x0
    80002306:	d10080e7          	jalr	-752(ra) # 80002012 <sched>
  p->chan = 0;
    8000230a:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000230e:	bff9                	j	800022ec <sleep+0x5a>

0000000080002310 <wait>:
{
    80002310:	715d                	addi	sp,sp,-80
    80002312:	e486                	sd	ra,72(sp)
    80002314:	e0a2                	sd	s0,64(sp)
    80002316:	fc26                	sd	s1,56(sp)
    80002318:	f84a                	sd	s2,48(sp)
    8000231a:	f44e                	sd	s3,40(sp)
    8000231c:	f052                	sd	s4,32(sp)
    8000231e:	ec56                	sd	s5,24(sp)
    80002320:	e85a                	sd	s6,16(sp)
    80002322:	e45e                	sd	s7,8(sp)
    80002324:	e062                	sd	s8,0(sp)
    80002326:	0880                	addi	s0,sp,80
    80002328:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	67c080e7          	jalr	1660(ra) # 800019a6 <myproc>
    80002332:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002334:	8c2a                	mv	s8,a0
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	8a0080e7          	jalr	-1888(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000233e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002340:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002342:	00021997          	auipc	s3,0x21
    80002346:	d7698993          	addi	s3,s3,-650 # 800230b8 <tickslock>
        havekids = 1;
    8000234a:	4a85                	li	s5,1
    havekids = 0;
    8000234c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000234e:	0000f497          	auipc	s1,0xf
    80002352:	36a48493          	addi	s1,s1,874 # 800116b8 <proc>
    80002356:	a08d                	j	800023b8 <wait+0xa8>
          pid = np->pid;
    80002358:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000235c:	000b0e63          	beqz	s6,80002378 <wait+0x68>
    80002360:	4691                	li	a3,4
    80002362:	03448613          	addi	a2,s1,52
    80002366:	85da                	mv	a1,s6
    80002368:	05093503          	ld	a0,80(s2)
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	2d0080e7          	jalr	720(ra) # 8000163c <copyout>
    80002374:	02054263          	bltz	a0,80002398 <wait+0x88>
          freeproc(np);
    80002378:	8526                	mv	a0,s1
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	7de080e7          	jalr	2014(ra) # 80001b58 <freeproc>
          release(&np->lock);
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	906080e7          	jalr	-1786(ra) # 80000c8a <release>
          release(&p->lock);
    8000238c:	854a                	mv	a0,s2
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	8fc080e7          	jalr	-1796(ra) # 80000c8a <release>
          return pid;
    80002396:	a8a9                	j	800023f0 <wait+0xe0>
            release(&np->lock);
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	8f0080e7          	jalr	-1808(ra) # 80000c8a <release>
            release(&p->lock);
    800023a2:	854a                	mv	a0,s2
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	8e6080e7          	jalr	-1818(ra) # 80000c8a <release>
            return -1;
    800023ac:	59fd                	li	s3,-1
    800023ae:	a089                	j	800023f0 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800023b0:	46848493          	addi	s1,s1,1128
    800023b4:	03348463          	beq	s1,s3,800023dc <wait+0xcc>
      if(np->parent == p){
    800023b8:	709c                	ld	a5,32(s1)
    800023ba:	ff279be3          	bne	a5,s2,800023b0 <wait+0xa0>
        acquire(&np->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	816080e7          	jalr	-2026(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    800023c8:	4c9c                	lw	a5,24(s1)
    800023ca:	f94787e3          	beq	a5,s4,80002358 <wait+0x48>
        release(&np->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8ba080e7          	jalr	-1862(ra) # 80000c8a <release>
        havekids = 1;
    800023d8:	8756                	mv	a4,s5
    800023da:	bfd9                	j	800023b0 <wait+0xa0>
    if(!havekids || p->killed){
    800023dc:	c701                	beqz	a4,800023e4 <wait+0xd4>
    800023de:	03092783          	lw	a5,48(s2)
    800023e2:	c785                	beqz	a5,8000240a <wait+0xfa>
      release(&p->lock);
    800023e4:	854a                	mv	a0,s2
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	8a4080e7          	jalr	-1884(ra) # 80000c8a <release>
      return -1;
    800023ee:	59fd                	li	s3,-1
}
    800023f0:	854e                	mv	a0,s3
    800023f2:	60a6                	ld	ra,72(sp)
    800023f4:	6406                	ld	s0,64(sp)
    800023f6:	74e2                	ld	s1,56(sp)
    800023f8:	7942                	ld	s2,48(sp)
    800023fa:	79a2                	ld	s3,40(sp)
    800023fc:	7a02                	ld	s4,32(sp)
    800023fe:	6ae2                	ld	s5,24(sp)
    80002400:	6b42                	ld	s6,16(sp)
    80002402:	6ba2                	ld	s7,8(sp)
    80002404:	6c02                	ld	s8,0(sp)
    80002406:	6161                	addi	sp,sp,80
    80002408:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000240a:	85e2                	mv	a1,s8
    8000240c:	854a                	mv	a0,s2
    8000240e:	00000097          	auipc	ra,0x0
    80002412:	e84080e7          	jalr	-380(ra) # 80002292 <sleep>
    havekids = 0;
    80002416:	bf1d                	j	8000234c <wait+0x3c>

0000000080002418 <wakeup>:
{
    80002418:	7139                	addi	sp,sp,-64
    8000241a:	fc06                	sd	ra,56(sp)
    8000241c:	f822                	sd	s0,48(sp)
    8000241e:	f426                	sd	s1,40(sp)
    80002420:	f04a                	sd	s2,32(sp)
    80002422:	ec4e                	sd	s3,24(sp)
    80002424:	e852                	sd	s4,16(sp)
    80002426:	e456                	sd	s5,8(sp)
    80002428:	0080                	addi	s0,sp,64
    8000242a:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000242c:	0000f497          	auipc	s1,0xf
    80002430:	28c48493          	addi	s1,s1,652 # 800116b8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002434:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002436:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002438:	00021917          	auipc	s2,0x21
    8000243c:	c8090913          	addi	s2,s2,-896 # 800230b8 <tickslock>
    80002440:	a821                	j	80002458 <wakeup+0x40>
      p->state = RUNNABLE;
    80002442:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	842080e7          	jalr	-1982(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002450:	46848493          	addi	s1,s1,1128
    80002454:	01248e63          	beq	s1,s2,80002470 <wakeup+0x58>
    acquire(&p->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	77c080e7          	jalr	1916(ra) # 80000bd6 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002462:	4c9c                	lw	a5,24(s1)
    80002464:	ff3791e3          	bne	a5,s3,80002446 <wakeup+0x2e>
    80002468:	749c                	ld	a5,40(s1)
    8000246a:	fd479ee3          	bne	a5,s4,80002446 <wakeup+0x2e>
    8000246e:	bfd1                	j	80002442 <wakeup+0x2a>
}
    80002470:	70e2                	ld	ra,56(sp)
    80002472:	7442                	ld	s0,48(sp)
    80002474:	74a2                	ld	s1,40(sp)
    80002476:	7902                	ld	s2,32(sp)
    80002478:	69e2                	ld	s3,24(sp)
    8000247a:	6a42                	ld	s4,16(sp)
    8000247c:	6aa2                	ld	s5,8(sp)
    8000247e:	6121                	addi	sp,sp,64
    80002480:	8082                	ret

0000000080002482 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002482:	7179                	addi	sp,sp,-48
    80002484:	f406                	sd	ra,40(sp)
    80002486:	f022                	sd	s0,32(sp)
    80002488:	ec26                	sd	s1,24(sp)
    8000248a:	e84a                	sd	s2,16(sp)
    8000248c:	e44e                	sd	s3,8(sp)
    8000248e:	1800                	addi	s0,sp,48
    80002490:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002492:	0000f497          	auipc	s1,0xf
    80002496:	22648493          	addi	s1,s1,550 # 800116b8 <proc>
    8000249a:	00021997          	auipc	s3,0x21
    8000249e:	c1e98993          	addi	s3,s3,-994 # 800230b8 <tickslock>
    acquire(&p->lock);
    800024a2:	8526                	mv	a0,s1
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	732080e7          	jalr	1842(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800024ac:	5c9c                	lw	a5,56(s1)
    800024ae:	01278d63          	beq	a5,s2,800024c8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	7d6080e7          	jalr	2006(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024bc:	46848493          	addi	s1,s1,1128
    800024c0:	ff3491e3          	bne	s1,s3,800024a2 <kill+0x20>
  }
  return -1;
    800024c4:	557d                	li	a0,-1
    800024c6:	a829                	j	800024e0 <kill+0x5e>
      p->killed = 1;
    800024c8:	4785                	li	a5,1
    800024ca:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800024cc:	4c98                	lw	a4,24(s1)
    800024ce:	4785                	li	a5,1
    800024d0:	00f70f63          	beq	a4,a5,800024ee <kill+0x6c>
      release(&p->lock);
    800024d4:	8526                	mv	a0,s1
    800024d6:	ffffe097          	auipc	ra,0xffffe
    800024da:	7b4080e7          	jalr	1972(ra) # 80000c8a <release>
      return 0;
    800024de:	4501                	li	a0,0
}
    800024e0:	70a2                	ld	ra,40(sp)
    800024e2:	7402                	ld	s0,32(sp)
    800024e4:	64e2                	ld	s1,24(sp)
    800024e6:	6942                	ld	s2,16(sp)
    800024e8:	69a2                	ld	s3,8(sp)
    800024ea:	6145                	addi	sp,sp,48
    800024ec:	8082                	ret
        p->state = RUNNABLE;
    800024ee:	4789                	li	a5,2
    800024f0:	cc9c                	sw	a5,24(s1)
    800024f2:	b7cd                	j	800024d4 <kill+0x52>

00000000800024f4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024f4:	7179                	addi	sp,sp,-48
    800024f6:	f406                	sd	ra,40(sp)
    800024f8:	f022                	sd	s0,32(sp)
    800024fa:	ec26                	sd	s1,24(sp)
    800024fc:	e84a                	sd	s2,16(sp)
    800024fe:	e44e                	sd	s3,8(sp)
    80002500:	e052                	sd	s4,0(sp)
    80002502:	1800                	addi	s0,sp,48
    80002504:	84aa                	mv	s1,a0
    80002506:	892e                	mv	s2,a1
    80002508:	89b2                	mv	s3,a2
    8000250a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	49a080e7          	jalr	1178(ra) # 800019a6 <myproc>
  if(user_dst){
    80002514:	c08d                	beqz	s1,80002536 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002516:	86d2                	mv	a3,s4
    80002518:	864e                	mv	a2,s3
    8000251a:	85ca                	mv	a1,s2
    8000251c:	6928                	ld	a0,80(a0)
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	11e080e7          	jalr	286(ra) # 8000163c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002526:	70a2                	ld	ra,40(sp)
    80002528:	7402                	ld	s0,32(sp)
    8000252a:	64e2                	ld	s1,24(sp)
    8000252c:	6942                	ld	s2,16(sp)
    8000252e:	69a2                	ld	s3,8(sp)
    80002530:	6a02                	ld	s4,0(sp)
    80002532:	6145                	addi	sp,sp,48
    80002534:	8082                	ret
    memmove((char *)dst, src, len);
    80002536:	000a061b          	sext.w	a2,s4
    8000253a:	85ce                	mv	a1,s3
    8000253c:	854a                	mv	a0,s2
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	7f4080e7          	jalr	2036(ra) # 80000d32 <memmove>
    return 0;
    80002546:	8526                	mv	a0,s1
    80002548:	bff9                	j	80002526 <either_copyout+0x32>

000000008000254a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000254a:	7179                	addi	sp,sp,-48
    8000254c:	f406                	sd	ra,40(sp)
    8000254e:	f022                	sd	s0,32(sp)
    80002550:	ec26                	sd	s1,24(sp)
    80002552:	e84a                	sd	s2,16(sp)
    80002554:	e44e                	sd	s3,8(sp)
    80002556:	e052                	sd	s4,0(sp)
    80002558:	1800                	addi	s0,sp,48
    8000255a:	892a                	mv	s2,a0
    8000255c:	84ae                	mv	s1,a1
    8000255e:	89b2                	mv	s3,a2
    80002560:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	444080e7          	jalr	1092(ra) # 800019a6 <myproc>
  if(user_src){
    8000256a:	c08d                	beqz	s1,8000258c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000256c:	86d2                	mv	a3,s4
    8000256e:	864e                	mv	a2,s3
    80002570:	85ca                	mv	a1,s2
    80002572:	6928                	ld	a0,80(a0)
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	154080e7          	jalr	340(ra) # 800016c8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000257c:	70a2                	ld	ra,40(sp)
    8000257e:	7402                	ld	s0,32(sp)
    80002580:	64e2                	ld	s1,24(sp)
    80002582:	6942                	ld	s2,16(sp)
    80002584:	69a2                	ld	s3,8(sp)
    80002586:	6a02                	ld	s4,0(sp)
    80002588:	6145                	addi	sp,sp,48
    8000258a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000258c:	000a061b          	sext.w	a2,s4
    80002590:	85ce                	mv	a1,s3
    80002592:	854a                	mv	a0,s2
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	79e080e7          	jalr	1950(ra) # 80000d32 <memmove>
    return 0;
    8000259c:	8526                	mv	a0,s1
    8000259e:	bff9                	j	8000257c <either_copyin+0x32>

00000000800025a0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025a0:	715d                	addi	sp,sp,-80
    800025a2:	e486                	sd	ra,72(sp)
    800025a4:	e0a2                	sd	s0,64(sp)
    800025a6:	fc26                	sd	s1,56(sp)
    800025a8:	f84a                	sd	s2,48(sp)
    800025aa:	f44e                	sd	s3,40(sp)
    800025ac:	f052                	sd	s4,32(sp)
    800025ae:	ec56                	sd	s5,24(sp)
    800025b0:	e85a                	sd	s6,16(sp)
    800025b2:	e45e                	sd	s7,8(sp)
    800025b4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025b6:	00006517          	auipc	a0,0x6
    800025ba:	b1250513          	addi	a0,a0,-1262 # 800080c8 <digits+0x88>
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	fbc080e7          	jalr	-68(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c6:	0000f497          	auipc	s1,0xf
    800025ca:	24a48493          	addi	s1,s1,586 # 80011810 <proc+0x158>
    800025ce:	00021917          	auipc	s2,0x21
    800025d2:	c4290913          	addi	s2,s2,-958 # 80023210 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d6:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025d8:	00006997          	auipc	s3,0x6
    800025dc:	c5098993          	addi	s3,s3,-944 # 80008228 <digits+0x1e8>
    printf("%d %s %s", p->pid, state, p->name);
    800025e0:	00006a97          	auipc	s5,0x6
    800025e4:	c50a8a93          	addi	s5,s5,-944 # 80008230 <digits+0x1f0>
    printf("\n");
    800025e8:	00006a17          	auipc	s4,0x6
    800025ec:	ae0a0a13          	addi	s4,s4,-1312 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f0:	00006b97          	auipc	s7,0x6
    800025f4:	c78b8b93          	addi	s7,s7,-904 # 80008268 <states.1739>
    800025f8:	a00d                	j	8000261a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025fa:	ee06a583          	lw	a1,-288(a3)
    800025fe:	8556                	mv	a0,s5
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	f7a080e7          	jalr	-134(ra) # 8000057a <printf>
    printf("\n");
    80002608:	8552                	mv	a0,s4
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	f70080e7          	jalr	-144(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002612:	46848493          	addi	s1,s1,1128
    80002616:	03248163          	beq	s1,s2,80002638 <procdump+0x98>
    if(p->state == UNUSED)
    8000261a:	86a6                	mv	a3,s1
    8000261c:	ec04a783          	lw	a5,-320(s1)
    80002620:	dbed                	beqz	a5,80002612 <procdump+0x72>
      state = "???";
    80002622:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002624:	fcfb6be3          	bltu	s6,a5,800025fa <procdump+0x5a>
    80002628:	1782                	slli	a5,a5,0x20
    8000262a:	9381                	srli	a5,a5,0x20
    8000262c:	078e                	slli	a5,a5,0x3
    8000262e:	97de                	add	a5,a5,s7
    80002630:	6390                	ld	a2,0(a5)
    80002632:	f661                	bnez	a2,800025fa <procdump+0x5a>
      state = "???";
    80002634:	864e                	mv	a2,s3
    80002636:	b7d1                	j	800025fa <procdump+0x5a>
  }
}
    80002638:	60a6                	ld	ra,72(sp)
    8000263a:	6406                	ld	s0,64(sp)
    8000263c:	74e2                	ld	s1,56(sp)
    8000263e:	7942                	ld	s2,48(sp)
    80002640:	79a2                	ld	s3,40(sp)
    80002642:	7a02                	ld	s4,32(sp)
    80002644:	6ae2                	ld	s5,24(sp)
    80002646:	6b42                	ld	s6,16(sp)
    80002648:	6ba2                	ld	s7,8(sp)
    8000264a:	6161                	addi	sp,sp,80
    8000264c:	8082                	ret

000000008000264e <swtch>:
    8000264e:	00153023          	sd	ra,0(a0)
    80002652:	00253423          	sd	sp,8(a0)
    80002656:	e900                	sd	s0,16(a0)
    80002658:	ed04                	sd	s1,24(a0)
    8000265a:	03253023          	sd	s2,32(a0)
    8000265e:	03353423          	sd	s3,40(a0)
    80002662:	03453823          	sd	s4,48(a0)
    80002666:	03553c23          	sd	s5,56(a0)
    8000266a:	05653023          	sd	s6,64(a0)
    8000266e:	05753423          	sd	s7,72(a0)
    80002672:	05853823          	sd	s8,80(a0)
    80002676:	05953c23          	sd	s9,88(a0)
    8000267a:	07a53023          	sd	s10,96(a0)
    8000267e:	07b53423          	sd	s11,104(a0)
    80002682:	0005b083          	ld	ra,0(a1)
    80002686:	0085b103          	ld	sp,8(a1)
    8000268a:	6980                	ld	s0,16(a1)
    8000268c:	6d84                	ld	s1,24(a1)
    8000268e:	0205b903          	ld	s2,32(a1)
    80002692:	0285b983          	ld	s3,40(a1)
    80002696:	0305ba03          	ld	s4,48(a1)
    8000269a:	0385ba83          	ld	s5,56(a1)
    8000269e:	0405bb03          	ld	s6,64(a1)
    800026a2:	0485bb83          	ld	s7,72(a1)
    800026a6:	0505bc03          	ld	s8,80(a1)
    800026aa:	0585bc83          	ld	s9,88(a1)
    800026ae:	0605bd03          	ld	s10,96(a1)
    800026b2:	0685bd83          	ld	s11,104(a1)
    800026b6:	8082                	ret

00000000800026b8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026b8:	1141                	addi	sp,sp,-16
    800026ba:	e406                	sd	ra,8(sp)
    800026bc:	e022                	sd	s0,0(sp)
    800026be:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026c0:	00006597          	auipc	a1,0x6
    800026c4:	bd058593          	addi	a1,a1,-1072 # 80008290 <states.1739+0x28>
    800026c8:	00021517          	auipc	a0,0x21
    800026cc:	9f050513          	addi	a0,a0,-1552 # 800230b8 <tickslock>
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	476080e7          	jalr	1142(ra) # 80000b46 <initlock>
}
    800026d8:	60a2                	ld	ra,8(sp)
    800026da:	6402                	ld	s0,0(sp)
    800026dc:	0141                	addi	sp,sp,16
    800026de:	8082                	ret

00000000800026e0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026e0:	1141                	addi	sp,sp,-16
    800026e2:	e422                	sd	s0,8(sp)
    800026e4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e6:	00004797          	auipc	a5,0x4
    800026ea:	8fa78793          	addi	a5,a5,-1798 # 80005fe0 <kernelvec>
    800026ee:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026f2:	6422                	ld	s0,8(sp)
    800026f4:	0141                	addi	sp,sp,16
    800026f6:	8082                	ret

00000000800026f8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026f8:	1141                	addi	sp,sp,-16
    800026fa:	e406                	sd	ra,8(sp)
    800026fc:	e022                	sd	s0,0(sp)
    800026fe:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002700:	fffff097          	auipc	ra,0xfffff
    80002704:	2a6080e7          	jalr	678(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002708:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000270c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000270e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002712:	00005617          	auipc	a2,0x5
    80002716:	8ee60613          	addi	a2,a2,-1810 # 80007000 <_trampoline>
    8000271a:	00005697          	auipc	a3,0x5
    8000271e:	8e668693          	addi	a3,a3,-1818 # 80007000 <_trampoline>
    80002722:	8e91                	sub	a3,a3,a2
    80002724:	040007b7          	lui	a5,0x4000
    80002728:	17fd                	addi	a5,a5,-1
    8000272a:	07b2                	slli	a5,a5,0xc
    8000272c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000272e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002732:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002734:	180026f3          	csrr	a3,satp
    80002738:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000273a:	6d38                	ld	a4,88(a0)
    8000273c:	6134                	ld	a3,64(a0)
    8000273e:	6585                	lui	a1,0x1
    80002740:	96ae                	add	a3,a3,a1
    80002742:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002744:	6d38                	ld	a4,88(a0)
    80002746:	00000697          	auipc	a3,0x0
    8000274a:	13868693          	addi	a3,a3,312 # 8000287e <usertrap>
    8000274e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002750:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002752:	8692                	mv	a3,tp
    80002754:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002756:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000275a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000275e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002762:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002766:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002768:	6f18                	ld	a4,24(a4)
    8000276a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000276e:	692c                	ld	a1,80(a0)
    80002770:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002772:	00005717          	auipc	a4,0x5
    80002776:	91e70713          	addi	a4,a4,-1762 # 80007090 <userret>
    8000277a:	8f11                	sub	a4,a4,a2
    8000277c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000277e:	577d                	li	a4,-1
    80002780:	177e                	slli	a4,a4,0x3f
    80002782:	8dd9                	or	a1,a1,a4
    80002784:	02000537          	lui	a0,0x2000
    80002788:	157d                	addi	a0,a0,-1
    8000278a:	0536                	slli	a0,a0,0xd
    8000278c:	9782                	jalr	a5
}
    8000278e:	60a2                	ld	ra,8(sp)
    80002790:	6402                	ld	s0,0(sp)
    80002792:	0141                	addi	sp,sp,16
    80002794:	8082                	ret

0000000080002796 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002796:	1101                	addi	sp,sp,-32
    80002798:	ec06                	sd	ra,24(sp)
    8000279a:	e822                	sd	s0,16(sp)
    8000279c:	e426                	sd	s1,8(sp)
    8000279e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027a0:	00021497          	auipc	s1,0x21
    800027a4:	91848493          	addi	s1,s1,-1768 # 800230b8 <tickslock>
    800027a8:	8526                	mv	a0,s1
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	42c080e7          	jalr	1068(ra) # 80000bd6 <acquire>
  ticks++;
    800027b2:	00007517          	auipc	a0,0x7
    800027b6:	87e50513          	addi	a0,a0,-1922 # 80009030 <ticks>
    800027ba:	411c                	lw	a5,0(a0)
    800027bc:	2785                	addiw	a5,a5,1
    800027be:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c0:	00000097          	auipc	ra,0x0
    800027c4:	c58080e7          	jalr	-936(ra) # 80002418 <wakeup>
  release(&tickslock);
    800027c8:	8526                	mv	a0,s1
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	4c0080e7          	jalr	1216(ra) # 80000c8a <release>
}
    800027d2:	60e2                	ld	ra,24(sp)
    800027d4:	6442                	ld	s0,16(sp)
    800027d6:	64a2                	ld	s1,8(sp)
    800027d8:	6105                	addi	sp,sp,32
    800027da:	8082                	ret

00000000800027dc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027dc:	1101                	addi	sp,sp,-32
    800027de:	ec06                	sd	ra,24(sp)
    800027e0:	e822                	sd	s0,16(sp)
    800027e2:	e426                	sd	s1,8(sp)
    800027e4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027ea:	00074d63          	bltz	a4,80002804 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027ee:	57fd                	li	a5,-1
    800027f0:	17fe                	slli	a5,a5,0x3f
    800027f2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027f4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027f6:	06f70363          	beq	a4,a5,8000285c <devintr+0x80>
  }
}
    800027fa:	60e2                	ld	ra,24(sp)
    800027fc:	6442                	ld	s0,16(sp)
    800027fe:	64a2                	ld	s1,8(sp)
    80002800:	6105                	addi	sp,sp,32
    80002802:	8082                	ret
     (scause & 0xff) == 9){
    80002804:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002808:	46a5                	li	a3,9
    8000280a:	fed792e3          	bne	a5,a3,800027ee <devintr+0x12>
    int irq = plic_claim();
    8000280e:	00004097          	auipc	ra,0x4
    80002812:	8da080e7          	jalr	-1830(ra) # 800060e8 <plic_claim>
    80002816:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002818:	47a9                	li	a5,10
    8000281a:	02f50763          	beq	a0,a5,80002848 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000281e:	4785                	li	a5,1
    80002820:	02f50963          	beq	a0,a5,80002852 <devintr+0x76>
    return 1;
    80002824:	4505                	li	a0,1
    } else if(irq){
    80002826:	d8f1                	beqz	s1,800027fa <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002828:	85a6                	mv	a1,s1
    8000282a:	00006517          	auipc	a0,0x6
    8000282e:	a6e50513          	addi	a0,a0,-1426 # 80008298 <states.1739+0x30>
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	d48080e7          	jalr	-696(ra) # 8000057a <printf>
      plic_complete(irq);
    8000283a:	8526                	mv	a0,s1
    8000283c:	00004097          	auipc	ra,0x4
    80002840:	8d0080e7          	jalr	-1840(ra) # 8000610c <plic_complete>
    return 1;
    80002844:	4505                	li	a0,1
    80002846:	bf55                	j	800027fa <devintr+0x1e>
      uartintr();
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	152080e7          	jalr	338(ra) # 8000099a <uartintr>
    80002850:	b7ed                	j	8000283a <devintr+0x5e>
      virtio_disk_intr();
    80002852:	00004097          	auipc	ra,0x4
    80002856:	d9a080e7          	jalr	-614(ra) # 800065ec <virtio_disk_intr>
    8000285a:	b7c5                	j	8000283a <devintr+0x5e>
    if(cpuid() == 0){
    8000285c:	fffff097          	auipc	ra,0xfffff
    80002860:	11e080e7          	jalr	286(ra) # 8000197a <cpuid>
    80002864:	c901                	beqz	a0,80002874 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002866:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000286a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000286c:	14479073          	csrw	sip,a5
    return 2;
    80002870:	4509                	li	a0,2
    80002872:	b761                	j	800027fa <devintr+0x1e>
      clockintr();
    80002874:	00000097          	auipc	ra,0x0
    80002878:	f22080e7          	jalr	-222(ra) # 80002796 <clockintr>
    8000287c:	b7ed                	j	80002866 <devintr+0x8a>

000000008000287e <usertrap>:
{
    8000287e:	7139                	addi	sp,sp,-64
    80002880:	fc06                	sd	ra,56(sp)
    80002882:	f822                	sd	s0,48(sp)
    80002884:	f426                	sd	s1,40(sp)
    80002886:	f04a                	sd	s2,32(sp)
    80002888:	ec4e                	sd	s3,24(sp)
    8000288a:	e852                	sd	s4,16(sp)
    8000288c:	e456                	sd	s5,8(sp)
    8000288e:	e05a                	sd	s6,0(sp)
    80002890:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002892:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002896:	1007f793          	andi	a5,a5,256
    8000289a:	e3ad                	bnez	a5,800028fc <usertrap+0x7e>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000289c:	00003797          	auipc	a5,0x3
    800028a0:	74478793          	addi	a5,a5,1860 # 80005fe0 <kernelvec>
    800028a4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028a8:	fffff097          	auipc	ra,0xfffff
    800028ac:	0fe080e7          	jalr	254(ra) # 800019a6 <myproc>
    800028b0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028b2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b4:	14102773          	csrr	a4,sepc
    800028b8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ba:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028be:	47a1                	li	a5,8
    800028c0:	04f70663          	beq	a4,a5,8000290c <usertrap+0x8e>
    800028c4:	14202773          	csrr	a4,scause
  } else if(r_scause() == 13 || r_scause() == 15) {
    800028c8:	47b5                	li	a5,13
    800028ca:	00f70763          	beq	a4,a5,800028d8 <usertrap+0x5a>
    800028ce:	14202773          	csrr	a4,scause
    800028d2:	47bd                	li	a5,15
    800028d4:	18f71263          	bne	a4,a5,80002a58 <usertrap+0x1da>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028d8:	143029f3          	csrr	s3,stval
    struct proc* p = myproc();
    800028dc:	fffff097          	auipc	ra,0xfffff
    800028e0:	0ca080e7          	jalr	202(ra) # 800019a6 <myproc>
    800028e4:	8a2a                	mv	s4,a0
    if (va > MAXVA || va > p->sz) {
    800028e6:	4785                	li	a5,1
    800028e8:	179a                	slli	a5,a5,0x26
    800028ea:	0137e563          	bltu	a5,s3,800028f4 <usertrap+0x76>
    800028ee:	653c                	ld	a5,72(a0)
    800028f0:	0737f563          	bgeu	a5,s3,8000295a <usertrap+0xdc>
      p->killed = 1;
    800028f4:	4785                	li	a5,1
    800028f6:	02fa2823          	sw	a5,48(s4)
    800028fa:	a80d                	j	8000292c <usertrap+0xae>
    panic("usertrap: not from user mode");
    800028fc:	00006517          	auipc	a0,0x6
    80002900:	9bc50513          	addi	a0,a0,-1604 # 800082b8 <states.1739+0x50>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c2c080e7          	jalr	-980(ra) # 80000530 <panic>
    if(p->killed)
    8000290c:	591c                	lw	a5,48(a0)
    8000290e:	e3a1                	bnez	a5,8000294e <usertrap+0xd0>
    p->trapframe->epc += 4;
    80002910:	6cb8                	ld	a4,88(s1)
    80002912:	6f1c                	ld	a5,24(a4)
    80002914:	0791                	addi	a5,a5,4
    80002916:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002918:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000291c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002920:	10079073          	csrw	sstatus,a5
    syscall();
    80002924:	00000097          	auipc	ra,0x0
    80002928:	3d8080e7          	jalr	984(ra) # 80002cfc <syscall>
  if(p->killed)
    8000292c:	589c                	lw	a5,48(s1)
    8000292e:	16079863          	bnez	a5,80002a9e <usertrap+0x220>
  usertrapret();
    80002932:	00000097          	auipc	ra,0x0
    80002936:	dc6080e7          	jalr	-570(ra) # 800026f8 <usertrapret>
}
    8000293a:	70e2                	ld	ra,56(sp)
    8000293c:	7442                	ld	s0,48(sp)
    8000293e:	74a2                	ld	s1,40(sp)
    80002940:	7902                	ld	s2,32(sp)
    80002942:	69e2                	ld	s3,24(sp)
    80002944:	6a42                	ld	s4,16(sp)
    80002946:	6aa2                	ld	s5,8(sp)
    80002948:	6b02                	ld	s6,0(sp)
    8000294a:	6121                	addi	sp,sp,64
    8000294c:	8082                	ret
      exit(-1);
    8000294e:	557d                	li	a0,-1
    80002950:	fffff097          	auipc	ra,0xfffff
    80002954:	798080e7          	jalr	1944(ra) # 800020e8 <exit>
    80002958:	bf65                	j	80002910 <usertrap+0x92>
    8000295a:	16850793          	addi	a5,a0,360
      for (int i = 0; i < NVMA; i++) {
    8000295e:	4901                	li	s2,0
    80002960:	4641                	li	a2,16
    80002962:	a00d                	j	80002984 <usertrap+0x106>
            iunlock(vma->f->ip);
    80002964:	1909b783          	ld	a5,400(s3)
    80002968:	6f88                	ld	a0,24(a5)
    8000296a:	00001097          	auipc	ra,0x1
    8000296e:	f52080e7          	jalr	-174(ra) # 800038bc <iunlock>
        p->killed = 1;
    80002972:	4785                	li	a5,1
    80002974:	02fa2823          	sw	a5,48(s4)
    80002978:	bf55                	j	8000292c <usertrap+0xae>
      for (int i = 0; i < NVMA; i++) {
    8000297a:	2905                	addiw	s2,s2,1
    8000297c:	03078793          	addi	a5,a5,48
    80002980:	fec909e3          	beq	s2,a2,80002972 <usertrap+0xf4>
        if (vma->valid && va >= vma->addr && va < vma->addr+vma->length) {
    80002984:	4398                	lw	a4,0(a5)
    80002986:	db75                	beqz	a4,8000297a <usertrap+0xfc>
    80002988:	6798                	ld	a4,8(a5)
    8000298a:	fee9e8e3          	bltu	s3,a4,8000297a <usertrap+0xfc>
    8000298e:	4b94                	lw	a3,16(a5)
    80002990:	9736                	add	a4,a4,a3
    80002992:	fee9f4e3          	bgeu	s3,a4,8000297a <usertrap+0xfc>
          uint64 pa = (uint64)kalloc();
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	150080e7          	jalr	336(ra) # 80000ae6 <kalloc>
    8000299e:	8aaa                	mv	s5,a0
          if (pa == 0) {
    800029a0:	d969                	beqz	a0,80002972 <usertrap+0xf4>
          va = PGROUNDDOWN(va);
    800029a2:	7b7d                	lui	s6,0xfffff
    800029a4:	0169fb33          	and	s6,s3,s6
          memset((void *)pa, 0, PGSIZE);
    800029a8:	6605                	lui	a2,0x1
    800029aa:	4581                	li	a1,0
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	326080e7          	jalr	806(ra) # 80000cd2 <memset>
          ilock(vma->f->ip);
    800029b4:	00191993          	slli	s3,s2,0x1
    800029b8:	99ca                	add	s3,s3,s2
    800029ba:	0992                	slli	s3,s3,0x4
    800029bc:	99d2                	add	s3,s3,s4
    800029be:	1909b783          	ld	a5,400(s3)
    800029c2:	6f88                	ld	a0,24(a5)
    800029c4:	00001097          	auipc	ra,0x1
    800029c8:	e36080e7          	jalr	-458(ra) # 800037fa <ilock>
          if(readi(vma->f->ip, 0, pa, vma->offset + va - vma->addr, PGSIZE) < 0) {
    800029cc:	1889a783          	lw	a5,392(s3)
    800029d0:	016787bb          	addw	a5,a5,s6
    800029d4:	1709b683          	ld	a3,368(s3)
    800029d8:	1909b503          	ld	a0,400(s3)
    800029dc:	6705                	lui	a4,0x1
    800029de:	40d786bb          	subw	a3,a5,a3
    800029e2:	8656                	mv	a2,s5
    800029e4:	4581                	li	a1,0
    800029e6:	6d08                	ld	a0,24(a0)
    800029e8:	00001097          	auipc	ra,0x1
    800029ec:	0c6080e7          	jalr	198(ra) # 80003aae <readi>
    800029f0:	f6054ae3          	bltz	a0,80002964 <usertrap+0xe6>
          iunlock(vma->f->ip);
    800029f4:	00191993          	slli	s3,s2,0x1
    800029f8:	012987b3          	add	a5,s3,s2
    800029fc:	0792                	slli	a5,a5,0x4
    800029fe:	97d2                	add	a5,a5,s4
    80002a00:	1907b783          	ld	a5,400(a5)
    80002a04:	6f88                	ld	a0,24(a5)
    80002a06:	00001097          	auipc	ra,0x1
    80002a0a:	eb6080e7          	jalr	-330(ra) # 800038bc <iunlock>
          if (vma->prot & PROT_READ)
    80002a0e:	012987b3          	add	a5,s3,s2
    80002a12:	0792                	slli	a5,a5,0x4
    80002a14:	97d2                	add	a5,a5,s4
    80002a16:	17c7a783          	lw	a5,380(a5)
    80002a1a:	0017f693          	andi	a3,a5,1
          int perm = PTE_U;
    80002a1e:	4741                	li	a4,16
          if (vma->prot & PROT_READ)
    80002a20:	c291                	beqz	a3,80002a24 <usertrap+0x1a6>
            perm |= PTE_R;
    80002a22:	4749                	li	a4,18
          if (vma->prot & PROT_WRITE)
    80002a24:	0027f693          	andi	a3,a5,2
    80002a28:	c299                	beqz	a3,80002a2e <usertrap+0x1b0>
            perm |= PTE_W;
    80002a2a:	00476713          	ori	a4,a4,4
          if (vma->prot & PROT_EXEC)
    80002a2e:	8b91                	andi	a5,a5,4
    80002a30:	c399                	beqz	a5,80002a36 <usertrap+0x1b8>
            perm |= PTE_X;
    80002a32:	00876713          	ori	a4,a4,8
          if (mappages(p->pagetable, va, PGSIZE, pa, perm) < 0) {
    80002a36:	86d6                	mv	a3,s5
    80002a38:	6605                	lui	a2,0x1
    80002a3a:	85da                	mv	a1,s6
    80002a3c:	050a3503          	ld	a0,80(s4)
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	666080e7          	jalr	1638(ra) # 800010a6 <mappages>
    80002a48:	ee0552e3          	bgez	a0,8000292c <usertrap+0xae>
            kfree((void*)pa);
    80002a4c:	8556                	mv	a0,s5
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	f9c080e7          	jalr	-100(ra) # 800009ea <kfree>
      if (!found)
    80002a56:	bf31                	j	80002972 <usertrap+0xf4>
  } else if((which_dev = devintr()) != 0){
    80002a58:	00000097          	auipc	ra,0x0
    80002a5c:	d84080e7          	jalr	-636(ra) # 800027dc <devintr>
    80002a60:	892a                	mv	s2,a0
    80002a62:	c501                	beqz	a0,80002a6a <usertrap+0x1ec>
  if(p->killed)
    80002a64:	589c                	lw	a5,48(s1)
    80002a66:	c3b1                	beqz	a5,80002aaa <usertrap+0x22c>
    80002a68:	a825                	j	80002aa0 <usertrap+0x222>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a6a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a6e:	5c90                	lw	a2,56(s1)
    80002a70:	00006517          	auipc	a0,0x6
    80002a74:	86850513          	addi	a0,a0,-1944 # 800082d8 <states.1739+0x70>
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	b02080e7          	jalr	-1278(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a80:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a84:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a88:	00006517          	auipc	a0,0x6
    80002a8c:	88050513          	addi	a0,a0,-1920 # 80008308 <states.1739+0xa0>
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	aea080e7          	jalr	-1302(ra) # 8000057a <printf>
    p->killed = 1;
    80002a98:	4785                	li	a5,1
    80002a9a:	d89c                	sw	a5,48(s1)
  if(p->killed)
    80002a9c:	a011                	j	80002aa0 <usertrap+0x222>
    80002a9e:	4901                	li	s2,0
    exit(-1);
    80002aa0:	557d                	li	a0,-1
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	646080e7          	jalr	1606(ra) # 800020e8 <exit>
  if(which_dev == 2)
    80002aaa:	4789                	li	a5,2
    80002aac:	e8f913e3          	bne	s2,a5,80002932 <usertrap+0xb4>
    yield();
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	7a6080e7          	jalr	1958(ra) # 80002256 <yield>
    80002ab8:	bdad                	j	80002932 <usertrap+0xb4>

0000000080002aba <kerneltrap>:
{
    80002aba:	7179                	addi	sp,sp,-48
    80002abc:	f406                	sd	ra,40(sp)
    80002abe:	f022                	sd	s0,32(sp)
    80002ac0:	ec26                	sd	s1,24(sp)
    80002ac2:	e84a                	sd	s2,16(sp)
    80002ac4:	e44e                	sd	s3,8(sp)
    80002ac6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ac8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002acc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ad0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ad4:	1004f793          	andi	a5,s1,256
    80002ad8:	cb85                	beqz	a5,80002b08 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ada:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ade:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ae0:	ef85                	bnez	a5,80002b18 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ae2:	00000097          	auipc	ra,0x0
    80002ae6:	cfa080e7          	jalr	-774(ra) # 800027dc <devintr>
    80002aea:	cd1d                	beqz	a0,80002b28 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aec:	4789                	li	a5,2
    80002aee:	06f50a63          	beq	a0,a5,80002b62 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002af2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002af6:	10049073          	csrw	sstatus,s1
}
    80002afa:	70a2                	ld	ra,40(sp)
    80002afc:	7402                	ld	s0,32(sp)
    80002afe:	64e2                	ld	s1,24(sp)
    80002b00:	6942                	ld	s2,16(sp)
    80002b02:	69a2                	ld	s3,8(sp)
    80002b04:	6145                	addi	sp,sp,48
    80002b06:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b08:	00006517          	auipc	a0,0x6
    80002b0c:	82050513          	addi	a0,a0,-2016 # 80008328 <states.1739+0xc0>
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	a20080e7          	jalr	-1504(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	83850513          	addi	a0,a0,-1992 # 80008350 <states.1739+0xe8>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	a10080e7          	jalr	-1520(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    80002b28:	85ce                	mv	a1,s3
    80002b2a:	00006517          	auipc	a0,0x6
    80002b2e:	84650513          	addi	a0,a0,-1978 # 80008370 <states.1739+0x108>
    80002b32:	ffffe097          	auipc	ra,0xffffe
    80002b36:	a48080e7          	jalr	-1464(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b3a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b3e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b42:	00006517          	auipc	a0,0x6
    80002b46:	83e50513          	addi	a0,a0,-1986 # 80008380 <states.1739+0x118>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	a30080e7          	jalr	-1488(ra) # 8000057a <printf>
    panic("kerneltrap");
    80002b52:	00006517          	auipc	a0,0x6
    80002b56:	84650513          	addi	a0,a0,-1978 # 80008398 <states.1739+0x130>
    80002b5a:	ffffe097          	auipc	ra,0xffffe
    80002b5e:	9d6080e7          	jalr	-1578(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b62:	fffff097          	auipc	ra,0xfffff
    80002b66:	e44080e7          	jalr	-444(ra) # 800019a6 <myproc>
    80002b6a:	d541                	beqz	a0,80002af2 <kerneltrap+0x38>
    80002b6c:	fffff097          	auipc	ra,0xfffff
    80002b70:	e3a080e7          	jalr	-454(ra) # 800019a6 <myproc>
    80002b74:	4d18                	lw	a4,24(a0)
    80002b76:	478d                	li	a5,3
    80002b78:	f6f71de3          	bne	a4,a5,80002af2 <kerneltrap+0x38>
    yield();
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	6da080e7          	jalr	1754(ra) # 80002256 <yield>
    80002b84:	b7bd                	j	80002af2 <kerneltrap+0x38>

0000000080002b86 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b86:	1101                	addi	sp,sp,-32
    80002b88:	ec06                	sd	ra,24(sp)
    80002b8a:	e822                	sd	s0,16(sp)
    80002b8c:	e426                	sd	s1,8(sp)
    80002b8e:	1000                	addi	s0,sp,32
    80002b90:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	e14080e7          	jalr	-492(ra) # 800019a6 <myproc>
  switch (n) {
    80002b9a:	4795                	li	a5,5
    80002b9c:	0497e163          	bltu	a5,s1,80002bde <argraw+0x58>
    80002ba0:	048a                	slli	s1,s1,0x2
    80002ba2:	00006717          	auipc	a4,0x6
    80002ba6:	82e70713          	addi	a4,a4,-2002 # 800083d0 <states.1739+0x168>
    80002baa:	94ba                	add	s1,s1,a4
    80002bac:	409c                	lw	a5,0(s1)
    80002bae:	97ba                	add	a5,a5,a4
    80002bb0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bb2:	6d3c                	ld	a5,88(a0)
    80002bb4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bb6:	60e2                	ld	ra,24(sp)
    80002bb8:	6442                	ld	s0,16(sp)
    80002bba:	64a2                	ld	s1,8(sp)
    80002bbc:	6105                	addi	sp,sp,32
    80002bbe:	8082                	ret
    return p->trapframe->a1;
    80002bc0:	6d3c                	ld	a5,88(a0)
    80002bc2:	7fa8                	ld	a0,120(a5)
    80002bc4:	bfcd                	j	80002bb6 <argraw+0x30>
    return p->trapframe->a2;
    80002bc6:	6d3c                	ld	a5,88(a0)
    80002bc8:	63c8                	ld	a0,128(a5)
    80002bca:	b7f5                	j	80002bb6 <argraw+0x30>
    return p->trapframe->a3;
    80002bcc:	6d3c                	ld	a5,88(a0)
    80002bce:	67c8                	ld	a0,136(a5)
    80002bd0:	b7dd                	j	80002bb6 <argraw+0x30>
    return p->trapframe->a4;
    80002bd2:	6d3c                	ld	a5,88(a0)
    80002bd4:	6bc8                	ld	a0,144(a5)
    80002bd6:	b7c5                	j	80002bb6 <argraw+0x30>
    return p->trapframe->a5;
    80002bd8:	6d3c                	ld	a5,88(a0)
    80002bda:	6fc8                	ld	a0,152(a5)
    80002bdc:	bfe9                	j	80002bb6 <argraw+0x30>
  panic("argraw");
    80002bde:	00005517          	auipc	a0,0x5
    80002be2:	7ca50513          	addi	a0,a0,1994 # 800083a8 <states.1739+0x140>
    80002be6:	ffffe097          	auipc	ra,0xffffe
    80002bea:	94a080e7          	jalr	-1718(ra) # 80000530 <panic>

0000000080002bee <fetchaddr>:
{
    80002bee:	1101                	addi	sp,sp,-32
    80002bf0:	ec06                	sd	ra,24(sp)
    80002bf2:	e822                	sd	s0,16(sp)
    80002bf4:	e426                	sd	s1,8(sp)
    80002bf6:	e04a                	sd	s2,0(sp)
    80002bf8:	1000                	addi	s0,sp,32
    80002bfa:	84aa                	mv	s1,a0
    80002bfc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bfe:	fffff097          	auipc	ra,0xfffff
    80002c02:	da8080e7          	jalr	-600(ra) # 800019a6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c06:	653c                	ld	a5,72(a0)
    80002c08:	02f4f863          	bgeu	s1,a5,80002c38 <fetchaddr+0x4a>
    80002c0c:	00848713          	addi	a4,s1,8
    80002c10:	02e7e663          	bltu	a5,a4,80002c3c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c14:	46a1                	li	a3,8
    80002c16:	8626                	mv	a2,s1
    80002c18:	85ca                	mv	a1,s2
    80002c1a:	6928                	ld	a0,80(a0)
    80002c1c:	fffff097          	auipc	ra,0xfffff
    80002c20:	aac080e7          	jalr	-1364(ra) # 800016c8 <copyin>
    80002c24:	00a03533          	snez	a0,a0
    80002c28:	40a00533          	neg	a0,a0
}
    80002c2c:	60e2                	ld	ra,24(sp)
    80002c2e:	6442                	ld	s0,16(sp)
    80002c30:	64a2                	ld	s1,8(sp)
    80002c32:	6902                	ld	s2,0(sp)
    80002c34:	6105                	addi	sp,sp,32
    80002c36:	8082                	ret
    return -1;
    80002c38:	557d                	li	a0,-1
    80002c3a:	bfcd                	j	80002c2c <fetchaddr+0x3e>
    80002c3c:	557d                	li	a0,-1
    80002c3e:	b7fd                	j	80002c2c <fetchaddr+0x3e>

0000000080002c40 <fetchstr>:
{
    80002c40:	7179                	addi	sp,sp,-48
    80002c42:	f406                	sd	ra,40(sp)
    80002c44:	f022                	sd	s0,32(sp)
    80002c46:	ec26                	sd	s1,24(sp)
    80002c48:	e84a                	sd	s2,16(sp)
    80002c4a:	e44e                	sd	s3,8(sp)
    80002c4c:	1800                	addi	s0,sp,48
    80002c4e:	892a                	mv	s2,a0
    80002c50:	84ae                	mv	s1,a1
    80002c52:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c54:	fffff097          	auipc	ra,0xfffff
    80002c58:	d52080e7          	jalr	-686(ra) # 800019a6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c5c:	86ce                	mv	a3,s3
    80002c5e:	864a                	mv	a2,s2
    80002c60:	85a6                	mv	a1,s1
    80002c62:	6928                	ld	a0,80(a0)
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	af0080e7          	jalr	-1296(ra) # 80001754 <copyinstr>
  if(err < 0)
    80002c6c:	00054763          	bltz	a0,80002c7a <fetchstr+0x3a>
  return strlen(buf);
    80002c70:	8526                	mv	a0,s1
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	1e8080e7          	jalr	488(ra) # 80000e5a <strlen>
}
    80002c7a:	70a2                	ld	ra,40(sp)
    80002c7c:	7402                	ld	s0,32(sp)
    80002c7e:	64e2                	ld	s1,24(sp)
    80002c80:	6942                	ld	s2,16(sp)
    80002c82:	69a2                	ld	s3,8(sp)
    80002c84:	6145                	addi	sp,sp,48
    80002c86:	8082                	ret

0000000080002c88 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c88:	1101                	addi	sp,sp,-32
    80002c8a:	ec06                	sd	ra,24(sp)
    80002c8c:	e822                	sd	s0,16(sp)
    80002c8e:	e426                	sd	s1,8(sp)
    80002c90:	1000                	addi	s0,sp,32
    80002c92:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	ef2080e7          	jalr	-270(ra) # 80002b86 <argraw>
    80002c9c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c9e:	4501                	li	a0,0
    80002ca0:	60e2                	ld	ra,24(sp)
    80002ca2:	6442                	ld	s0,16(sp)
    80002ca4:	64a2                	ld	s1,8(sp)
    80002ca6:	6105                	addi	sp,sp,32
    80002ca8:	8082                	ret

0000000080002caa <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002caa:	1101                	addi	sp,sp,-32
    80002cac:	ec06                	sd	ra,24(sp)
    80002cae:	e822                	sd	s0,16(sp)
    80002cb0:	e426                	sd	s1,8(sp)
    80002cb2:	1000                	addi	s0,sp,32
    80002cb4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cb6:	00000097          	auipc	ra,0x0
    80002cba:	ed0080e7          	jalr	-304(ra) # 80002b86 <argraw>
    80002cbe:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cc0:	4501                	li	a0,0
    80002cc2:	60e2                	ld	ra,24(sp)
    80002cc4:	6442                	ld	s0,16(sp)
    80002cc6:	64a2                	ld	s1,8(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret

0000000080002ccc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ccc:	1101                	addi	sp,sp,-32
    80002cce:	ec06                	sd	ra,24(sp)
    80002cd0:	e822                	sd	s0,16(sp)
    80002cd2:	e426                	sd	s1,8(sp)
    80002cd4:	e04a                	sd	s2,0(sp)
    80002cd6:	1000                	addi	s0,sp,32
    80002cd8:	84ae                	mv	s1,a1
    80002cda:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cdc:	00000097          	auipc	ra,0x0
    80002ce0:	eaa080e7          	jalr	-342(ra) # 80002b86 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ce4:	864a                	mv	a2,s2
    80002ce6:	85a6                	mv	a1,s1
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	f58080e7          	jalr	-168(ra) # 80002c40 <fetchstr>
}
    80002cf0:	60e2                	ld	ra,24(sp)
    80002cf2:	6442                	ld	s0,16(sp)
    80002cf4:	64a2                	ld	s1,8(sp)
    80002cf6:	6902                	ld	s2,0(sp)
    80002cf8:	6105                	addi	sp,sp,32
    80002cfa:	8082                	ret

0000000080002cfc <syscall>:
[SYS_munmap]  sys_munmap,
};

void
syscall(void)
{
    80002cfc:	1101                	addi	sp,sp,-32
    80002cfe:	ec06                	sd	ra,24(sp)
    80002d00:	e822                	sd	s0,16(sp)
    80002d02:	e426                	sd	s1,8(sp)
    80002d04:	e04a                	sd	s2,0(sp)
    80002d06:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	c9e080e7          	jalr	-866(ra) # 800019a6 <myproc>
    80002d10:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d12:	05853903          	ld	s2,88(a0)
    80002d16:	0a893783          	ld	a5,168(s2)
    80002d1a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d1e:	37fd                	addiw	a5,a5,-1
    80002d20:	4759                	li	a4,22
    80002d22:	00f76f63          	bltu	a4,a5,80002d40 <syscall+0x44>
    80002d26:	00369713          	slli	a4,a3,0x3
    80002d2a:	00005797          	auipc	a5,0x5
    80002d2e:	6be78793          	addi	a5,a5,1726 # 800083e8 <syscalls>
    80002d32:	97ba                	add	a5,a5,a4
    80002d34:	639c                	ld	a5,0(a5)
    80002d36:	c789                	beqz	a5,80002d40 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d38:	9782                	jalr	a5
    80002d3a:	06a93823          	sd	a0,112(s2)
    80002d3e:	a839                	j	80002d5c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d40:	15848613          	addi	a2,s1,344
    80002d44:	5c8c                	lw	a1,56(s1)
    80002d46:	00005517          	auipc	a0,0x5
    80002d4a:	66a50513          	addi	a0,a0,1642 # 800083b0 <states.1739+0x148>
    80002d4e:	ffffe097          	auipc	ra,0xffffe
    80002d52:	82c080e7          	jalr	-2004(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d56:	6cbc                	ld	a5,88(s1)
    80002d58:	577d                	li	a4,-1
    80002d5a:	fbb8                	sd	a4,112(a5)
  }
}
    80002d5c:	60e2                	ld	ra,24(sp)
    80002d5e:	6442                	ld	s0,16(sp)
    80002d60:	64a2                	ld	s1,8(sp)
    80002d62:	6902                	ld	s2,0(sp)
    80002d64:	6105                	addi	sp,sp,32
    80002d66:	8082                	ret

0000000080002d68 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d68:	1101                	addi	sp,sp,-32
    80002d6a:	ec06                	sd	ra,24(sp)
    80002d6c:	e822                	sd	s0,16(sp)
    80002d6e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d70:	fec40593          	addi	a1,s0,-20
    80002d74:	4501                	li	a0,0
    80002d76:	00000097          	auipc	ra,0x0
    80002d7a:	f12080e7          	jalr	-238(ra) # 80002c88 <argint>
    return -1;
    80002d7e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d80:	00054963          	bltz	a0,80002d92 <sys_exit+0x2a>
  exit(n);
    80002d84:	fec42503          	lw	a0,-20(s0)
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	360080e7          	jalr	864(ra) # 800020e8 <exit>
  return 0;  // not reached
    80002d90:	4781                	li	a5,0
}
    80002d92:	853e                	mv	a0,a5
    80002d94:	60e2                	ld	ra,24(sp)
    80002d96:	6442                	ld	s0,16(sp)
    80002d98:	6105                	addi	sp,sp,32
    80002d9a:	8082                	ret

0000000080002d9c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d9c:	1141                	addi	sp,sp,-16
    80002d9e:	e406                	sd	ra,8(sp)
    80002da0:	e022                	sd	s0,0(sp)
    80002da2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002da4:	fffff097          	auipc	ra,0xfffff
    80002da8:	c02080e7          	jalr	-1022(ra) # 800019a6 <myproc>
}
    80002dac:	5d08                	lw	a0,56(a0)
    80002dae:	60a2                	ld	ra,8(sp)
    80002db0:	6402                	ld	s0,0(sp)
    80002db2:	0141                	addi	sp,sp,16
    80002db4:	8082                	ret

0000000080002db6 <sys_fork>:

uint64
sys_fork(void)
{
    80002db6:	1141                	addi	sp,sp,-16
    80002db8:	e406                	sd	ra,8(sp)
    80002dba:	e022                	sd	s0,0(sp)
    80002dbc:	0800                	addi	s0,sp,16
  return fork();
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	fdc080e7          	jalr	-36(ra) # 80001d9a <fork>
}
    80002dc6:	60a2                	ld	ra,8(sp)
    80002dc8:	6402                	ld	s0,0(sp)
    80002dca:	0141                	addi	sp,sp,16
    80002dcc:	8082                	ret

0000000080002dce <sys_wait>:

uint64
sys_wait(void)
{
    80002dce:	1101                	addi	sp,sp,-32
    80002dd0:	ec06                	sd	ra,24(sp)
    80002dd2:	e822                	sd	s0,16(sp)
    80002dd4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002dd6:	fe840593          	addi	a1,s0,-24
    80002dda:	4501                	li	a0,0
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	ece080e7          	jalr	-306(ra) # 80002caa <argaddr>
    80002de4:	87aa                	mv	a5,a0
    return -1;
    80002de6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002de8:	0007c863          	bltz	a5,80002df8 <sys_wait+0x2a>
  return wait(p);
    80002dec:	fe843503          	ld	a0,-24(s0)
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	520080e7          	jalr	1312(ra) # 80002310 <wait>
}
    80002df8:	60e2                	ld	ra,24(sp)
    80002dfa:	6442                	ld	s0,16(sp)
    80002dfc:	6105                	addi	sp,sp,32
    80002dfe:	8082                	ret

0000000080002e00 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e00:	7179                	addi	sp,sp,-48
    80002e02:	f406                	sd	ra,40(sp)
    80002e04:	f022                	sd	s0,32(sp)
    80002e06:	ec26                	sd	s1,24(sp)
    80002e08:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e0a:	fdc40593          	addi	a1,s0,-36
    80002e0e:	4501                	li	a0,0
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	e78080e7          	jalr	-392(ra) # 80002c88 <argint>
    80002e18:	87aa                	mv	a5,a0
    return -1;
    80002e1a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e1c:	0207c063          	bltz	a5,80002e3c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	b86080e7          	jalr	-1146(ra) # 800019a6 <myproc>
    80002e28:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e2a:	fdc42503          	lw	a0,-36(s0)
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	ef8080e7          	jalr	-264(ra) # 80001d26 <growproc>
    80002e36:	00054863          	bltz	a0,80002e46 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e3a:	8526                	mv	a0,s1
}
    80002e3c:	70a2                	ld	ra,40(sp)
    80002e3e:	7402                	ld	s0,32(sp)
    80002e40:	64e2                	ld	s1,24(sp)
    80002e42:	6145                	addi	sp,sp,48
    80002e44:	8082                	ret
    return -1;
    80002e46:	557d                	li	a0,-1
    80002e48:	bfd5                	j	80002e3c <sys_sbrk+0x3c>

0000000080002e4a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e4a:	7139                	addi	sp,sp,-64
    80002e4c:	fc06                	sd	ra,56(sp)
    80002e4e:	f822                	sd	s0,48(sp)
    80002e50:	f426                	sd	s1,40(sp)
    80002e52:	f04a                	sd	s2,32(sp)
    80002e54:	ec4e                	sd	s3,24(sp)
    80002e56:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e58:	fcc40593          	addi	a1,s0,-52
    80002e5c:	4501                	li	a0,0
    80002e5e:	00000097          	auipc	ra,0x0
    80002e62:	e2a080e7          	jalr	-470(ra) # 80002c88 <argint>
    return -1;
    80002e66:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e68:	06054563          	bltz	a0,80002ed2 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e6c:	00020517          	auipc	a0,0x20
    80002e70:	24c50513          	addi	a0,a0,588 # 800230b8 <tickslock>
    80002e74:	ffffe097          	auipc	ra,0xffffe
    80002e78:	d62080e7          	jalr	-670(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002e7c:	00006917          	auipc	s2,0x6
    80002e80:	1b492903          	lw	s2,436(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e84:	fcc42783          	lw	a5,-52(s0)
    80002e88:	cf85                	beqz	a5,80002ec0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e8a:	00020997          	auipc	s3,0x20
    80002e8e:	22e98993          	addi	s3,s3,558 # 800230b8 <tickslock>
    80002e92:	00006497          	auipc	s1,0x6
    80002e96:	19e48493          	addi	s1,s1,414 # 80009030 <ticks>
    if(myproc()->killed){
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	b0c080e7          	jalr	-1268(ra) # 800019a6 <myproc>
    80002ea2:	591c                	lw	a5,48(a0)
    80002ea4:	ef9d                	bnez	a5,80002ee2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002ea6:	85ce                	mv	a1,s3
    80002ea8:	8526                	mv	a0,s1
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	3e8080e7          	jalr	1000(ra) # 80002292 <sleep>
  while(ticks - ticks0 < n){
    80002eb2:	409c                	lw	a5,0(s1)
    80002eb4:	412787bb          	subw	a5,a5,s2
    80002eb8:	fcc42703          	lw	a4,-52(s0)
    80002ebc:	fce7efe3          	bltu	a5,a4,80002e9a <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ec0:	00020517          	auipc	a0,0x20
    80002ec4:	1f850513          	addi	a0,a0,504 # 800230b8 <tickslock>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	dc2080e7          	jalr	-574(ra) # 80000c8a <release>
  return 0;
    80002ed0:	4781                	li	a5,0
}
    80002ed2:	853e                	mv	a0,a5
    80002ed4:	70e2                	ld	ra,56(sp)
    80002ed6:	7442                	ld	s0,48(sp)
    80002ed8:	74a2                	ld	s1,40(sp)
    80002eda:	7902                	ld	s2,32(sp)
    80002edc:	69e2                	ld	s3,24(sp)
    80002ede:	6121                	addi	sp,sp,64
    80002ee0:	8082                	ret
      release(&tickslock);
    80002ee2:	00020517          	auipc	a0,0x20
    80002ee6:	1d650513          	addi	a0,a0,470 # 800230b8 <tickslock>
    80002eea:	ffffe097          	auipc	ra,0xffffe
    80002eee:	da0080e7          	jalr	-608(ra) # 80000c8a <release>
      return -1;
    80002ef2:	57fd                	li	a5,-1
    80002ef4:	bff9                	j	80002ed2 <sys_sleep+0x88>

0000000080002ef6 <sys_kill>:

uint64
sys_kill(void)
{
    80002ef6:	1101                	addi	sp,sp,-32
    80002ef8:	ec06                	sd	ra,24(sp)
    80002efa:	e822                	sd	s0,16(sp)
    80002efc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002efe:	fec40593          	addi	a1,s0,-20
    80002f02:	4501                	li	a0,0
    80002f04:	00000097          	auipc	ra,0x0
    80002f08:	d84080e7          	jalr	-636(ra) # 80002c88 <argint>
    80002f0c:	87aa                	mv	a5,a0
    return -1;
    80002f0e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f10:	0007c863          	bltz	a5,80002f20 <sys_kill+0x2a>
  return kill(pid);
    80002f14:	fec42503          	lw	a0,-20(s0)
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	56a080e7          	jalr	1386(ra) # 80002482 <kill>
}
    80002f20:	60e2                	ld	ra,24(sp)
    80002f22:	6442                	ld	s0,16(sp)
    80002f24:	6105                	addi	sp,sp,32
    80002f26:	8082                	ret

0000000080002f28 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f28:	1101                	addi	sp,sp,-32
    80002f2a:	ec06                	sd	ra,24(sp)
    80002f2c:	e822                	sd	s0,16(sp)
    80002f2e:	e426                	sd	s1,8(sp)
    80002f30:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f32:	00020517          	auipc	a0,0x20
    80002f36:	18650513          	addi	a0,a0,390 # 800230b8 <tickslock>
    80002f3a:	ffffe097          	auipc	ra,0xffffe
    80002f3e:	c9c080e7          	jalr	-868(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002f42:	00006497          	auipc	s1,0x6
    80002f46:	0ee4a483          	lw	s1,238(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f4a:	00020517          	auipc	a0,0x20
    80002f4e:	16e50513          	addi	a0,a0,366 # 800230b8 <tickslock>
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	d38080e7          	jalr	-712(ra) # 80000c8a <release>
  return xticks;
}
    80002f5a:	02049513          	slli	a0,s1,0x20
    80002f5e:	9101                	srli	a0,a0,0x20
    80002f60:	60e2                	ld	ra,24(sp)
    80002f62:	6442                	ld	s0,16(sp)
    80002f64:	64a2                	ld	s1,8(sp)
    80002f66:	6105                	addi	sp,sp,32
    80002f68:	8082                	ret

0000000080002f6a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f6a:	7179                	addi	sp,sp,-48
    80002f6c:	f406                	sd	ra,40(sp)
    80002f6e:	f022                	sd	s0,32(sp)
    80002f70:	ec26                	sd	s1,24(sp)
    80002f72:	e84a                	sd	s2,16(sp)
    80002f74:	e44e                	sd	s3,8(sp)
    80002f76:	e052                	sd	s4,0(sp)
    80002f78:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f7a:	00005597          	auipc	a1,0x5
    80002f7e:	52e58593          	addi	a1,a1,1326 # 800084a8 <syscalls+0xc0>
    80002f82:	00020517          	auipc	a0,0x20
    80002f86:	14e50513          	addi	a0,a0,334 # 800230d0 <bcache>
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	bbc080e7          	jalr	-1092(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f92:	00028797          	auipc	a5,0x28
    80002f96:	13e78793          	addi	a5,a5,318 # 8002b0d0 <bcache+0x8000>
    80002f9a:	00028717          	auipc	a4,0x28
    80002f9e:	39e70713          	addi	a4,a4,926 # 8002b338 <bcache+0x8268>
    80002fa2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fa6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002faa:	00020497          	auipc	s1,0x20
    80002fae:	13e48493          	addi	s1,s1,318 # 800230e8 <bcache+0x18>
    b->next = bcache.head.next;
    80002fb2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fb4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fb6:	00005a17          	auipc	s4,0x5
    80002fba:	4faa0a13          	addi	s4,s4,1274 # 800084b0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002fbe:	2b893783          	ld	a5,696(s2)
    80002fc2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fc4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fc8:	85d2                	mv	a1,s4
    80002fca:	01048513          	addi	a0,s1,16
    80002fce:	00001097          	auipc	ra,0x1
    80002fd2:	4c4080e7          	jalr	1220(ra) # 80004492 <initsleeplock>
    bcache.head.next->prev = b;
    80002fd6:	2b893783          	ld	a5,696(s2)
    80002fda:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fdc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fe0:	45848493          	addi	s1,s1,1112
    80002fe4:	fd349de3          	bne	s1,s3,80002fbe <binit+0x54>
  }
}
    80002fe8:	70a2                	ld	ra,40(sp)
    80002fea:	7402                	ld	s0,32(sp)
    80002fec:	64e2                	ld	s1,24(sp)
    80002fee:	6942                	ld	s2,16(sp)
    80002ff0:	69a2                	ld	s3,8(sp)
    80002ff2:	6a02                	ld	s4,0(sp)
    80002ff4:	6145                	addi	sp,sp,48
    80002ff6:	8082                	ret

0000000080002ff8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ff8:	7179                	addi	sp,sp,-48
    80002ffa:	f406                	sd	ra,40(sp)
    80002ffc:	f022                	sd	s0,32(sp)
    80002ffe:	ec26                	sd	s1,24(sp)
    80003000:	e84a                	sd	s2,16(sp)
    80003002:	e44e                	sd	s3,8(sp)
    80003004:	1800                	addi	s0,sp,48
    80003006:	89aa                	mv	s3,a0
    80003008:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000300a:	00020517          	auipc	a0,0x20
    8000300e:	0c650513          	addi	a0,a0,198 # 800230d0 <bcache>
    80003012:	ffffe097          	auipc	ra,0xffffe
    80003016:	bc4080e7          	jalr	-1084(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000301a:	00028497          	auipc	s1,0x28
    8000301e:	36e4b483          	ld	s1,878(s1) # 8002b388 <bcache+0x82b8>
    80003022:	00028797          	auipc	a5,0x28
    80003026:	31678793          	addi	a5,a5,790 # 8002b338 <bcache+0x8268>
    8000302a:	02f48f63          	beq	s1,a5,80003068 <bread+0x70>
    8000302e:	873e                	mv	a4,a5
    80003030:	a021                	j	80003038 <bread+0x40>
    80003032:	68a4                	ld	s1,80(s1)
    80003034:	02e48a63          	beq	s1,a4,80003068 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003038:	449c                	lw	a5,8(s1)
    8000303a:	ff379ce3          	bne	a5,s3,80003032 <bread+0x3a>
    8000303e:	44dc                	lw	a5,12(s1)
    80003040:	ff2799e3          	bne	a5,s2,80003032 <bread+0x3a>
      b->refcnt++;
    80003044:	40bc                	lw	a5,64(s1)
    80003046:	2785                	addiw	a5,a5,1
    80003048:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000304a:	00020517          	auipc	a0,0x20
    8000304e:	08650513          	addi	a0,a0,134 # 800230d0 <bcache>
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	c38080e7          	jalr	-968(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000305a:	01048513          	addi	a0,s1,16
    8000305e:	00001097          	auipc	ra,0x1
    80003062:	46e080e7          	jalr	1134(ra) # 800044cc <acquiresleep>
      return b;
    80003066:	a8b9                	j	800030c4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003068:	00028497          	auipc	s1,0x28
    8000306c:	3184b483          	ld	s1,792(s1) # 8002b380 <bcache+0x82b0>
    80003070:	00028797          	auipc	a5,0x28
    80003074:	2c878793          	addi	a5,a5,712 # 8002b338 <bcache+0x8268>
    80003078:	00f48863          	beq	s1,a5,80003088 <bread+0x90>
    8000307c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000307e:	40bc                	lw	a5,64(s1)
    80003080:	cf81                	beqz	a5,80003098 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003082:	64a4                	ld	s1,72(s1)
    80003084:	fee49de3          	bne	s1,a4,8000307e <bread+0x86>
  panic("bget: no buffers");
    80003088:	00005517          	auipc	a0,0x5
    8000308c:	43050513          	addi	a0,a0,1072 # 800084b8 <syscalls+0xd0>
    80003090:	ffffd097          	auipc	ra,0xffffd
    80003094:	4a0080e7          	jalr	1184(ra) # 80000530 <panic>
      b->dev = dev;
    80003098:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000309c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030a0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030a4:	4785                	li	a5,1
    800030a6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030a8:	00020517          	auipc	a0,0x20
    800030ac:	02850513          	addi	a0,a0,40 # 800230d0 <bcache>
    800030b0:	ffffe097          	auipc	ra,0xffffe
    800030b4:	bda080e7          	jalr	-1062(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800030b8:	01048513          	addi	a0,s1,16
    800030bc:	00001097          	auipc	ra,0x1
    800030c0:	410080e7          	jalr	1040(ra) # 800044cc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030c4:	409c                	lw	a5,0(s1)
    800030c6:	cb89                	beqz	a5,800030d8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030c8:	8526                	mv	a0,s1
    800030ca:	70a2                	ld	ra,40(sp)
    800030cc:	7402                	ld	s0,32(sp)
    800030ce:	64e2                	ld	s1,24(sp)
    800030d0:	6942                	ld	s2,16(sp)
    800030d2:	69a2                	ld	s3,8(sp)
    800030d4:	6145                	addi	sp,sp,48
    800030d6:	8082                	ret
    virtio_disk_rw(b, 0);
    800030d8:	4581                	li	a1,0
    800030da:	8526                	mv	a0,s1
    800030dc:	00003097          	auipc	ra,0x3
    800030e0:	23a080e7          	jalr	570(ra) # 80006316 <virtio_disk_rw>
    b->valid = 1;
    800030e4:	4785                	li	a5,1
    800030e6:	c09c                	sw	a5,0(s1)
  return b;
    800030e8:	b7c5                	j	800030c8 <bread+0xd0>

00000000800030ea <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030ea:	1101                	addi	sp,sp,-32
    800030ec:	ec06                	sd	ra,24(sp)
    800030ee:	e822                	sd	s0,16(sp)
    800030f0:	e426                	sd	s1,8(sp)
    800030f2:	1000                	addi	s0,sp,32
    800030f4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030f6:	0541                	addi	a0,a0,16
    800030f8:	00001097          	auipc	ra,0x1
    800030fc:	46e080e7          	jalr	1134(ra) # 80004566 <holdingsleep>
    80003100:	cd01                	beqz	a0,80003118 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003102:	4585                	li	a1,1
    80003104:	8526                	mv	a0,s1
    80003106:	00003097          	auipc	ra,0x3
    8000310a:	210080e7          	jalr	528(ra) # 80006316 <virtio_disk_rw>
}
    8000310e:	60e2                	ld	ra,24(sp)
    80003110:	6442                	ld	s0,16(sp)
    80003112:	64a2                	ld	s1,8(sp)
    80003114:	6105                	addi	sp,sp,32
    80003116:	8082                	ret
    panic("bwrite");
    80003118:	00005517          	auipc	a0,0x5
    8000311c:	3b850513          	addi	a0,a0,952 # 800084d0 <syscalls+0xe8>
    80003120:	ffffd097          	auipc	ra,0xffffd
    80003124:	410080e7          	jalr	1040(ra) # 80000530 <panic>

0000000080003128 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003128:	1101                	addi	sp,sp,-32
    8000312a:	ec06                	sd	ra,24(sp)
    8000312c:	e822                	sd	s0,16(sp)
    8000312e:	e426                	sd	s1,8(sp)
    80003130:	e04a                	sd	s2,0(sp)
    80003132:	1000                	addi	s0,sp,32
    80003134:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003136:	01050913          	addi	s2,a0,16
    8000313a:	854a                	mv	a0,s2
    8000313c:	00001097          	auipc	ra,0x1
    80003140:	42a080e7          	jalr	1066(ra) # 80004566 <holdingsleep>
    80003144:	c92d                	beqz	a0,800031b6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003146:	854a                	mv	a0,s2
    80003148:	00001097          	auipc	ra,0x1
    8000314c:	3da080e7          	jalr	986(ra) # 80004522 <releasesleep>

  acquire(&bcache.lock);
    80003150:	00020517          	auipc	a0,0x20
    80003154:	f8050513          	addi	a0,a0,-128 # 800230d0 <bcache>
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	a7e080e7          	jalr	-1410(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003160:	40bc                	lw	a5,64(s1)
    80003162:	37fd                	addiw	a5,a5,-1
    80003164:	0007871b          	sext.w	a4,a5
    80003168:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000316a:	eb05                	bnez	a4,8000319a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000316c:	68bc                	ld	a5,80(s1)
    8000316e:	64b8                	ld	a4,72(s1)
    80003170:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003172:	64bc                	ld	a5,72(s1)
    80003174:	68b8                	ld	a4,80(s1)
    80003176:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003178:	00028797          	auipc	a5,0x28
    8000317c:	f5878793          	addi	a5,a5,-168 # 8002b0d0 <bcache+0x8000>
    80003180:	2b87b703          	ld	a4,696(a5)
    80003184:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003186:	00028717          	auipc	a4,0x28
    8000318a:	1b270713          	addi	a4,a4,434 # 8002b338 <bcache+0x8268>
    8000318e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003190:	2b87b703          	ld	a4,696(a5)
    80003194:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003196:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000319a:	00020517          	auipc	a0,0x20
    8000319e:	f3650513          	addi	a0,a0,-202 # 800230d0 <bcache>
    800031a2:	ffffe097          	auipc	ra,0xffffe
    800031a6:	ae8080e7          	jalr	-1304(ra) # 80000c8a <release>
}
    800031aa:	60e2                	ld	ra,24(sp)
    800031ac:	6442                	ld	s0,16(sp)
    800031ae:	64a2                	ld	s1,8(sp)
    800031b0:	6902                	ld	s2,0(sp)
    800031b2:	6105                	addi	sp,sp,32
    800031b4:	8082                	ret
    panic("brelse");
    800031b6:	00005517          	auipc	a0,0x5
    800031ba:	32250513          	addi	a0,a0,802 # 800084d8 <syscalls+0xf0>
    800031be:	ffffd097          	auipc	ra,0xffffd
    800031c2:	372080e7          	jalr	882(ra) # 80000530 <panic>

00000000800031c6 <bpin>:

void
bpin(struct buf *b) {
    800031c6:	1101                	addi	sp,sp,-32
    800031c8:	ec06                	sd	ra,24(sp)
    800031ca:	e822                	sd	s0,16(sp)
    800031cc:	e426                	sd	s1,8(sp)
    800031ce:	1000                	addi	s0,sp,32
    800031d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031d2:	00020517          	auipc	a0,0x20
    800031d6:	efe50513          	addi	a0,a0,-258 # 800230d0 <bcache>
    800031da:	ffffe097          	auipc	ra,0xffffe
    800031de:	9fc080e7          	jalr	-1540(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800031e2:	40bc                	lw	a5,64(s1)
    800031e4:	2785                	addiw	a5,a5,1
    800031e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031e8:	00020517          	auipc	a0,0x20
    800031ec:	ee850513          	addi	a0,a0,-280 # 800230d0 <bcache>
    800031f0:	ffffe097          	auipc	ra,0xffffe
    800031f4:	a9a080e7          	jalr	-1382(ra) # 80000c8a <release>
}
    800031f8:	60e2                	ld	ra,24(sp)
    800031fa:	6442                	ld	s0,16(sp)
    800031fc:	64a2                	ld	s1,8(sp)
    800031fe:	6105                	addi	sp,sp,32
    80003200:	8082                	ret

0000000080003202 <bunpin>:

void
bunpin(struct buf *b) {
    80003202:	1101                	addi	sp,sp,-32
    80003204:	ec06                	sd	ra,24(sp)
    80003206:	e822                	sd	s0,16(sp)
    80003208:	e426                	sd	s1,8(sp)
    8000320a:	1000                	addi	s0,sp,32
    8000320c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000320e:	00020517          	auipc	a0,0x20
    80003212:	ec250513          	addi	a0,a0,-318 # 800230d0 <bcache>
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	9c0080e7          	jalr	-1600(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000321e:	40bc                	lw	a5,64(s1)
    80003220:	37fd                	addiw	a5,a5,-1
    80003222:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003224:	00020517          	auipc	a0,0x20
    80003228:	eac50513          	addi	a0,a0,-340 # 800230d0 <bcache>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	a5e080e7          	jalr	-1442(ra) # 80000c8a <release>
}
    80003234:	60e2                	ld	ra,24(sp)
    80003236:	6442                	ld	s0,16(sp)
    80003238:	64a2                	ld	s1,8(sp)
    8000323a:	6105                	addi	sp,sp,32
    8000323c:	8082                	ret

000000008000323e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000323e:	1101                	addi	sp,sp,-32
    80003240:	ec06                	sd	ra,24(sp)
    80003242:	e822                	sd	s0,16(sp)
    80003244:	e426                	sd	s1,8(sp)
    80003246:	e04a                	sd	s2,0(sp)
    80003248:	1000                	addi	s0,sp,32
    8000324a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000324c:	00d5d59b          	srliw	a1,a1,0xd
    80003250:	00028797          	auipc	a5,0x28
    80003254:	55c7a783          	lw	a5,1372(a5) # 8002b7ac <sb+0x1c>
    80003258:	9dbd                	addw	a1,a1,a5
    8000325a:	00000097          	auipc	ra,0x0
    8000325e:	d9e080e7          	jalr	-610(ra) # 80002ff8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003262:	0074f713          	andi	a4,s1,7
    80003266:	4785                	li	a5,1
    80003268:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000326c:	14ce                	slli	s1,s1,0x33
    8000326e:	90d9                	srli	s1,s1,0x36
    80003270:	00950733          	add	a4,a0,s1
    80003274:	05874703          	lbu	a4,88(a4)
    80003278:	00e7f6b3          	and	a3,a5,a4
    8000327c:	c69d                	beqz	a3,800032aa <bfree+0x6c>
    8000327e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003280:	94aa                	add	s1,s1,a0
    80003282:	fff7c793          	not	a5,a5
    80003286:	8ff9                	and	a5,a5,a4
    80003288:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000328c:	00001097          	auipc	ra,0x1
    80003290:	118080e7          	jalr	280(ra) # 800043a4 <log_write>
  brelse(bp);
    80003294:	854a                	mv	a0,s2
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	e92080e7          	jalr	-366(ra) # 80003128 <brelse>
}
    8000329e:	60e2                	ld	ra,24(sp)
    800032a0:	6442                	ld	s0,16(sp)
    800032a2:	64a2                	ld	s1,8(sp)
    800032a4:	6902                	ld	s2,0(sp)
    800032a6:	6105                	addi	sp,sp,32
    800032a8:	8082                	ret
    panic("freeing free block");
    800032aa:	00005517          	auipc	a0,0x5
    800032ae:	23650513          	addi	a0,a0,566 # 800084e0 <syscalls+0xf8>
    800032b2:	ffffd097          	auipc	ra,0xffffd
    800032b6:	27e080e7          	jalr	638(ra) # 80000530 <panic>

00000000800032ba <balloc>:
{
    800032ba:	711d                	addi	sp,sp,-96
    800032bc:	ec86                	sd	ra,88(sp)
    800032be:	e8a2                	sd	s0,80(sp)
    800032c0:	e4a6                	sd	s1,72(sp)
    800032c2:	e0ca                	sd	s2,64(sp)
    800032c4:	fc4e                	sd	s3,56(sp)
    800032c6:	f852                	sd	s4,48(sp)
    800032c8:	f456                	sd	s5,40(sp)
    800032ca:	f05a                	sd	s6,32(sp)
    800032cc:	ec5e                	sd	s7,24(sp)
    800032ce:	e862                	sd	s8,16(sp)
    800032d0:	e466                	sd	s9,8(sp)
    800032d2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032d4:	00028797          	auipc	a5,0x28
    800032d8:	4c07a783          	lw	a5,1216(a5) # 8002b794 <sb+0x4>
    800032dc:	cbd1                	beqz	a5,80003370 <balloc+0xb6>
    800032de:	8baa                	mv	s7,a0
    800032e0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032e2:	00028b17          	auipc	s6,0x28
    800032e6:	4aeb0b13          	addi	s6,s6,1198 # 8002b790 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ea:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032ec:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ee:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032f0:	6c89                	lui	s9,0x2
    800032f2:	a831                	j	8000330e <balloc+0x54>
    brelse(bp);
    800032f4:	854a                	mv	a0,s2
    800032f6:	00000097          	auipc	ra,0x0
    800032fa:	e32080e7          	jalr	-462(ra) # 80003128 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032fe:	015c87bb          	addw	a5,s9,s5
    80003302:	00078a9b          	sext.w	s5,a5
    80003306:	004b2703          	lw	a4,4(s6)
    8000330a:	06eaf363          	bgeu	s5,a4,80003370 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000330e:	41fad79b          	sraiw	a5,s5,0x1f
    80003312:	0137d79b          	srliw	a5,a5,0x13
    80003316:	015787bb          	addw	a5,a5,s5
    8000331a:	40d7d79b          	sraiw	a5,a5,0xd
    8000331e:	01cb2583          	lw	a1,28(s6)
    80003322:	9dbd                	addw	a1,a1,a5
    80003324:	855e                	mv	a0,s7
    80003326:	00000097          	auipc	ra,0x0
    8000332a:	cd2080e7          	jalr	-814(ra) # 80002ff8 <bread>
    8000332e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003330:	004b2503          	lw	a0,4(s6)
    80003334:	000a849b          	sext.w	s1,s5
    80003338:	8662                	mv	a2,s8
    8000333a:	faa4fde3          	bgeu	s1,a0,800032f4 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000333e:	41f6579b          	sraiw	a5,a2,0x1f
    80003342:	01d7d69b          	srliw	a3,a5,0x1d
    80003346:	00c6873b          	addw	a4,a3,a2
    8000334a:	00777793          	andi	a5,a4,7
    8000334e:	9f95                	subw	a5,a5,a3
    80003350:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003354:	4037571b          	sraiw	a4,a4,0x3
    80003358:	00e906b3          	add	a3,s2,a4
    8000335c:	0586c683          	lbu	a3,88(a3)
    80003360:	00d7f5b3          	and	a1,a5,a3
    80003364:	cd91                	beqz	a1,80003380 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003366:	2605                	addiw	a2,a2,1
    80003368:	2485                	addiw	s1,s1,1
    8000336a:	fd4618e3          	bne	a2,s4,8000333a <balloc+0x80>
    8000336e:	b759                	j	800032f4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003370:	00005517          	auipc	a0,0x5
    80003374:	18850513          	addi	a0,a0,392 # 800084f8 <syscalls+0x110>
    80003378:	ffffd097          	auipc	ra,0xffffd
    8000337c:	1b8080e7          	jalr	440(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003380:	974a                	add	a4,a4,s2
    80003382:	8fd5                	or	a5,a5,a3
    80003384:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003388:	854a                	mv	a0,s2
    8000338a:	00001097          	auipc	ra,0x1
    8000338e:	01a080e7          	jalr	26(ra) # 800043a4 <log_write>
        brelse(bp);
    80003392:	854a                	mv	a0,s2
    80003394:	00000097          	auipc	ra,0x0
    80003398:	d94080e7          	jalr	-620(ra) # 80003128 <brelse>
  bp = bread(dev, bno);
    8000339c:	85a6                	mv	a1,s1
    8000339e:	855e                	mv	a0,s7
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	c58080e7          	jalr	-936(ra) # 80002ff8 <bread>
    800033a8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033aa:	40000613          	li	a2,1024
    800033ae:	4581                	li	a1,0
    800033b0:	05850513          	addi	a0,a0,88
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	91e080e7          	jalr	-1762(ra) # 80000cd2 <memset>
  log_write(bp);
    800033bc:	854a                	mv	a0,s2
    800033be:	00001097          	auipc	ra,0x1
    800033c2:	fe6080e7          	jalr	-26(ra) # 800043a4 <log_write>
  brelse(bp);
    800033c6:	854a                	mv	a0,s2
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	d60080e7          	jalr	-672(ra) # 80003128 <brelse>
}
    800033d0:	8526                	mv	a0,s1
    800033d2:	60e6                	ld	ra,88(sp)
    800033d4:	6446                	ld	s0,80(sp)
    800033d6:	64a6                	ld	s1,72(sp)
    800033d8:	6906                	ld	s2,64(sp)
    800033da:	79e2                	ld	s3,56(sp)
    800033dc:	7a42                	ld	s4,48(sp)
    800033de:	7aa2                	ld	s5,40(sp)
    800033e0:	7b02                	ld	s6,32(sp)
    800033e2:	6be2                	ld	s7,24(sp)
    800033e4:	6c42                	ld	s8,16(sp)
    800033e6:	6ca2                	ld	s9,8(sp)
    800033e8:	6125                	addi	sp,sp,96
    800033ea:	8082                	ret

00000000800033ec <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033ec:	7179                	addi	sp,sp,-48
    800033ee:	f406                	sd	ra,40(sp)
    800033f0:	f022                	sd	s0,32(sp)
    800033f2:	ec26                	sd	s1,24(sp)
    800033f4:	e84a                	sd	s2,16(sp)
    800033f6:	e44e                	sd	s3,8(sp)
    800033f8:	e052                	sd	s4,0(sp)
    800033fa:	1800                	addi	s0,sp,48
    800033fc:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033fe:	47ad                	li	a5,11
    80003400:	04b7fe63          	bgeu	a5,a1,8000345c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003404:	ff45849b          	addiw	s1,a1,-12
    80003408:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000340c:	0ff00793          	li	a5,255
    80003410:	0ae7e363          	bltu	a5,a4,800034b6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003414:	08052583          	lw	a1,128(a0)
    80003418:	c5ad                	beqz	a1,80003482 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000341a:	00092503          	lw	a0,0(s2)
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	bda080e7          	jalr	-1062(ra) # 80002ff8 <bread>
    80003426:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003428:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000342c:	02049593          	slli	a1,s1,0x20
    80003430:	9181                	srli	a1,a1,0x20
    80003432:	058a                	slli	a1,a1,0x2
    80003434:	00b784b3          	add	s1,a5,a1
    80003438:	0004a983          	lw	s3,0(s1)
    8000343c:	04098d63          	beqz	s3,80003496 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003440:	8552                	mv	a0,s4
    80003442:	00000097          	auipc	ra,0x0
    80003446:	ce6080e7          	jalr	-794(ra) # 80003128 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000344a:	854e                	mv	a0,s3
    8000344c:	70a2                	ld	ra,40(sp)
    8000344e:	7402                	ld	s0,32(sp)
    80003450:	64e2                	ld	s1,24(sp)
    80003452:	6942                	ld	s2,16(sp)
    80003454:	69a2                	ld	s3,8(sp)
    80003456:	6a02                	ld	s4,0(sp)
    80003458:	6145                	addi	sp,sp,48
    8000345a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000345c:	02059493          	slli	s1,a1,0x20
    80003460:	9081                	srli	s1,s1,0x20
    80003462:	048a                	slli	s1,s1,0x2
    80003464:	94aa                	add	s1,s1,a0
    80003466:	0504a983          	lw	s3,80(s1)
    8000346a:	fe0990e3          	bnez	s3,8000344a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000346e:	4108                	lw	a0,0(a0)
    80003470:	00000097          	auipc	ra,0x0
    80003474:	e4a080e7          	jalr	-438(ra) # 800032ba <balloc>
    80003478:	0005099b          	sext.w	s3,a0
    8000347c:	0534a823          	sw	s3,80(s1)
    80003480:	b7e9                	j	8000344a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003482:	4108                	lw	a0,0(a0)
    80003484:	00000097          	auipc	ra,0x0
    80003488:	e36080e7          	jalr	-458(ra) # 800032ba <balloc>
    8000348c:	0005059b          	sext.w	a1,a0
    80003490:	08b92023          	sw	a1,128(s2)
    80003494:	b759                	j	8000341a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003496:	00092503          	lw	a0,0(s2)
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	e20080e7          	jalr	-480(ra) # 800032ba <balloc>
    800034a2:	0005099b          	sext.w	s3,a0
    800034a6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034aa:	8552                	mv	a0,s4
    800034ac:	00001097          	auipc	ra,0x1
    800034b0:	ef8080e7          	jalr	-264(ra) # 800043a4 <log_write>
    800034b4:	b771                	j	80003440 <bmap+0x54>
  panic("bmap: out of range");
    800034b6:	00005517          	auipc	a0,0x5
    800034ba:	05a50513          	addi	a0,a0,90 # 80008510 <syscalls+0x128>
    800034be:	ffffd097          	auipc	ra,0xffffd
    800034c2:	072080e7          	jalr	114(ra) # 80000530 <panic>

00000000800034c6 <iget>:
{
    800034c6:	7179                	addi	sp,sp,-48
    800034c8:	f406                	sd	ra,40(sp)
    800034ca:	f022                	sd	s0,32(sp)
    800034cc:	ec26                	sd	s1,24(sp)
    800034ce:	e84a                	sd	s2,16(sp)
    800034d0:	e44e                	sd	s3,8(sp)
    800034d2:	e052                	sd	s4,0(sp)
    800034d4:	1800                	addi	s0,sp,48
    800034d6:	89aa                	mv	s3,a0
    800034d8:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800034da:	00028517          	auipc	a0,0x28
    800034de:	2d650513          	addi	a0,a0,726 # 8002b7b0 <icache>
    800034e2:	ffffd097          	auipc	ra,0xffffd
    800034e6:	6f4080e7          	jalr	1780(ra) # 80000bd6 <acquire>
  empty = 0;
    800034ea:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034ec:	00028497          	auipc	s1,0x28
    800034f0:	2dc48493          	addi	s1,s1,732 # 8002b7c8 <icache+0x18>
    800034f4:	0002a697          	auipc	a3,0x2a
    800034f8:	d6468693          	addi	a3,a3,-668 # 8002d258 <log>
    800034fc:	a039                	j	8000350a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034fe:	02090b63          	beqz	s2,80003534 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003502:	08848493          	addi	s1,s1,136
    80003506:	02d48a63          	beq	s1,a3,8000353a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000350a:	449c                	lw	a5,8(s1)
    8000350c:	fef059e3          	blez	a5,800034fe <iget+0x38>
    80003510:	4098                	lw	a4,0(s1)
    80003512:	ff3716e3          	bne	a4,s3,800034fe <iget+0x38>
    80003516:	40d8                	lw	a4,4(s1)
    80003518:	ff4713e3          	bne	a4,s4,800034fe <iget+0x38>
      ip->ref++;
    8000351c:	2785                	addiw	a5,a5,1
    8000351e:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003520:	00028517          	auipc	a0,0x28
    80003524:	29050513          	addi	a0,a0,656 # 8002b7b0 <icache>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	762080e7          	jalr	1890(ra) # 80000c8a <release>
      return ip;
    80003530:	8926                	mv	s2,s1
    80003532:	a03d                	j	80003560 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003534:	f7f9                	bnez	a5,80003502 <iget+0x3c>
    80003536:	8926                	mv	s2,s1
    80003538:	b7e9                	j	80003502 <iget+0x3c>
  if(empty == 0)
    8000353a:	02090c63          	beqz	s2,80003572 <iget+0xac>
  ip->dev = dev;
    8000353e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003542:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003546:	4785                	li	a5,1
    80003548:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000354c:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003550:	00028517          	auipc	a0,0x28
    80003554:	26050513          	addi	a0,a0,608 # 8002b7b0 <icache>
    80003558:	ffffd097          	auipc	ra,0xffffd
    8000355c:	732080e7          	jalr	1842(ra) # 80000c8a <release>
}
    80003560:	854a                	mv	a0,s2
    80003562:	70a2                	ld	ra,40(sp)
    80003564:	7402                	ld	s0,32(sp)
    80003566:	64e2                	ld	s1,24(sp)
    80003568:	6942                	ld	s2,16(sp)
    8000356a:	69a2                	ld	s3,8(sp)
    8000356c:	6a02                	ld	s4,0(sp)
    8000356e:	6145                	addi	sp,sp,48
    80003570:	8082                	ret
    panic("iget: no inodes");
    80003572:	00005517          	auipc	a0,0x5
    80003576:	fb650513          	addi	a0,a0,-74 # 80008528 <syscalls+0x140>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	fb6080e7          	jalr	-74(ra) # 80000530 <panic>

0000000080003582 <fsinit>:
fsinit(int dev) {
    80003582:	7179                	addi	sp,sp,-48
    80003584:	f406                	sd	ra,40(sp)
    80003586:	f022                	sd	s0,32(sp)
    80003588:	ec26                	sd	s1,24(sp)
    8000358a:	e84a                	sd	s2,16(sp)
    8000358c:	e44e                	sd	s3,8(sp)
    8000358e:	1800                	addi	s0,sp,48
    80003590:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003592:	4585                	li	a1,1
    80003594:	00000097          	auipc	ra,0x0
    80003598:	a64080e7          	jalr	-1436(ra) # 80002ff8 <bread>
    8000359c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000359e:	00028997          	auipc	s3,0x28
    800035a2:	1f298993          	addi	s3,s3,498 # 8002b790 <sb>
    800035a6:	02000613          	li	a2,32
    800035aa:	05850593          	addi	a1,a0,88
    800035ae:	854e                	mv	a0,s3
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	782080e7          	jalr	1922(ra) # 80000d32 <memmove>
  brelse(bp);
    800035b8:	8526                	mv	a0,s1
    800035ba:	00000097          	auipc	ra,0x0
    800035be:	b6e080e7          	jalr	-1170(ra) # 80003128 <brelse>
  if(sb.magic != FSMAGIC)
    800035c2:	0009a703          	lw	a4,0(s3)
    800035c6:	102037b7          	lui	a5,0x10203
    800035ca:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035ce:	02f71263          	bne	a4,a5,800035f2 <fsinit+0x70>
  initlog(dev, &sb);
    800035d2:	00028597          	auipc	a1,0x28
    800035d6:	1be58593          	addi	a1,a1,446 # 8002b790 <sb>
    800035da:	854a                	mv	a0,s2
    800035dc:	00001097          	auipc	ra,0x1
    800035e0:	b4c080e7          	jalr	-1204(ra) # 80004128 <initlog>
}
    800035e4:	70a2                	ld	ra,40(sp)
    800035e6:	7402                	ld	s0,32(sp)
    800035e8:	64e2                	ld	s1,24(sp)
    800035ea:	6942                	ld	s2,16(sp)
    800035ec:	69a2                	ld	s3,8(sp)
    800035ee:	6145                	addi	sp,sp,48
    800035f0:	8082                	ret
    panic("invalid file system");
    800035f2:	00005517          	auipc	a0,0x5
    800035f6:	f4650513          	addi	a0,a0,-186 # 80008538 <syscalls+0x150>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	f36080e7          	jalr	-202(ra) # 80000530 <panic>

0000000080003602 <iinit>:
{
    80003602:	7179                	addi	sp,sp,-48
    80003604:	f406                	sd	ra,40(sp)
    80003606:	f022                	sd	s0,32(sp)
    80003608:	ec26                	sd	s1,24(sp)
    8000360a:	e84a                	sd	s2,16(sp)
    8000360c:	e44e                	sd	s3,8(sp)
    8000360e:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003610:	00005597          	auipc	a1,0x5
    80003614:	f4058593          	addi	a1,a1,-192 # 80008550 <syscalls+0x168>
    80003618:	00028517          	auipc	a0,0x28
    8000361c:	19850513          	addi	a0,a0,408 # 8002b7b0 <icache>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	526080e7          	jalr	1318(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003628:	00028497          	auipc	s1,0x28
    8000362c:	1b048493          	addi	s1,s1,432 # 8002b7d8 <icache+0x28>
    80003630:	0002a997          	auipc	s3,0x2a
    80003634:	c3898993          	addi	s3,s3,-968 # 8002d268 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003638:	00005917          	auipc	s2,0x5
    8000363c:	f2090913          	addi	s2,s2,-224 # 80008558 <syscalls+0x170>
    80003640:	85ca                	mv	a1,s2
    80003642:	8526                	mv	a0,s1
    80003644:	00001097          	auipc	ra,0x1
    80003648:	e4e080e7          	jalr	-434(ra) # 80004492 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000364c:	08848493          	addi	s1,s1,136
    80003650:	ff3498e3          	bne	s1,s3,80003640 <iinit+0x3e>
}
    80003654:	70a2                	ld	ra,40(sp)
    80003656:	7402                	ld	s0,32(sp)
    80003658:	64e2                	ld	s1,24(sp)
    8000365a:	6942                	ld	s2,16(sp)
    8000365c:	69a2                	ld	s3,8(sp)
    8000365e:	6145                	addi	sp,sp,48
    80003660:	8082                	ret

0000000080003662 <ialloc>:
{
    80003662:	715d                	addi	sp,sp,-80
    80003664:	e486                	sd	ra,72(sp)
    80003666:	e0a2                	sd	s0,64(sp)
    80003668:	fc26                	sd	s1,56(sp)
    8000366a:	f84a                	sd	s2,48(sp)
    8000366c:	f44e                	sd	s3,40(sp)
    8000366e:	f052                	sd	s4,32(sp)
    80003670:	ec56                	sd	s5,24(sp)
    80003672:	e85a                	sd	s6,16(sp)
    80003674:	e45e                	sd	s7,8(sp)
    80003676:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003678:	00028717          	auipc	a4,0x28
    8000367c:	12472703          	lw	a4,292(a4) # 8002b79c <sb+0xc>
    80003680:	4785                	li	a5,1
    80003682:	04e7fa63          	bgeu	a5,a4,800036d6 <ialloc+0x74>
    80003686:	8aaa                	mv	s5,a0
    80003688:	8bae                	mv	s7,a1
    8000368a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000368c:	00028a17          	auipc	s4,0x28
    80003690:	104a0a13          	addi	s4,s4,260 # 8002b790 <sb>
    80003694:	00048b1b          	sext.w	s6,s1
    80003698:	0044d593          	srli	a1,s1,0x4
    8000369c:	018a2783          	lw	a5,24(s4)
    800036a0:	9dbd                	addw	a1,a1,a5
    800036a2:	8556                	mv	a0,s5
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	954080e7          	jalr	-1708(ra) # 80002ff8 <bread>
    800036ac:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036ae:	05850993          	addi	s3,a0,88
    800036b2:	00f4f793          	andi	a5,s1,15
    800036b6:	079a                	slli	a5,a5,0x6
    800036b8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036ba:	00099783          	lh	a5,0(s3)
    800036be:	c785                	beqz	a5,800036e6 <ialloc+0x84>
    brelse(bp);
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	a68080e7          	jalr	-1432(ra) # 80003128 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036c8:	0485                	addi	s1,s1,1
    800036ca:	00ca2703          	lw	a4,12(s4)
    800036ce:	0004879b          	sext.w	a5,s1
    800036d2:	fce7e1e3          	bltu	a5,a4,80003694 <ialloc+0x32>
  panic("ialloc: no inodes");
    800036d6:	00005517          	auipc	a0,0x5
    800036da:	e8a50513          	addi	a0,a0,-374 # 80008560 <syscalls+0x178>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	e52080e7          	jalr	-430(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    800036e6:	04000613          	li	a2,64
    800036ea:	4581                	li	a1,0
    800036ec:	854e                	mv	a0,s3
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	5e4080e7          	jalr	1508(ra) # 80000cd2 <memset>
      dip->type = type;
    800036f6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036fa:	854a                	mv	a0,s2
    800036fc:	00001097          	auipc	ra,0x1
    80003700:	ca8080e7          	jalr	-856(ra) # 800043a4 <log_write>
      brelse(bp);
    80003704:	854a                	mv	a0,s2
    80003706:	00000097          	auipc	ra,0x0
    8000370a:	a22080e7          	jalr	-1502(ra) # 80003128 <brelse>
      return iget(dev, inum);
    8000370e:	85da                	mv	a1,s6
    80003710:	8556                	mv	a0,s5
    80003712:	00000097          	auipc	ra,0x0
    80003716:	db4080e7          	jalr	-588(ra) # 800034c6 <iget>
}
    8000371a:	60a6                	ld	ra,72(sp)
    8000371c:	6406                	ld	s0,64(sp)
    8000371e:	74e2                	ld	s1,56(sp)
    80003720:	7942                	ld	s2,48(sp)
    80003722:	79a2                	ld	s3,40(sp)
    80003724:	7a02                	ld	s4,32(sp)
    80003726:	6ae2                	ld	s5,24(sp)
    80003728:	6b42                	ld	s6,16(sp)
    8000372a:	6ba2                	ld	s7,8(sp)
    8000372c:	6161                	addi	sp,sp,80
    8000372e:	8082                	ret

0000000080003730 <iupdate>:
{
    80003730:	1101                	addi	sp,sp,-32
    80003732:	ec06                	sd	ra,24(sp)
    80003734:	e822                	sd	s0,16(sp)
    80003736:	e426                	sd	s1,8(sp)
    80003738:	e04a                	sd	s2,0(sp)
    8000373a:	1000                	addi	s0,sp,32
    8000373c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000373e:	415c                	lw	a5,4(a0)
    80003740:	0047d79b          	srliw	a5,a5,0x4
    80003744:	00028597          	auipc	a1,0x28
    80003748:	0645a583          	lw	a1,100(a1) # 8002b7a8 <sb+0x18>
    8000374c:	9dbd                	addw	a1,a1,a5
    8000374e:	4108                	lw	a0,0(a0)
    80003750:	00000097          	auipc	ra,0x0
    80003754:	8a8080e7          	jalr	-1880(ra) # 80002ff8 <bread>
    80003758:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000375a:	05850793          	addi	a5,a0,88
    8000375e:	40c8                	lw	a0,4(s1)
    80003760:	893d                	andi	a0,a0,15
    80003762:	051a                	slli	a0,a0,0x6
    80003764:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003766:	04449703          	lh	a4,68(s1)
    8000376a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000376e:	04649703          	lh	a4,70(s1)
    80003772:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003776:	04849703          	lh	a4,72(s1)
    8000377a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000377e:	04a49703          	lh	a4,74(s1)
    80003782:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003786:	44f8                	lw	a4,76(s1)
    80003788:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000378a:	03400613          	li	a2,52
    8000378e:	05048593          	addi	a1,s1,80
    80003792:	0531                	addi	a0,a0,12
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	59e080e7          	jalr	1438(ra) # 80000d32 <memmove>
  log_write(bp);
    8000379c:	854a                	mv	a0,s2
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	c06080e7          	jalr	-1018(ra) # 800043a4 <log_write>
  brelse(bp);
    800037a6:	854a                	mv	a0,s2
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	980080e7          	jalr	-1664(ra) # 80003128 <brelse>
}
    800037b0:	60e2                	ld	ra,24(sp)
    800037b2:	6442                	ld	s0,16(sp)
    800037b4:	64a2                	ld	s1,8(sp)
    800037b6:	6902                	ld	s2,0(sp)
    800037b8:	6105                	addi	sp,sp,32
    800037ba:	8082                	ret

00000000800037bc <idup>:
{
    800037bc:	1101                	addi	sp,sp,-32
    800037be:	ec06                	sd	ra,24(sp)
    800037c0:	e822                	sd	s0,16(sp)
    800037c2:	e426                	sd	s1,8(sp)
    800037c4:	1000                	addi	s0,sp,32
    800037c6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800037c8:	00028517          	auipc	a0,0x28
    800037cc:	fe850513          	addi	a0,a0,-24 # 8002b7b0 <icache>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	406080e7          	jalr	1030(ra) # 80000bd6 <acquire>
  ip->ref++;
    800037d8:	449c                	lw	a5,8(s1)
    800037da:	2785                	addiw	a5,a5,1
    800037dc:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037de:	00028517          	auipc	a0,0x28
    800037e2:	fd250513          	addi	a0,a0,-46 # 8002b7b0 <icache>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	4a4080e7          	jalr	1188(ra) # 80000c8a <release>
}
    800037ee:	8526                	mv	a0,s1
    800037f0:	60e2                	ld	ra,24(sp)
    800037f2:	6442                	ld	s0,16(sp)
    800037f4:	64a2                	ld	s1,8(sp)
    800037f6:	6105                	addi	sp,sp,32
    800037f8:	8082                	ret

00000000800037fa <ilock>:
{
    800037fa:	1101                	addi	sp,sp,-32
    800037fc:	ec06                	sd	ra,24(sp)
    800037fe:	e822                	sd	s0,16(sp)
    80003800:	e426                	sd	s1,8(sp)
    80003802:	e04a                	sd	s2,0(sp)
    80003804:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003806:	c115                	beqz	a0,8000382a <ilock+0x30>
    80003808:	84aa                	mv	s1,a0
    8000380a:	451c                	lw	a5,8(a0)
    8000380c:	00f05f63          	blez	a5,8000382a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003810:	0541                	addi	a0,a0,16
    80003812:	00001097          	auipc	ra,0x1
    80003816:	cba080e7          	jalr	-838(ra) # 800044cc <acquiresleep>
  if(ip->valid == 0){
    8000381a:	40bc                	lw	a5,64(s1)
    8000381c:	cf99                	beqz	a5,8000383a <ilock+0x40>
}
    8000381e:	60e2                	ld	ra,24(sp)
    80003820:	6442                	ld	s0,16(sp)
    80003822:	64a2                	ld	s1,8(sp)
    80003824:	6902                	ld	s2,0(sp)
    80003826:	6105                	addi	sp,sp,32
    80003828:	8082                	ret
    panic("ilock");
    8000382a:	00005517          	auipc	a0,0x5
    8000382e:	d4e50513          	addi	a0,a0,-690 # 80008578 <syscalls+0x190>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	cfe080e7          	jalr	-770(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000383a:	40dc                	lw	a5,4(s1)
    8000383c:	0047d79b          	srliw	a5,a5,0x4
    80003840:	00028597          	auipc	a1,0x28
    80003844:	f685a583          	lw	a1,-152(a1) # 8002b7a8 <sb+0x18>
    80003848:	9dbd                	addw	a1,a1,a5
    8000384a:	4088                	lw	a0,0(s1)
    8000384c:	fffff097          	auipc	ra,0xfffff
    80003850:	7ac080e7          	jalr	1964(ra) # 80002ff8 <bread>
    80003854:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003856:	05850593          	addi	a1,a0,88
    8000385a:	40dc                	lw	a5,4(s1)
    8000385c:	8bbd                	andi	a5,a5,15
    8000385e:	079a                	slli	a5,a5,0x6
    80003860:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003862:	00059783          	lh	a5,0(a1)
    80003866:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000386a:	00259783          	lh	a5,2(a1)
    8000386e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003872:	00459783          	lh	a5,4(a1)
    80003876:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000387a:	00659783          	lh	a5,6(a1)
    8000387e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003882:	459c                	lw	a5,8(a1)
    80003884:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003886:	03400613          	li	a2,52
    8000388a:	05b1                	addi	a1,a1,12
    8000388c:	05048513          	addi	a0,s1,80
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	4a2080e7          	jalr	1186(ra) # 80000d32 <memmove>
    brelse(bp);
    80003898:	854a                	mv	a0,s2
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	88e080e7          	jalr	-1906(ra) # 80003128 <brelse>
    ip->valid = 1;
    800038a2:	4785                	li	a5,1
    800038a4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038a6:	04449783          	lh	a5,68(s1)
    800038aa:	fbb5                	bnez	a5,8000381e <ilock+0x24>
      panic("ilock: no type");
    800038ac:	00005517          	auipc	a0,0x5
    800038b0:	cd450513          	addi	a0,a0,-812 # 80008580 <syscalls+0x198>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	c7c080e7          	jalr	-900(ra) # 80000530 <panic>

00000000800038bc <iunlock>:
{
    800038bc:	1101                	addi	sp,sp,-32
    800038be:	ec06                	sd	ra,24(sp)
    800038c0:	e822                	sd	s0,16(sp)
    800038c2:	e426                	sd	s1,8(sp)
    800038c4:	e04a                	sd	s2,0(sp)
    800038c6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038c8:	c905                	beqz	a0,800038f8 <iunlock+0x3c>
    800038ca:	84aa                	mv	s1,a0
    800038cc:	01050913          	addi	s2,a0,16
    800038d0:	854a                	mv	a0,s2
    800038d2:	00001097          	auipc	ra,0x1
    800038d6:	c94080e7          	jalr	-876(ra) # 80004566 <holdingsleep>
    800038da:	cd19                	beqz	a0,800038f8 <iunlock+0x3c>
    800038dc:	449c                	lw	a5,8(s1)
    800038de:	00f05d63          	blez	a5,800038f8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038e2:	854a                	mv	a0,s2
    800038e4:	00001097          	auipc	ra,0x1
    800038e8:	c3e080e7          	jalr	-962(ra) # 80004522 <releasesleep>
}
    800038ec:	60e2                	ld	ra,24(sp)
    800038ee:	6442                	ld	s0,16(sp)
    800038f0:	64a2                	ld	s1,8(sp)
    800038f2:	6902                	ld	s2,0(sp)
    800038f4:	6105                	addi	sp,sp,32
    800038f6:	8082                	ret
    panic("iunlock");
    800038f8:	00005517          	auipc	a0,0x5
    800038fc:	c9850513          	addi	a0,a0,-872 # 80008590 <syscalls+0x1a8>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	c30080e7          	jalr	-976(ra) # 80000530 <panic>

0000000080003908 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003908:	7179                	addi	sp,sp,-48
    8000390a:	f406                	sd	ra,40(sp)
    8000390c:	f022                	sd	s0,32(sp)
    8000390e:	ec26                	sd	s1,24(sp)
    80003910:	e84a                	sd	s2,16(sp)
    80003912:	e44e                	sd	s3,8(sp)
    80003914:	e052                	sd	s4,0(sp)
    80003916:	1800                	addi	s0,sp,48
    80003918:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000391a:	05050493          	addi	s1,a0,80
    8000391e:	08050913          	addi	s2,a0,128
    80003922:	a021                	j	8000392a <itrunc+0x22>
    80003924:	0491                	addi	s1,s1,4
    80003926:	01248d63          	beq	s1,s2,80003940 <itrunc+0x38>
    if(ip->addrs[i]){
    8000392a:	408c                	lw	a1,0(s1)
    8000392c:	dde5                	beqz	a1,80003924 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000392e:	0009a503          	lw	a0,0(s3)
    80003932:	00000097          	auipc	ra,0x0
    80003936:	90c080e7          	jalr	-1780(ra) # 8000323e <bfree>
      ip->addrs[i] = 0;
    8000393a:	0004a023          	sw	zero,0(s1)
    8000393e:	b7dd                	j	80003924 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003940:	0809a583          	lw	a1,128(s3)
    80003944:	e185                	bnez	a1,80003964 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003946:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000394a:	854e                	mv	a0,s3
    8000394c:	00000097          	auipc	ra,0x0
    80003950:	de4080e7          	jalr	-540(ra) # 80003730 <iupdate>
}
    80003954:	70a2                	ld	ra,40(sp)
    80003956:	7402                	ld	s0,32(sp)
    80003958:	64e2                	ld	s1,24(sp)
    8000395a:	6942                	ld	s2,16(sp)
    8000395c:	69a2                	ld	s3,8(sp)
    8000395e:	6a02                	ld	s4,0(sp)
    80003960:	6145                	addi	sp,sp,48
    80003962:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003964:	0009a503          	lw	a0,0(s3)
    80003968:	fffff097          	auipc	ra,0xfffff
    8000396c:	690080e7          	jalr	1680(ra) # 80002ff8 <bread>
    80003970:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003972:	05850493          	addi	s1,a0,88
    80003976:	45850913          	addi	s2,a0,1112
    8000397a:	a811                	j	8000398e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000397c:	0009a503          	lw	a0,0(s3)
    80003980:	00000097          	auipc	ra,0x0
    80003984:	8be080e7          	jalr	-1858(ra) # 8000323e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003988:	0491                	addi	s1,s1,4
    8000398a:	01248563          	beq	s1,s2,80003994 <itrunc+0x8c>
      if(a[j])
    8000398e:	408c                	lw	a1,0(s1)
    80003990:	dde5                	beqz	a1,80003988 <itrunc+0x80>
    80003992:	b7ed                	j	8000397c <itrunc+0x74>
    brelse(bp);
    80003994:	8552                	mv	a0,s4
    80003996:	fffff097          	auipc	ra,0xfffff
    8000399a:	792080e7          	jalr	1938(ra) # 80003128 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000399e:	0809a583          	lw	a1,128(s3)
    800039a2:	0009a503          	lw	a0,0(s3)
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	898080e7          	jalr	-1896(ra) # 8000323e <bfree>
    ip->addrs[NDIRECT] = 0;
    800039ae:	0809a023          	sw	zero,128(s3)
    800039b2:	bf51                	j	80003946 <itrunc+0x3e>

00000000800039b4 <iput>:
{
    800039b4:	1101                	addi	sp,sp,-32
    800039b6:	ec06                	sd	ra,24(sp)
    800039b8:	e822                	sd	s0,16(sp)
    800039ba:	e426                	sd	s1,8(sp)
    800039bc:	e04a                	sd	s2,0(sp)
    800039be:	1000                	addi	s0,sp,32
    800039c0:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800039c2:	00028517          	auipc	a0,0x28
    800039c6:	dee50513          	addi	a0,a0,-530 # 8002b7b0 <icache>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	20c080e7          	jalr	524(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039d2:	4498                	lw	a4,8(s1)
    800039d4:	4785                	li	a5,1
    800039d6:	02f70363          	beq	a4,a5,800039fc <iput+0x48>
  ip->ref--;
    800039da:	449c                	lw	a5,8(s1)
    800039dc:	37fd                	addiw	a5,a5,-1
    800039de:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039e0:	00028517          	auipc	a0,0x28
    800039e4:	dd050513          	addi	a0,a0,-560 # 8002b7b0 <icache>
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	2a2080e7          	jalr	674(ra) # 80000c8a <release>
}
    800039f0:	60e2                	ld	ra,24(sp)
    800039f2:	6442                	ld	s0,16(sp)
    800039f4:	64a2                	ld	s1,8(sp)
    800039f6:	6902                	ld	s2,0(sp)
    800039f8:	6105                	addi	sp,sp,32
    800039fa:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039fc:	40bc                	lw	a5,64(s1)
    800039fe:	dff1                	beqz	a5,800039da <iput+0x26>
    80003a00:	04a49783          	lh	a5,74(s1)
    80003a04:	fbf9                	bnez	a5,800039da <iput+0x26>
    acquiresleep(&ip->lock);
    80003a06:	01048913          	addi	s2,s1,16
    80003a0a:	854a                	mv	a0,s2
    80003a0c:	00001097          	auipc	ra,0x1
    80003a10:	ac0080e7          	jalr	-1344(ra) # 800044cc <acquiresleep>
    release(&icache.lock);
    80003a14:	00028517          	auipc	a0,0x28
    80003a18:	d9c50513          	addi	a0,a0,-612 # 8002b7b0 <icache>
    80003a1c:	ffffd097          	auipc	ra,0xffffd
    80003a20:	26e080e7          	jalr	622(ra) # 80000c8a <release>
    itrunc(ip);
    80003a24:	8526                	mv	a0,s1
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	ee2080e7          	jalr	-286(ra) # 80003908 <itrunc>
    ip->type = 0;
    80003a2e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a32:	8526                	mv	a0,s1
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	cfc080e7          	jalr	-772(ra) # 80003730 <iupdate>
    ip->valid = 0;
    80003a3c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a40:	854a                	mv	a0,s2
    80003a42:	00001097          	auipc	ra,0x1
    80003a46:	ae0080e7          	jalr	-1312(ra) # 80004522 <releasesleep>
    acquire(&icache.lock);
    80003a4a:	00028517          	auipc	a0,0x28
    80003a4e:	d6650513          	addi	a0,a0,-666 # 8002b7b0 <icache>
    80003a52:	ffffd097          	auipc	ra,0xffffd
    80003a56:	184080e7          	jalr	388(ra) # 80000bd6 <acquire>
    80003a5a:	b741                	j	800039da <iput+0x26>

0000000080003a5c <iunlockput>:
{
    80003a5c:	1101                	addi	sp,sp,-32
    80003a5e:	ec06                	sd	ra,24(sp)
    80003a60:	e822                	sd	s0,16(sp)
    80003a62:	e426                	sd	s1,8(sp)
    80003a64:	1000                	addi	s0,sp,32
    80003a66:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	e54080e7          	jalr	-428(ra) # 800038bc <iunlock>
  iput(ip);
    80003a70:	8526                	mv	a0,s1
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	f42080e7          	jalr	-190(ra) # 800039b4 <iput>
}
    80003a7a:	60e2                	ld	ra,24(sp)
    80003a7c:	6442                	ld	s0,16(sp)
    80003a7e:	64a2                	ld	s1,8(sp)
    80003a80:	6105                	addi	sp,sp,32
    80003a82:	8082                	ret

0000000080003a84 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a84:	1141                	addi	sp,sp,-16
    80003a86:	e422                	sd	s0,8(sp)
    80003a88:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a8a:	411c                	lw	a5,0(a0)
    80003a8c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a8e:	415c                	lw	a5,4(a0)
    80003a90:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a92:	04451783          	lh	a5,68(a0)
    80003a96:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a9a:	04a51783          	lh	a5,74(a0)
    80003a9e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003aa2:	04c56783          	lwu	a5,76(a0)
    80003aa6:	e99c                	sd	a5,16(a1)
}
    80003aa8:	6422                	ld	s0,8(sp)
    80003aaa:	0141                	addi	sp,sp,16
    80003aac:	8082                	ret

0000000080003aae <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aae:	457c                	lw	a5,76(a0)
    80003ab0:	0ed7e963          	bltu	a5,a3,80003ba2 <readi+0xf4>
{
    80003ab4:	7159                	addi	sp,sp,-112
    80003ab6:	f486                	sd	ra,104(sp)
    80003ab8:	f0a2                	sd	s0,96(sp)
    80003aba:	eca6                	sd	s1,88(sp)
    80003abc:	e8ca                	sd	s2,80(sp)
    80003abe:	e4ce                	sd	s3,72(sp)
    80003ac0:	e0d2                	sd	s4,64(sp)
    80003ac2:	fc56                	sd	s5,56(sp)
    80003ac4:	f85a                	sd	s6,48(sp)
    80003ac6:	f45e                	sd	s7,40(sp)
    80003ac8:	f062                	sd	s8,32(sp)
    80003aca:	ec66                	sd	s9,24(sp)
    80003acc:	e86a                	sd	s10,16(sp)
    80003ace:	e46e                	sd	s11,8(sp)
    80003ad0:	1880                	addi	s0,sp,112
    80003ad2:	8baa                	mv	s7,a0
    80003ad4:	8c2e                	mv	s8,a1
    80003ad6:	8ab2                	mv	s5,a2
    80003ad8:	84b6                	mv	s1,a3
    80003ada:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003adc:	9f35                	addw	a4,a4,a3
    return 0;
    80003ade:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ae0:	0ad76063          	bltu	a4,a3,80003b80 <readi+0xd2>
  if(off + n > ip->size)
    80003ae4:	00e7f463          	bgeu	a5,a4,80003aec <readi+0x3e>
    n = ip->size - off;
    80003ae8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aec:	0a0b0963          	beqz	s6,80003b9e <readi+0xf0>
    80003af0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003af6:	5cfd                	li	s9,-1
    80003af8:	a82d                	j	80003b32 <readi+0x84>
    80003afa:	020a1d93          	slli	s11,s4,0x20
    80003afe:	020ddd93          	srli	s11,s11,0x20
    80003b02:	05890613          	addi	a2,s2,88
    80003b06:	86ee                	mv	a3,s11
    80003b08:	963a                	add	a2,a2,a4
    80003b0a:	85d6                	mv	a1,s5
    80003b0c:	8562                	mv	a0,s8
    80003b0e:	fffff097          	auipc	ra,0xfffff
    80003b12:	9e6080e7          	jalr	-1562(ra) # 800024f4 <either_copyout>
    80003b16:	05950d63          	beq	a0,s9,80003b70 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b1a:	854a                	mv	a0,s2
    80003b1c:	fffff097          	auipc	ra,0xfffff
    80003b20:	60c080e7          	jalr	1548(ra) # 80003128 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b24:	013a09bb          	addw	s3,s4,s3
    80003b28:	009a04bb          	addw	s1,s4,s1
    80003b2c:	9aee                	add	s5,s5,s11
    80003b2e:	0569f763          	bgeu	s3,s6,80003b7c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b32:	000ba903          	lw	s2,0(s7)
    80003b36:	00a4d59b          	srliw	a1,s1,0xa
    80003b3a:	855e                	mv	a0,s7
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	8b0080e7          	jalr	-1872(ra) # 800033ec <bmap>
    80003b44:	0005059b          	sext.w	a1,a0
    80003b48:	854a                	mv	a0,s2
    80003b4a:	fffff097          	auipc	ra,0xfffff
    80003b4e:	4ae080e7          	jalr	1198(ra) # 80002ff8 <bread>
    80003b52:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b54:	3ff4f713          	andi	a4,s1,1023
    80003b58:	40ed07bb          	subw	a5,s10,a4
    80003b5c:	413b06bb          	subw	a3,s6,s3
    80003b60:	8a3e                	mv	s4,a5
    80003b62:	2781                	sext.w	a5,a5
    80003b64:	0006861b          	sext.w	a2,a3
    80003b68:	f8f679e3          	bgeu	a2,a5,80003afa <readi+0x4c>
    80003b6c:	8a36                	mv	s4,a3
    80003b6e:	b771                	j	80003afa <readi+0x4c>
      brelse(bp);
    80003b70:	854a                	mv	a0,s2
    80003b72:	fffff097          	auipc	ra,0xfffff
    80003b76:	5b6080e7          	jalr	1462(ra) # 80003128 <brelse>
      tot = -1;
    80003b7a:	59fd                	li	s3,-1
  }
  return tot;
    80003b7c:	0009851b          	sext.w	a0,s3
}
    80003b80:	70a6                	ld	ra,104(sp)
    80003b82:	7406                	ld	s0,96(sp)
    80003b84:	64e6                	ld	s1,88(sp)
    80003b86:	6946                	ld	s2,80(sp)
    80003b88:	69a6                	ld	s3,72(sp)
    80003b8a:	6a06                	ld	s4,64(sp)
    80003b8c:	7ae2                	ld	s5,56(sp)
    80003b8e:	7b42                	ld	s6,48(sp)
    80003b90:	7ba2                	ld	s7,40(sp)
    80003b92:	7c02                	ld	s8,32(sp)
    80003b94:	6ce2                	ld	s9,24(sp)
    80003b96:	6d42                	ld	s10,16(sp)
    80003b98:	6da2                	ld	s11,8(sp)
    80003b9a:	6165                	addi	sp,sp,112
    80003b9c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b9e:	89da                	mv	s3,s6
    80003ba0:	bff1                	j	80003b7c <readi+0xce>
    return 0;
    80003ba2:	4501                	li	a0,0
}
    80003ba4:	8082                	ret

0000000080003ba6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ba6:	457c                	lw	a5,76(a0)
    80003ba8:	10d7e863          	bltu	a5,a3,80003cb8 <writei+0x112>
{
    80003bac:	7159                	addi	sp,sp,-112
    80003bae:	f486                	sd	ra,104(sp)
    80003bb0:	f0a2                	sd	s0,96(sp)
    80003bb2:	eca6                	sd	s1,88(sp)
    80003bb4:	e8ca                	sd	s2,80(sp)
    80003bb6:	e4ce                	sd	s3,72(sp)
    80003bb8:	e0d2                	sd	s4,64(sp)
    80003bba:	fc56                	sd	s5,56(sp)
    80003bbc:	f85a                	sd	s6,48(sp)
    80003bbe:	f45e                	sd	s7,40(sp)
    80003bc0:	f062                	sd	s8,32(sp)
    80003bc2:	ec66                	sd	s9,24(sp)
    80003bc4:	e86a                	sd	s10,16(sp)
    80003bc6:	e46e                	sd	s11,8(sp)
    80003bc8:	1880                	addi	s0,sp,112
    80003bca:	8b2a                	mv	s6,a0
    80003bcc:	8c2e                	mv	s8,a1
    80003bce:	8ab2                	mv	s5,a2
    80003bd0:	8936                	mv	s2,a3
    80003bd2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003bd4:	00e687bb          	addw	a5,a3,a4
    80003bd8:	0ed7e263          	bltu	a5,a3,80003cbc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bdc:	00043737          	lui	a4,0x43
    80003be0:	0ef76063          	bltu	a4,a5,80003cc0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003be4:	0c0b8863          	beqz	s7,80003cb4 <writei+0x10e>
    80003be8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bea:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bee:	5cfd                	li	s9,-1
    80003bf0:	a091                	j	80003c34 <writei+0x8e>
    80003bf2:	02099d93          	slli	s11,s3,0x20
    80003bf6:	020ddd93          	srli	s11,s11,0x20
    80003bfa:	05848513          	addi	a0,s1,88
    80003bfe:	86ee                	mv	a3,s11
    80003c00:	8656                	mv	a2,s5
    80003c02:	85e2                	mv	a1,s8
    80003c04:	953a                	add	a0,a0,a4
    80003c06:	fffff097          	auipc	ra,0xfffff
    80003c0a:	944080e7          	jalr	-1724(ra) # 8000254a <either_copyin>
    80003c0e:	07950263          	beq	a0,s9,80003c72 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c12:	8526                	mv	a0,s1
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	790080e7          	jalr	1936(ra) # 800043a4 <log_write>
    brelse(bp);
    80003c1c:	8526                	mv	a0,s1
    80003c1e:	fffff097          	auipc	ra,0xfffff
    80003c22:	50a080e7          	jalr	1290(ra) # 80003128 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c26:	01498a3b          	addw	s4,s3,s4
    80003c2a:	0129893b          	addw	s2,s3,s2
    80003c2e:	9aee                	add	s5,s5,s11
    80003c30:	057a7663          	bgeu	s4,s7,80003c7c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c34:	000b2483          	lw	s1,0(s6)
    80003c38:	00a9559b          	srliw	a1,s2,0xa
    80003c3c:	855a                	mv	a0,s6
    80003c3e:	fffff097          	auipc	ra,0xfffff
    80003c42:	7ae080e7          	jalr	1966(ra) # 800033ec <bmap>
    80003c46:	0005059b          	sext.w	a1,a0
    80003c4a:	8526                	mv	a0,s1
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	3ac080e7          	jalr	940(ra) # 80002ff8 <bread>
    80003c54:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c56:	3ff97713          	andi	a4,s2,1023
    80003c5a:	40ed07bb          	subw	a5,s10,a4
    80003c5e:	414b86bb          	subw	a3,s7,s4
    80003c62:	89be                	mv	s3,a5
    80003c64:	2781                	sext.w	a5,a5
    80003c66:	0006861b          	sext.w	a2,a3
    80003c6a:	f8f674e3          	bgeu	a2,a5,80003bf2 <writei+0x4c>
    80003c6e:	89b6                	mv	s3,a3
    80003c70:	b749                	j	80003bf2 <writei+0x4c>
      brelse(bp);
    80003c72:	8526                	mv	a0,s1
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	4b4080e7          	jalr	1204(ra) # 80003128 <brelse>
  }

  if(off > ip->size)
    80003c7c:	04cb2783          	lw	a5,76(s6)
    80003c80:	0127f463          	bgeu	a5,s2,80003c88 <writei+0xe2>
    ip->size = off;
    80003c84:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c88:	855a                	mv	a0,s6
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	aa6080e7          	jalr	-1370(ra) # 80003730 <iupdate>

  return tot;
    80003c92:	000a051b          	sext.w	a0,s4
}
    80003c96:	70a6                	ld	ra,104(sp)
    80003c98:	7406                	ld	s0,96(sp)
    80003c9a:	64e6                	ld	s1,88(sp)
    80003c9c:	6946                	ld	s2,80(sp)
    80003c9e:	69a6                	ld	s3,72(sp)
    80003ca0:	6a06                	ld	s4,64(sp)
    80003ca2:	7ae2                	ld	s5,56(sp)
    80003ca4:	7b42                	ld	s6,48(sp)
    80003ca6:	7ba2                	ld	s7,40(sp)
    80003ca8:	7c02                	ld	s8,32(sp)
    80003caa:	6ce2                	ld	s9,24(sp)
    80003cac:	6d42                	ld	s10,16(sp)
    80003cae:	6da2                	ld	s11,8(sp)
    80003cb0:	6165                	addi	sp,sp,112
    80003cb2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cb4:	8a5e                	mv	s4,s7
    80003cb6:	bfc9                	j	80003c88 <writei+0xe2>
    return -1;
    80003cb8:	557d                	li	a0,-1
}
    80003cba:	8082                	ret
    return -1;
    80003cbc:	557d                	li	a0,-1
    80003cbe:	bfe1                	j	80003c96 <writei+0xf0>
    return -1;
    80003cc0:	557d                	li	a0,-1
    80003cc2:	bfd1                	j	80003c96 <writei+0xf0>

0000000080003cc4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cc4:	1141                	addi	sp,sp,-16
    80003cc6:	e406                	sd	ra,8(sp)
    80003cc8:	e022                	sd	s0,0(sp)
    80003cca:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ccc:	4639                	li	a2,14
    80003cce:	ffffd097          	auipc	ra,0xffffd
    80003cd2:	0e0080e7          	jalr	224(ra) # 80000dae <strncmp>
}
    80003cd6:	60a2                	ld	ra,8(sp)
    80003cd8:	6402                	ld	s0,0(sp)
    80003cda:	0141                	addi	sp,sp,16
    80003cdc:	8082                	ret

0000000080003cde <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cde:	7139                	addi	sp,sp,-64
    80003ce0:	fc06                	sd	ra,56(sp)
    80003ce2:	f822                	sd	s0,48(sp)
    80003ce4:	f426                	sd	s1,40(sp)
    80003ce6:	f04a                	sd	s2,32(sp)
    80003ce8:	ec4e                	sd	s3,24(sp)
    80003cea:	e852                	sd	s4,16(sp)
    80003cec:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cee:	04451703          	lh	a4,68(a0)
    80003cf2:	4785                	li	a5,1
    80003cf4:	00f71a63          	bne	a4,a5,80003d08 <dirlookup+0x2a>
    80003cf8:	892a                	mv	s2,a0
    80003cfa:	89ae                	mv	s3,a1
    80003cfc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cfe:	457c                	lw	a5,76(a0)
    80003d00:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d02:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d04:	e79d                	bnez	a5,80003d32 <dirlookup+0x54>
    80003d06:	a8a5                	j	80003d7e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d08:	00005517          	auipc	a0,0x5
    80003d0c:	89050513          	addi	a0,a0,-1904 # 80008598 <syscalls+0x1b0>
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	820080e7          	jalr	-2016(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003d18:	00005517          	auipc	a0,0x5
    80003d1c:	89850513          	addi	a0,a0,-1896 # 800085b0 <syscalls+0x1c8>
    80003d20:	ffffd097          	auipc	ra,0xffffd
    80003d24:	810080e7          	jalr	-2032(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d28:	24c1                	addiw	s1,s1,16
    80003d2a:	04c92783          	lw	a5,76(s2)
    80003d2e:	04f4f763          	bgeu	s1,a5,80003d7c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d32:	4741                	li	a4,16
    80003d34:	86a6                	mv	a3,s1
    80003d36:	fc040613          	addi	a2,s0,-64
    80003d3a:	4581                	li	a1,0
    80003d3c:	854a                	mv	a0,s2
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	d70080e7          	jalr	-656(ra) # 80003aae <readi>
    80003d46:	47c1                	li	a5,16
    80003d48:	fcf518e3          	bne	a0,a5,80003d18 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d4c:	fc045783          	lhu	a5,-64(s0)
    80003d50:	dfe1                	beqz	a5,80003d28 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d52:	fc240593          	addi	a1,s0,-62
    80003d56:	854e                	mv	a0,s3
    80003d58:	00000097          	auipc	ra,0x0
    80003d5c:	f6c080e7          	jalr	-148(ra) # 80003cc4 <namecmp>
    80003d60:	f561                	bnez	a0,80003d28 <dirlookup+0x4a>
      if(poff)
    80003d62:	000a0463          	beqz	s4,80003d6a <dirlookup+0x8c>
        *poff = off;
    80003d66:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d6a:	fc045583          	lhu	a1,-64(s0)
    80003d6e:	00092503          	lw	a0,0(s2)
    80003d72:	fffff097          	auipc	ra,0xfffff
    80003d76:	754080e7          	jalr	1876(ra) # 800034c6 <iget>
    80003d7a:	a011                	j	80003d7e <dirlookup+0xa0>
  return 0;
    80003d7c:	4501                	li	a0,0
}
    80003d7e:	70e2                	ld	ra,56(sp)
    80003d80:	7442                	ld	s0,48(sp)
    80003d82:	74a2                	ld	s1,40(sp)
    80003d84:	7902                	ld	s2,32(sp)
    80003d86:	69e2                	ld	s3,24(sp)
    80003d88:	6a42                	ld	s4,16(sp)
    80003d8a:	6121                	addi	sp,sp,64
    80003d8c:	8082                	ret

0000000080003d8e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d8e:	711d                	addi	sp,sp,-96
    80003d90:	ec86                	sd	ra,88(sp)
    80003d92:	e8a2                	sd	s0,80(sp)
    80003d94:	e4a6                	sd	s1,72(sp)
    80003d96:	e0ca                	sd	s2,64(sp)
    80003d98:	fc4e                	sd	s3,56(sp)
    80003d9a:	f852                	sd	s4,48(sp)
    80003d9c:	f456                	sd	s5,40(sp)
    80003d9e:	f05a                	sd	s6,32(sp)
    80003da0:	ec5e                	sd	s7,24(sp)
    80003da2:	e862                	sd	s8,16(sp)
    80003da4:	e466                	sd	s9,8(sp)
    80003da6:	1080                	addi	s0,sp,96
    80003da8:	84aa                	mv	s1,a0
    80003daa:	8b2e                	mv	s6,a1
    80003dac:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dae:	00054703          	lbu	a4,0(a0)
    80003db2:	02f00793          	li	a5,47
    80003db6:	02f70363          	beq	a4,a5,80003ddc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003dba:	ffffe097          	auipc	ra,0xffffe
    80003dbe:	bec080e7          	jalr	-1044(ra) # 800019a6 <myproc>
    80003dc2:	15053503          	ld	a0,336(a0)
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	9f6080e7          	jalr	-1546(ra) # 800037bc <idup>
    80003dce:	89aa                	mv	s3,a0
  while(*path == '/')
    80003dd0:	02f00913          	li	s2,47
  len = path - s;
    80003dd4:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003dd6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dd8:	4c05                	li	s8,1
    80003dda:	a865                	j	80003e92 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ddc:	4585                	li	a1,1
    80003dde:	4505                	li	a0,1
    80003de0:	fffff097          	auipc	ra,0xfffff
    80003de4:	6e6080e7          	jalr	1766(ra) # 800034c6 <iget>
    80003de8:	89aa                	mv	s3,a0
    80003dea:	b7dd                	j	80003dd0 <namex+0x42>
      iunlockput(ip);
    80003dec:	854e                	mv	a0,s3
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	c6e080e7          	jalr	-914(ra) # 80003a5c <iunlockput>
      return 0;
    80003df6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003df8:	854e                	mv	a0,s3
    80003dfa:	60e6                	ld	ra,88(sp)
    80003dfc:	6446                	ld	s0,80(sp)
    80003dfe:	64a6                	ld	s1,72(sp)
    80003e00:	6906                	ld	s2,64(sp)
    80003e02:	79e2                	ld	s3,56(sp)
    80003e04:	7a42                	ld	s4,48(sp)
    80003e06:	7aa2                	ld	s5,40(sp)
    80003e08:	7b02                	ld	s6,32(sp)
    80003e0a:	6be2                	ld	s7,24(sp)
    80003e0c:	6c42                	ld	s8,16(sp)
    80003e0e:	6ca2                	ld	s9,8(sp)
    80003e10:	6125                	addi	sp,sp,96
    80003e12:	8082                	ret
      iunlock(ip);
    80003e14:	854e                	mv	a0,s3
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	aa6080e7          	jalr	-1370(ra) # 800038bc <iunlock>
      return ip;
    80003e1e:	bfe9                	j	80003df8 <namex+0x6a>
      iunlockput(ip);
    80003e20:	854e                	mv	a0,s3
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	c3a080e7          	jalr	-966(ra) # 80003a5c <iunlockput>
      return 0;
    80003e2a:	89d2                	mv	s3,s4
    80003e2c:	b7f1                	j	80003df8 <namex+0x6a>
  len = path - s;
    80003e2e:	40b48633          	sub	a2,s1,a1
    80003e32:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e36:	094cd463          	bge	s9,s4,80003ebe <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e3a:	4639                	li	a2,14
    80003e3c:	8556                	mv	a0,s5
    80003e3e:	ffffd097          	auipc	ra,0xffffd
    80003e42:	ef4080e7          	jalr	-268(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003e46:	0004c783          	lbu	a5,0(s1)
    80003e4a:	01279763          	bne	a5,s2,80003e58 <namex+0xca>
    path++;
    80003e4e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e50:	0004c783          	lbu	a5,0(s1)
    80003e54:	ff278de3          	beq	a5,s2,80003e4e <namex+0xc0>
    ilock(ip);
    80003e58:	854e                	mv	a0,s3
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	9a0080e7          	jalr	-1632(ra) # 800037fa <ilock>
    if(ip->type != T_DIR){
    80003e62:	04499783          	lh	a5,68(s3)
    80003e66:	f98793e3          	bne	a5,s8,80003dec <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e6a:	000b0563          	beqz	s6,80003e74 <namex+0xe6>
    80003e6e:	0004c783          	lbu	a5,0(s1)
    80003e72:	d3cd                	beqz	a5,80003e14 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e74:	865e                	mv	a2,s7
    80003e76:	85d6                	mv	a1,s5
    80003e78:	854e                	mv	a0,s3
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	e64080e7          	jalr	-412(ra) # 80003cde <dirlookup>
    80003e82:	8a2a                	mv	s4,a0
    80003e84:	dd51                	beqz	a0,80003e20 <namex+0x92>
    iunlockput(ip);
    80003e86:	854e                	mv	a0,s3
    80003e88:	00000097          	auipc	ra,0x0
    80003e8c:	bd4080e7          	jalr	-1068(ra) # 80003a5c <iunlockput>
    ip = next;
    80003e90:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e92:	0004c783          	lbu	a5,0(s1)
    80003e96:	05279763          	bne	a5,s2,80003ee4 <namex+0x156>
    path++;
    80003e9a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e9c:	0004c783          	lbu	a5,0(s1)
    80003ea0:	ff278de3          	beq	a5,s2,80003e9a <namex+0x10c>
  if(*path == 0)
    80003ea4:	c79d                	beqz	a5,80003ed2 <namex+0x144>
    path++;
    80003ea6:	85a6                	mv	a1,s1
  len = path - s;
    80003ea8:	8a5e                	mv	s4,s7
    80003eaa:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003eac:	01278963          	beq	a5,s2,80003ebe <namex+0x130>
    80003eb0:	dfbd                	beqz	a5,80003e2e <namex+0xa0>
    path++;
    80003eb2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003eb4:	0004c783          	lbu	a5,0(s1)
    80003eb8:	ff279ce3          	bne	a5,s2,80003eb0 <namex+0x122>
    80003ebc:	bf8d                	j	80003e2e <namex+0xa0>
    memmove(name, s, len);
    80003ebe:	2601                	sext.w	a2,a2
    80003ec0:	8556                	mv	a0,s5
    80003ec2:	ffffd097          	auipc	ra,0xffffd
    80003ec6:	e70080e7          	jalr	-400(ra) # 80000d32 <memmove>
    name[len] = 0;
    80003eca:	9a56                	add	s4,s4,s5
    80003ecc:	000a0023          	sb	zero,0(s4)
    80003ed0:	bf9d                	j	80003e46 <namex+0xb8>
  if(nameiparent){
    80003ed2:	f20b03e3          	beqz	s6,80003df8 <namex+0x6a>
    iput(ip);
    80003ed6:	854e                	mv	a0,s3
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	adc080e7          	jalr	-1316(ra) # 800039b4 <iput>
    return 0;
    80003ee0:	4981                	li	s3,0
    80003ee2:	bf19                	j	80003df8 <namex+0x6a>
  if(*path == 0)
    80003ee4:	d7fd                	beqz	a5,80003ed2 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ee6:	0004c783          	lbu	a5,0(s1)
    80003eea:	85a6                	mv	a1,s1
    80003eec:	b7d1                	j	80003eb0 <namex+0x122>

0000000080003eee <dirlink>:
{
    80003eee:	7139                	addi	sp,sp,-64
    80003ef0:	fc06                	sd	ra,56(sp)
    80003ef2:	f822                	sd	s0,48(sp)
    80003ef4:	f426                	sd	s1,40(sp)
    80003ef6:	f04a                	sd	s2,32(sp)
    80003ef8:	ec4e                	sd	s3,24(sp)
    80003efa:	e852                	sd	s4,16(sp)
    80003efc:	0080                	addi	s0,sp,64
    80003efe:	892a                	mv	s2,a0
    80003f00:	8a2e                	mv	s4,a1
    80003f02:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f04:	4601                	li	a2,0
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	dd8080e7          	jalr	-552(ra) # 80003cde <dirlookup>
    80003f0e:	e93d                	bnez	a0,80003f84 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f10:	04c92483          	lw	s1,76(s2)
    80003f14:	c49d                	beqz	s1,80003f42 <dirlink+0x54>
    80003f16:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f18:	4741                	li	a4,16
    80003f1a:	86a6                	mv	a3,s1
    80003f1c:	fc040613          	addi	a2,s0,-64
    80003f20:	4581                	li	a1,0
    80003f22:	854a                	mv	a0,s2
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	b8a080e7          	jalr	-1142(ra) # 80003aae <readi>
    80003f2c:	47c1                	li	a5,16
    80003f2e:	06f51163          	bne	a0,a5,80003f90 <dirlink+0xa2>
    if(de.inum == 0)
    80003f32:	fc045783          	lhu	a5,-64(s0)
    80003f36:	c791                	beqz	a5,80003f42 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f38:	24c1                	addiw	s1,s1,16
    80003f3a:	04c92783          	lw	a5,76(s2)
    80003f3e:	fcf4ede3          	bltu	s1,a5,80003f18 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f42:	4639                	li	a2,14
    80003f44:	85d2                	mv	a1,s4
    80003f46:	fc240513          	addi	a0,s0,-62
    80003f4a:	ffffd097          	auipc	ra,0xffffd
    80003f4e:	ea0080e7          	jalr	-352(ra) # 80000dea <strncpy>
  de.inum = inum;
    80003f52:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f56:	4741                	li	a4,16
    80003f58:	86a6                	mv	a3,s1
    80003f5a:	fc040613          	addi	a2,s0,-64
    80003f5e:	4581                	li	a1,0
    80003f60:	854a                	mv	a0,s2
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	c44080e7          	jalr	-956(ra) # 80003ba6 <writei>
    80003f6a:	872a                	mv	a4,a0
    80003f6c:	47c1                	li	a5,16
  return 0;
    80003f6e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f70:	02f71863          	bne	a4,a5,80003fa0 <dirlink+0xb2>
}
    80003f74:	70e2                	ld	ra,56(sp)
    80003f76:	7442                	ld	s0,48(sp)
    80003f78:	74a2                	ld	s1,40(sp)
    80003f7a:	7902                	ld	s2,32(sp)
    80003f7c:	69e2                	ld	s3,24(sp)
    80003f7e:	6a42                	ld	s4,16(sp)
    80003f80:	6121                	addi	sp,sp,64
    80003f82:	8082                	ret
    iput(ip);
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	a30080e7          	jalr	-1488(ra) # 800039b4 <iput>
    return -1;
    80003f8c:	557d                	li	a0,-1
    80003f8e:	b7dd                	j	80003f74 <dirlink+0x86>
      panic("dirlink read");
    80003f90:	00004517          	auipc	a0,0x4
    80003f94:	63050513          	addi	a0,a0,1584 # 800085c0 <syscalls+0x1d8>
    80003f98:	ffffc097          	auipc	ra,0xffffc
    80003f9c:	598080e7          	jalr	1432(ra) # 80000530 <panic>
    panic("dirlink");
    80003fa0:	00004517          	auipc	a0,0x4
    80003fa4:	73050513          	addi	a0,a0,1840 # 800086d0 <syscalls+0x2e8>
    80003fa8:	ffffc097          	auipc	ra,0xffffc
    80003fac:	588080e7          	jalr	1416(ra) # 80000530 <panic>

0000000080003fb0 <namei>:

struct inode*
namei(char *path)
{
    80003fb0:	1101                	addi	sp,sp,-32
    80003fb2:	ec06                	sd	ra,24(sp)
    80003fb4:	e822                	sd	s0,16(sp)
    80003fb6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fb8:	fe040613          	addi	a2,s0,-32
    80003fbc:	4581                	li	a1,0
    80003fbe:	00000097          	auipc	ra,0x0
    80003fc2:	dd0080e7          	jalr	-560(ra) # 80003d8e <namex>
}
    80003fc6:	60e2                	ld	ra,24(sp)
    80003fc8:	6442                	ld	s0,16(sp)
    80003fca:	6105                	addi	sp,sp,32
    80003fcc:	8082                	ret

0000000080003fce <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fce:	1141                	addi	sp,sp,-16
    80003fd0:	e406                	sd	ra,8(sp)
    80003fd2:	e022                	sd	s0,0(sp)
    80003fd4:	0800                	addi	s0,sp,16
    80003fd6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fd8:	4585                	li	a1,1
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	db4080e7          	jalr	-588(ra) # 80003d8e <namex>
}
    80003fe2:	60a2                	ld	ra,8(sp)
    80003fe4:	6402                	ld	s0,0(sp)
    80003fe6:	0141                	addi	sp,sp,16
    80003fe8:	8082                	ret

0000000080003fea <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fea:	1101                	addi	sp,sp,-32
    80003fec:	ec06                	sd	ra,24(sp)
    80003fee:	e822                	sd	s0,16(sp)
    80003ff0:	e426                	sd	s1,8(sp)
    80003ff2:	e04a                	sd	s2,0(sp)
    80003ff4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ff6:	00029917          	auipc	s2,0x29
    80003ffa:	26290913          	addi	s2,s2,610 # 8002d258 <log>
    80003ffe:	01892583          	lw	a1,24(s2)
    80004002:	02892503          	lw	a0,40(s2)
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	ff2080e7          	jalr	-14(ra) # 80002ff8 <bread>
    8000400e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004010:	02c92683          	lw	a3,44(s2)
    80004014:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004016:	02d05763          	blez	a3,80004044 <write_head+0x5a>
    8000401a:	00029797          	auipc	a5,0x29
    8000401e:	26e78793          	addi	a5,a5,622 # 8002d288 <log+0x30>
    80004022:	05c50713          	addi	a4,a0,92
    80004026:	36fd                	addiw	a3,a3,-1
    80004028:	1682                	slli	a3,a3,0x20
    8000402a:	9281                	srli	a3,a3,0x20
    8000402c:	068a                	slli	a3,a3,0x2
    8000402e:	00029617          	auipc	a2,0x29
    80004032:	25e60613          	addi	a2,a2,606 # 8002d28c <log+0x34>
    80004036:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004038:	4390                	lw	a2,0(a5)
    8000403a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000403c:	0791                	addi	a5,a5,4
    8000403e:	0711                	addi	a4,a4,4
    80004040:	fed79ce3          	bne	a5,a3,80004038 <write_head+0x4e>
  }
  bwrite(buf);
    80004044:	8526                	mv	a0,s1
    80004046:	fffff097          	auipc	ra,0xfffff
    8000404a:	0a4080e7          	jalr	164(ra) # 800030ea <bwrite>
  brelse(buf);
    8000404e:	8526                	mv	a0,s1
    80004050:	fffff097          	auipc	ra,0xfffff
    80004054:	0d8080e7          	jalr	216(ra) # 80003128 <brelse>
}
    80004058:	60e2                	ld	ra,24(sp)
    8000405a:	6442                	ld	s0,16(sp)
    8000405c:	64a2                	ld	s1,8(sp)
    8000405e:	6902                	ld	s2,0(sp)
    80004060:	6105                	addi	sp,sp,32
    80004062:	8082                	ret

0000000080004064 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004064:	00029797          	auipc	a5,0x29
    80004068:	2207a783          	lw	a5,544(a5) # 8002d284 <log+0x2c>
    8000406c:	0af05d63          	blez	a5,80004126 <install_trans+0xc2>
{
    80004070:	7139                	addi	sp,sp,-64
    80004072:	fc06                	sd	ra,56(sp)
    80004074:	f822                	sd	s0,48(sp)
    80004076:	f426                	sd	s1,40(sp)
    80004078:	f04a                	sd	s2,32(sp)
    8000407a:	ec4e                	sd	s3,24(sp)
    8000407c:	e852                	sd	s4,16(sp)
    8000407e:	e456                	sd	s5,8(sp)
    80004080:	e05a                	sd	s6,0(sp)
    80004082:	0080                	addi	s0,sp,64
    80004084:	8b2a                	mv	s6,a0
    80004086:	00029a97          	auipc	s5,0x29
    8000408a:	202a8a93          	addi	s5,s5,514 # 8002d288 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000408e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004090:	00029997          	auipc	s3,0x29
    80004094:	1c898993          	addi	s3,s3,456 # 8002d258 <log>
    80004098:	a035                	j	800040c4 <install_trans+0x60>
      bunpin(dbuf);
    8000409a:	8526                	mv	a0,s1
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	166080e7          	jalr	358(ra) # 80003202 <bunpin>
    brelse(lbuf);
    800040a4:	854a                	mv	a0,s2
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	082080e7          	jalr	130(ra) # 80003128 <brelse>
    brelse(dbuf);
    800040ae:	8526                	mv	a0,s1
    800040b0:	fffff097          	auipc	ra,0xfffff
    800040b4:	078080e7          	jalr	120(ra) # 80003128 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040b8:	2a05                	addiw	s4,s4,1
    800040ba:	0a91                	addi	s5,s5,4
    800040bc:	02c9a783          	lw	a5,44(s3)
    800040c0:	04fa5963          	bge	s4,a5,80004112 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040c4:	0189a583          	lw	a1,24(s3)
    800040c8:	014585bb          	addw	a1,a1,s4
    800040cc:	2585                	addiw	a1,a1,1
    800040ce:	0289a503          	lw	a0,40(s3)
    800040d2:	fffff097          	auipc	ra,0xfffff
    800040d6:	f26080e7          	jalr	-218(ra) # 80002ff8 <bread>
    800040da:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040dc:	000aa583          	lw	a1,0(s5)
    800040e0:	0289a503          	lw	a0,40(s3)
    800040e4:	fffff097          	auipc	ra,0xfffff
    800040e8:	f14080e7          	jalr	-236(ra) # 80002ff8 <bread>
    800040ec:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040ee:	40000613          	li	a2,1024
    800040f2:	05890593          	addi	a1,s2,88
    800040f6:	05850513          	addi	a0,a0,88
    800040fa:	ffffd097          	auipc	ra,0xffffd
    800040fe:	c38080e7          	jalr	-968(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004102:	8526                	mv	a0,s1
    80004104:	fffff097          	auipc	ra,0xfffff
    80004108:	fe6080e7          	jalr	-26(ra) # 800030ea <bwrite>
    if(recovering == 0)
    8000410c:	f80b1ce3          	bnez	s6,800040a4 <install_trans+0x40>
    80004110:	b769                	j	8000409a <install_trans+0x36>
}
    80004112:	70e2                	ld	ra,56(sp)
    80004114:	7442                	ld	s0,48(sp)
    80004116:	74a2                	ld	s1,40(sp)
    80004118:	7902                	ld	s2,32(sp)
    8000411a:	69e2                	ld	s3,24(sp)
    8000411c:	6a42                	ld	s4,16(sp)
    8000411e:	6aa2                	ld	s5,8(sp)
    80004120:	6b02                	ld	s6,0(sp)
    80004122:	6121                	addi	sp,sp,64
    80004124:	8082                	ret
    80004126:	8082                	ret

0000000080004128 <initlog>:
{
    80004128:	7179                	addi	sp,sp,-48
    8000412a:	f406                	sd	ra,40(sp)
    8000412c:	f022                	sd	s0,32(sp)
    8000412e:	ec26                	sd	s1,24(sp)
    80004130:	e84a                	sd	s2,16(sp)
    80004132:	e44e                	sd	s3,8(sp)
    80004134:	1800                	addi	s0,sp,48
    80004136:	892a                	mv	s2,a0
    80004138:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000413a:	00029497          	auipc	s1,0x29
    8000413e:	11e48493          	addi	s1,s1,286 # 8002d258 <log>
    80004142:	00004597          	auipc	a1,0x4
    80004146:	48e58593          	addi	a1,a1,1166 # 800085d0 <syscalls+0x1e8>
    8000414a:	8526                	mv	a0,s1
    8000414c:	ffffd097          	auipc	ra,0xffffd
    80004150:	9fa080e7          	jalr	-1542(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004154:	0149a583          	lw	a1,20(s3)
    80004158:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000415a:	0109a783          	lw	a5,16(s3)
    8000415e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004160:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004164:	854a                	mv	a0,s2
    80004166:	fffff097          	auipc	ra,0xfffff
    8000416a:	e92080e7          	jalr	-366(ra) # 80002ff8 <bread>
  log.lh.n = lh->n;
    8000416e:	4d3c                	lw	a5,88(a0)
    80004170:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004172:	02f05563          	blez	a5,8000419c <initlog+0x74>
    80004176:	05c50713          	addi	a4,a0,92
    8000417a:	00029697          	auipc	a3,0x29
    8000417e:	10e68693          	addi	a3,a3,270 # 8002d288 <log+0x30>
    80004182:	37fd                	addiw	a5,a5,-1
    80004184:	1782                	slli	a5,a5,0x20
    80004186:	9381                	srli	a5,a5,0x20
    80004188:	078a                	slli	a5,a5,0x2
    8000418a:	06050613          	addi	a2,a0,96
    8000418e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004190:	4310                	lw	a2,0(a4)
    80004192:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004194:	0711                	addi	a4,a4,4
    80004196:	0691                	addi	a3,a3,4
    80004198:	fef71ce3          	bne	a4,a5,80004190 <initlog+0x68>
  brelse(buf);
    8000419c:	fffff097          	auipc	ra,0xfffff
    800041a0:	f8c080e7          	jalr	-116(ra) # 80003128 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041a4:	4505                	li	a0,1
    800041a6:	00000097          	auipc	ra,0x0
    800041aa:	ebe080e7          	jalr	-322(ra) # 80004064 <install_trans>
  log.lh.n = 0;
    800041ae:	00029797          	auipc	a5,0x29
    800041b2:	0c07ab23          	sw	zero,214(a5) # 8002d284 <log+0x2c>
  write_head(); // clear the log
    800041b6:	00000097          	auipc	ra,0x0
    800041ba:	e34080e7          	jalr	-460(ra) # 80003fea <write_head>
}
    800041be:	70a2                	ld	ra,40(sp)
    800041c0:	7402                	ld	s0,32(sp)
    800041c2:	64e2                	ld	s1,24(sp)
    800041c4:	6942                	ld	s2,16(sp)
    800041c6:	69a2                	ld	s3,8(sp)
    800041c8:	6145                	addi	sp,sp,48
    800041ca:	8082                	ret

00000000800041cc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041cc:	1101                	addi	sp,sp,-32
    800041ce:	ec06                	sd	ra,24(sp)
    800041d0:	e822                	sd	s0,16(sp)
    800041d2:	e426                	sd	s1,8(sp)
    800041d4:	e04a                	sd	s2,0(sp)
    800041d6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041d8:	00029517          	auipc	a0,0x29
    800041dc:	08050513          	addi	a0,a0,128 # 8002d258 <log>
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	9f6080e7          	jalr	-1546(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800041e8:	00029497          	auipc	s1,0x29
    800041ec:	07048493          	addi	s1,s1,112 # 8002d258 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041f0:	4979                	li	s2,30
    800041f2:	a039                	j	80004200 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041f4:	85a6                	mv	a1,s1
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffe097          	auipc	ra,0xffffe
    800041fc:	09a080e7          	jalr	154(ra) # 80002292 <sleep>
    if(log.committing){
    80004200:	50dc                	lw	a5,36(s1)
    80004202:	fbed                	bnez	a5,800041f4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004204:	509c                	lw	a5,32(s1)
    80004206:	0017871b          	addiw	a4,a5,1
    8000420a:	0007069b          	sext.w	a3,a4
    8000420e:	0027179b          	slliw	a5,a4,0x2
    80004212:	9fb9                	addw	a5,a5,a4
    80004214:	0017979b          	slliw	a5,a5,0x1
    80004218:	54d8                	lw	a4,44(s1)
    8000421a:	9fb9                	addw	a5,a5,a4
    8000421c:	00f95963          	bge	s2,a5,8000422e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004220:	85a6                	mv	a1,s1
    80004222:	8526                	mv	a0,s1
    80004224:	ffffe097          	auipc	ra,0xffffe
    80004228:	06e080e7          	jalr	110(ra) # 80002292 <sleep>
    8000422c:	bfd1                	j	80004200 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000422e:	00029517          	auipc	a0,0x29
    80004232:	02a50513          	addi	a0,a0,42 # 8002d258 <log>
    80004236:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004238:	ffffd097          	auipc	ra,0xffffd
    8000423c:	a52080e7          	jalr	-1454(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004240:	60e2                	ld	ra,24(sp)
    80004242:	6442                	ld	s0,16(sp)
    80004244:	64a2                	ld	s1,8(sp)
    80004246:	6902                	ld	s2,0(sp)
    80004248:	6105                	addi	sp,sp,32
    8000424a:	8082                	ret

000000008000424c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000424c:	7139                	addi	sp,sp,-64
    8000424e:	fc06                	sd	ra,56(sp)
    80004250:	f822                	sd	s0,48(sp)
    80004252:	f426                	sd	s1,40(sp)
    80004254:	f04a                	sd	s2,32(sp)
    80004256:	ec4e                	sd	s3,24(sp)
    80004258:	e852                	sd	s4,16(sp)
    8000425a:	e456                	sd	s5,8(sp)
    8000425c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000425e:	00029497          	auipc	s1,0x29
    80004262:	ffa48493          	addi	s1,s1,-6 # 8002d258 <log>
    80004266:	8526                	mv	a0,s1
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	96e080e7          	jalr	-1682(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004270:	509c                	lw	a5,32(s1)
    80004272:	37fd                	addiw	a5,a5,-1
    80004274:	0007891b          	sext.w	s2,a5
    80004278:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000427a:	50dc                	lw	a5,36(s1)
    8000427c:	efb9                	bnez	a5,800042da <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000427e:	06091663          	bnez	s2,800042ea <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004282:	00029497          	auipc	s1,0x29
    80004286:	fd648493          	addi	s1,s1,-42 # 8002d258 <log>
    8000428a:	4785                	li	a5,1
    8000428c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000428e:	8526                	mv	a0,s1
    80004290:	ffffd097          	auipc	ra,0xffffd
    80004294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004298:	54dc                	lw	a5,44(s1)
    8000429a:	06f04763          	bgtz	a5,80004308 <end_op+0xbc>
    acquire(&log.lock);
    8000429e:	00029497          	auipc	s1,0x29
    800042a2:	fba48493          	addi	s1,s1,-70 # 8002d258 <log>
    800042a6:	8526                	mv	a0,s1
    800042a8:	ffffd097          	auipc	ra,0xffffd
    800042ac:	92e080e7          	jalr	-1746(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800042b0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042b4:	8526                	mv	a0,s1
    800042b6:	ffffe097          	auipc	ra,0xffffe
    800042ba:	162080e7          	jalr	354(ra) # 80002418 <wakeup>
    release(&log.lock);
    800042be:	8526                	mv	a0,s1
    800042c0:	ffffd097          	auipc	ra,0xffffd
    800042c4:	9ca080e7          	jalr	-1590(ra) # 80000c8a <release>
}
    800042c8:	70e2                	ld	ra,56(sp)
    800042ca:	7442                	ld	s0,48(sp)
    800042cc:	74a2                	ld	s1,40(sp)
    800042ce:	7902                	ld	s2,32(sp)
    800042d0:	69e2                	ld	s3,24(sp)
    800042d2:	6a42                	ld	s4,16(sp)
    800042d4:	6aa2                	ld	s5,8(sp)
    800042d6:	6121                	addi	sp,sp,64
    800042d8:	8082                	ret
    panic("log.committing");
    800042da:	00004517          	auipc	a0,0x4
    800042de:	2fe50513          	addi	a0,a0,766 # 800085d8 <syscalls+0x1f0>
    800042e2:	ffffc097          	auipc	ra,0xffffc
    800042e6:	24e080e7          	jalr	590(ra) # 80000530 <panic>
    wakeup(&log);
    800042ea:	00029497          	auipc	s1,0x29
    800042ee:	f6e48493          	addi	s1,s1,-146 # 8002d258 <log>
    800042f2:	8526                	mv	a0,s1
    800042f4:	ffffe097          	auipc	ra,0xffffe
    800042f8:	124080e7          	jalr	292(ra) # 80002418 <wakeup>
  release(&log.lock);
    800042fc:	8526                	mv	a0,s1
    800042fe:	ffffd097          	auipc	ra,0xffffd
    80004302:	98c080e7          	jalr	-1652(ra) # 80000c8a <release>
  if(do_commit){
    80004306:	b7c9                	j	800042c8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004308:	00029a97          	auipc	s5,0x29
    8000430c:	f80a8a93          	addi	s5,s5,-128 # 8002d288 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004310:	00029a17          	auipc	s4,0x29
    80004314:	f48a0a13          	addi	s4,s4,-184 # 8002d258 <log>
    80004318:	018a2583          	lw	a1,24(s4)
    8000431c:	012585bb          	addw	a1,a1,s2
    80004320:	2585                	addiw	a1,a1,1
    80004322:	028a2503          	lw	a0,40(s4)
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	cd2080e7          	jalr	-814(ra) # 80002ff8 <bread>
    8000432e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004330:	000aa583          	lw	a1,0(s5)
    80004334:	028a2503          	lw	a0,40(s4)
    80004338:	fffff097          	auipc	ra,0xfffff
    8000433c:	cc0080e7          	jalr	-832(ra) # 80002ff8 <bread>
    80004340:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004342:	40000613          	li	a2,1024
    80004346:	05850593          	addi	a1,a0,88
    8000434a:	05848513          	addi	a0,s1,88
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	9e4080e7          	jalr	-1564(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    80004356:	8526                	mv	a0,s1
    80004358:	fffff097          	auipc	ra,0xfffff
    8000435c:	d92080e7          	jalr	-622(ra) # 800030ea <bwrite>
    brelse(from);
    80004360:	854e                	mv	a0,s3
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	dc6080e7          	jalr	-570(ra) # 80003128 <brelse>
    brelse(to);
    8000436a:	8526                	mv	a0,s1
    8000436c:	fffff097          	auipc	ra,0xfffff
    80004370:	dbc080e7          	jalr	-580(ra) # 80003128 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004374:	2905                	addiw	s2,s2,1
    80004376:	0a91                	addi	s5,s5,4
    80004378:	02ca2783          	lw	a5,44(s4)
    8000437c:	f8f94ee3          	blt	s2,a5,80004318 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004380:	00000097          	auipc	ra,0x0
    80004384:	c6a080e7          	jalr	-918(ra) # 80003fea <write_head>
    install_trans(0); // Now install writes to home locations
    80004388:	4501                	li	a0,0
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	cda080e7          	jalr	-806(ra) # 80004064 <install_trans>
    log.lh.n = 0;
    80004392:	00029797          	auipc	a5,0x29
    80004396:	ee07a923          	sw	zero,-270(a5) # 8002d284 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000439a:	00000097          	auipc	ra,0x0
    8000439e:	c50080e7          	jalr	-944(ra) # 80003fea <write_head>
    800043a2:	bdf5                	j	8000429e <end_op+0x52>

00000000800043a4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043a4:	1101                	addi	sp,sp,-32
    800043a6:	ec06                	sd	ra,24(sp)
    800043a8:	e822                	sd	s0,16(sp)
    800043aa:	e426                	sd	s1,8(sp)
    800043ac:	e04a                	sd	s2,0(sp)
    800043ae:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043b0:	00029717          	auipc	a4,0x29
    800043b4:	ed472703          	lw	a4,-300(a4) # 8002d284 <log+0x2c>
    800043b8:	47f5                	li	a5,29
    800043ba:	08e7c063          	blt	a5,a4,8000443a <log_write+0x96>
    800043be:	84aa                	mv	s1,a0
    800043c0:	00029797          	auipc	a5,0x29
    800043c4:	eb47a783          	lw	a5,-332(a5) # 8002d274 <log+0x1c>
    800043c8:	37fd                	addiw	a5,a5,-1
    800043ca:	06f75863          	bge	a4,a5,8000443a <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043ce:	00029797          	auipc	a5,0x29
    800043d2:	eaa7a783          	lw	a5,-342(a5) # 8002d278 <log+0x20>
    800043d6:	06f05a63          	blez	a5,8000444a <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800043da:	00029917          	auipc	s2,0x29
    800043de:	e7e90913          	addi	s2,s2,-386 # 8002d258 <log>
    800043e2:	854a                	mv	a0,s2
    800043e4:	ffffc097          	auipc	ra,0xffffc
    800043e8:	7f2080e7          	jalr	2034(ra) # 80000bd6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800043ec:	02c92603          	lw	a2,44(s2)
    800043f0:	06c05563          	blez	a2,8000445a <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043f4:	44cc                	lw	a1,12(s1)
    800043f6:	00029717          	auipc	a4,0x29
    800043fa:	e9270713          	addi	a4,a4,-366 # 8002d288 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043fe:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004400:	4314                	lw	a3,0(a4)
    80004402:	04b68d63          	beq	a3,a1,8000445c <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004406:	2785                	addiw	a5,a5,1
    80004408:	0711                	addi	a4,a4,4
    8000440a:	fec79be3          	bne	a5,a2,80004400 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000440e:	0621                	addi	a2,a2,8
    80004410:	060a                	slli	a2,a2,0x2
    80004412:	00029797          	auipc	a5,0x29
    80004416:	e4678793          	addi	a5,a5,-442 # 8002d258 <log>
    8000441a:	963e                	add	a2,a2,a5
    8000441c:	44dc                	lw	a5,12(s1)
    8000441e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004420:	8526                	mv	a0,s1
    80004422:	fffff097          	auipc	ra,0xfffff
    80004426:	da4080e7          	jalr	-604(ra) # 800031c6 <bpin>
    log.lh.n++;
    8000442a:	00029717          	auipc	a4,0x29
    8000442e:	e2e70713          	addi	a4,a4,-466 # 8002d258 <log>
    80004432:	575c                	lw	a5,44(a4)
    80004434:	2785                	addiw	a5,a5,1
    80004436:	d75c                	sw	a5,44(a4)
    80004438:	a83d                	j	80004476 <log_write+0xd2>
    panic("too big a transaction");
    8000443a:	00004517          	auipc	a0,0x4
    8000443e:	1ae50513          	addi	a0,a0,430 # 800085e8 <syscalls+0x200>
    80004442:	ffffc097          	auipc	ra,0xffffc
    80004446:	0ee080e7          	jalr	238(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    8000444a:	00004517          	auipc	a0,0x4
    8000444e:	1b650513          	addi	a0,a0,438 # 80008600 <syscalls+0x218>
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	0de080e7          	jalr	222(ra) # 80000530 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000445a:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000445c:	00878713          	addi	a4,a5,8
    80004460:	00271693          	slli	a3,a4,0x2
    80004464:	00029717          	auipc	a4,0x29
    80004468:	df470713          	addi	a4,a4,-524 # 8002d258 <log>
    8000446c:	9736                	add	a4,a4,a3
    8000446e:	44d4                	lw	a3,12(s1)
    80004470:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004472:	faf607e3          	beq	a2,a5,80004420 <log_write+0x7c>
  }
  release(&log.lock);
    80004476:	00029517          	auipc	a0,0x29
    8000447a:	de250513          	addi	a0,a0,-542 # 8002d258 <log>
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	80c080e7          	jalr	-2036(ra) # 80000c8a <release>
}
    80004486:	60e2                	ld	ra,24(sp)
    80004488:	6442                	ld	s0,16(sp)
    8000448a:	64a2                	ld	s1,8(sp)
    8000448c:	6902                	ld	s2,0(sp)
    8000448e:	6105                	addi	sp,sp,32
    80004490:	8082                	ret

0000000080004492 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004492:	1101                	addi	sp,sp,-32
    80004494:	ec06                	sd	ra,24(sp)
    80004496:	e822                	sd	s0,16(sp)
    80004498:	e426                	sd	s1,8(sp)
    8000449a:	e04a                	sd	s2,0(sp)
    8000449c:	1000                	addi	s0,sp,32
    8000449e:	84aa                	mv	s1,a0
    800044a0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044a2:	00004597          	auipc	a1,0x4
    800044a6:	17e58593          	addi	a1,a1,382 # 80008620 <syscalls+0x238>
    800044aa:	0521                	addi	a0,a0,8
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	69a080e7          	jalr	1690(ra) # 80000b46 <initlock>
  lk->name = name;
    800044b4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044b8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044bc:	0204a423          	sw	zero,40(s1)
}
    800044c0:	60e2                	ld	ra,24(sp)
    800044c2:	6442                	ld	s0,16(sp)
    800044c4:	64a2                	ld	s1,8(sp)
    800044c6:	6902                	ld	s2,0(sp)
    800044c8:	6105                	addi	sp,sp,32
    800044ca:	8082                	ret

00000000800044cc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044cc:	1101                	addi	sp,sp,-32
    800044ce:	ec06                	sd	ra,24(sp)
    800044d0:	e822                	sd	s0,16(sp)
    800044d2:	e426                	sd	s1,8(sp)
    800044d4:	e04a                	sd	s2,0(sp)
    800044d6:	1000                	addi	s0,sp,32
    800044d8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044da:	00850913          	addi	s2,a0,8
    800044de:	854a                	mv	a0,s2
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	6f6080e7          	jalr	1782(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800044e8:	409c                	lw	a5,0(s1)
    800044ea:	cb89                	beqz	a5,800044fc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044ec:	85ca                	mv	a1,s2
    800044ee:	8526                	mv	a0,s1
    800044f0:	ffffe097          	auipc	ra,0xffffe
    800044f4:	da2080e7          	jalr	-606(ra) # 80002292 <sleep>
  while (lk->locked) {
    800044f8:	409c                	lw	a5,0(s1)
    800044fa:	fbed                	bnez	a5,800044ec <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044fc:	4785                	li	a5,1
    800044fe:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004500:	ffffd097          	auipc	ra,0xffffd
    80004504:	4a6080e7          	jalr	1190(ra) # 800019a6 <myproc>
    80004508:	5d1c                	lw	a5,56(a0)
    8000450a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000450c:	854a                	mv	a0,s2
    8000450e:	ffffc097          	auipc	ra,0xffffc
    80004512:	77c080e7          	jalr	1916(ra) # 80000c8a <release>
}
    80004516:	60e2                	ld	ra,24(sp)
    80004518:	6442                	ld	s0,16(sp)
    8000451a:	64a2                	ld	s1,8(sp)
    8000451c:	6902                	ld	s2,0(sp)
    8000451e:	6105                	addi	sp,sp,32
    80004520:	8082                	ret

0000000080004522 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004522:	1101                	addi	sp,sp,-32
    80004524:	ec06                	sd	ra,24(sp)
    80004526:	e822                	sd	s0,16(sp)
    80004528:	e426                	sd	s1,8(sp)
    8000452a:	e04a                	sd	s2,0(sp)
    8000452c:	1000                	addi	s0,sp,32
    8000452e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004530:	00850913          	addi	s2,a0,8
    80004534:	854a                	mv	a0,s2
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	6a0080e7          	jalr	1696(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000453e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004542:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004546:	8526                	mv	a0,s1
    80004548:	ffffe097          	auipc	ra,0xffffe
    8000454c:	ed0080e7          	jalr	-304(ra) # 80002418 <wakeup>
  release(&lk->lk);
    80004550:	854a                	mv	a0,s2
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	738080e7          	jalr	1848(ra) # 80000c8a <release>
}
    8000455a:	60e2                	ld	ra,24(sp)
    8000455c:	6442                	ld	s0,16(sp)
    8000455e:	64a2                	ld	s1,8(sp)
    80004560:	6902                	ld	s2,0(sp)
    80004562:	6105                	addi	sp,sp,32
    80004564:	8082                	ret

0000000080004566 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004566:	7179                	addi	sp,sp,-48
    80004568:	f406                	sd	ra,40(sp)
    8000456a:	f022                	sd	s0,32(sp)
    8000456c:	ec26                	sd	s1,24(sp)
    8000456e:	e84a                	sd	s2,16(sp)
    80004570:	e44e                	sd	s3,8(sp)
    80004572:	1800                	addi	s0,sp,48
    80004574:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004576:	00850913          	addi	s2,a0,8
    8000457a:	854a                	mv	a0,s2
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	65a080e7          	jalr	1626(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004584:	409c                	lw	a5,0(s1)
    80004586:	ef99                	bnez	a5,800045a4 <holdingsleep+0x3e>
    80004588:	4481                	li	s1,0
  release(&lk->lk);
    8000458a:	854a                	mv	a0,s2
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	6fe080e7          	jalr	1790(ra) # 80000c8a <release>
  return r;
}
    80004594:	8526                	mv	a0,s1
    80004596:	70a2                	ld	ra,40(sp)
    80004598:	7402                	ld	s0,32(sp)
    8000459a:	64e2                	ld	s1,24(sp)
    8000459c:	6942                	ld	s2,16(sp)
    8000459e:	69a2                	ld	s3,8(sp)
    800045a0:	6145                	addi	sp,sp,48
    800045a2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045a4:	0284a983          	lw	s3,40(s1)
    800045a8:	ffffd097          	auipc	ra,0xffffd
    800045ac:	3fe080e7          	jalr	1022(ra) # 800019a6 <myproc>
    800045b0:	5d04                	lw	s1,56(a0)
    800045b2:	413484b3          	sub	s1,s1,s3
    800045b6:	0014b493          	seqz	s1,s1
    800045ba:	bfc1                	j	8000458a <holdingsleep+0x24>

00000000800045bc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045bc:	1141                	addi	sp,sp,-16
    800045be:	e406                	sd	ra,8(sp)
    800045c0:	e022                	sd	s0,0(sp)
    800045c2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045c4:	00004597          	auipc	a1,0x4
    800045c8:	06c58593          	addi	a1,a1,108 # 80008630 <syscalls+0x248>
    800045cc:	00029517          	auipc	a0,0x29
    800045d0:	dd450513          	addi	a0,a0,-556 # 8002d3a0 <ftable>
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	572080e7          	jalr	1394(ra) # 80000b46 <initlock>
}
    800045dc:	60a2                	ld	ra,8(sp)
    800045de:	6402                	ld	s0,0(sp)
    800045e0:	0141                	addi	sp,sp,16
    800045e2:	8082                	ret

00000000800045e4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045e4:	1101                	addi	sp,sp,-32
    800045e6:	ec06                	sd	ra,24(sp)
    800045e8:	e822                	sd	s0,16(sp)
    800045ea:	e426                	sd	s1,8(sp)
    800045ec:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045ee:	00029517          	auipc	a0,0x29
    800045f2:	db250513          	addi	a0,a0,-590 # 8002d3a0 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	5e0080e7          	jalr	1504(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045fe:	00029497          	auipc	s1,0x29
    80004602:	dba48493          	addi	s1,s1,-582 # 8002d3b8 <ftable+0x18>
    80004606:	0002a717          	auipc	a4,0x2a
    8000460a:	d5270713          	addi	a4,a4,-686 # 8002e358 <ftable+0xfb8>
    if(f->ref == 0){
    8000460e:	40dc                	lw	a5,4(s1)
    80004610:	cf99                	beqz	a5,8000462e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004612:	02848493          	addi	s1,s1,40
    80004616:	fee49ce3          	bne	s1,a4,8000460e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000461a:	00029517          	auipc	a0,0x29
    8000461e:	d8650513          	addi	a0,a0,-634 # 8002d3a0 <ftable>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	668080e7          	jalr	1640(ra) # 80000c8a <release>
  return 0;
    8000462a:	4481                	li	s1,0
    8000462c:	a819                	j	80004642 <filealloc+0x5e>
      f->ref = 1;
    8000462e:	4785                	li	a5,1
    80004630:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004632:	00029517          	auipc	a0,0x29
    80004636:	d6e50513          	addi	a0,a0,-658 # 8002d3a0 <ftable>
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	650080e7          	jalr	1616(ra) # 80000c8a <release>
}
    80004642:	8526                	mv	a0,s1
    80004644:	60e2                	ld	ra,24(sp)
    80004646:	6442                	ld	s0,16(sp)
    80004648:	64a2                	ld	s1,8(sp)
    8000464a:	6105                	addi	sp,sp,32
    8000464c:	8082                	ret

000000008000464e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000464e:	1101                	addi	sp,sp,-32
    80004650:	ec06                	sd	ra,24(sp)
    80004652:	e822                	sd	s0,16(sp)
    80004654:	e426                	sd	s1,8(sp)
    80004656:	1000                	addi	s0,sp,32
    80004658:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000465a:	00029517          	auipc	a0,0x29
    8000465e:	d4650513          	addi	a0,a0,-698 # 8002d3a0 <ftable>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	574080e7          	jalr	1396(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000466a:	40dc                	lw	a5,4(s1)
    8000466c:	02f05263          	blez	a5,80004690 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004670:	2785                	addiw	a5,a5,1
    80004672:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004674:	00029517          	auipc	a0,0x29
    80004678:	d2c50513          	addi	a0,a0,-724 # 8002d3a0 <ftable>
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	60e080e7          	jalr	1550(ra) # 80000c8a <release>
  return f;
}
    80004684:	8526                	mv	a0,s1
    80004686:	60e2                	ld	ra,24(sp)
    80004688:	6442                	ld	s0,16(sp)
    8000468a:	64a2                	ld	s1,8(sp)
    8000468c:	6105                	addi	sp,sp,32
    8000468e:	8082                	ret
    panic("filedup");
    80004690:	00004517          	auipc	a0,0x4
    80004694:	fa850513          	addi	a0,a0,-88 # 80008638 <syscalls+0x250>
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	e98080e7          	jalr	-360(ra) # 80000530 <panic>

00000000800046a0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046a0:	7139                	addi	sp,sp,-64
    800046a2:	fc06                	sd	ra,56(sp)
    800046a4:	f822                	sd	s0,48(sp)
    800046a6:	f426                	sd	s1,40(sp)
    800046a8:	f04a                	sd	s2,32(sp)
    800046aa:	ec4e                	sd	s3,24(sp)
    800046ac:	e852                	sd	s4,16(sp)
    800046ae:	e456                	sd	s5,8(sp)
    800046b0:	0080                	addi	s0,sp,64
    800046b2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046b4:	00029517          	auipc	a0,0x29
    800046b8:	cec50513          	addi	a0,a0,-788 # 8002d3a0 <ftable>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	51a080e7          	jalr	1306(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800046c4:	40dc                	lw	a5,4(s1)
    800046c6:	06f05163          	blez	a5,80004728 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046ca:	37fd                	addiw	a5,a5,-1
    800046cc:	0007871b          	sext.w	a4,a5
    800046d0:	c0dc                	sw	a5,4(s1)
    800046d2:	06e04363          	bgtz	a4,80004738 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046d6:	0004a903          	lw	s2,0(s1)
    800046da:	0094ca83          	lbu	s5,9(s1)
    800046de:	0104ba03          	ld	s4,16(s1)
    800046e2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046e6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046ea:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046ee:	00029517          	auipc	a0,0x29
    800046f2:	cb250513          	addi	a0,a0,-846 # 8002d3a0 <ftable>
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	594080e7          	jalr	1428(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800046fe:	4785                	li	a5,1
    80004700:	04f90d63          	beq	s2,a5,8000475a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004704:	3979                	addiw	s2,s2,-2
    80004706:	4785                	li	a5,1
    80004708:	0527e063          	bltu	a5,s2,80004748 <fileclose+0xa8>
    begin_op();
    8000470c:	00000097          	auipc	ra,0x0
    80004710:	ac0080e7          	jalr	-1344(ra) # 800041cc <begin_op>
    iput(ff.ip);
    80004714:	854e                	mv	a0,s3
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	29e080e7          	jalr	670(ra) # 800039b4 <iput>
    end_op();
    8000471e:	00000097          	auipc	ra,0x0
    80004722:	b2e080e7          	jalr	-1234(ra) # 8000424c <end_op>
    80004726:	a00d                	j	80004748 <fileclose+0xa8>
    panic("fileclose");
    80004728:	00004517          	auipc	a0,0x4
    8000472c:	f1850513          	addi	a0,a0,-232 # 80008640 <syscalls+0x258>
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	e00080e7          	jalr	-512(ra) # 80000530 <panic>
    release(&ftable.lock);
    80004738:	00029517          	auipc	a0,0x29
    8000473c:	c6850513          	addi	a0,a0,-920 # 8002d3a0 <ftable>
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	54a080e7          	jalr	1354(ra) # 80000c8a <release>
  }
}
    80004748:	70e2                	ld	ra,56(sp)
    8000474a:	7442                	ld	s0,48(sp)
    8000474c:	74a2                	ld	s1,40(sp)
    8000474e:	7902                	ld	s2,32(sp)
    80004750:	69e2                	ld	s3,24(sp)
    80004752:	6a42                	ld	s4,16(sp)
    80004754:	6aa2                	ld	s5,8(sp)
    80004756:	6121                	addi	sp,sp,64
    80004758:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000475a:	85d6                	mv	a1,s5
    8000475c:	8552                	mv	a0,s4
    8000475e:	00000097          	auipc	ra,0x0
    80004762:	34c080e7          	jalr	844(ra) # 80004aaa <pipeclose>
    80004766:	b7cd                	j	80004748 <fileclose+0xa8>

0000000080004768 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004768:	715d                	addi	sp,sp,-80
    8000476a:	e486                	sd	ra,72(sp)
    8000476c:	e0a2                	sd	s0,64(sp)
    8000476e:	fc26                	sd	s1,56(sp)
    80004770:	f84a                	sd	s2,48(sp)
    80004772:	f44e                	sd	s3,40(sp)
    80004774:	0880                	addi	s0,sp,80
    80004776:	84aa                	mv	s1,a0
    80004778:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000477a:	ffffd097          	auipc	ra,0xffffd
    8000477e:	22c080e7          	jalr	556(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004782:	409c                	lw	a5,0(s1)
    80004784:	37f9                	addiw	a5,a5,-2
    80004786:	4705                	li	a4,1
    80004788:	04f76763          	bltu	a4,a5,800047d6 <filestat+0x6e>
    8000478c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000478e:	6c88                	ld	a0,24(s1)
    80004790:	fffff097          	auipc	ra,0xfffff
    80004794:	06a080e7          	jalr	106(ra) # 800037fa <ilock>
    stati(f->ip, &st);
    80004798:	fb840593          	addi	a1,s0,-72
    8000479c:	6c88                	ld	a0,24(s1)
    8000479e:	fffff097          	auipc	ra,0xfffff
    800047a2:	2e6080e7          	jalr	742(ra) # 80003a84 <stati>
    iunlock(f->ip);
    800047a6:	6c88                	ld	a0,24(s1)
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	114080e7          	jalr	276(ra) # 800038bc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047b0:	46e1                	li	a3,24
    800047b2:	fb840613          	addi	a2,s0,-72
    800047b6:	85ce                	mv	a1,s3
    800047b8:	05093503          	ld	a0,80(s2)
    800047bc:	ffffd097          	auipc	ra,0xffffd
    800047c0:	e80080e7          	jalr	-384(ra) # 8000163c <copyout>
    800047c4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047c8:	60a6                	ld	ra,72(sp)
    800047ca:	6406                	ld	s0,64(sp)
    800047cc:	74e2                	ld	s1,56(sp)
    800047ce:	7942                	ld	s2,48(sp)
    800047d0:	79a2                	ld	s3,40(sp)
    800047d2:	6161                	addi	sp,sp,80
    800047d4:	8082                	ret
  return -1;
    800047d6:	557d                	li	a0,-1
    800047d8:	bfc5                	j	800047c8 <filestat+0x60>

00000000800047da <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047da:	7179                	addi	sp,sp,-48
    800047dc:	f406                	sd	ra,40(sp)
    800047de:	f022                	sd	s0,32(sp)
    800047e0:	ec26                	sd	s1,24(sp)
    800047e2:	e84a                	sd	s2,16(sp)
    800047e4:	e44e                	sd	s3,8(sp)
    800047e6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047e8:	00854783          	lbu	a5,8(a0)
    800047ec:	c3d5                	beqz	a5,80004890 <fileread+0xb6>
    800047ee:	84aa                	mv	s1,a0
    800047f0:	89ae                	mv	s3,a1
    800047f2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047f4:	411c                	lw	a5,0(a0)
    800047f6:	4705                	li	a4,1
    800047f8:	04e78963          	beq	a5,a4,8000484a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047fc:	470d                	li	a4,3
    800047fe:	04e78d63          	beq	a5,a4,80004858 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004802:	4709                	li	a4,2
    80004804:	06e79e63          	bne	a5,a4,80004880 <fileread+0xa6>
    ilock(f->ip);
    80004808:	6d08                	ld	a0,24(a0)
    8000480a:	fffff097          	auipc	ra,0xfffff
    8000480e:	ff0080e7          	jalr	-16(ra) # 800037fa <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004812:	874a                	mv	a4,s2
    80004814:	5094                	lw	a3,32(s1)
    80004816:	864e                	mv	a2,s3
    80004818:	4585                	li	a1,1
    8000481a:	6c88                	ld	a0,24(s1)
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	292080e7          	jalr	658(ra) # 80003aae <readi>
    80004824:	892a                	mv	s2,a0
    80004826:	00a05563          	blez	a0,80004830 <fileread+0x56>
      f->off += r;
    8000482a:	509c                	lw	a5,32(s1)
    8000482c:	9fa9                	addw	a5,a5,a0
    8000482e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004830:	6c88                	ld	a0,24(s1)
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	08a080e7          	jalr	138(ra) # 800038bc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000483a:	854a                	mv	a0,s2
    8000483c:	70a2                	ld	ra,40(sp)
    8000483e:	7402                	ld	s0,32(sp)
    80004840:	64e2                	ld	s1,24(sp)
    80004842:	6942                	ld	s2,16(sp)
    80004844:	69a2                	ld	s3,8(sp)
    80004846:	6145                	addi	sp,sp,48
    80004848:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000484a:	6908                	ld	a0,16(a0)
    8000484c:	00000097          	auipc	ra,0x0
    80004850:	3c8080e7          	jalr	968(ra) # 80004c14 <piperead>
    80004854:	892a                	mv	s2,a0
    80004856:	b7d5                	j	8000483a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004858:	02451783          	lh	a5,36(a0)
    8000485c:	03079693          	slli	a3,a5,0x30
    80004860:	92c1                	srli	a3,a3,0x30
    80004862:	4725                	li	a4,9
    80004864:	02d76863          	bltu	a4,a3,80004894 <fileread+0xba>
    80004868:	0792                	slli	a5,a5,0x4
    8000486a:	00029717          	auipc	a4,0x29
    8000486e:	a9670713          	addi	a4,a4,-1386 # 8002d300 <devsw>
    80004872:	97ba                	add	a5,a5,a4
    80004874:	639c                	ld	a5,0(a5)
    80004876:	c38d                	beqz	a5,80004898 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004878:	4505                	li	a0,1
    8000487a:	9782                	jalr	a5
    8000487c:	892a                	mv	s2,a0
    8000487e:	bf75                	j	8000483a <fileread+0x60>
    panic("fileread");
    80004880:	00004517          	auipc	a0,0x4
    80004884:	dd050513          	addi	a0,a0,-560 # 80008650 <syscalls+0x268>
    80004888:	ffffc097          	auipc	ra,0xffffc
    8000488c:	ca8080e7          	jalr	-856(ra) # 80000530 <panic>
    return -1;
    80004890:	597d                	li	s2,-1
    80004892:	b765                	j	8000483a <fileread+0x60>
      return -1;
    80004894:	597d                	li	s2,-1
    80004896:	b755                	j	8000483a <fileread+0x60>
    80004898:	597d                	li	s2,-1
    8000489a:	b745                	j	8000483a <fileread+0x60>

000000008000489c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000489c:	715d                	addi	sp,sp,-80
    8000489e:	e486                	sd	ra,72(sp)
    800048a0:	e0a2                	sd	s0,64(sp)
    800048a2:	fc26                	sd	s1,56(sp)
    800048a4:	f84a                	sd	s2,48(sp)
    800048a6:	f44e                	sd	s3,40(sp)
    800048a8:	f052                	sd	s4,32(sp)
    800048aa:	ec56                	sd	s5,24(sp)
    800048ac:	e85a                	sd	s6,16(sp)
    800048ae:	e45e                	sd	s7,8(sp)
    800048b0:	e062                	sd	s8,0(sp)
    800048b2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048b4:	00954783          	lbu	a5,9(a0)
    800048b8:	10078663          	beqz	a5,800049c4 <filewrite+0x128>
    800048bc:	892a                	mv	s2,a0
    800048be:	8aae                	mv	s5,a1
    800048c0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048c2:	411c                	lw	a5,0(a0)
    800048c4:	4705                	li	a4,1
    800048c6:	02e78263          	beq	a5,a4,800048ea <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ca:	470d                	li	a4,3
    800048cc:	02e78663          	beq	a5,a4,800048f8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048d0:	4709                	li	a4,2
    800048d2:	0ee79163          	bne	a5,a4,800049b4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048d6:	0ac05d63          	blez	a2,80004990 <filewrite+0xf4>
    int i = 0;
    800048da:	4981                	li	s3,0
    800048dc:	6b05                	lui	s6,0x1
    800048de:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048e2:	6b85                	lui	s7,0x1
    800048e4:	c00b8b9b          	addiw	s7,s7,-1024
    800048e8:	a861                	j	80004980 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048ea:	6908                	ld	a0,16(a0)
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	22e080e7          	jalr	558(ra) # 80004b1a <pipewrite>
    800048f4:	8a2a                	mv	s4,a0
    800048f6:	a045                	j	80004996 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048f8:	02451783          	lh	a5,36(a0)
    800048fc:	03079693          	slli	a3,a5,0x30
    80004900:	92c1                	srli	a3,a3,0x30
    80004902:	4725                	li	a4,9
    80004904:	0cd76263          	bltu	a4,a3,800049c8 <filewrite+0x12c>
    80004908:	0792                	slli	a5,a5,0x4
    8000490a:	00029717          	auipc	a4,0x29
    8000490e:	9f670713          	addi	a4,a4,-1546 # 8002d300 <devsw>
    80004912:	97ba                	add	a5,a5,a4
    80004914:	679c                	ld	a5,8(a5)
    80004916:	cbdd                	beqz	a5,800049cc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004918:	4505                	li	a0,1
    8000491a:	9782                	jalr	a5
    8000491c:	8a2a                	mv	s4,a0
    8000491e:	a8a5                	j	80004996 <filewrite+0xfa>
    80004920:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004924:	00000097          	auipc	ra,0x0
    80004928:	8a8080e7          	jalr	-1880(ra) # 800041cc <begin_op>
      ilock(f->ip);
    8000492c:	01893503          	ld	a0,24(s2)
    80004930:	fffff097          	auipc	ra,0xfffff
    80004934:	eca080e7          	jalr	-310(ra) # 800037fa <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004938:	8762                	mv	a4,s8
    8000493a:	02092683          	lw	a3,32(s2)
    8000493e:	01598633          	add	a2,s3,s5
    80004942:	4585                	li	a1,1
    80004944:	01893503          	ld	a0,24(s2)
    80004948:	fffff097          	auipc	ra,0xfffff
    8000494c:	25e080e7          	jalr	606(ra) # 80003ba6 <writei>
    80004950:	84aa                	mv	s1,a0
    80004952:	00a05763          	blez	a0,80004960 <filewrite+0xc4>
        f->off += r;
    80004956:	02092783          	lw	a5,32(s2)
    8000495a:	9fa9                	addw	a5,a5,a0
    8000495c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004960:	01893503          	ld	a0,24(s2)
    80004964:	fffff097          	auipc	ra,0xfffff
    80004968:	f58080e7          	jalr	-168(ra) # 800038bc <iunlock>
      end_op();
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	8e0080e7          	jalr	-1824(ra) # 8000424c <end_op>

      if(r != n1){
    80004974:	009c1f63          	bne	s8,s1,80004992 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004978:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000497c:	0149db63          	bge	s3,s4,80004992 <filewrite+0xf6>
      int n1 = n - i;
    80004980:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004984:	84be                	mv	s1,a5
    80004986:	2781                	sext.w	a5,a5
    80004988:	f8fb5ce3          	bge	s6,a5,80004920 <filewrite+0x84>
    8000498c:	84de                	mv	s1,s7
    8000498e:	bf49                	j	80004920 <filewrite+0x84>
    int i = 0;
    80004990:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004992:	013a1f63          	bne	s4,s3,800049b0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004996:	8552                	mv	a0,s4
    80004998:	60a6                	ld	ra,72(sp)
    8000499a:	6406                	ld	s0,64(sp)
    8000499c:	74e2                	ld	s1,56(sp)
    8000499e:	7942                	ld	s2,48(sp)
    800049a0:	79a2                	ld	s3,40(sp)
    800049a2:	7a02                	ld	s4,32(sp)
    800049a4:	6ae2                	ld	s5,24(sp)
    800049a6:	6b42                	ld	s6,16(sp)
    800049a8:	6ba2                	ld	s7,8(sp)
    800049aa:	6c02                	ld	s8,0(sp)
    800049ac:	6161                	addi	sp,sp,80
    800049ae:	8082                	ret
    ret = (i == n ? n : -1);
    800049b0:	5a7d                	li	s4,-1
    800049b2:	b7d5                	j	80004996 <filewrite+0xfa>
    panic("filewrite");
    800049b4:	00004517          	auipc	a0,0x4
    800049b8:	cac50513          	addi	a0,a0,-852 # 80008660 <syscalls+0x278>
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	b74080e7          	jalr	-1164(ra) # 80000530 <panic>
    return -1;
    800049c4:	5a7d                	li	s4,-1
    800049c6:	bfc1                	j	80004996 <filewrite+0xfa>
      return -1;
    800049c8:	5a7d                	li	s4,-1
    800049ca:	b7f1                	j	80004996 <filewrite+0xfa>
    800049cc:	5a7d                	li	s4,-1
    800049ce:	b7e1                	j	80004996 <filewrite+0xfa>

00000000800049d0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049d0:	7179                	addi	sp,sp,-48
    800049d2:	f406                	sd	ra,40(sp)
    800049d4:	f022                	sd	s0,32(sp)
    800049d6:	ec26                	sd	s1,24(sp)
    800049d8:	e84a                	sd	s2,16(sp)
    800049da:	e44e                	sd	s3,8(sp)
    800049dc:	e052                	sd	s4,0(sp)
    800049de:	1800                	addi	s0,sp,48
    800049e0:	84aa                	mv	s1,a0
    800049e2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049e4:	0005b023          	sd	zero,0(a1)
    800049e8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049ec:	00000097          	auipc	ra,0x0
    800049f0:	bf8080e7          	jalr	-1032(ra) # 800045e4 <filealloc>
    800049f4:	e088                	sd	a0,0(s1)
    800049f6:	c551                	beqz	a0,80004a82 <pipealloc+0xb2>
    800049f8:	00000097          	auipc	ra,0x0
    800049fc:	bec080e7          	jalr	-1044(ra) # 800045e4 <filealloc>
    80004a00:	00aa3023          	sd	a0,0(s4)
    80004a04:	c92d                	beqz	a0,80004a76 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	0e0080e7          	jalr	224(ra) # 80000ae6 <kalloc>
    80004a0e:	892a                	mv	s2,a0
    80004a10:	c125                	beqz	a0,80004a70 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a12:	4985                	li	s3,1
    80004a14:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a18:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a1c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a20:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a24:	00004597          	auipc	a1,0x4
    80004a28:	c4c58593          	addi	a1,a1,-948 # 80008670 <syscalls+0x288>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	11a080e7          	jalr	282(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004a34:	609c                	ld	a5,0(s1)
    80004a36:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a3a:	609c                	ld	a5,0(s1)
    80004a3c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a40:	609c                	ld	a5,0(s1)
    80004a42:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a46:	609c                	ld	a5,0(s1)
    80004a48:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a4c:	000a3783          	ld	a5,0(s4)
    80004a50:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a54:	000a3783          	ld	a5,0(s4)
    80004a58:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a5c:	000a3783          	ld	a5,0(s4)
    80004a60:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a64:	000a3783          	ld	a5,0(s4)
    80004a68:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a6c:	4501                	li	a0,0
    80004a6e:	a025                	j	80004a96 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a70:	6088                	ld	a0,0(s1)
    80004a72:	e501                	bnez	a0,80004a7a <pipealloc+0xaa>
    80004a74:	a039                	j	80004a82 <pipealloc+0xb2>
    80004a76:	6088                	ld	a0,0(s1)
    80004a78:	c51d                	beqz	a0,80004aa6 <pipealloc+0xd6>
    fileclose(*f0);
    80004a7a:	00000097          	auipc	ra,0x0
    80004a7e:	c26080e7          	jalr	-986(ra) # 800046a0 <fileclose>
  if(*f1)
    80004a82:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a86:	557d                	li	a0,-1
  if(*f1)
    80004a88:	c799                	beqz	a5,80004a96 <pipealloc+0xc6>
    fileclose(*f1);
    80004a8a:	853e                	mv	a0,a5
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	c14080e7          	jalr	-1004(ra) # 800046a0 <fileclose>
  return -1;
    80004a94:	557d                	li	a0,-1
}
    80004a96:	70a2                	ld	ra,40(sp)
    80004a98:	7402                	ld	s0,32(sp)
    80004a9a:	64e2                	ld	s1,24(sp)
    80004a9c:	6942                	ld	s2,16(sp)
    80004a9e:	69a2                	ld	s3,8(sp)
    80004aa0:	6a02                	ld	s4,0(sp)
    80004aa2:	6145                	addi	sp,sp,48
    80004aa4:	8082                	ret
  return -1;
    80004aa6:	557d                	li	a0,-1
    80004aa8:	b7fd                	j	80004a96 <pipealloc+0xc6>

0000000080004aaa <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004aaa:	1101                	addi	sp,sp,-32
    80004aac:	ec06                	sd	ra,24(sp)
    80004aae:	e822                	sd	s0,16(sp)
    80004ab0:	e426                	sd	s1,8(sp)
    80004ab2:	e04a                	sd	s2,0(sp)
    80004ab4:	1000                	addi	s0,sp,32
    80004ab6:	84aa                	mv	s1,a0
    80004ab8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	11c080e7          	jalr	284(ra) # 80000bd6 <acquire>
  if(writable){
    80004ac2:	02090d63          	beqz	s2,80004afc <pipeclose+0x52>
    pi->writeopen = 0;
    80004ac6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004aca:	21848513          	addi	a0,s1,536
    80004ace:	ffffe097          	auipc	ra,0xffffe
    80004ad2:	94a080e7          	jalr	-1718(ra) # 80002418 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ad6:	2204b783          	ld	a5,544(s1)
    80004ada:	eb95                	bnez	a5,80004b0e <pipeclose+0x64>
    release(&pi->lock);
    80004adc:	8526                	mv	a0,s1
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	1ac080e7          	jalr	428(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004ae6:	8526                	mv	a0,s1
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	f02080e7          	jalr	-254(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004af0:	60e2                	ld	ra,24(sp)
    80004af2:	6442                	ld	s0,16(sp)
    80004af4:	64a2                	ld	s1,8(sp)
    80004af6:	6902                	ld	s2,0(sp)
    80004af8:	6105                	addi	sp,sp,32
    80004afa:	8082                	ret
    pi->readopen = 0;
    80004afc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b00:	21c48513          	addi	a0,s1,540
    80004b04:	ffffe097          	auipc	ra,0xffffe
    80004b08:	914080e7          	jalr	-1772(ra) # 80002418 <wakeup>
    80004b0c:	b7e9                	j	80004ad6 <pipeclose+0x2c>
    release(&pi->lock);
    80004b0e:	8526                	mv	a0,s1
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	17a080e7          	jalr	378(ra) # 80000c8a <release>
}
    80004b18:	bfe1                	j	80004af0 <pipeclose+0x46>

0000000080004b1a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b1a:	7159                	addi	sp,sp,-112
    80004b1c:	f486                	sd	ra,104(sp)
    80004b1e:	f0a2                	sd	s0,96(sp)
    80004b20:	eca6                	sd	s1,88(sp)
    80004b22:	e8ca                	sd	s2,80(sp)
    80004b24:	e4ce                	sd	s3,72(sp)
    80004b26:	e0d2                	sd	s4,64(sp)
    80004b28:	fc56                	sd	s5,56(sp)
    80004b2a:	f85a                	sd	s6,48(sp)
    80004b2c:	f45e                	sd	s7,40(sp)
    80004b2e:	f062                	sd	s8,32(sp)
    80004b30:	ec66                	sd	s9,24(sp)
    80004b32:	1880                	addi	s0,sp,112
    80004b34:	84aa                	mv	s1,a0
    80004b36:	8aae                	mv	s5,a1
    80004b38:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b3a:	ffffd097          	auipc	ra,0xffffd
    80004b3e:	e6c080e7          	jalr	-404(ra) # 800019a6 <myproc>
    80004b42:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b44:	8526                	mv	a0,s1
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	090080e7          	jalr	144(ra) # 80000bd6 <acquire>
  while(i < n){
    80004b4e:	0d405163          	blez	s4,80004c10 <pipewrite+0xf6>
    80004b52:	8ba6                	mv	s7,s1
  int i = 0;
    80004b54:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b56:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b58:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b5c:	21c48c13          	addi	s8,s1,540
    80004b60:	a08d                	j	80004bc2 <pipewrite+0xa8>
      release(&pi->lock);
    80004b62:	8526                	mv	a0,s1
    80004b64:	ffffc097          	auipc	ra,0xffffc
    80004b68:	126080e7          	jalr	294(ra) # 80000c8a <release>
      return -1;
    80004b6c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b6e:	854a                	mv	a0,s2
    80004b70:	70a6                	ld	ra,104(sp)
    80004b72:	7406                	ld	s0,96(sp)
    80004b74:	64e6                	ld	s1,88(sp)
    80004b76:	6946                	ld	s2,80(sp)
    80004b78:	69a6                	ld	s3,72(sp)
    80004b7a:	6a06                	ld	s4,64(sp)
    80004b7c:	7ae2                	ld	s5,56(sp)
    80004b7e:	7b42                	ld	s6,48(sp)
    80004b80:	7ba2                	ld	s7,40(sp)
    80004b82:	7c02                	ld	s8,32(sp)
    80004b84:	6ce2                	ld	s9,24(sp)
    80004b86:	6165                	addi	sp,sp,112
    80004b88:	8082                	ret
      wakeup(&pi->nread);
    80004b8a:	8566                	mv	a0,s9
    80004b8c:	ffffe097          	auipc	ra,0xffffe
    80004b90:	88c080e7          	jalr	-1908(ra) # 80002418 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b94:	85de                	mv	a1,s7
    80004b96:	8562                	mv	a0,s8
    80004b98:	ffffd097          	auipc	ra,0xffffd
    80004b9c:	6fa080e7          	jalr	1786(ra) # 80002292 <sleep>
    80004ba0:	a839                	j	80004bbe <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ba2:	21c4a783          	lw	a5,540(s1)
    80004ba6:	0017871b          	addiw	a4,a5,1
    80004baa:	20e4ae23          	sw	a4,540(s1)
    80004bae:	1ff7f793          	andi	a5,a5,511
    80004bb2:	97a6                	add	a5,a5,s1
    80004bb4:	f9f44703          	lbu	a4,-97(s0)
    80004bb8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bbc:	2905                	addiw	s2,s2,1
  while(i < n){
    80004bbe:	03495d63          	bge	s2,s4,80004bf8 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004bc2:	2204a783          	lw	a5,544(s1)
    80004bc6:	dfd1                	beqz	a5,80004b62 <pipewrite+0x48>
    80004bc8:	0309a783          	lw	a5,48(s3)
    80004bcc:	fbd9                	bnez	a5,80004b62 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bce:	2184a783          	lw	a5,536(s1)
    80004bd2:	21c4a703          	lw	a4,540(s1)
    80004bd6:	2007879b          	addiw	a5,a5,512
    80004bda:	faf708e3          	beq	a4,a5,80004b8a <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bde:	4685                	li	a3,1
    80004be0:	01590633          	add	a2,s2,s5
    80004be4:	f9f40593          	addi	a1,s0,-97
    80004be8:	0509b503          	ld	a0,80(s3)
    80004bec:	ffffd097          	auipc	ra,0xffffd
    80004bf0:	adc080e7          	jalr	-1316(ra) # 800016c8 <copyin>
    80004bf4:	fb6517e3          	bne	a0,s6,80004ba2 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004bf8:	21848513          	addi	a0,s1,536
    80004bfc:	ffffe097          	auipc	ra,0xffffe
    80004c00:	81c080e7          	jalr	-2020(ra) # 80002418 <wakeup>
  release(&pi->lock);
    80004c04:	8526                	mv	a0,s1
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	084080e7          	jalr	132(ra) # 80000c8a <release>
  return i;
    80004c0e:	b785                	j	80004b6e <pipewrite+0x54>
  int i = 0;
    80004c10:	4901                	li	s2,0
    80004c12:	b7dd                	j	80004bf8 <pipewrite+0xde>

0000000080004c14 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c14:	715d                	addi	sp,sp,-80
    80004c16:	e486                	sd	ra,72(sp)
    80004c18:	e0a2                	sd	s0,64(sp)
    80004c1a:	fc26                	sd	s1,56(sp)
    80004c1c:	f84a                	sd	s2,48(sp)
    80004c1e:	f44e                	sd	s3,40(sp)
    80004c20:	f052                	sd	s4,32(sp)
    80004c22:	ec56                	sd	s5,24(sp)
    80004c24:	e85a                	sd	s6,16(sp)
    80004c26:	0880                	addi	s0,sp,80
    80004c28:	84aa                	mv	s1,a0
    80004c2a:	892e                	mv	s2,a1
    80004c2c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c2e:	ffffd097          	auipc	ra,0xffffd
    80004c32:	d78080e7          	jalr	-648(ra) # 800019a6 <myproc>
    80004c36:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c38:	8b26                	mv	s6,s1
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	f9a080e7          	jalr	-102(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c44:	2184a703          	lw	a4,536(s1)
    80004c48:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c4c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c50:	02f71463          	bne	a4,a5,80004c78 <piperead+0x64>
    80004c54:	2244a783          	lw	a5,548(s1)
    80004c58:	c385                	beqz	a5,80004c78 <piperead+0x64>
    if(pr->killed){
    80004c5a:	030a2783          	lw	a5,48(s4)
    80004c5e:	ebc1                	bnez	a5,80004cee <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c60:	85da                	mv	a1,s6
    80004c62:	854e                	mv	a0,s3
    80004c64:	ffffd097          	auipc	ra,0xffffd
    80004c68:	62e080e7          	jalr	1582(ra) # 80002292 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c6c:	2184a703          	lw	a4,536(s1)
    80004c70:	21c4a783          	lw	a5,540(s1)
    80004c74:	fef700e3          	beq	a4,a5,80004c54 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c78:	09505263          	blez	s5,80004cfc <piperead+0xe8>
    80004c7c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c7e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c80:	2184a783          	lw	a5,536(s1)
    80004c84:	21c4a703          	lw	a4,540(s1)
    80004c88:	02f70d63          	beq	a4,a5,80004cc2 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c8c:	0017871b          	addiw	a4,a5,1
    80004c90:	20e4ac23          	sw	a4,536(s1)
    80004c94:	1ff7f793          	andi	a5,a5,511
    80004c98:	97a6                	add	a5,a5,s1
    80004c9a:	0187c783          	lbu	a5,24(a5)
    80004c9e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ca2:	4685                	li	a3,1
    80004ca4:	fbf40613          	addi	a2,s0,-65
    80004ca8:	85ca                	mv	a1,s2
    80004caa:	050a3503          	ld	a0,80(s4)
    80004cae:	ffffd097          	auipc	ra,0xffffd
    80004cb2:	98e080e7          	jalr	-1650(ra) # 8000163c <copyout>
    80004cb6:	01650663          	beq	a0,s6,80004cc2 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cba:	2985                	addiw	s3,s3,1
    80004cbc:	0905                	addi	s2,s2,1
    80004cbe:	fd3a91e3          	bne	s5,s3,80004c80 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cc2:	21c48513          	addi	a0,s1,540
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	752080e7          	jalr	1874(ra) # 80002418 <wakeup>
  release(&pi->lock);
    80004cce:	8526                	mv	a0,s1
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	fba080e7          	jalr	-70(ra) # 80000c8a <release>
  return i;
}
    80004cd8:	854e                	mv	a0,s3
    80004cda:	60a6                	ld	ra,72(sp)
    80004cdc:	6406                	ld	s0,64(sp)
    80004cde:	74e2                	ld	s1,56(sp)
    80004ce0:	7942                	ld	s2,48(sp)
    80004ce2:	79a2                	ld	s3,40(sp)
    80004ce4:	7a02                	ld	s4,32(sp)
    80004ce6:	6ae2                	ld	s5,24(sp)
    80004ce8:	6b42                	ld	s6,16(sp)
    80004cea:	6161                	addi	sp,sp,80
    80004cec:	8082                	ret
      release(&pi->lock);
    80004cee:	8526                	mv	a0,s1
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	f9a080e7          	jalr	-102(ra) # 80000c8a <release>
      return -1;
    80004cf8:	59fd                	li	s3,-1
    80004cfa:	bff9                	j	80004cd8 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cfc:	4981                	li	s3,0
    80004cfe:	b7d1                	j	80004cc2 <piperead+0xae>

0000000080004d00 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d00:	df010113          	addi	sp,sp,-528
    80004d04:	20113423          	sd	ra,520(sp)
    80004d08:	20813023          	sd	s0,512(sp)
    80004d0c:	ffa6                	sd	s1,504(sp)
    80004d0e:	fbca                	sd	s2,496(sp)
    80004d10:	f7ce                	sd	s3,488(sp)
    80004d12:	f3d2                	sd	s4,480(sp)
    80004d14:	efd6                	sd	s5,472(sp)
    80004d16:	ebda                	sd	s6,464(sp)
    80004d18:	e7de                	sd	s7,456(sp)
    80004d1a:	e3e2                	sd	s8,448(sp)
    80004d1c:	ff66                	sd	s9,440(sp)
    80004d1e:	fb6a                	sd	s10,432(sp)
    80004d20:	f76e                	sd	s11,424(sp)
    80004d22:	0c00                	addi	s0,sp,528
    80004d24:	84aa                	mv	s1,a0
    80004d26:	dea43c23          	sd	a0,-520(s0)
    80004d2a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d2e:	ffffd097          	auipc	ra,0xffffd
    80004d32:	c78080e7          	jalr	-904(ra) # 800019a6 <myproc>
    80004d36:	892a                	mv	s2,a0

  begin_op();
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	494080e7          	jalr	1172(ra) # 800041cc <begin_op>

  if((ip = namei(path)) == 0){
    80004d40:	8526                	mv	a0,s1
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	26e080e7          	jalr	622(ra) # 80003fb0 <namei>
    80004d4a:	c92d                	beqz	a0,80004dbc <exec+0xbc>
    80004d4c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	aac080e7          	jalr	-1364(ra) # 800037fa <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d56:	04000713          	li	a4,64
    80004d5a:	4681                	li	a3,0
    80004d5c:	e4840613          	addi	a2,s0,-440
    80004d60:	4581                	li	a1,0
    80004d62:	8526                	mv	a0,s1
    80004d64:	fffff097          	auipc	ra,0xfffff
    80004d68:	d4a080e7          	jalr	-694(ra) # 80003aae <readi>
    80004d6c:	04000793          	li	a5,64
    80004d70:	00f51a63          	bne	a0,a5,80004d84 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d74:	e4842703          	lw	a4,-440(s0)
    80004d78:	464c47b7          	lui	a5,0x464c4
    80004d7c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d80:	04f70463          	beq	a4,a5,80004dc8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d84:	8526                	mv	a0,s1
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	cd6080e7          	jalr	-810(ra) # 80003a5c <iunlockput>
    end_op();
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	4be080e7          	jalr	1214(ra) # 8000424c <end_op>
  }
  return -1;
    80004d96:	557d                	li	a0,-1
}
    80004d98:	20813083          	ld	ra,520(sp)
    80004d9c:	20013403          	ld	s0,512(sp)
    80004da0:	74fe                	ld	s1,504(sp)
    80004da2:	795e                	ld	s2,496(sp)
    80004da4:	79be                	ld	s3,488(sp)
    80004da6:	7a1e                	ld	s4,480(sp)
    80004da8:	6afe                	ld	s5,472(sp)
    80004daa:	6b5e                	ld	s6,464(sp)
    80004dac:	6bbe                	ld	s7,456(sp)
    80004dae:	6c1e                	ld	s8,448(sp)
    80004db0:	7cfa                	ld	s9,440(sp)
    80004db2:	7d5a                	ld	s10,432(sp)
    80004db4:	7dba                	ld	s11,424(sp)
    80004db6:	21010113          	addi	sp,sp,528
    80004dba:	8082                	ret
    end_op();
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	490080e7          	jalr	1168(ra) # 8000424c <end_op>
    return -1;
    80004dc4:	557d                	li	a0,-1
    80004dc6:	bfc9                	j	80004d98 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dc8:	854a                	mv	a0,s2
    80004dca:	ffffd097          	auipc	ra,0xffffd
    80004dce:	ca0080e7          	jalr	-864(ra) # 80001a6a <proc_pagetable>
    80004dd2:	8baa                	mv	s7,a0
    80004dd4:	d945                	beqz	a0,80004d84 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dd6:	e6842983          	lw	s3,-408(s0)
    80004dda:	e8045783          	lhu	a5,-384(s0)
    80004dde:	c7ad                	beqz	a5,80004e48 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004de0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004de2:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004de4:	6c85                	lui	s9,0x1
    80004de6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004dea:	def43823          	sd	a5,-528(s0)
    80004dee:	a42d                	j	80005018 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004df0:	00004517          	auipc	a0,0x4
    80004df4:	88850513          	addi	a0,a0,-1912 # 80008678 <syscalls+0x290>
    80004df8:	ffffb097          	auipc	ra,0xffffb
    80004dfc:	738080e7          	jalr	1848(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e00:	8756                	mv	a4,s5
    80004e02:	012d86bb          	addw	a3,s11,s2
    80004e06:	4581                	li	a1,0
    80004e08:	8526                	mv	a0,s1
    80004e0a:	fffff097          	auipc	ra,0xfffff
    80004e0e:	ca4080e7          	jalr	-860(ra) # 80003aae <readi>
    80004e12:	2501                	sext.w	a0,a0
    80004e14:	1aaa9963          	bne	s5,a0,80004fc6 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e18:	6785                	lui	a5,0x1
    80004e1a:	0127893b          	addw	s2,a5,s2
    80004e1e:	77fd                	lui	a5,0xfffff
    80004e20:	01478a3b          	addw	s4,a5,s4
    80004e24:	1f897163          	bgeu	s2,s8,80005006 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e28:	02091593          	slli	a1,s2,0x20
    80004e2c:	9181                	srli	a1,a1,0x20
    80004e2e:	95ea                	add	a1,a1,s10
    80004e30:	855e                	mv	a0,s7
    80004e32:	ffffc097          	auipc	ra,0xffffc
    80004e36:	232080e7          	jalr	562(ra) # 80001064 <walkaddr>
    80004e3a:	862a                	mv	a2,a0
    if(pa == 0)
    80004e3c:	d955                	beqz	a0,80004df0 <exec+0xf0>
      n = PGSIZE;
    80004e3e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e40:	fd9a70e3          	bgeu	s4,s9,80004e00 <exec+0x100>
      n = sz - i;
    80004e44:	8ad2                	mv	s5,s4
    80004e46:	bf6d                	j	80004e00 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e48:	4901                	li	s2,0
  iunlockput(ip);
    80004e4a:	8526                	mv	a0,s1
    80004e4c:	fffff097          	auipc	ra,0xfffff
    80004e50:	c10080e7          	jalr	-1008(ra) # 80003a5c <iunlockput>
  end_op();
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	3f8080e7          	jalr	1016(ra) # 8000424c <end_op>
  p = myproc();
    80004e5c:	ffffd097          	auipc	ra,0xffffd
    80004e60:	b4a080e7          	jalr	-1206(ra) # 800019a6 <myproc>
    80004e64:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e66:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e6a:	6785                	lui	a5,0x1
    80004e6c:	17fd                	addi	a5,a5,-1
    80004e6e:	993e                	add	s2,s2,a5
    80004e70:	757d                	lui	a0,0xfffff
    80004e72:	00a977b3          	and	a5,s2,a0
    80004e76:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e7a:	6609                	lui	a2,0x2
    80004e7c:	963e                	add	a2,a2,a5
    80004e7e:	85be                	mv	a1,a5
    80004e80:	855e                	mv	a0,s7
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	576080e7          	jalr	1398(ra) # 800013f8 <uvmalloc>
    80004e8a:	8b2a                	mv	s6,a0
  ip = 0;
    80004e8c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e8e:	12050c63          	beqz	a0,80004fc6 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e92:	75f9                	lui	a1,0xffffe
    80004e94:	95aa                	add	a1,a1,a0
    80004e96:	855e                	mv	a0,s7
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	772080e7          	jalr	1906(ra) # 8000160a <uvmclear>
  stackbase = sp - PGSIZE;
    80004ea0:	7c7d                	lui	s8,0xfffff
    80004ea2:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ea4:	e0043783          	ld	a5,-512(s0)
    80004ea8:	6388                	ld	a0,0(a5)
    80004eaa:	c535                	beqz	a0,80004f16 <exec+0x216>
    80004eac:	e8840993          	addi	s3,s0,-376
    80004eb0:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004eb4:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	fa4080e7          	jalr	-92(ra) # 80000e5a <strlen>
    80004ebe:	2505                	addiw	a0,a0,1
    80004ec0:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ec4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ec8:	13896363          	bltu	s2,s8,80004fee <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ecc:	e0043d83          	ld	s11,-512(s0)
    80004ed0:	000dba03          	ld	s4,0(s11)
    80004ed4:	8552                	mv	a0,s4
    80004ed6:	ffffc097          	auipc	ra,0xffffc
    80004eda:	f84080e7          	jalr	-124(ra) # 80000e5a <strlen>
    80004ede:	0015069b          	addiw	a3,a0,1
    80004ee2:	8652                	mv	a2,s4
    80004ee4:	85ca                	mv	a1,s2
    80004ee6:	855e                	mv	a0,s7
    80004ee8:	ffffc097          	auipc	ra,0xffffc
    80004eec:	754080e7          	jalr	1876(ra) # 8000163c <copyout>
    80004ef0:	10054363          	bltz	a0,80004ff6 <exec+0x2f6>
    ustack[argc] = sp;
    80004ef4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ef8:	0485                	addi	s1,s1,1
    80004efa:	008d8793          	addi	a5,s11,8
    80004efe:	e0f43023          	sd	a5,-512(s0)
    80004f02:	008db503          	ld	a0,8(s11)
    80004f06:	c911                	beqz	a0,80004f1a <exec+0x21a>
    if(argc >= MAXARG)
    80004f08:	09a1                	addi	s3,s3,8
    80004f0a:	fb3c96e3          	bne	s9,s3,80004eb6 <exec+0x1b6>
  sz = sz1;
    80004f0e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f12:	4481                	li	s1,0
    80004f14:	a84d                	j	80004fc6 <exec+0x2c6>
  sp = sz;
    80004f16:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f18:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f1a:	00349793          	slli	a5,s1,0x3
    80004f1e:	f9040713          	addi	a4,s0,-112
    80004f22:	97ba                	add	a5,a5,a4
    80004f24:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004f28:	00148693          	addi	a3,s1,1
    80004f2c:	068e                	slli	a3,a3,0x3
    80004f2e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f32:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f36:	01897663          	bgeu	s2,s8,80004f42 <exec+0x242>
  sz = sz1;
    80004f3a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f3e:	4481                	li	s1,0
    80004f40:	a059                	j	80004fc6 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f42:	e8840613          	addi	a2,s0,-376
    80004f46:	85ca                	mv	a1,s2
    80004f48:	855e                	mv	a0,s7
    80004f4a:	ffffc097          	auipc	ra,0xffffc
    80004f4e:	6f2080e7          	jalr	1778(ra) # 8000163c <copyout>
    80004f52:	0a054663          	bltz	a0,80004ffe <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f56:	058ab783          	ld	a5,88(s5)
    80004f5a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f5e:	df843783          	ld	a5,-520(s0)
    80004f62:	0007c703          	lbu	a4,0(a5)
    80004f66:	cf11                	beqz	a4,80004f82 <exec+0x282>
    80004f68:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f6a:	02f00693          	li	a3,47
    80004f6e:	a029                	j	80004f78 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f70:	0785                	addi	a5,a5,1
    80004f72:	fff7c703          	lbu	a4,-1(a5)
    80004f76:	c711                	beqz	a4,80004f82 <exec+0x282>
    if(*s == '/')
    80004f78:	fed71ce3          	bne	a4,a3,80004f70 <exec+0x270>
      last = s+1;
    80004f7c:	def43c23          	sd	a5,-520(s0)
    80004f80:	bfc5                	j	80004f70 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f82:	4641                	li	a2,16
    80004f84:	df843583          	ld	a1,-520(s0)
    80004f88:	158a8513          	addi	a0,s5,344
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	e9c080e7          	jalr	-356(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f94:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f98:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f9c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fa0:	058ab783          	ld	a5,88(s5)
    80004fa4:	e6043703          	ld	a4,-416(s0)
    80004fa8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004faa:	058ab783          	ld	a5,88(s5)
    80004fae:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fb2:	85ea                	mv	a1,s10
    80004fb4:	ffffd097          	auipc	ra,0xffffd
    80004fb8:	b52080e7          	jalr	-1198(ra) # 80001b06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fbc:	0004851b          	sext.w	a0,s1
    80004fc0:	bbe1                	j	80004d98 <exec+0x98>
    80004fc2:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fc6:	e0843583          	ld	a1,-504(s0)
    80004fca:	855e                	mv	a0,s7
    80004fcc:	ffffd097          	auipc	ra,0xffffd
    80004fd0:	b3a080e7          	jalr	-1222(ra) # 80001b06 <proc_freepagetable>
  if(ip){
    80004fd4:	da0498e3          	bnez	s1,80004d84 <exec+0x84>
  return -1;
    80004fd8:	557d                	li	a0,-1
    80004fda:	bb7d                	j	80004d98 <exec+0x98>
    80004fdc:	e1243423          	sd	s2,-504(s0)
    80004fe0:	b7dd                	j	80004fc6 <exec+0x2c6>
    80004fe2:	e1243423          	sd	s2,-504(s0)
    80004fe6:	b7c5                	j	80004fc6 <exec+0x2c6>
    80004fe8:	e1243423          	sd	s2,-504(s0)
    80004fec:	bfe9                	j	80004fc6 <exec+0x2c6>
  sz = sz1;
    80004fee:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ff2:	4481                	li	s1,0
    80004ff4:	bfc9                	j	80004fc6 <exec+0x2c6>
  sz = sz1;
    80004ff6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ffa:	4481                	li	s1,0
    80004ffc:	b7e9                	j	80004fc6 <exec+0x2c6>
  sz = sz1;
    80004ffe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005002:	4481                	li	s1,0
    80005004:	b7c9                	j	80004fc6 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005006:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000500a:	2b05                	addiw	s6,s6,1
    8000500c:	0389899b          	addiw	s3,s3,56
    80005010:	e8045783          	lhu	a5,-384(s0)
    80005014:	e2fb5be3          	bge	s6,a5,80004e4a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005018:	2981                	sext.w	s3,s3
    8000501a:	03800713          	li	a4,56
    8000501e:	86ce                	mv	a3,s3
    80005020:	e1040613          	addi	a2,s0,-496
    80005024:	4581                	li	a1,0
    80005026:	8526                	mv	a0,s1
    80005028:	fffff097          	auipc	ra,0xfffff
    8000502c:	a86080e7          	jalr	-1402(ra) # 80003aae <readi>
    80005030:	03800793          	li	a5,56
    80005034:	f8f517e3          	bne	a0,a5,80004fc2 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005038:	e1042783          	lw	a5,-496(s0)
    8000503c:	4705                	li	a4,1
    8000503e:	fce796e3          	bne	a5,a4,8000500a <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005042:	e3843603          	ld	a2,-456(s0)
    80005046:	e3043783          	ld	a5,-464(s0)
    8000504a:	f8f669e3          	bltu	a2,a5,80004fdc <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000504e:	e2043783          	ld	a5,-480(s0)
    80005052:	963e                	add	a2,a2,a5
    80005054:	f8f667e3          	bltu	a2,a5,80004fe2 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005058:	85ca                	mv	a1,s2
    8000505a:	855e                	mv	a0,s7
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	39c080e7          	jalr	924(ra) # 800013f8 <uvmalloc>
    80005064:	e0a43423          	sd	a0,-504(s0)
    80005068:	d141                	beqz	a0,80004fe8 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    8000506a:	e2043d03          	ld	s10,-480(s0)
    8000506e:	df043783          	ld	a5,-528(s0)
    80005072:	00fd77b3          	and	a5,s10,a5
    80005076:	fba1                	bnez	a5,80004fc6 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005078:	e1842d83          	lw	s11,-488(s0)
    8000507c:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005080:	f80c03e3          	beqz	s8,80005006 <exec+0x306>
    80005084:	8a62                	mv	s4,s8
    80005086:	4901                	li	s2,0
    80005088:	b345                	j	80004e28 <exec+0x128>

000000008000508a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000508a:	7179                	addi	sp,sp,-48
    8000508c:	f406                	sd	ra,40(sp)
    8000508e:	f022                	sd	s0,32(sp)
    80005090:	ec26                	sd	s1,24(sp)
    80005092:	e84a                	sd	s2,16(sp)
    80005094:	1800                	addi	s0,sp,48
    80005096:	892e                	mv	s2,a1
    80005098:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000509a:	fdc40593          	addi	a1,s0,-36
    8000509e:	ffffe097          	auipc	ra,0xffffe
    800050a2:	bea080e7          	jalr	-1046(ra) # 80002c88 <argint>
    800050a6:	04054063          	bltz	a0,800050e6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050aa:	fdc42703          	lw	a4,-36(s0)
    800050ae:	47bd                	li	a5,15
    800050b0:	02e7ed63          	bltu	a5,a4,800050ea <argfd+0x60>
    800050b4:	ffffd097          	auipc	ra,0xffffd
    800050b8:	8f2080e7          	jalr	-1806(ra) # 800019a6 <myproc>
    800050bc:	fdc42703          	lw	a4,-36(s0)
    800050c0:	01a70793          	addi	a5,a4,26
    800050c4:	078e                	slli	a5,a5,0x3
    800050c6:	953e                	add	a0,a0,a5
    800050c8:	611c                	ld	a5,0(a0)
    800050ca:	c395                	beqz	a5,800050ee <argfd+0x64>
    return -1;
  if(pfd)
    800050cc:	00090463          	beqz	s2,800050d4 <argfd+0x4a>
    *pfd = fd;
    800050d0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050d4:	4501                	li	a0,0
  if(pf)
    800050d6:	c091                	beqz	s1,800050da <argfd+0x50>
    *pf = f;
    800050d8:	e09c                	sd	a5,0(s1)
}
    800050da:	70a2                	ld	ra,40(sp)
    800050dc:	7402                	ld	s0,32(sp)
    800050de:	64e2                	ld	s1,24(sp)
    800050e0:	6942                	ld	s2,16(sp)
    800050e2:	6145                	addi	sp,sp,48
    800050e4:	8082                	ret
    return -1;
    800050e6:	557d                	li	a0,-1
    800050e8:	bfcd                	j	800050da <argfd+0x50>
    return -1;
    800050ea:	557d                	li	a0,-1
    800050ec:	b7fd                	j	800050da <argfd+0x50>
    800050ee:	557d                	li	a0,-1
    800050f0:	b7ed                	j	800050da <argfd+0x50>

00000000800050f2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050f2:	1101                	addi	sp,sp,-32
    800050f4:	ec06                	sd	ra,24(sp)
    800050f6:	e822                	sd	s0,16(sp)
    800050f8:	e426                	sd	s1,8(sp)
    800050fa:	1000                	addi	s0,sp,32
    800050fc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050fe:	ffffd097          	auipc	ra,0xffffd
    80005102:	8a8080e7          	jalr	-1880(ra) # 800019a6 <myproc>
    80005106:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005108:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffcd0d0>
    8000510c:	4501                	li	a0,0
    8000510e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005110:	6398                	ld	a4,0(a5)
    80005112:	cb19                	beqz	a4,80005128 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005114:	2505                	addiw	a0,a0,1
    80005116:	07a1                	addi	a5,a5,8
    80005118:	fed51ce3          	bne	a0,a3,80005110 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000511c:	557d                	li	a0,-1
}
    8000511e:	60e2                	ld	ra,24(sp)
    80005120:	6442                	ld	s0,16(sp)
    80005122:	64a2                	ld	s1,8(sp)
    80005124:	6105                	addi	sp,sp,32
    80005126:	8082                	ret
      p->ofile[fd] = f;
    80005128:	01a50793          	addi	a5,a0,26
    8000512c:	078e                	slli	a5,a5,0x3
    8000512e:	963e                	add	a2,a2,a5
    80005130:	e204                	sd	s1,0(a2)
      return fd;
    80005132:	b7f5                	j	8000511e <fdalloc+0x2c>

0000000080005134 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005134:	715d                	addi	sp,sp,-80
    80005136:	e486                	sd	ra,72(sp)
    80005138:	e0a2                	sd	s0,64(sp)
    8000513a:	fc26                	sd	s1,56(sp)
    8000513c:	f84a                	sd	s2,48(sp)
    8000513e:	f44e                	sd	s3,40(sp)
    80005140:	f052                	sd	s4,32(sp)
    80005142:	ec56                	sd	s5,24(sp)
    80005144:	0880                	addi	s0,sp,80
    80005146:	89ae                	mv	s3,a1
    80005148:	8ab2                	mv	s5,a2
    8000514a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000514c:	fb040593          	addi	a1,s0,-80
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	e7e080e7          	jalr	-386(ra) # 80003fce <nameiparent>
    80005158:	892a                	mv	s2,a0
    8000515a:	12050f63          	beqz	a0,80005298 <create+0x164>
    return 0;

  ilock(dp);
    8000515e:	ffffe097          	auipc	ra,0xffffe
    80005162:	69c080e7          	jalr	1692(ra) # 800037fa <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005166:	4601                	li	a2,0
    80005168:	fb040593          	addi	a1,s0,-80
    8000516c:	854a                	mv	a0,s2
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	b70080e7          	jalr	-1168(ra) # 80003cde <dirlookup>
    80005176:	84aa                	mv	s1,a0
    80005178:	c921                	beqz	a0,800051c8 <create+0x94>
    iunlockput(dp);
    8000517a:	854a                	mv	a0,s2
    8000517c:	fffff097          	auipc	ra,0xfffff
    80005180:	8e0080e7          	jalr	-1824(ra) # 80003a5c <iunlockput>
    ilock(ip);
    80005184:	8526                	mv	a0,s1
    80005186:	ffffe097          	auipc	ra,0xffffe
    8000518a:	674080e7          	jalr	1652(ra) # 800037fa <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000518e:	2981                	sext.w	s3,s3
    80005190:	4789                	li	a5,2
    80005192:	02f99463          	bne	s3,a5,800051ba <create+0x86>
    80005196:	0444d783          	lhu	a5,68(s1)
    8000519a:	37f9                	addiw	a5,a5,-2
    8000519c:	17c2                	slli	a5,a5,0x30
    8000519e:	93c1                	srli	a5,a5,0x30
    800051a0:	4705                	li	a4,1
    800051a2:	00f76c63          	bltu	a4,a5,800051ba <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051a6:	8526                	mv	a0,s1
    800051a8:	60a6                	ld	ra,72(sp)
    800051aa:	6406                	ld	s0,64(sp)
    800051ac:	74e2                	ld	s1,56(sp)
    800051ae:	7942                	ld	s2,48(sp)
    800051b0:	79a2                	ld	s3,40(sp)
    800051b2:	7a02                	ld	s4,32(sp)
    800051b4:	6ae2                	ld	s5,24(sp)
    800051b6:	6161                	addi	sp,sp,80
    800051b8:	8082                	ret
    iunlockput(ip);
    800051ba:	8526                	mv	a0,s1
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	8a0080e7          	jalr	-1888(ra) # 80003a5c <iunlockput>
    return 0;
    800051c4:	4481                	li	s1,0
    800051c6:	b7c5                	j	800051a6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051c8:	85ce                	mv	a1,s3
    800051ca:	00092503          	lw	a0,0(s2)
    800051ce:	ffffe097          	auipc	ra,0xffffe
    800051d2:	494080e7          	jalr	1172(ra) # 80003662 <ialloc>
    800051d6:	84aa                	mv	s1,a0
    800051d8:	c529                	beqz	a0,80005222 <create+0xee>
  ilock(ip);
    800051da:	ffffe097          	auipc	ra,0xffffe
    800051de:	620080e7          	jalr	1568(ra) # 800037fa <ilock>
  ip->major = major;
    800051e2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051e6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051ea:	4785                	li	a5,1
    800051ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051f0:	8526                	mv	a0,s1
    800051f2:	ffffe097          	auipc	ra,0xffffe
    800051f6:	53e080e7          	jalr	1342(ra) # 80003730 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051fa:	2981                	sext.w	s3,s3
    800051fc:	4785                	li	a5,1
    800051fe:	02f98a63          	beq	s3,a5,80005232 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005202:	40d0                	lw	a2,4(s1)
    80005204:	fb040593          	addi	a1,s0,-80
    80005208:	854a                	mv	a0,s2
    8000520a:	fffff097          	auipc	ra,0xfffff
    8000520e:	ce4080e7          	jalr	-796(ra) # 80003eee <dirlink>
    80005212:	06054b63          	bltz	a0,80005288 <create+0x154>
  iunlockput(dp);
    80005216:	854a                	mv	a0,s2
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	844080e7          	jalr	-1980(ra) # 80003a5c <iunlockput>
  return ip;
    80005220:	b759                	j	800051a6 <create+0x72>
    panic("create: ialloc");
    80005222:	00003517          	auipc	a0,0x3
    80005226:	47650513          	addi	a0,a0,1142 # 80008698 <syscalls+0x2b0>
    8000522a:	ffffb097          	auipc	ra,0xffffb
    8000522e:	306080e7          	jalr	774(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    80005232:	04a95783          	lhu	a5,74(s2)
    80005236:	2785                	addiw	a5,a5,1
    80005238:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000523c:	854a                	mv	a0,s2
    8000523e:	ffffe097          	auipc	ra,0xffffe
    80005242:	4f2080e7          	jalr	1266(ra) # 80003730 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005246:	40d0                	lw	a2,4(s1)
    80005248:	00003597          	auipc	a1,0x3
    8000524c:	46058593          	addi	a1,a1,1120 # 800086a8 <syscalls+0x2c0>
    80005250:	8526                	mv	a0,s1
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	c9c080e7          	jalr	-868(ra) # 80003eee <dirlink>
    8000525a:	00054f63          	bltz	a0,80005278 <create+0x144>
    8000525e:	00492603          	lw	a2,4(s2)
    80005262:	00003597          	auipc	a1,0x3
    80005266:	44e58593          	addi	a1,a1,1102 # 800086b0 <syscalls+0x2c8>
    8000526a:	8526                	mv	a0,s1
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	c82080e7          	jalr	-894(ra) # 80003eee <dirlink>
    80005274:	f80557e3          	bgez	a0,80005202 <create+0xce>
      panic("create dots");
    80005278:	00003517          	auipc	a0,0x3
    8000527c:	44050513          	addi	a0,a0,1088 # 800086b8 <syscalls+0x2d0>
    80005280:	ffffb097          	auipc	ra,0xffffb
    80005284:	2b0080e7          	jalr	688(ra) # 80000530 <panic>
    panic("create: dirlink");
    80005288:	00003517          	auipc	a0,0x3
    8000528c:	44050513          	addi	a0,a0,1088 # 800086c8 <syscalls+0x2e0>
    80005290:	ffffb097          	auipc	ra,0xffffb
    80005294:	2a0080e7          	jalr	672(ra) # 80000530 <panic>
    return 0;
    80005298:	84aa                	mv	s1,a0
    8000529a:	b731                	j	800051a6 <create+0x72>

000000008000529c <sys_dup>:
{
    8000529c:	7179                	addi	sp,sp,-48
    8000529e:	f406                	sd	ra,40(sp)
    800052a0:	f022                	sd	s0,32(sp)
    800052a2:	ec26                	sd	s1,24(sp)
    800052a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052a6:	fd840613          	addi	a2,s0,-40
    800052aa:	4581                	li	a1,0
    800052ac:	4501                	li	a0,0
    800052ae:	00000097          	auipc	ra,0x0
    800052b2:	ddc080e7          	jalr	-548(ra) # 8000508a <argfd>
    return -1;
    800052b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052b8:	02054363          	bltz	a0,800052de <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052bc:	fd843503          	ld	a0,-40(s0)
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	e32080e7          	jalr	-462(ra) # 800050f2 <fdalloc>
    800052c8:	84aa                	mv	s1,a0
    return -1;
    800052ca:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052cc:	00054963          	bltz	a0,800052de <sys_dup+0x42>
  filedup(f);
    800052d0:	fd843503          	ld	a0,-40(s0)
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	37a080e7          	jalr	890(ra) # 8000464e <filedup>
  return fd;
    800052dc:	87a6                	mv	a5,s1
}
    800052de:	853e                	mv	a0,a5
    800052e0:	70a2                	ld	ra,40(sp)
    800052e2:	7402                	ld	s0,32(sp)
    800052e4:	64e2                	ld	s1,24(sp)
    800052e6:	6145                	addi	sp,sp,48
    800052e8:	8082                	ret

00000000800052ea <sys_read>:
{
    800052ea:	7179                	addi	sp,sp,-48
    800052ec:	f406                	sd	ra,40(sp)
    800052ee:	f022                	sd	s0,32(sp)
    800052f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f2:	fe840613          	addi	a2,s0,-24
    800052f6:	4581                	li	a1,0
    800052f8:	4501                	li	a0,0
    800052fa:	00000097          	auipc	ra,0x0
    800052fe:	d90080e7          	jalr	-624(ra) # 8000508a <argfd>
    return -1;
    80005302:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005304:	04054163          	bltz	a0,80005346 <sys_read+0x5c>
    80005308:	fe440593          	addi	a1,s0,-28
    8000530c:	4509                	li	a0,2
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	97a080e7          	jalr	-1670(ra) # 80002c88 <argint>
    return -1;
    80005316:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005318:	02054763          	bltz	a0,80005346 <sys_read+0x5c>
    8000531c:	fd840593          	addi	a1,s0,-40
    80005320:	4505                	li	a0,1
    80005322:	ffffe097          	auipc	ra,0xffffe
    80005326:	988080e7          	jalr	-1656(ra) # 80002caa <argaddr>
    return -1;
    8000532a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000532c:	00054d63          	bltz	a0,80005346 <sys_read+0x5c>
  return fileread(f, p, n);
    80005330:	fe442603          	lw	a2,-28(s0)
    80005334:	fd843583          	ld	a1,-40(s0)
    80005338:	fe843503          	ld	a0,-24(s0)
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	49e080e7          	jalr	1182(ra) # 800047da <fileread>
    80005344:	87aa                	mv	a5,a0
}
    80005346:	853e                	mv	a0,a5
    80005348:	70a2                	ld	ra,40(sp)
    8000534a:	7402                	ld	s0,32(sp)
    8000534c:	6145                	addi	sp,sp,48
    8000534e:	8082                	ret

0000000080005350 <sys_write>:
{
    80005350:	7179                	addi	sp,sp,-48
    80005352:	f406                	sd	ra,40(sp)
    80005354:	f022                	sd	s0,32(sp)
    80005356:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005358:	fe840613          	addi	a2,s0,-24
    8000535c:	4581                	li	a1,0
    8000535e:	4501                	li	a0,0
    80005360:	00000097          	auipc	ra,0x0
    80005364:	d2a080e7          	jalr	-726(ra) # 8000508a <argfd>
    return -1;
    80005368:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000536a:	04054163          	bltz	a0,800053ac <sys_write+0x5c>
    8000536e:	fe440593          	addi	a1,s0,-28
    80005372:	4509                	li	a0,2
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	914080e7          	jalr	-1772(ra) # 80002c88 <argint>
    return -1;
    8000537c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537e:	02054763          	bltz	a0,800053ac <sys_write+0x5c>
    80005382:	fd840593          	addi	a1,s0,-40
    80005386:	4505                	li	a0,1
    80005388:	ffffe097          	auipc	ra,0xffffe
    8000538c:	922080e7          	jalr	-1758(ra) # 80002caa <argaddr>
    return -1;
    80005390:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005392:	00054d63          	bltz	a0,800053ac <sys_write+0x5c>
  return filewrite(f, p, n);
    80005396:	fe442603          	lw	a2,-28(s0)
    8000539a:	fd843583          	ld	a1,-40(s0)
    8000539e:	fe843503          	ld	a0,-24(s0)
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	4fa080e7          	jalr	1274(ra) # 8000489c <filewrite>
    800053aa:	87aa                	mv	a5,a0
}
    800053ac:	853e                	mv	a0,a5
    800053ae:	70a2                	ld	ra,40(sp)
    800053b0:	7402                	ld	s0,32(sp)
    800053b2:	6145                	addi	sp,sp,48
    800053b4:	8082                	ret

00000000800053b6 <sys_close>:
{
    800053b6:	1101                	addi	sp,sp,-32
    800053b8:	ec06                	sd	ra,24(sp)
    800053ba:	e822                	sd	s0,16(sp)
    800053bc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053be:	fe040613          	addi	a2,s0,-32
    800053c2:	fec40593          	addi	a1,s0,-20
    800053c6:	4501                	li	a0,0
    800053c8:	00000097          	auipc	ra,0x0
    800053cc:	cc2080e7          	jalr	-830(ra) # 8000508a <argfd>
    return -1;
    800053d0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053d2:	02054463          	bltz	a0,800053fa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053d6:	ffffc097          	auipc	ra,0xffffc
    800053da:	5d0080e7          	jalr	1488(ra) # 800019a6 <myproc>
    800053de:	fec42783          	lw	a5,-20(s0)
    800053e2:	07e9                	addi	a5,a5,26
    800053e4:	078e                	slli	a5,a5,0x3
    800053e6:	97aa                	add	a5,a5,a0
    800053e8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053ec:	fe043503          	ld	a0,-32(s0)
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	2b0080e7          	jalr	688(ra) # 800046a0 <fileclose>
  return 0;
    800053f8:	4781                	li	a5,0
}
    800053fa:	853e                	mv	a0,a5
    800053fc:	60e2                	ld	ra,24(sp)
    800053fe:	6442                	ld	s0,16(sp)
    80005400:	6105                	addi	sp,sp,32
    80005402:	8082                	ret

0000000080005404 <sys_fstat>:
{
    80005404:	1101                	addi	sp,sp,-32
    80005406:	ec06                	sd	ra,24(sp)
    80005408:	e822                	sd	s0,16(sp)
    8000540a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000540c:	fe840613          	addi	a2,s0,-24
    80005410:	4581                	li	a1,0
    80005412:	4501                	li	a0,0
    80005414:	00000097          	auipc	ra,0x0
    80005418:	c76080e7          	jalr	-906(ra) # 8000508a <argfd>
    return -1;
    8000541c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000541e:	02054563          	bltz	a0,80005448 <sys_fstat+0x44>
    80005422:	fe040593          	addi	a1,s0,-32
    80005426:	4505                	li	a0,1
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	882080e7          	jalr	-1918(ra) # 80002caa <argaddr>
    return -1;
    80005430:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005432:	00054b63          	bltz	a0,80005448 <sys_fstat+0x44>
  return filestat(f, st);
    80005436:	fe043583          	ld	a1,-32(s0)
    8000543a:	fe843503          	ld	a0,-24(s0)
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	32a080e7          	jalr	810(ra) # 80004768 <filestat>
    80005446:	87aa                	mv	a5,a0
}
    80005448:	853e                	mv	a0,a5
    8000544a:	60e2                	ld	ra,24(sp)
    8000544c:	6442                	ld	s0,16(sp)
    8000544e:	6105                	addi	sp,sp,32
    80005450:	8082                	ret

0000000080005452 <sys_link>:
{
    80005452:	7169                	addi	sp,sp,-304
    80005454:	f606                	sd	ra,296(sp)
    80005456:	f222                	sd	s0,288(sp)
    80005458:	ee26                	sd	s1,280(sp)
    8000545a:	ea4a                	sd	s2,272(sp)
    8000545c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000545e:	08000613          	li	a2,128
    80005462:	ed040593          	addi	a1,s0,-304
    80005466:	4501                	li	a0,0
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	864080e7          	jalr	-1948(ra) # 80002ccc <argstr>
    return -1;
    80005470:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005472:	10054e63          	bltz	a0,8000558e <sys_link+0x13c>
    80005476:	08000613          	li	a2,128
    8000547a:	f5040593          	addi	a1,s0,-176
    8000547e:	4505                	li	a0,1
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	84c080e7          	jalr	-1972(ra) # 80002ccc <argstr>
    return -1;
    80005488:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000548a:	10054263          	bltz	a0,8000558e <sys_link+0x13c>
  begin_op();
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	d3e080e7          	jalr	-706(ra) # 800041cc <begin_op>
  if((ip = namei(old)) == 0){
    80005496:	ed040513          	addi	a0,s0,-304
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	b16080e7          	jalr	-1258(ra) # 80003fb0 <namei>
    800054a2:	84aa                	mv	s1,a0
    800054a4:	c551                	beqz	a0,80005530 <sys_link+0xde>
  ilock(ip);
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	354080e7          	jalr	852(ra) # 800037fa <ilock>
  if(ip->type == T_DIR){
    800054ae:	04449703          	lh	a4,68(s1)
    800054b2:	4785                	li	a5,1
    800054b4:	08f70463          	beq	a4,a5,8000553c <sys_link+0xea>
  ip->nlink++;
    800054b8:	04a4d783          	lhu	a5,74(s1)
    800054bc:	2785                	addiw	a5,a5,1
    800054be:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054c2:	8526                	mv	a0,s1
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	26c080e7          	jalr	620(ra) # 80003730 <iupdate>
  iunlock(ip);
    800054cc:	8526                	mv	a0,s1
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	3ee080e7          	jalr	1006(ra) # 800038bc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054d6:	fd040593          	addi	a1,s0,-48
    800054da:	f5040513          	addi	a0,s0,-176
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	af0080e7          	jalr	-1296(ra) # 80003fce <nameiparent>
    800054e6:	892a                	mv	s2,a0
    800054e8:	c935                	beqz	a0,8000555c <sys_link+0x10a>
  ilock(dp);
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	310080e7          	jalr	784(ra) # 800037fa <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054f2:	00092703          	lw	a4,0(s2)
    800054f6:	409c                	lw	a5,0(s1)
    800054f8:	04f71d63          	bne	a4,a5,80005552 <sys_link+0x100>
    800054fc:	40d0                	lw	a2,4(s1)
    800054fe:	fd040593          	addi	a1,s0,-48
    80005502:	854a                	mv	a0,s2
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	9ea080e7          	jalr	-1558(ra) # 80003eee <dirlink>
    8000550c:	04054363          	bltz	a0,80005552 <sys_link+0x100>
  iunlockput(dp);
    80005510:	854a                	mv	a0,s2
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	54a080e7          	jalr	1354(ra) # 80003a5c <iunlockput>
  iput(ip);
    8000551a:	8526                	mv	a0,s1
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	498080e7          	jalr	1176(ra) # 800039b4 <iput>
  end_op();
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	d28080e7          	jalr	-728(ra) # 8000424c <end_op>
  return 0;
    8000552c:	4781                	li	a5,0
    8000552e:	a085                	j	8000558e <sys_link+0x13c>
    end_op();
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	d1c080e7          	jalr	-740(ra) # 8000424c <end_op>
    return -1;
    80005538:	57fd                	li	a5,-1
    8000553a:	a891                	j	8000558e <sys_link+0x13c>
    iunlockput(ip);
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	51e080e7          	jalr	1310(ra) # 80003a5c <iunlockput>
    end_op();
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	d06080e7          	jalr	-762(ra) # 8000424c <end_op>
    return -1;
    8000554e:	57fd                	li	a5,-1
    80005550:	a83d                	j	8000558e <sys_link+0x13c>
    iunlockput(dp);
    80005552:	854a                	mv	a0,s2
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	508080e7          	jalr	1288(ra) # 80003a5c <iunlockput>
  ilock(ip);
    8000555c:	8526                	mv	a0,s1
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	29c080e7          	jalr	668(ra) # 800037fa <ilock>
  ip->nlink--;
    80005566:	04a4d783          	lhu	a5,74(s1)
    8000556a:	37fd                	addiw	a5,a5,-1
    8000556c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005570:	8526                	mv	a0,s1
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	1be080e7          	jalr	446(ra) # 80003730 <iupdate>
  iunlockput(ip);
    8000557a:	8526                	mv	a0,s1
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	4e0080e7          	jalr	1248(ra) # 80003a5c <iunlockput>
  end_op();
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	cc8080e7          	jalr	-824(ra) # 8000424c <end_op>
  return -1;
    8000558c:	57fd                	li	a5,-1
}
    8000558e:	853e                	mv	a0,a5
    80005590:	70b2                	ld	ra,296(sp)
    80005592:	7412                	ld	s0,288(sp)
    80005594:	64f2                	ld	s1,280(sp)
    80005596:	6952                	ld	s2,272(sp)
    80005598:	6155                	addi	sp,sp,304
    8000559a:	8082                	ret

000000008000559c <sys_unlink>:
{
    8000559c:	7151                	addi	sp,sp,-240
    8000559e:	f586                	sd	ra,232(sp)
    800055a0:	f1a2                	sd	s0,224(sp)
    800055a2:	eda6                	sd	s1,216(sp)
    800055a4:	e9ca                	sd	s2,208(sp)
    800055a6:	e5ce                	sd	s3,200(sp)
    800055a8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055aa:	08000613          	li	a2,128
    800055ae:	f3040593          	addi	a1,s0,-208
    800055b2:	4501                	li	a0,0
    800055b4:	ffffd097          	auipc	ra,0xffffd
    800055b8:	718080e7          	jalr	1816(ra) # 80002ccc <argstr>
    800055bc:	18054163          	bltz	a0,8000573e <sys_unlink+0x1a2>
  begin_op();
    800055c0:	fffff097          	auipc	ra,0xfffff
    800055c4:	c0c080e7          	jalr	-1012(ra) # 800041cc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055c8:	fb040593          	addi	a1,s0,-80
    800055cc:	f3040513          	addi	a0,s0,-208
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	9fe080e7          	jalr	-1538(ra) # 80003fce <nameiparent>
    800055d8:	84aa                	mv	s1,a0
    800055da:	c979                	beqz	a0,800056b0 <sys_unlink+0x114>
  ilock(dp);
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	21e080e7          	jalr	542(ra) # 800037fa <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055e4:	00003597          	auipc	a1,0x3
    800055e8:	0c458593          	addi	a1,a1,196 # 800086a8 <syscalls+0x2c0>
    800055ec:	fb040513          	addi	a0,s0,-80
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	6d4080e7          	jalr	1748(ra) # 80003cc4 <namecmp>
    800055f8:	14050a63          	beqz	a0,8000574c <sys_unlink+0x1b0>
    800055fc:	00003597          	auipc	a1,0x3
    80005600:	0b458593          	addi	a1,a1,180 # 800086b0 <syscalls+0x2c8>
    80005604:	fb040513          	addi	a0,s0,-80
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	6bc080e7          	jalr	1724(ra) # 80003cc4 <namecmp>
    80005610:	12050e63          	beqz	a0,8000574c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005614:	f2c40613          	addi	a2,s0,-212
    80005618:	fb040593          	addi	a1,s0,-80
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	6c0080e7          	jalr	1728(ra) # 80003cde <dirlookup>
    80005626:	892a                	mv	s2,a0
    80005628:	12050263          	beqz	a0,8000574c <sys_unlink+0x1b0>
  ilock(ip);
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	1ce080e7          	jalr	462(ra) # 800037fa <ilock>
  if(ip->nlink < 1)
    80005634:	04a91783          	lh	a5,74(s2)
    80005638:	08f05263          	blez	a5,800056bc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000563c:	04491703          	lh	a4,68(s2)
    80005640:	4785                	li	a5,1
    80005642:	08f70563          	beq	a4,a5,800056cc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005646:	4641                	li	a2,16
    80005648:	4581                	li	a1,0
    8000564a:	fc040513          	addi	a0,s0,-64
    8000564e:	ffffb097          	auipc	ra,0xffffb
    80005652:	684080e7          	jalr	1668(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005656:	4741                	li	a4,16
    80005658:	f2c42683          	lw	a3,-212(s0)
    8000565c:	fc040613          	addi	a2,s0,-64
    80005660:	4581                	li	a1,0
    80005662:	8526                	mv	a0,s1
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	542080e7          	jalr	1346(ra) # 80003ba6 <writei>
    8000566c:	47c1                	li	a5,16
    8000566e:	0af51563          	bne	a0,a5,80005718 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005672:	04491703          	lh	a4,68(s2)
    80005676:	4785                	li	a5,1
    80005678:	0af70863          	beq	a4,a5,80005728 <sys_unlink+0x18c>
  iunlockput(dp);
    8000567c:	8526                	mv	a0,s1
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	3de080e7          	jalr	990(ra) # 80003a5c <iunlockput>
  ip->nlink--;
    80005686:	04a95783          	lhu	a5,74(s2)
    8000568a:	37fd                	addiw	a5,a5,-1
    8000568c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005690:	854a                	mv	a0,s2
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	09e080e7          	jalr	158(ra) # 80003730 <iupdate>
  iunlockput(ip);
    8000569a:	854a                	mv	a0,s2
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	3c0080e7          	jalr	960(ra) # 80003a5c <iunlockput>
  end_op();
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	ba8080e7          	jalr	-1112(ra) # 8000424c <end_op>
  return 0;
    800056ac:	4501                	li	a0,0
    800056ae:	a84d                	j	80005760 <sys_unlink+0x1c4>
    end_op();
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	b9c080e7          	jalr	-1124(ra) # 8000424c <end_op>
    return -1;
    800056b8:	557d                	li	a0,-1
    800056ba:	a05d                	j	80005760 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056bc:	00003517          	auipc	a0,0x3
    800056c0:	01c50513          	addi	a0,a0,28 # 800086d8 <syscalls+0x2f0>
    800056c4:	ffffb097          	auipc	ra,0xffffb
    800056c8:	e6c080e7          	jalr	-404(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056cc:	04c92703          	lw	a4,76(s2)
    800056d0:	02000793          	li	a5,32
    800056d4:	f6e7f9e3          	bgeu	a5,a4,80005646 <sys_unlink+0xaa>
    800056d8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056dc:	4741                	li	a4,16
    800056de:	86ce                	mv	a3,s3
    800056e0:	f1840613          	addi	a2,s0,-232
    800056e4:	4581                	li	a1,0
    800056e6:	854a                	mv	a0,s2
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	3c6080e7          	jalr	966(ra) # 80003aae <readi>
    800056f0:	47c1                	li	a5,16
    800056f2:	00f51b63          	bne	a0,a5,80005708 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056f6:	f1845783          	lhu	a5,-232(s0)
    800056fa:	e7a1                	bnez	a5,80005742 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056fc:	29c1                	addiw	s3,s3,16
    800056fe:	04c92783          	lw	a5,76(s2)
    80005702:	fcf9ede3          	bltu	s3,a5,800056dc <sys_unlink+0x140>
    80005706:	b781                	j	80005646 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005708:	00003517          	auipc	a0,0x3
    8000570c:	fe850513          	addi	a0,a0,-24 # 800086f0 <syscalls+0x308>
    80005710:	ffffb097          	auipc	ra,0xffffb
    80005714:	e20080e7          	jalr	-480(ra) # 80000530 <panic>
    panic("unlink: writei");
    80005718:	00003517          	auipc	a0,0x3
    8000571c:	ff050513          	addi	a0,a0,-16 # 80008708 <syscalls+0x320>
    80005720:	ffffb097          	auipc	ra,0xffffb
    80005724:	e10080e7          	jalr	-496(ra) # 80000530 <panic>
    dp->nlink--;
    80005728:	04a4d783          	lhu	a5,74(s1)
    8000572c:	37fd                	addiw	a5,a5,-1
    8000572e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005732:	8526                	mv	a0,s1
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	ffc080e7          	jalr	-4(ra) # 80003730 <iupdate>
    8000573c:	b781                	j	8000567c <sys_unlink+0xe0>
    return -1;
    8000573e:	557d                	li	a0,-1
    80005740:	a005                	j	80005760 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005742:	854a                	mv	a0,s2
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	318080e7          	jalr	792(ra) # 80003a5c <iunlockput>
  iunlockput(dp);
    8000574c:	8526                	mv	a0,s1
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	30e080e7          	jalr	782(ra) # 80003a5c <iunlockput>
  end_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	af6080e7          	jalr	-1290(ra) # 8000424c <end_op>
  return -1;
    8000575e:	557d                	li	a0,-1
}
    80005760:	70ae                	ld	ra,232(sp)
    80005762:	740e                	ld	s0,224(sp)
    80005764:	64ee                	ld	s1,216(sp)
    80005766:	694e                	ld	s2,208(sp)
    80005768:	69ae                	ld	s3,200(sp)
    8000576a:	616d                	addi	sp,sp,240
    8000576c:	8082                	ret

000000008000576e <sys_open>:

uint64
sys_open(void)
{
    8000576e:	7131                	addi	sp,sp,-192
    80005770:	fd06                	sd	ra,184(sp)
    80005772:	f922                	sd	s0,176(sp)
    80005774:	f526                	sd	s1,168(sp)
    80005776:	f14a                	sd	s2,160(sp)
    80005778:	ed4e                	sd	s3,152(sp)
    8000577a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000577c:	08000613          	li	a2,128
    80005780:	f5040593          	addi	a1,s0,-176
    80005784:	4501                	li	a0,0
    80005786:	ffffd097          	auipc	ra,0xffffd
    8000578a:	546080e7          	jalr	1350(ra) # 80002ccc <argstr>
    return -1;
    8000578e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005790:	0c054163          	bltz	a0,80005852 <sys_open+0xe4>
    80005794:	f4c40593          	addi	a1,s0,-180
    80005798:	4505                	li	a0,1
    8000579a:	ffffd097          	auipc	ra,0xffffd
    8000579e:	4ee080e7          	jalr	1262(ra) # 80002c88 <argint>
    800057a2:	0a054863          	bltz	a0,80005852 <sys_open+0xe4>

  begin_op();
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	a26080e7          	jalr	-1498(ra) # 800041cc <begin_op>

  if(omode & O_CREATE){
    800057ae:	f4c42783          	lw	a5,-180(s0)
    800057b2:	2007f793          	andi	a5,a5,512
    800057b6:	cbdd                	beqz	a5,8000586c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057b8:	4681                	li	a3,0
    800057ba:	4601                	li	a2,0
    800057bc:	4589                	li	a1,2
    800057be:	f5040513          	addi	a0,s0,-176
    800057c2:	00000097          	auipc	ra,0x0
    800057c6:	972080e7          	jalr	-1678(ra) # 80005134 <create>
    800057ca:	892a                	mv	s2,a0
    if(ip == 0){
    800057cc:	c959                	beqz	a0,80005862 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057ce:	04491703          	lh	a4,68(s2)
    800057d2:	478d                	li	a5,3
    800057d4:	00f71763          	bne	a4,a5,800057e2 <sys_open+0x74>
    800057d8:	04695703          	lhu	a4,70(s2)
    800057dc:	47a5                	li	a5,9
    800057de:	0ce7ec63          	bltu	a5,a4,800058b6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	e02080e7          	jalr	-510(ra) # 800045e4 <filealloc>
    800057ea:	89aa                	mv	s3,a0
    800057ec:	10050263          	beqz	a0,800058f0 <sys_open+0x182>
    800057f0:	00000097          	auipc	ra,0x0
    800057f4:	902080e7          	jalr	-1790(ra) # 800050f2 <fdalloc>
    800057f8:	84aa                	mv	s1,a0
    800057fa:	0e054663          	bltz	a0,800058e6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057fe:	04491703          	lh	a4,68(s2)
    80005802:	478d                	li	a5,3
    80005804:	0cf70463          	beq	a4,a5,800058cc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005808:	4789                	li	a5,2
    8000580a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000580e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005812:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005816:	f4c42783          	lw	a5,-180(s0)
    8000581a:	0017c713          	xori	a4,a5,1
    8000581e:	8b05                	andi	a4,a4,1
    80005820:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005824:	0037f713          	andi	a4,a5,3
    80005828:	00e03733          	snez	a4,a4
    8000582c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005830:	4007f793          	andi	a5,a5,1024
    80005834:	c791                	beqz	a5,80005840 <sys_open+0xd2>
    80005836:	04491703          	lh	a4,68(s2)
    8000583a:	4789                	li	a5,2
    8000583c:	08f70f63          	beq	a4,a5,800058da <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005840:	854a                	mv	a0,s2
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	07a080e7          	jalr	122(ra) # 800038bc <iunlock>
  end_op();
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	a02080e7          	jalr	-1534(ra) # 8000424c <end_op>

  return fd;
}
    80005852:	8526                	mv	a0,s1
    80005854:	70ea                	ld	ra,184(sp)
    80005856:	744a                	ld	s0,176(sp)
    80005858:	74aa                	ld	s1,168(sp)
    8000585a:	790a                	ld	s2,160(sp)
    8000585c:	69ea                	ld	s3,152(sp)
    8000585e:	6129                	addi	sp,sp,192
    80005860:	8082                	ret
      end_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	9ea080e7          	jalr	-1558(ra) # 8000424c <end_op>
      return -1;
    8000586a:	b7e5                	j	80005852 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000586c:	f5040513          	addi	a0,s0,-176
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	740080e7          	jalr	1856(ra) # 80003fb0 <namei>
    80005878:	892a                	mv	s2,a0
    8000587a:	c905                	beqz	a0,800058aa <sys_open+0x13c>
    ilock(ip);
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	f7e080e7          	jalr	-130(ra) # 800037fa <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005884:	04491703          	lh	a4,68(s2)
    80005888:	4785                	li	a5,1
    8000588a:	f4f712e3          	bne	a4,a5,800057ce <sys_open+0x60>
    8000588e:	f4c42783          	lw	a5,-180(s0)
    80005892:	dba1                	beqz	a5,800057e2 <sys_open+0x74>
      iunlockput(ip);
    80005894:	854a                	mv	a0,s2
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	1c6080e7          	jalr	454(ra) # 80003a5c <iunlockput>
      end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	9ae080e7          	jalr	-1618(ra) # 8000424c <end_op>
      return -1;
    800058a6:	54fd                	li	s1,-1
    800058a8:	b76d                	j	80005852 <sys_open+0xe4>
      end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	9a2080e7          	jalr	-1630(ra) # 8000424c <end_op>
      return -1;
    800058b2:	54fd                	li	s1,-1
    800058b4:	bf79                	j	80005852 <sys_open+0xe4>
    iunlockput(ip);
    800058b6:	854a                	mv	a0,s2
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	1a4080e7          	jalr	420(ra) # 80003a5c <iunlockput>
    end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	98c080e7          	jalr	-1652(ra) # 8000424c <end_op>
    return -1;
    800058c8:	54fd                	li	s1,-1
    800058ca:	b761                	j	80005852 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058cc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058d0:	04691783          	lh	a5,70(s2)
    800058d4:	02f99223          	sh	a5,36(s3)
    800058d8:	bf2d                	j	80005812 <sys_open+0xa4>
    itrunc(ip);
    800058da:	854a                	mv	a0,s2
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	02c080e7          	jalr	44(ra) # 80003908 <itrunc>
    800058e4:	bfb1                	j	80005840 <sys_open+0xd2>
      fileclose(f);
    800058e6:	854e                	mv	a0,s3
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	db8080e7          	jalr	-584(ra) # 800046a0 <fileclose>
    iunlockput(ip);
    800058f0:	854a                	mv	a0,s2
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	16a080e7          	jalr	362(ra) # 80003a5c <iunlockput>
    end_op();
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	952080e7          	jalr	-1710(ra) # 8000424c <end_op>
    return -1;
    80005902:	54fd                	li	s1,-1
    80005904:	b7b9                	j	80005852 <sys_open+0xe4>

0000000080005906 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005906:	7175                	addi	sp,sp,-144
    80005908:	e506                	sd	ra,136(sp)
    8000590a:	e122                	sd	s0,128(sp)
    8000590c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	8be080e7          	jalr	-1858(ra) # 800041cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005916:	08000613          	li	a2,128
    8000591a:	f7040593          	addi	a1,s0,-144
    8000591e:	4501                	li	a0,0
    80005920:	ffffd097          	auipc	ra,0xffffd
    80005924:	3ac080e7          	jalr	940(ra) # 80002ccc <argstr>
    80005928:	02054963          	bltz	a0,8000595a <sys_mkdir+0x54>
    8000592c:	4681                	li	a3,0
    8000592e:	4601                	li	a2,0
    80005930:	4585                	li	a1,1
    80005932:	f7040513          	addi	a0,s0,-144
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	7fe080e7          	jalr	2046(ra) # 80005134 <create>
    8000593e:	cd11                	beqz	a0,8000595a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	11c080e7          	jalr	284(ra) # 80003a5c <iunlockput>
  end_op();
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	904080e7          	jalr	-1788(ra) # 8000424c <end_op>
  return 0;
    80005950:	4501                	li	a0,0
}
    80005952:	60aa                	ld	ra,136(sp)
    80005954:	640a                	ld	s0,128(sp)
    80005956:	6149                	addi	sp,sp,144
    80005958:	8082                	ret
    end_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	8f2080e7          	jalr	-1806(ra) # 8000424c <end_op>
    return -1;
    80005962:	557d                	li	a0,-1
    80005964:	b7fd                	j	80005952 <sys_mkdir+0x4c>

0000000080005966 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005966:	7135                	addi	sp,sp,-160
    80005968:	ed06                	sd	ra,152(sp)
    8000596a:	e922                	sd	s0,144(sp)
    8000596c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	85e080e7          	jalr	-1954(ra) # 800041cc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005976:	08000613          	li	a2,128
    8000597a:	f7040593          	addi	a1,s0,-144
    8000597e:	4501                	li	a0,0
    80005980:	ffffd097          	auipc	ra,0xffffd
    80005984:	34c080e7          	jalr	844(ra) # 80002ccc <argstr>
    80005988:	04054a63          	bltz	a0,800059dc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000598c:	f6c40593          	addi	a1,s0,-148
    80005990:	4505                	li	a0,1
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	2f6080e7          	jalr	758(ra) # 80002c88 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000599a:	04054163          	bltz	a0,800059dc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000599e:	f6840593          	addi	a1,s0,-152
    800059a2:	4509                	li	a0,2
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	2e4080e7          	jalr	740(ra) # 80002c88 <argint>
     argint(1, &major) < 0 ||
    800059ac:	02054863          	bltz	a0,800059dc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059b0:	f6841683          	lh	a3,-152(s0)
    800059b4:	f6c41603          	lh	a2,-148(s0)
    800059b8:	458d                	li	a1,3
    800059ba:	f7040513          	addi	a0,s0,-144
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	776080e7          	jalr	1910(ra) # 80005134 <create>
     argint(2, &minor) < 0 ||
    800059c6:	c919                	beqz	a0,800059dc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	094080e7          	jalr	148(ra) # 80003a5c <iunlockput>
  end_op();
    800059d0:	fffff097          	auipc	ra,0xfffff
    800059d4:	87c080e7          	jalr	-1924(ra) # 8000424c <end_op>
  return 0;
    800059d8:	4501                	li	a0,0
    800059da:	a031                	j	800059e6 <sys_mknod+0x80>
    end_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	870080e7          	jalr	-1936(ra) # 8000424c <end_op>
    return -1;
    800059e4:	557d                	li	a0,-1
}
    800059e6:	60ea                	ld	ra,152(sp)
    800059e8:	644a                	ld	s0,144(sp)
    800059ea:	610d                	addi	sp,sp,160
    800059ec:	8082                	ret

00000000800059ee <sys_chdir>:

uint64
sys_chdir(void)
{
    800059ee:	7135                	addi	sp,sp,-160
    800059f0:	ed06                	sd	ra,152(sp)
    800059f2:	e922                	sd	s0,144(sp)
    800059f4:	e526                	sd	s1,136(sp)
    800059f6:	e14a                	sd	s2,128(sp)
    800059f8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059fa:	ffffc097          	auipc	ra,0xffffc
    800059fe:	fac080e7          	jalr	-84(ra) # 800019a6 <myproc>
    80005a02:	892a                	mv	s2,a0
  
  begin_op();
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	7c8080e7          	jalr	1992(ra) # 800041cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a0c:	08000613          	li	a2,128
    80005a10:	f6040593          	addi	a1,s0,-160
    80005a14:	4501                	li	a0,0
    80005a16:	ffffd097          	auipc	ra,0xffffd
    80005a1a:	2b6080e7          	jalr	694(ra) # 80002ccc <argstr>
    80005a1e:	04054b63          	bltz	a0,80005a74 <sys_chdir+0x86>
    80005a22:	f6040513          	addi	a0,s0,-160
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	58a080e7          	jalr	1418(ra) # 80003fb0 <namei>
    80005a2e:	84aa                	mv	s1,a0
    80005a30:	c131                	beqz	a0,80005a74 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	dc8080e7          	jalr	-568(ra) # 800037fa <ilock>
  if(ip->type != T_DIR){
    80005a3a:	04449703          	lh	a4,68(s1)
    80005a3e:	4785                	li	a5,1
    80005a40:	04f71063          	bne	a4,a5,80005a80 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	e76080e7          	jalr	-394(ra) # 800038bc <iunlock>
  iput(p->cwd);
    80005a4e:	15093503          	ld	a0,336(s2)
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	f62080e7          	jalr	-158(ra) # 800039b4 <iput>
  end_op();
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	7f2080e7          	jalr	2034(ra) # 8000424c <end_op>
  p->cwd = ip;
    80005a62:	14993823          	sd	s1,336(s2)
  return 0;
    80005a66:	4501                	li	a0,0
}
    80005a68:	60ea                	ld	ra,152(sp)
    80005a6a:	644a                	ld	s0,144(sp)
    80005a6c:	64aa                	ld	s1,136(sp)
    80005a6e:	690a                	ld	s2,128(sp)
    80005a70:	610d                	addi	sp,sp,160
    80005a72:	8082                	ret
    end_op();
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	7d8080e7          	jalr	2008(ra) # 8000424c <end_op>
    return -1;
    80005a7c:	557d                	li	a0,-1
    80005a7e:	b7ed                	j	80005a68 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a80:	8526                	mv	a0,s1
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	fda080e7          	jalr	-38(ra) # 80003a5c <iunlockput>
    end_op();
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	7c2080e7          	jalr	1986(ra) # 8000424c <end_op>
    return -1;
    80005a92:	557d                	li	a0,-1
    80005a94:	bfd1                	j	80005a68 <sys_chdir+0x7a>

0000000080005a96 <sys_exec>:

uint64
sys_exec(void)
{
    80005a96:	7145                	addi	sp,sp,-464
    80005a98:	e786                	sd	ra,456(sp)
    80005a9a:	e3a2                	sd	s0,448(sp)
    80005a9c:	ff26                	sd	s1,440(sp)
    80005a9e:	fb4a                	sd	s2,432(sp)
    80005aa0:	f74e                	sd	s3,424(sp)
    80005aa2:	f352                	sd	s4,416(sp)
    80005aa4:	ef56                	sd	s5,408(sp)
    80005aa6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005aa8:	08000613          	li	a2,128
    80005aac:	f4040593          	addi	a1,s0,-192
    80005ab0:	4501                	li	a0,0
    80005ab2:	ffffd097          	auipc	ra,0xffffd
    80005ab6:	21a080e7          	jalr	538(ra) # 80002ccc <argstr>
    return -1;
    80005aba:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005abc:	0c054a63          	bltz	a0,80005b90 <sys_exec+0xfa>
    80005ac0:	e3840593          	addi	a1,s0,-456
    80005ac4:	4505                	li	a0,1
    80005ac6:	ffffd097          	auipc	ra,0xffffd
    80005aca:	1e4080e7          	jalr	484(ra) # 80002caa <argaddr>
    80005ace:	0c054163          	bltz	a0,80005b90 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ad2:	10000613          	li	a2,256
    80005ad6:	4581                	li	a1,0
    80005ad8:	e4040513          	addi	a0,s0,-448
    80005adc:	ffffb097          	auipc	ra,0xffffb
    80005ae0:	1f6080e7          	jalr	502(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ae4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ae8:	89a6                	mv	s3,s1
    80005aea:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aec:	02000a13          	li	s4,32
    80005af0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005af4:	00391513          	slli	a0,s2,0x3
    80005af8:	e3040593          	addi	a1,s0,-464
    80005afc:	e3843783          	ld	a5,-456(s0)
    80005b00:	953e                	add	a0,a0,a5
    80005b02:	ffffd097          	auipc	ra,0xffffd
    80005b06:	0ec080e7          	jalr	236(ra) # 80002bee <fetchaddr>
    80005b0a:	02054a63          	bltz	a0,80005b3e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b0e:	e3043783          	ld	a5,-464(s0)
    80005b12:	c3b9                	beqz	a5,80005b58 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b14:	ffffb097          	auipc	ra,0xffffb
    80005b18:	fd2080e7          	jalr	-46(ra) # 80000ae6 <kalloc>
    80005b1c:	85aa                	mv	a1,a0
    80005b1e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b22:	cd11                	beqz	a0,80005b3e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b24:	6605                	lui	a2,0x1
    80005b26:	e3043503          	ld	a0,-464(s0)
    80005b2a:	ffffd097          	auipc	ra,0xffffd
    80005b2e:	116080e7          	jalr	278(ra) # 80002c40 <fetchstr>
    80005b32:	00054663          	bltz	a0,80005b3e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b36:	0905                	addi	s2,s2,1
    80005b38:	09a1                	addi	s3,s3,8
    80005b3a:	fb491be3          	bne	s2,s4,80005af0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3e:	10048913          	addi	s2,s1,256
    80005b42:	6088                	ld	a0,0(s1)
    80005b44:	c529                	beqz	a0,80005b8e <sys_exec+0xf8>
    kfree(argv[i]);
    80005b46:	ffffb097          	auipc	ra,0xffffb
    80005b4a:	ea4080e7          	jalr	-348(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b4e:	04a1                	addi	s1,s1,8
    80005b50:	ff2499e3          	bne	s1,s2,80005b42 <sys_exec+0xac>
  return -1;
    80005b54:	597d                	li	s2,-1
    80005b56:	a82d                	j	80005b90 <sys_exec+0xfa>
      argv[i] = 0;
    80005b58:	0a8e                	slli	s5,s5,0x3
    80005b5a:	fc040793          	addi	a5,s0,-64
    80005b5e:	9abe                	add	s5,s5,a5
    80005b60:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b64:	e4040593          	addi	a1,s0,-448
    80005b68:	f4040513          	addi	a0,s0,-192
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	194080e7          	jalr	404(ra) # 80004d00 <exec>
    80005b74:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b76:	10048993          	addi	s3,s1,256
    80005b7a:	6088                	ld	a0,0(s1)
    80005b7c:	c911                	beqz	a0,80005b90 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b7e:	ffffb097          	auipc	ra,0xffffb
    80005b82:	e6c080e7          	jalr	-404(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b86:	04a1                	addi	s1,s1,8
    80005b88:	ff3499e3          	bne	s1,s3,80005b7a <sys_exec+0xe4>
    80005b8c:	a011                	j	80005b90 <sys_exec+0xfa>
  return -1;
    80005b8e:	597d                	li	s2,-1
}
    80005b90:	854a                	mv	a0,s2
    80005b92:	60be                	ld	ra,456(sp)
    80005b94:	641e                	ld	s0,448(sp)
    80005b96:	74fa                	ld	s1,440(sp)
    80005b98:	795a                	ld	s2,432(sp)
    80005b9a:	79ba                	ld	s3,424(sp)
    80005b9c:	7a1a                	ld	s4,416(sp)
    80005b9e:	6afa                	ld	s5,408(sp)
    80005ba0:	6179                	addi	sp,sp,464
    80005ba2:	8082                	ret

0000000080005ba4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ba4:	7139                	addi	sp,sp,-64
    80005ba6:	fc06                	sd	ra,56(sp)
    80005ba8:	f822                	sd	s0,48(sp)
    80005baa:	f426                	sd	s1,40(sp)
    80005bac:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bae:	ffffc097          	auipc	ra,0xffffc
    80005bb2:	df8080e7          	jalr	-520(ra) # 800019a6 <myproc>
    80005bb6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bb8:	fd840593          	addi	a1,s0,-40
    80005bbc:	4501                	li	a0,0
    80005bbe:	ffffd097          	auipc	ra,0xffffd
    80005bc2:	0ec080e7          	jalr	236(ra) # 80002caa <argaddr>
    return -1;
    80005bc6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bc8:	0e054063          	bltz	a0,80005ca8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bcc:	fc840593          	addi	a1,s0,-56
    80005bd0:	fd040513          	addi	a0,s0,-48
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	dfc080e7          	jalr	-516(ra) # 800049d0 <pipealloc>
    return -1;
    80005bdc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bde:	0c054563          	bltz	a0,80005ca8 <sys_pipe+0x104>
  fd0 = -1;
    80005be2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005be6:	fd043503          	ld	a0,-48(s0)
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	508080e7          	jalr	1288(ra) # 800050f2 <fdalloc>
    80005bf2:	fca42223          	sw	a0,-60(s0)
    80005bf6:	08054c63          	bltz	a0,80005c8e <sys_pipe+0xea>
    80005bfa:	fc843503          	ld	a0,-56(s0)
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	4f4080e7          	jalr	1268(ra) # 800050f2 <fdalloc>
    80005c06:	fca42023          	sw	a0,-64(s0)
    80005c0a:	06054863          	bltz	a0,80005c7a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c0e:	4691                	li	a3,4
    80005c10:	fc440613          	addi	a2,s0,-60
    80005c14:	fd843583          	ld	a1,-40(s0)
    80005c18:	68a8                	ld	a0,80(s1)
    80005c1a:	ffffc097          	auipc	ra,0xffffc
    80005c1e:	a22080e7          	jalr	-1502(ra) # 8000163c <copyout>
    80005c22:	02054063          	bltz	a0,80005c42 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c26:	4691                	li	a3,4
    80005c28:	fc040613          	addi	a2,s0,-64
    80005c2c:	fd843583          	ld	a1,-40(s0)
    80005c30:	0591                	addi	a1,a1,4
    80005c32:	68a8                	ld	a0,80(s1)
    80005c34:	ffffc097          	auipc	ra,0xffffc
    80005c38:	a08080e7          	jalr	-1528(ra) # 8000163c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c3c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c3e:	06055563          	bgez	a0,80005ca8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c42:	fc442783          	lw	a5,-60(s0)
    80005c46:	07e9                	addi	a5,a5,26
    80005c48:	078e                	slli	a5,a5,0x3
    80005c4a:	97a6                	add	a5,a5,s1
    80005c4c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c50:	fc042503          	lw	a0,-64(s0)
    80005c54:	0569                	addi	a0,a0,26
    80005c56:	050e                	slli	a0,a0,0x3
    80005c58:	9526                	add	a0,a0,s1
    80005c5a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c5e:	fd043503          	ld	a0,-48(s0)
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	a3e080e7          	jalr	-1474(ra) # 800046a0 <fileclose>
    fileclose(wf);
    80005c6a:	fc843503          	ld	a0,-56(s0)
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	a32080e7          	jalr	-1486(ra) # 800046a0 <fileclose>
    return -1;
    80005c76:	57fd                	li	a5,-1
    80005c78:	a805                	j	80005ca8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c7a:	fc442783          	lw	a5,-60(s0)
    80005c7e:	0007c863          	bltz	a5,80005c8e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c82:	01a78513          	addi	a0,a5,26
    80005c86:	050e                	slli	a0,a0,0x3
    80005c88:	9526                	add	a0,a0,s1
    80005c8a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c8e:	fd043503          	ld	a0,-48(s0)
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	a0e080e7          	jalr	-1522(ra) # 800046a0 <fileclose>
    fileclose(wf);
    80005c9a:	fc843503          	ld	a0,-56(s0)
    80005c9e:	fffff097          	auipc	ra,0xfffff
    80005ca2:	a02080e7          	jalr	-1534(ra) # 800046a0 <fileclose>
    return -1;
    80005ca6:	57fd                	li	a5,-1
}
    80005ca8:	853e                	mv	a0,a5
    80005caa:	70e2                	ld	ra,56(sp)
    80005cac:	7442                	ld	s0,48(sp)
    80005cae:	74a2                	ld	s1,40(sp)
    80005cb0:	6121                	addi	sp,sp,64
    80005cb2:	8082                	ret

0000000080005cb4 <sys_mmap>:

uint64
sys_mmap(void) {
    80005cb4:	711d                	addi	sp,sp,-96
    80005cb6:	ec86                	sd	ra,88(sp)
    80005cb8:	e8a2                	sd	s0,80(sp)
    80005cba:	e4a6                	sd	s1,72(sp)
    80005cbc:	e0ca                	sd	s2,64(sp)
    80005cbe:	fc4e                	sd	s3,56(sp)
    80005cc0:	f852                	sd	s4,48(sp)
    80005cc2:	1080                	addi	s0,sp,96
  uint64 failure = (uint64)((char *) -1);
  struct proc* p = myproc();
    80005cc4:	ffffc097          	auipc	ra,0xffffc
    80005cc8:	ce2080e7          	jalr	-798(ra) # 800019a6 <myproc>
    80005ccc:	892a                	mv	s2,a0
  uint64 addr;
  int length, prot, flags, fd, offset;
  struct file* f;

  // parse argument
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0
    80005cce:	fc840593          	addi	a1,s0,-56
    80005cd2:	4501                	li	a0,0
    80005cd4:	ffffd097          	auipc	ra,0xffffd
    80005cd8:	fd6080e7          	jalr	-42(ra) # 80002caa <argaddr>
      || argint(3, &flags) < 0 || argfd(4, &fd, &f) < 0 || argint(5, &offset) < 0)
    return failure;
    80005cdc:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0
    80005cde:	0c054063          	bltz	a0,80005d9e <sys_mmap+0xea>
    80005ce2:	fc440593          	addi	a1,s0,-60
    80005ce6:	4505                	li	a0,1
    80005ce8:	ffffd097          	auipc	ra,0xffffd
    80005cec:	fa0080e7          	jalr	-96(ra) # 80002c88 <argint>
    return failure;
    80005cf0:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0
    80005cf2:	0a054663          	bltz	a0,80005d9e <sys_mmap+0xea>
    80005cf6:	fc040593          	addi	a1,s0,-64
    80005cfa:	4509                	li	a0,2
    80005cfc:	ffffd097          	auipc	ra,0xffffd
    80005d00:	f8c080e7          	jalr	-116(ra) # 80002c88 <argint>
    return failure;
    80005d04:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0
    80005d06:	08054c63          	bltz	a0,80005d9e <sys_mmap+0xea>
      || argint(3, &flags) < 0 || argfd(4, &fd, &f) < 0 || argint(5, &offset) < 0)
    80005d0a:	fbc40593          	addi	a1,s0,-68
    80005d0e:	450d                	li	a0,3
    80005d10:	ffffd097          	auipc	ra,0xffffd
    80005d14:	f78080e7          	jalr	-136(ra) # 80002c88 <argint>
    return failure;
    80005d18:	57fd                	li	a5,-1
      || argint(3, &flags) < 0 || argfd(4, &fd, &f) < 0 || argint(5, &offset) < 0)
    80005d1a:	08054263          	bltz	a0,80005d9e <sys_mmap+0xea>
    80005d1e:	fa840613          	addi	a2,s0,-88
    80005d22:	fb840593          	addi	a1,s0,-72
    80005d26:	4511                	li	a0,4
    80005d28:	fffff097          	auipc	ra,0xfffff
    80005d2c:	362080e7          	jalr	866(ra) # 8000508a <argfd>
    return failure;
    80005d30:	57fd                	li	a5,-1
      || argint(3, &flags) < 0 || argfd(4, &fd, &f) < 0 || argint(5, &offset) < 0)
    80005d32:	06054663          	bltz	a0,80005d9e <sys_mmap+0xea>
    80005d36:	fb440593          	addi	a1,s0,-76
    80005d3a:	4515                	li	a0,5
    80005d3c:	ffffd097          	auipc	ra,0xffffd
    80005d40:	f4c080e7          	jalr	-180(ra) # 80002c88 <argint>
    80005d44:	0c054a63          	bltz	a0,80005e18 <sys_mmap+0x164>

  // sanity check
  length = PGROUNDUP(length);
    80005d48:	fc442683          	lw	a3,-60(s0)
    80005d4c:	6785                	lui	a5,0x1
    80005d4e:	37fd                	addiw	a5,a5,-1
    80005d50:	9ebd                	addw	a3,a3,a5
    80005d52:	77fd                	lui	a5,0xfffff
    80005d54:	8efd                	and	a3,a3,a5
    80005d56:	2681                	sext.w	a3,a3
    80005d58:	fcd42223          	sw	a3,-60(s0)
  if (MAXVA - length < p->sz)
    80005d5c:	04893583          	ld	a1,72(s2)
    80005d60:	4705                	li	a4,1
    80005d62:	171a                	slli	a4,a4,0x26
    80005d64:	8f15                	sub	a4,a4,a3
    return failure;
    80005d66:	57fd                	li	a5,-1
  if (MAXVA - length < p->sz)
    80005d68:	02b76b63          	bltu	a4,a1,80005d9e <sys_mmap+0xea>
  if (!f->readable && (prot & PROT_READ))
    80005d6c:	fa843503          	ld	a0,-88(s0)
    80005d70:	00854783          	lbu	a5,8(a0)
    80005d74:	e791                	bnez	a5,80005d80 <sys_mmap+0xcc>
    80005d76:	fc042703          	lw	a4,-64(s0)
    80005d7a:	8b05                	andi	a4,a4,1
    return failure;
    80005d7c:	57fd                	li	a5,-1
  if (!f->readable && (prot & PROT_READ))
    80005d7e:	e305                	bnez	a4,80005d9e <sys_mmap+0xea>
  if (!f->writable && (prot & PROT_WRITE) && (flags == MAP_SHARED))
    80005d80:	00954783          	lbu	a5,9(a0)
    80005d84:	c795                	beqz	a5,80005db0 <sys_mmap+0xfc>
    return failure;

  // find an empty vma slot and fill in
  for (int i = 0; i < NVMA; i++) {
    80005d86:	16890793          	addi	a5,s2,360
sys_mmap(void) {
    80005d8a:	4481                	li	s1,0
  for (int i = 0; i < NVMA; i++) {
    80005d8c:	4641                	li	a2,16
    struct vma* vma = &p->vmas[i];
    if (vma->valid == 0) {
    80005d8e:	4398                	lw	a4,0(a5)
    80005d90:	cb1d                	beqz	a4,80005dc6 <sys_mmap+0x112>
  for (int i = 0; i < NVMA; i++) {
    80005d92:	2485                	addiw	s1,s1,1
    80005d94:	03078793          	addi	a5,a5,48 # fffffffffffff030 <end+0xffffffff7ffcd030>
    80005d98:	fec49be3          	bne	s1,a2,80005d8e <sys_mmap+0xda>
      return vma->addr;
    }
  }

  // all vma are in use
  return failure;
    80005d9c:	57fd                	li	a5,-1
}
    80005d9e:	853e                	mv	a0,a5
    80005da0:	60e6                	ld	ra,88(sp)
    80005da2:	6446                	ld	s0,80(sp)
    80005da4:	64a6                	ld	s1,72(sp)
    80005da6:	6906                	ld	s2,64(sp)
    80005da8:	79e2                	ld	s3,56(sp)
    80005daa:	7a42                	ld	s4,48(sp)
    80005dac:	6125                	addi	sp,sp,96
    80005dae:	8082                	ret
  if (!f->writable && (prot & PROT_WRITE) && (flags == MAP_SHARED))
    80005db0:	fc042783          	lw	a5,-64(s0)
    80005db4:	8b89                	andi	a5,a5,2
    80005db6:	dbe1                	beqz	a5,80005d86 <sys_mmap+0xd2>
    80005db8:	fbc42703          	lw	a4,-68(s0)
    80005dbc:	4785                	li	a5,1
    80005dbe:	fcf714e3          	bne	a4,a5,80005d86 <sys_mmap+0xd2>
    return failure;
    80005dc2:	57fd                	li	a5,-1
    80005dc4:	bfe9                	j	80005d9e <sys_mmap+0xea>
      vma->valid = 1;
    80005dc6:	00149a13          	slli	s4,s1,0x1
    80005dca:	009a09b3          	add	s3,s4,s1
    80005dce:	0992                	slli	s3,s3,0x4
    80005dd0:	99ca                	add	s3,s3,s2
    80005dd2:	4785                	li	a5,1
    80005dd4:	16f9a423          	sw	a5,360(s3)
      vma->addr = p->sz;
    80005dd8:	16b9b823          	sd	a1,368(s3)
      p->sz += length;
    80005ddc:	95b6                	add	a1,a1,a3
    80005dde:	04b93423          	sd	a1,72(s2)
      vma->length = length;
    80005de2:	16d9ac23          	sw	a3,376(s3)
      vma->prot = prot;
    80005de6:	fc042783          	lw	a5,-64(s0)
    80005dea:	16f9ae23          	sw	a5,380(s3)
      vma->flags = flags;
    80005dee:	fbc42783          	lw	a5,-68(s0)
    80005df2:	18f9a023          	sw	a5,384(s3)
      vma->fd = fd;
    80005df6:	fb842783          	lw	a5,-72(s0)
    80005dfa:	18f9a223          	sw	a5,388(s3)
      vma->f = f;
    80005dfe:	18a9b823          	sd	a0,400(s3)
      filedup(f);
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	84c080e7          	jalr	-1972(ra) # 8000464e <filedup>
      vma->offset = offset;
    80005e0a:	fb442783          	lw	a5,-76(s0)
    80005e0e:	18f9a423          	sw	a5,392(s3)
      return vma->addr;
    80005e12:	1709b783          	ld	a5,368(s3)
    80005e16:	b761                	j	80005d9e <sys_mmap+0xea>
    return failure;
    80005e18:	57fd                	li	a5,-1
    80005e1a:	b751                	j	80005d9e <sys_mmap+0xea>

0000000080005e1c <sys_munmap>:

uint64
sys_munmap(void) {
    80005e1c:	7139                	addi	sp,sp,-64
    80005e1e:	fc06                	sd	ra,56(sp)
    80005e20:	f822                	sd	s0,48(sp)
    80005e22:	f426                	sd	s1,40(sp)
    80005e24:	f04a                	sd	s2,32(sp)
    80005e26:	ec4e                	sd	s3,24(sp)
    80005e28:	0080                	addi	s0,sp,64
  uint64 addr;
  int length;
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0)
    80005e2a:	fc840593          	addi	a1,s0,-56
    80005e2e:	4501                	li	a0,0
    80005e30:	ffffd097          	auipc	ra,0xffffd
    80005e34:	e7a080e7          	jalr	-390(ra) # 80002caa <argaddr>
    80005e38:	18054d63          	bltz	a0,80005fd2 <sys_munmap+0x1b6>
    80005e3c:	fc440593          	addi	a1,s0,-60
    80005e40:	4505                	li	a0,1
    80005e42:	ffffd097          	auipc	ra,0xffffd
    80005e46:	e46080e7          	jalr	-442(ra) # 80002c88 <argint>
    80005e4a:	18054663          	bltz	a0,80005fd6 <sys_munmap+0x1ba>
    return -1;
  struct proc *p = myproc();
    80005e4e:	ffffc097          	auipc	ra,0xffffc
    80005e52:	b58080e7          	jalr	-1192(ra) # 800019a6 <myproc>
    80005e56:	892a                	mv	s2,a0
  struct vma* vma = 0;
  int idx = -1;
  // find the corresponding vma
  for (int i = 0; i < NVMA; i++) {
    if (p->vmas[i].valid && addr >= p->vmas[i].addr && addr <= p->vmas[i].addr + p->vmas[i].length) {
    80005e58:	fc843583          	ld	a1,-56(s0)
    80005e5c:	16850793          	addi	a5,a0,360
  for (int i = 0; i < NVMA; i++) {
    80005e60:	4481                	li	s1,0
    80005e62:	4641                	li	a2,16
    80005e64:	a031                	j	80005e70 <sys_munmap+0x54>
    80005e66:	2485                	addiw	s1,s1,1
    80005e68:	03078793          	addi	a5,a5,48
    80005e6c:	0ac48963          	beq	s1,a2,80005f1e <sys_munmap+0x102>
    if (p->vmas[i].valid && addr >= p->vmas[i].addr && addr <= p->vmas[i].addr + p->vmas[i].length) {
    80005e70:	4398                	lw	a4,0(a5)
    80005e72:	db75                	beqz	a4,80005e66 <sys_munmap+0x4a>
    80005e74:	6798                	ld	a4,8(a5)
    80005e76:	fee5e8e3          	bltu	a1,a4,80005e66 <sys_munmap+0x4a>
    80005e7a:	4b94                	lw	a3,16(a5)
    80005e7c:	9736                	add	a4,a4,a3
    80005e7e:	feb764e3          	bltu	a4,a1,80005e66 <sys_munmap+0x4a>
      idx = i;
      vma = &p->vmas[i];
      break;
    }
  }
  if (idx == -1)
    80005e82:	57fd                	li	a5,-1
    80005e84:	14f48b63          	beq	s1,a5,80005fda <sys_munmap+0x1be>
    // not in a valid VMA
    return -1;

  addr = PGROUNDDOWN(addr);
    80005e88:	77fd                	lui	a5,0xfffff
    80005e8a:	8dfd                	and	a1,a1,a5
    80005e8c:	fcb43423          	sd	a1,-56(s0)
  length = PGROUNDUP(length);
    80005e90:	fc442603          	lw	a2,-60(s0)
    80005e94:	6785                	lui	a5,0x1
    80005e96:	37fd                	addiw	a5,a5,-1
    80005e98:	9e3d                	addw	a2,a2,a5
    80005e9a:	77fd                	lui	a5,0xfffff
    80005e9c:	8e7d                	and	a2,a2,a5
    80005e9e:	2601                	sext.w	a2,a2
    80005ea0:	fcc42223          	sw	a2,-60(s0)
  if (vma->flags & MAP_SHARED) {
    80005ea4:	00149793          	slli	a5,s1,0x1
    80005ea8:	97a6                	add	a5,a5,s1
    80005eaa:	0792                	slli	a5,a5,0x4
    80005eac:	97ca                	add	a5,a5,s2
    80005eae:	1807a783          	lw	a5,384(a5) # fffffffffffff180 <end+0xffffffff7ffcd180>
    80005eb2:	8b85                	andi	a5,a5,1
    80005eb4:	efad                	bnez	a5,80005f2e <sys_munmap+0x112>
    // write back
    if (filewrite(vma->f, addr, length) < 0) {
      printf("munmap: filewrite < 0\n");
    }
  }
  uvmunmap(p->pagetable, addr, length/PGSIZE, 1);
    80005eb6:	fc442783          	lw	a5,-60(s0)
    80005eba:	41f7d61b          	sraiw	a2,a5,0x1f
    80005ebe:	0146561b          	srliw	a2,a2,0x14
    80005ec2:	9e3d                	addw	a2,a2,a5
    80005ec4:	4685                	li	a3,1
    80005ec6:	40c6561b          	sraiw	a2,a2,0xc
    80005eca:	fc843583          	ld	a1,-56(s0)
    80005ece:	05093503          	ld	a0,80(s2)
    80005ed2:	ffffb097          	auipc	ra,0xffffb
    80005ed6:	388080e7          	jalr	904(ra) # 8000125a <uvmunmap>

  // change the mmap parameter
  if (addr == vma->addr && length == vma->length) {
    80005eda:	00149793          	slli	a5,s1,0x1
    80005ede:	97a6                	add	a5,a5,s1
    80005ee0:	0792                	slli	a5,a5,0x4
    80005ee2:	97ca                	add	a5,a5,s2
    80005ee4:	1707b703          	ld	a4,368(a5)
    80005ee8:	fc843683          	ld	a3,-56(s0)
    80005eec:	06d70763          	beq	a4,a3,80005f5a <sys_munmap+0x13e>
  } else if (addr == vma->addr) {
    // cover the beginning
    vma->addr += length;
    vma->length -= length;
    vma->offset += length;
  } else if ((addr + length) == (vma->addr + vma->length)) {
    80005ef0:	fc442583          	lw	a1,-60(s0)
    80005ef4:	00149793          	slli	a5,s1,0x1
    80005ef8:	97a6                	add	a5,a5,s1
    80005efa:	0792                	slli	a5,a5,0x4
    80005efc:	97ca                	add	a5,a5,s2
    80005efe:	1787a603          	lw	a2,376(a5)
    80005f02:	96ae                	add	a3,a3,a1
    80005f04:	9732                	add	a4,a4,a2
    80005f06:	0ae69e63          	bne	a3,a4,80005fc2 <sys_munmap+0x1a6>
    // cover the end
    vma->length -= length;
    80005f0a:	00149793          	slli	a5,s1,0x1
    80005f0e:	94be                	add	s1,s1,a5
    80005f10:	0492                	slli	s1,s1,0x4
    80005f12:	9926                	add	s2,s2,s1
    80005f14:	9e0d                	subw	a2,a2,a1
    80005f16:	16c92c23          	sw	a2,376(s2)
  } else {
    panic("munmap neither cover beginning or end of mapped region");
  }

  return 0;
    80005f1a:	4501                	li	a0,0
    80005f1c:	a011                	j	80005f20 <sys_munmap+0x104>
    return -1;
    80005f1e:	557d                	li	a0,-1
}
    80005f20:	70e2                	ld	ra,56(sp)
    80005f22:	7442                	ld	s0,48(sp)
    80005f24:	74a2                	ld	s1,40(sp)
    80005f26:	7902                	ld	s2,32(sp)
    80005f28:	69e2                	ld	s3,24(sp)
    80005f2a:	6121                	addi	sp,sp,64
    80005f2c:	8082                	ret
    if (filewrite(vma->f, addr, length) < 0) {
    80005f2e:	00149793          	slli	a5,s1,0x1
    80005f32:	97a6                	add	a5,a5,s1
    80005f34:	0792                	slli	a5,a5,0x4
    80005f36:	97ca                	add	a5,a5,s2
    80005f38:	1907b503          	ld	a0,400(a5)
    80005f3c:	fffff097          	auipc	ra,0xfffff
    80005f40:	960080e7          	jalr	-1696(ra) # 8000489c <filewrite>
    80005f44:	f60559e3          	bgez	a0,80005eb6 <sys_munmap+0x9a>
      printf("munmap: filewrite < 0\n");
    80005f48:	00002517          	auipc	a0,0x2
    80005f4c:	7d050513          	addi	a0,a0,2000 # 80008718 <syscalls+0x330>
    80005f50:	ffffa097          	auipc	ra,0xffffa
    80005f54:	62a080e7          	jalr	1578(ra) # 8000057a <printf>
    80005f58:	bfb9                	j	80005eb6 <sys_munmap+0x9a>
  if (addr == vma->addr && length == vma->length) {
    80005f5a:	fc442603          	lw	a2,-60(s0)
    80005f5e:	00149793          	slli	a5,s1,0x1
    80005f62:	97a6                	add	a5,a5,s1
    80005f64:	0792                	slli	a5,a5,0x4
    80005f66:	97ca                	add	a5,a5,s2
    80005f68:	1787a783          	lw	a5,376(a5)
    80005f6c:	02c78763          	beq	a5,a2,80005f9a <sys_munmap+0x17e>
    vma->addr += length;
    80005f70:	00149693          	slli	a3,s1,0x1
    80005f74:	009687b3          	add	a5,a3,s1
    80005f78:	0792                	slli	a5,a5,0x4
    80005f7a:	97ca                	add	a5,a5,s2
    80005f7c:	9732                	add	a4,a4,a2
    80005f7e:	16e7b823          	sd	a4,368(a5)
    vma->length -= length;
    80005f82:	1787a703          	lw	a4,376(a5)
    80005f86:	9f11                	subw	a4,a4,a2
    80005f88:	16e7ac23          	sw	a4,376(a5)
    vma->offset += length;
    80005f8c:	1887a703          	lw	a4,392(a5)
    80005f90:	9e39                	addw	a2,a2,a4
    80005f92:	18c7a423          	sw	a2,392(a5)
  return 0;
    80005f96:	4501                	li	a0,0
    80005f98:	b761                	j	80005f20 <sys_munmap+0x104>
    fileclose(vma->f);
    80005f9a:	00149993          	slli	s3,s1,0x1
    80005f9e:	009987b3          	add	a5,s3,s1
    80005fa2:	0792                	slli	a5,a5,0x4
    80005fa4:	97ca                	add	a5,a5,s2
    80005fa6:	1907b503          	ld	a0,400(a5)
    80005faa:	ffffe097          	auipc	ra,0xffffe
    80005fae:	6f6080e7          	jalr	1782(ra) # 800046a0 <fileclose>
    vma->valid = 0;
    80005fb2:	009987b3          	add	a5,s3,s1
    80005fb6:	0792                	slli	a5,a5,0x4
    80005fb8:	993e                	add	s2,s2,a5
    80005fba:	16092423          	sw	zero,360(s2)
  return 0;
    80005fbe:	4501                	li	a0,0
    vma->valid = 0;
    80005fc0:	b785                	j	80005f20 <sys_munmap+0x104>
    panic("munmap neither cover beginning or end of mapped region");
    80005fc2:	00002517          	auipc	a0,0x2
    80005fc6:	76e50513          	addi	a0,a0,1902 # 80008730 <syscalls+0x348>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	566080e7          	jalr	1382(ra) # 80000530 <panic>
    return -1;
    80005fd2:	557d                	li	a0,-1
    80005fd4:	b7b1                	j	80005f20 <sys_munmap+0x104>
    80005fd6:	557d                	li	a0,-1
    80005fd8:	b7a1                	j	80005f20 <sys_munmap+0x104>
    return -1;
    80005fda:	557d                	li	a0,-1
    80005fdc:	b791                	j	80005f20 <sys_munmap+0x104>
	...

0000000080005fe0 <kernelvec>:
    80005fe0:	7111                	addi	sp,sp,-256
    80005fe2:	e006                	sd	ra,0(sp)
    80005fe4:	e40a                	sd	sp,8(sp)
    80005fe6:	e80e                	sd	gp,16(sp)
    80005fe8:	ec12                	sd	tp,24(sp)
    80005fea:	f016                	sd	t0,32(sp)
    80005fec:	f41a                	sd	t1,40(sp)
    80005fee:	f81e                	sd	t2,48(sp)
    80005ff0:	fc22                	sd	s0,56(sp)
    80005ff2:	e0a6                	sd	s1,64(sp)
    80005ff4:	e4aa                	sd	a0,72(sp)
    80005ff6:	e8ae                	sd	a1,80(sp)
    80005ff8:	ecb2                	sd	a2,88(sp)
    80005ffa:	f0b6                	sd	a3,96(sp)
    80005ffc:	f4ba                	sd	a4,104(sp)
    80005ffe:	f8be                	sd	a5,112(sp)
    80006000:	fcc2                	sd	a6,120(sp)
    80006002:	e146                	sd	a7,128(sp)
    80006004:	e54a                	sd	s2,136(sp)
    80006006:	e94e                	sd	s3,144(sp)
    80006008:	ed52                	sd	s4,152(sp)
    8000600a:	f156                	sd	s5,160(sp)
    8000600c:	f55a                	sd	s6,168(sp)
    8000600e:	f95e                	sd	s7,176(sp)
    80006010:	fd62                	sd	s8,184(sp)
    80006012:	e1e6                	sd	s9,192(sp)
    80006014:	e5ea                	sd	s10,200(sp)
    80006016:	e9ee                	sd	s11,208(sp)
    80006018:	edf2                	sd	t3,216(sp)
    8000601a:	f1f6                	sd	t4,224(sp)
    8000601c:	f5fa                	sd	t5,232(sp)
    8000601e:	f9fe                	sd	t6,240(sp)
    80006020:	a9bfc0ef          	jal	ra,80002aba <kerneltrap>
    80006024:	6082                	ld	ra,0(sp)
    80006026:	6122                	ld	sp,8(sp)
    80006028:	61c2                	ld	gp,16(sp)
    8000602a:	7282                	ld	t0,32(sp)
    8000602c:	7322                	ld	t1,40(sp)
    8000602e:	73c2                	ld	t2,48(sp)
    80006030:	7462                	ld	s0,56(sp)
    80006032:	6486                	ld	s1,64(sp)
    80006034:	6526                	ld	a0,72(sp)
    80006036:	65c6                	ld	a1,80(sp)
    80006038:	6666                	ld	a2,88(sp)
    8000603a:	7686                	ld	a3,96(sp)
    8000603c:	7726                	ld	a4,104(sp)
    8000603e:	77c6                	ld	a5,112(sp)
    80006040:	7866                	ld	a6,120(sp)
    80006042:	688a                	ld	a7,128(sp)
    80006044:	692a                	ld	s2,136(sp)
    80006046:	69ca                	ld	s3,144(sp)
    80006048:	6a6a                	ld	s4,152(sp)
    8000604a:	7a8a                	ld	s5,160(sp)
    8000604c:	7b2a                	ld	s6,168(sp)
    8000604e:	7bca                	ld	s7,176(sp)
    80006050:	7c6a                	ld	s8,184(sp)
    80006052:	6c8e                	ld	s9,192(sp)
    80006054:	6d2e                	ld	s10,200(sp)
    80006056:	6dce                	ld	s11,208(sp)
    80006058:	6e6e                	ld	t3,216(sp)
    8000605a:	7e8e                	ld	t4,224(sp)
    8000605c:	7f2e                	ld	t5,232(sp)
    8000605e:	7fce                	ld	t6,240(sp)
    80006060:	6111                	addi	sp,sp,256
    80006062:	10200073          	sret
    80006066:	00000013          	nop
    8000606a:	00000013          	nop
    8000606e:	0001                	nop

0000000080006070 <timervec>:
    80006070:	34051573          	csrrw	a0,mscratch,a0
    80006074:	e10c                	sd	a1,0(a0)
    80006076:	e510                	sd	a2,8(a0)
    80006078:	e914                	sd	a3,16(a0)
    8000607a:	6d0c                	ld	a1,24(a0)
    8000607c:	7110                	ld	a2,32(a0)
    8000607e:	6194                	ld	a3,0(a1)
    80006080:	96b2                	add	a3,a3,a2
    80006082:	e194                	sd	a3,0(a1)
    80006084:	4589                	li	a1,2
    80006086:	14459073          	csrw	sip,a1
    8000608a:	6914                	ld	a3,16(a0)
    8000608c:	6510                	ld	a2,8(a0)
    8000608e:	610c                	ld	a1,0(a0)
    80006090:	34051573          	csrrw	a0,mscratch,a0
    80006094:	30200073          	mret
	...

000000008000609a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000609a:	1141                	addi	sp,sp,-16
    8000609c:	e422                	sd	s0,8(sp)
    8000609e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060a0:	0c0007b7          	lui	a5,0xc000
    800060a4:	4705                	li	a4,1
    800060a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060a8:	c3d8                	sw	a4,4(a5)
}
    800060aa:	6422                	ld	s0,8(sp)
    800060ac:	0141                	addi	sp,sp,16
    800060ae:	8082                	ret

00000000800060b0 <plicinithart>:

void
plicinithart(void)
{
    800060b0:	1141                	addi	sp,sp,-16
    800060b2:	e406                	sd	ra,8(sp)
    800060b4:	e022                	sd	s0,0(sp)
    800060b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	8c2080e7          	jalr	-1854(ra) # 8000197a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060c0:	0085171b          	slliw	a4,a0,0x8
    800060c4:	0c0027b7          	lui	a5,0xc002
    800060c8:	97ba                	add	a5,a5,a4
    800060ca:	40200713          	li	a4,1026
    800060ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060d2:	00d5151b          	slliw	a0,a0,0xd
    800060d6:	0c2017b7          	lui	a5,0xc201
    800060da:	953e                	add	a0,a0,a5
    800060dc:	00052023          	sw	zero,0(a0)
}
    800060e0:	60a2                	ld	ra,8(sp)
    800060e2:	6402                	ld	s0,0(sp)
    800060e4:	0141                	addi	sp,sp,16
    800060e6:	8082                	ret

00000000800060e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060e8:	1141                	addi	sp,sp,-16
    800060ea:	e406                	sd	ra,8(sp)
    800060ec:	e022                	sd	s0,0(sp)
    800060ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060f0:	ffffc097          	auipc	ra,0xffffc
    800060f4:	88a080e7          	jalr	-1910(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060f8:	00d5179b          	slliw	a5,a0,0xd
    800060fc:	0c201537          	lui	a0,0xc201
    80006100:	953e                	add	a0,a0,a5
  return irq;
}
    80006102:	4148                	lw	a0,4(a0)
    80006104:	60a2                	ld	ra,8(sp)
    80006106:	6402                	ld	s0,0(sp)
    80006108:	0141                	addi	sp,sp,16
    8000610a:	8082                	ret

000000008000610c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000610c:	1101                	addi	sp,sp,-32
    8000610e:	ec06                	sd	ra,24(sp)
    80006110:	e822                	sd	s0,16(sp)
    80006112:	e426                	sd	s1,8(sp)
    80006114:	1000                	addi	s0,sp,32
    80006116:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006118:	ffffc097          	auipc	ra,0xffffc
    8000611c:	862080e7          	jalr	-1950(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006120:	00d5151b          	slliw	a0,a0,0xd
    80006124:	0c2017b7          	lui	a5,0xc201
    80006128:	97aa                	add	a5,a5,a0
    8000612a:	c3c4                	sw	s1,4(a5)
}
    8000612c:	60e2                	ld	ra,24(sp)
    8000612e:	6442                	ld	s0,16(sp)
    80006130:	64a2                	ld	s1,8(sp)
    80006132:	6105                	addi	sp,sp,32
    80006134:	8082                	ret

0000000080006136 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006136:	1141                	addi	sp,sp,-16
    80006138:	e406                	sd	ra,8(sp)
    8000613a:	e022                	sd	s0,0(sp)
    8000613c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000613e:	479d                	li	a5,7
    80006140:	06a7c963          	blt	a5,a0,800061b2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006144:	00029797          	auipc	a5,0x29
    80006148:	ebc78793          	addi	a5,a5,-324 # 8002f000 <disk>
    8000614c:	00a78733          	add	a4,a5,a0
    80006150:	6789                	lui	a5,0x2
    80006152:	97ba                	add	a5,a5,a4
    80006154:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006158:	e7ad                	bnez	a5,800061c2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000615a:	00451793          	slli	a5,a0,0x4
    8000615e:	0002b717          	auipc	a4,0x2b
    80006162:	ea270713          	addi	a4,a4,-350 # 80031000 <disk+0x2000>
    80006166:	6314                	ld	a3,0(a4)
    80006168:	96be                	add	a3,a3,a5
    8000616a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000616e:	6314                	ld	a3,0(a4)
    80006170:	96be                	add	a3,a3,a5
    80006172:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006176:	6314                	ld	a3,0(a4)
    80006178:	96be                	add	a3,a3,a5
    8000617a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000617e:	6318                	ld	a4,0(a4)
    80006180:	97ba                	add	a5,a5,a4
    80006182:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006186:	00029797          	auipc	a5,0x29
    8000618a:	e7a78793          	addi	a5,a5,-390 # 8002f000 <disk>
    8000618e:	97aa                	add	a5,a5,a0
    80006190:	6509                	lui	a0,0x2
    80006192:	953e                	add	a0,a0,a5
    80006194:	4785                	li	a5,1
    80006196:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000619a:	0002b517          	auipc	a0,0x2b
    8000619e:	e7e50513          	addi	a0,a0,-386 # 80031018 <disk+0x2018>
    800061a2:	ffffc097          	auipc	ra,0xffffc
    800061a6:	276080e7          	jalr	630(ra) # 80002418 <wakeup>
}
    800061aa:	60a2                	ld	ra,8(sp)
    800061ac:	6402                	ld	s0,0(sp)
    800061ae:	0141                	addi	sp,sp,16
    800061b0:	8082                	ret
    panic("free_desc 1");
    800061b2:	00002517          	auipc	a0,0x2
    800061b6:	5b650513          	addi	a0,a0,1462 # 80008768 <syscalls+0x380>
    800061ba:	ffffa097          	auipc	ra,0xffffa
    800061be:	376080e7          	jalr	886(ra) # 80000530 <panic>
    panic("free_desc 2");
    800061c2:	00002517          	auipc	a0,0x2
    800061c6:	5b650513          	addi	a0,a0,1462 # 80008778 <syscalls+0x390>
    800061ca:	ffffa097          	auipc	ra,0xffffa
    800061ce:	366080e7          	jalr	870(ra) # 80000530 <panic>

00000000800061d2 <virtio_disk_init>:
{
    800061d2:	1101                	addi	sp,sp,-32
    800061d4:	ec06                	sd	ra,24(sp)
    800061d6:	e822                	sd	s0,16(sp)
    800061d8:	e426                	sd	s1,8(sp)
    800061da:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061dc:	00002597          	auipc	a1,0x2
    800061e0:	5ac58593          	addi	a1,a1,1452 # 80008788 <syscalls+0x3a0>
    800061e4:	0002b517          	auipc	a0,0x2b
    800061e8:	f4450513          	addi	a0,a0,-188 # 80031128 <disk+0x2128>
    800061ec:	ffffb097          	auipc	ra,0xffffb
    800061f0:	95a080e7          	jalr	-1702(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061f4:	100017b7          	lui	a5,0x10001
    800061f8:	4398                	lw	a4,0(a5)
    800061fa:	2701                	sext.w	a4,a4
    800061fc:	747277b7          	lui	a5,0x74727
    80006200:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006204:	0ef71163          	bne	a4,a5,800062e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006208:	100017b7          	lui	a5,0x10001
    8000620c:	43dc                	lw	a5,4(a5)
    8000620e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006210:	4705                	li	a4,1
    80006212:	0ce79a63          	bne	a5,a4,800062e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006216:	100017b7          	lui	a5,0x10001
    8000621a:	479c                	lw	a5,8(a5)
    8000621c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000621e:	4709                	li	a4,2
    80006220:	0ce79363          	bne	a5,a4,800062e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006224:	100017b7          	lui	a5,0x10001
    80006228:	47d8                	lw	a4,12(a5)
    8000622a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000622c:	554d47b7          	lui	a5,0x554d4
    80006230:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006234:	0af71963          	bne	a4,a5,800062e6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006238:	100017b7          	lui	a5,0x10001
    8000623c:	4705                	li	a4,1
    8000623e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006240:	470d                	li	a4,3
    80006242:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006244:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006246:	c7ffe737          	lui	a4,0xc7ffe
    8000624a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcc75f>
    8000624e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006250:	2701                	sext.w	a4,a4
    80006252:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006254:	472d                	li	a4,11
    80006256:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006258:	473d                	li	a4,15
    8000625a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000625c:	6705                	lui	a4,0x1
    8000625e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006260:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006264:	5bdc                	lw	a5,52(a5)
    80006266:	2781                	sext.w	a5,a5
  if(max == 0)
    80006268:	c7d9                	beqz	a5,800062f6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000626a:	471d                	li	a4,7
    8000626c:	08f77d63          	bgeu	a4,a5,80006306 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006270:	100014b7          	lui	s1,0x10001
    80006274:	47a1                	li	a5,8
    80006276:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006278:	6609                	lui	a2,0x2
    8000627a:	4581                	li	a1,0
    8000627c:	00029517          	auipc	a0,0x29
    80006280:	d8450513          	addi	a0,a0,-636 # 8002f000 <disk>
    80006284:	ffffb097          	auipc	ra,0xffffb
    80006288:	a4e080e7          	jalr	-1458(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000628c:	00029717          	auipc	a4,0x29
    80006290:	d7470713          	addi	a4,a4,-652 # 8002f000 <disk>
    80006294:	00c75793          	srli	a5,a4,0xc
    80006298:	2781                	sext.w	a5,a5
    8000629a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000629c:	0002b797          	auipc	a5,0x2b
    800062a0:	d6478793          	addi	a5,a5,-668 # 80031000 <disk+0x2000>
    800062a4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800062a6:	00029717          	auipc	a4,0x29
    800062aa:	dda70713          	addi	a4,a4,-550 # 8002f080 <disk+0x80>
    800062ae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800062b0:	0002a717          	auipc	a4,0x2a
    800062b4:	d5070713          	addi	a4,a4,-688 # 80030000 <disk+0x1000>
    800062b8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800062ba:	4705                	li	a4,1
    800062bc:	00e78c23          	sb	a4,24(a5)
    800062c0:	00e78ca3          	sb	a4,25(a5)
    800062c4:	00e78d23          	sb	a4,26(a5)
    800062c8:	00e78da3          	sb	a4,27(a5)
    800062cc:	00e78e23          	sb	a4,28(a5)
    800062d0:	00e78ea3          	sb	a4,29(a5)
    800062d4:	00e78f23          	sb	a4,30(a5)
    800062d8:	00e78fa3          	sb	a4,31(a5)
}
    800062dc:	60e2                	ld	ra,24(sp)
    800062de:	6442                	ld	s0,16(sp)
    800062e0:	64a2                	ld	s1,8(sp)
    800062e2:	6105                	addi	sp,sp,32
    800062e4:	8082                	ret
    panic("could not find virtio disk");
    800062e6:	00002517          	auipc	a0,0x2
    800062ea:	4b250513          	addi	a0,a0,1202 # 80008798 <syscalls+0x3b0>
    800062ee:	ffffa097          	auipc	ra,0xffffa
    800062f2:	242080e7          	jalr	578(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    800062f6:	00002517          	auipc	a0,0x2
    800062fa:	4c250513          	addi	a0,a0,1218 # 800087b8 <syscalls+0x3d0>
    800062fe:	ffffa097          	auipc	ra,0xffffa
    80006302:	232080e7          	jalr	562(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    80006306:	00002517          	auipc	a0,0x2
    8000630a:	4d250513          	addi	a0,a0,1234 # 800087d8 <syscalls+0x3f0>
    8000630e:	ffffa097          	auipc	ra,0xffffa
    80006312:	222080e7          	jalr	546(ra) # 80000530 <panic>

0000000080006316 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006316:	7159                	addi	sp,sp,-112
    80006318:	f486                	sd	ra,104(sp)
    8000631a:	f0a2                	sd	s0,96(sp)
    8000631c:	eca6                	sd	s1,88(sp)
    8000631e:	e8ca                	sd	s2,80(sp)
    80006320:	e4ce                	sd	s3,72(sp)
    80006322:	e0d2                	sd	s4,64(sp)
    80006324:	fc56                	sd	s5,56(sp)
    80006326:	f85a                	sd	s6,48(sp)
    80006328:	f45e                	sd	s7,40(sp)
    8000632a:	f062                	sd	s8,32(sp)
    8000632c:	ec66                	sd	s9,24(sp)
    8000632e:	e86a                	sd	s10,16(sp)
    80006330:	1880                	addi	s0,sp,112
    80006332:	892a                	mv	s2,a0
    80006334:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006336:	00c52c83          	lw	s9,12(a0)
    8000633a:	001c9c9b          	slliw	s9,s9,0x1
    8000633e:	1c82                	slli	s9,s9,0x20
    80006340:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006344:	0002b517          	auipc	a0,0x2b
    80006348:	de450513          	addi	a0,a0,-540 # 80031128 <disk+0x2128>
    8000634c:	ffffb097          	auipc	ra,0xffffb
    80006350:	88a080e7          	jalr	-1910(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006354:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006356:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006358:	00029b97          	auipc	s7,0x29
    8000635c:	ca8b8b93          	addi	s7,s7,-856 # 8002f000 <disk>
    80006360:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006362:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006364:	8a4e                	mv	s4,s3
    80006366:	a051                	j	800063ea <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006368:	00fb86b3          	add	a3,s7,a5
    8000636c:	96da                	add	a3,a3,s6
    8000636e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006372:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006374:	0207c563          	bltz	a5,8000639e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006378:	2485                	addiw	s1,s1,1
    8000637a:	0711                	addi	a4,a4,4
    8000637c:	25548063          	beq	s1,s5,800065bc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006380:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006382:	0002b697          	auipc	a3,0x2b
    80006386:	c9668693          	addi	a3,a3,-874 # 80031018 <disk+0x2018>
    8000638a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000638c:	0006c583          	lbu	a1,0(a3)
    80006390:	fde1                	bnez	a1,80006368 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006392:	2785                	addiw	a5,a5,1
    80006394:	0685                	addi	a3,a3,1
    80006396:	ff879be3          	bne	a5,s8,8000638c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000639a:	57fd                	li	a5,-1
    8000639c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000639e:	02905a63          	blez	s1,800063d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063a2:	f9042503          	lw	a0,-112(s0)
    800063a6:	00000097          	auipc	ra,0x0
    800063aa:	d90080e7          	jalr	-624(ra) # 80006136 <free_desc>
      for(int j = 0; j < i; j++)
    800063ae:	4785                	li	a5,1
    800063b0:	0297d163          	bge	a5,s1,800063d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063b4:	f9442503          	lw	a0,-108(s0)
    800063b8:	00000097          	auipc	ra,0x0
    800063bc:	d7e080e7          	jalr	-642(ra) # 80006136 <free_desc>
      for(int j = 0; j < i; j++)
    800063c0:	4789                	li	a5,2
    800063c2:	0097d863          	bge	a5,s1,800063d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063c6:	f9842503          	lw	a0,-104(s0)
    800063ca:	00000097          	auipc	ra,0x0
    800063ce:	d6c080e7          	jalr	-660(ra) # 80006136 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063d2:	0002b597          	auipc	a1,0x2b
    800063d6:	d5658593          	addi	a1,a1,-682 # 80031128 <disk+0x2128>
    800063da:	0002b517          	auipc	a0,0x2b
    800063de:	c3e50513          	addi	a0,a0,-962 # 80031018 <disk+0x2018>
    800063e2:	ffffc097          	auipc	ra,0xffffc
    800063e6:	eb0080e7          	jalr	-336(ra) # 80002292 <sleep>
  for(int i = 0; i < 3; i++){
    800063ea:	f9040713          	addi	a4,s0,-112
    800063ee:	84ce                	mv	s1,s3
    800063f0:	bf41                	j	80006380 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800063f2:	20058713          	addi	a4,a1,512
    800063f6:	00471693          	slli	a3,a4,0x4
    800063fa:	00029717          	auipc	a4,0x29
    800063fe:	c0670713          	addi	a4,a4,-1018 # 8002f000 <disk>
    80006402:	9736                	add	a4,a4,a3
    80006404:	4685                	li	a3,1
    80006406:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000640a:	20058713          	addi	a4,a1,512
    8000640e:	00471693          	slli	a3,a4,0x4
    80006412:	00029717          	auipc	a4,0x29
    80006416:	bee70713          	addi	a4,a4,-1042 # 8002f000 <disk>
    8000641a:	9736                	add	a4,a4,a3
    8000641c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006420:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006424:	7679                	lui	a2,0xffffe
    80006426:	963e                	add	a2,a2,a5
    80006428:	0002b697          	auipc	a3,0x2b
    8000642c:	bd868693          	addi	a3,a3,-1064 # 80031000 <disk+0x2000>
    80006430:	6298                	ld	a4,0(a3)
    80006432:	9732                	add	a4,a4,a2
    80006434:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006436:	6298                	ld	a4,0(a3)
    80006438:	9732                	add	a4,a4,a2
    8000643a:	4541                	li	a0,16
    8000643c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000643e:	6298                	ld	a4,0(a3)
    80006440:	9732                	add	a4,a4,a2
    80006442:	4505                	li	a0,1
    80006444:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006448:	f9442703          	lw	a4,-108(s0)
    8000644c:	6288                	ld	a0,0(a3)
    8000644e:	962a                	add	a2,a2,a0
    80006450:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcc00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006454:	0712                	slli	a4,a4,0x4
    80006456:	6290                	ld	a2,0(a3)
    80006458:	963a                	add	a2,a2,a4
    8000645a:	05890513          	addi	a0,s2,88
    8000645e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006460:	6294                	ld	a3,0(a3)
    80006462:	96ba                	add	a3,a3,a4
    80006464:	40000613          	li	a2,1024
    80006468:	c690                	sw	a2,8(a3)
  if(write)
    8000646a:	140d0063          	beqz	s10,800065aa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000646e:	0002b697          	auipc	a3,0x2b
    80006472:	b926b683          	ld	a3,-1134(a3) # 80031000 <disk+0x2000>
    80006476:	96ba                	add	a3,a3,a4
    80006478:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000647c:	00029817          	auipc	a6,0x29
    80006480:	b8480813          	addi	a6,a6,-1148 # 8002f000 <disk>
    80006484:	0002b517          	auipc	a0,0x2b
    80006488:	b7c50513          	addi	a0,a0,-1156 # 80031000 <disk+0x2000>
    8000648c:	6114                	ld	a3,0(a0)
    8000648e:	96ba                	add	a3,a3,a4
    80006490:	00c6d603          	lhu	a2,12(a3)
    80006494:	00166613          	ori	a2,a2,1
    80006498:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000649c:	f9842683          	lw	a3,-104(s0)
    800064a0:	6110                	ld	a2,0(a0)
    800064a2:	9732                	add	a4,a4,a2
    800064a4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064a8:	20058613          	addi	a2,a1,512
    800064ac:	0612                	slli	a2,a2,0x4
    800064ae:	9642                	add	a2,a2,a6
    800064b0:	577d                	li	a4,-1
    800064b2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064b6:	00469713          	slli	a4,a3,0x4
    800064ba:	6114                	ld	a3,0(a0)
    800064bc:	96ba                	add	a3,a3,a4
    800064be:	03078793          	addi	a5,a5,48
    800064c2:	97c2                	add	a5,a5,a6
    800064c4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800064c6:	611c                	ld	a5,0(a0)
    800064c8:	97ba                	add	a5,a5,a4
    800064ca:	4685                	li	a3,1
    800064cc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064ce:	611c                	ld	a5,0(a0)
    800064d0:	97ba                	add	a5,a5,a4
    800064d2:	4809                	li	a6,2
    800064d4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800064d8:	611c                	ld	a5,0(a0)
    800064da:	973e                	add	a4,a4,a5
    800064dc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800064e0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800064e4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800064e8:	6518                	ld	a4,8(a0)
    800064ea:	00275783          	lhu	a5,2(a4)
    800064ee:	8b9d                	andi	a5,a5,7
    800064f0:	0786                	slli	a5,a5,0x1
    800064f2:	97ba                	add	a5,a5,a4
    800064f4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800064f8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064fc:	6518                	ld	a4,8(a0)
    800064fe:	00275783          	lhu	a5,2(a4)
    80006502:	2785                	addiw	a5,a5,1
    80006504:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006508:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000650c:	100017b7          	lui	a5,0x10001
    80006510:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006514:	00492703          	lw	a4,4(s2)
    80006518:	4785                	li	a5,1
    8000651a:	02f71163          	bne	a4,a5,8000653c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000651e:	0002b997          	auipc	s3,0x2b
    80006522:	c0a98993          	addi	s3,s3,-1014 # 80031128 <disk+0x2128>
  while(b->disk == 1) {
    80006526:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006528:	85ce                	mv	a1,s3
    8000652a:	854a                	mv	a0,s2
    8000652c:	ffffc097          	auipc	ra,0xffffc
    80006530:	d66080e7          	jalr	-666(ra) # 80002292 <sleep>
  while(b->disk == 1) {
    80006534:	00492783          	lw	a5,4(s2)
    80006538:	fe9788e3          	beq	a5,s1,80006528 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000653c:	f9042903          	lw	s2,-112(s0)
    80006540:	20090793          	addi	a5,s2,512
    80006544:	00479713          	slli	a4,a5,0x4
    80006548:	00029797          	auipc	a5,0x29
    8000654c:	ab878793          	addi	a5,a5,-1352 # 8002f000 <disk>
    80006550:	97ba                	add	a5,a5,a4
    80006552:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006556:	0002b997          	auipc	s3,0x2b
    8000655a:	aaa98993          	addi	s3,s3,-1366 # 80031000 <disk+0x2000>
    8000655e:	00491713          	slli	a4,s2,0x4
    80006562:	0009b783          	ld	a5,0(s3)
    80006566:	97ba                	add	a5,a5,a4
    80006568:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000656c:	854a                	mv	a0,s2
    8000656e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006572:	00000097          	auipc	ra,0x0
    80006576:	bc4080e7          	jalr	-1084(ra) # 80006136 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000657a:	8885                	andi	s1,s1,1
    8000657c:	f0ed                	bnez	s1,8000655e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000657e:	0002b517          	auipc	a0,0x2b
    80006582:	baa50513          	addi	a0,a0,-1110 # 80031128 <disk+0x2128>
    80006586:	ffffa097          	auipc	ra,0xffffa
    8000658a:	704080e7          	jalr	1796(ra) # 80000c8a <release>
}
    8000658e:	70a6                	ld	ra,104(sp)
    80006590:	7406                	ld	s0,96(sp)
    80006592:	64e6                	ld	s1,88(sp)
    80006594:	6946                	ld	s2,80(sp)
    80006596:	69a6                	ld	s3,72(sp)
    80006598:	6a06                	ld	s4,64(sp)
    8000659a:	7ae2                	ld	s5,56(sp)
    8000659c:	7b42                	ld	s6,48(sp)
    8000659e:	7ba2                	ld	s7,40(sp)
    800065a0:	7c02                	ld	s8,32(sp)
    800065a2:	6ce2                	ld	s9,24(sp)
    800065a4:	6d42                	ld	s10,16(sp)
    800065a6:	6165                	addi	sp,sp,112
    800065a8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065aa:	0002b697          	auipc	a3,0x2b
    800065ae:	a566b683          	ld	a3,-1450(a3) # 80031000 <disk+0x2000>
    800065b2:	96ba                	add	a3,a3,a4
    800065b4:	4609                	li	a2,2
    800065b6:	00c69623          	sh	a2,12(a3)
    800065ba:	b5c9                	j	8000647c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065bc:	f9042583          	lw	a1,-112(s0)
    800065c0:	20058793          	addi	a5,a1,512
    800065c4:	0792                	slli	a5,a5,0x4
    800065c6:	00029517          	auipc	a0,0x29
    800065ca:	ae250513          	addi	a0,a0,-1310 # 8002f0a8 <disk+0xa8>
    800065ce:	953e                	add	a0,a0,a5
  if(write)
    800065d0:	e20d11e3          	bnez	s10,800063f2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800065d4:	20058713          	addi	a4,a1,512
    800065d8:	00471693          	slli	a3,a4,0x4
    800065dc:	00029717          	auipc	a4,0x29
    800065e0:	a2470713          	addi	a4,a4,-1500 # 8002f000 <disk>
    800065e4:	9736                	add	a4,a4,a3
    800065e6:	0a072423          	sw	zero,168(a4)
    800065ea:	b505                	j	8000640a <virtio_disk_rw+0xf4>

00000000800065ec <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065ec:	1101                	addi	sp,sp,-32
    800065ee:	ec06                	sd	ra,24(sp)
    800065f0:	e822                	sd	s0,16(sp)
    800065f2:	e426                	sd	s1,8(sp)
    800065f4:	e04a                	sd	s2,0(sp)
    800065f6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065f8:	0002b517          	auipc	a0,0x2b
    800065fc:	b3050513          	addi	a0,a0,-1232 # 80031128 <disk+0x2128>
    80006600:	ffffa097          	auipc	ra,0xffffa
    80006604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006608:	10001737          	lui	a4,0x10001
    8000660c:	533c                	lw	a5,96(a4)
    8000660e:	8b8d                	andi	a5,a5,3
    80006610:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006612:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006616:	0002b797          	auipc	a5,0x2b
    8000661a:	9ea78793          	addi	a5,a5,-1558 # 80031000 <disk+0x2000>
    8000661e:	6b94                	ld	a3,16(a5)
    80006620:	0207d703          	lhu	a4,32(a5)
    80006624:	0026d783          	lhu	a5,2(a3)
    80006628:	06f70163          	beq	a4,a5,8000668a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000662c:	00029917          	auipc	s2,0x29
    80006630:	9d490913          	addi	s2,s2,-1580 # 8002f000 <disk>
    80006634:	0002b497          	auipc	s1,0x2b
    80006638:	9cc48493          	addi	s1,s1,-1588 # 80031000 <disk+0x2000>
    __sync_synchronize();
    8000663c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006640:	6898                	ld	a4,16(s1)
    80006642:	0204d783          	lhu	a5,32(s1)
    80006646:	8b9d                	andi	a5,a5,7
    80006648:	078e                	slli	a5,a5,0x3
    8000664a:	97ba                	add	a5,a5,a4
    8000664c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000664e:	20078713          	addi	a4,a5,512
    80006652:	0712                	slli	a4,a4,0x4
    80006654:	974a                	add	a4,a4,s2
    80006656:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000665a:	e731                	bnez	a4,800066a6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000665c:	20078793          	addi	a5,a5,512
    80006660:	0792                	slli	a5,a5,0x4
    80006662:	97ca                	add	a5,a5,s2
    80006664:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006666:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000666a:	ffffc097          	auipc	ra,0xffffc
    8000666e:	dae080e7          	jalr	-594(ra) # 80002418 <wakeup>

    disk.used_idx += 1;
    80006672:	0204d783          	lhu	a5,32(s1)
    80006676:	2785                	addiw	a5,a5,1
    80006678:	17c2                	slli	a5,a5,0x30
    8000667a:	93c1                	srli	a5,a5,0x30
    8000667c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006680:	6898                	ld	a4,16(s1)
    80006682:	00275703          	lhu	a4,2(a4)
    80006686:	faf71be3          	bne	a4,a5,8000663c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000668a:	0002b517          	auipc	a0,0x2b
    8000668e:	a9e50513          	addi	a0,a0,-1378 # 80031128 <disk+0x2128>
    80006692:	ffffa097          	auipc	ra,0xffffa
    80006696:	5f8080e7          	jalr	1528(ra) # 80000c8a <release>
}
    8000669a:	60e2                	ld	ra,24(sp)
    8000669c:	6442                	ld	s0,16(sp)
    8000669e:	64a2                	ld	s1,8(sp)
    800066a0:	6902                	ld	s2,0(sp)
    800066a2:	6105                	addi	sp,sp,32
    800066a4:	8082                	ret
      panic("virtio_disk_intr status");
    800066a6:	00002517          	auipc	a0,0x2
    800066aa:	15250513          	addi	a0,a0,338 # 800087f8 <syscalls+0x410>
    800066ae:	ffffa097          	auipc	ra,0xffffa
    800066b2:	e82080e7          	jalr	-382(ra) # 80000530 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
