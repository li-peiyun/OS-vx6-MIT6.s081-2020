
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b3013103          	ld	sp,-1232(sp) # 80008b30 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

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

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	24478793          	addi	a5,a5,580 # 800062a0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e6278793          	addi	a5,a5,-414 # 80000f08 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b4e080e7          	jalr	-1202(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00003097          	auipc	ra,0x3
    8000012a:	916080e7          	jalr	-1770(ra) # 80002a3c <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bc0080e7          	jalr	-1088(ra) # 80000d0e <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	abc080e7          	jalr	-1348(ra) # 80000c5a <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	c1e080e7          	jalr	-994(ra) # 80001dec <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	5a6080e7          	jalr	1446(ra) # 80002784 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	7cc080e7          	jalr	1996(ra) # 800029e6 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	ad8080e7          	jalr	-1320(ra) # 80000d0e <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	ac2080e7          	jalr	-1342(ra) # 80000d0e <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	97c080e7          	jalr	-1668(ra) # 80000c5a <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	796080e7          	jalr	1942(ra) # 80002a92 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a02080e7          	jalr	-1534(ra) # 80000d0e <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	4ba080e7          	jalr	1210(ra) # 8000290a <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	758080e7          	jalr	1880(ra) # 80000bca <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00022797          	auipc	a5,0x22
    80000486:	92e78793          	addi	a5,a5,-1746 # 80021db0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	650080e7          	jalr	1616(ra) # 80000c5a <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	5a0080e7          	jalr	1440(ra) # 80000d0e <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	436080e7          	jalr	1078(ra) # 80000bca <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	3e0080e7          	jalr	992(ra) # 80000bca <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	408080e7          	jalr	1032(ra) # 80000c0e <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	476080e7          	jalr	1142(ra) # 80000cae <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	054080e7          	jalr	84(ra) # 8000290a <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	360080e7          	jalr	864(ra) # 80000c5a <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	e34080e7          	jalr	-460(ra) # 80002784 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	37a080e7          	jalr	890(ra) # 80000d0e <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	25a080e7          	jalr	602(ra) # 80000c5a <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2fc080e7          	jalr	764(ra) # 80000d0e <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	306080e7          	jalr	774(ra) # 80000d56 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1f8080e7          	jalr	504(ra) # 80000c5a <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	298080e7          	jalr	664(ra) # 80000d0e <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	0ce080e7          	jalr	206(ra) # 80000bca <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	126080e7          	jalr	294(ra) # 80000c5a <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	1c2080e7          	jalr	450(ra) # 80000d0e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1fc080e7          	jalr	508(ra) # 80000d56 <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	198080e7          	jalr	408(ra) # 80000d0e <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <kfreemem>:

// Return the number of bytes of free memory
// should be multiple of PGSIZE
uint64
kfreemem(void) {
    80000b80:	1101                	addi	sp,sp,-32
    80000b82:	ec06                	sd	ra,24(sp)
    80000b84:	e822                	sd	s0,16(sp)
    80000b86:	e426                	sd	s1,8(sp)
    80000b88:	1000                	addi	s0,sp,32
  struct run *r;
  uint64 free = 0;
  acquire(&kmem.lock);
    80000b8a:	00011497          	auipc	s1,0x11
    80000b8e:	da648493          	addi	s1,s1,-602 # 80011930 <kmem>
    80000b92:	8526                	mv	a0,s1
    80000b94:	00000097          	auipc	ra,0x0
    80000b98:	0c6080e7          	jalr	198(ra) # 80000c5a <acquire>
  r = kmem.freelist;
    80000b9c:	6c9c                	ld	a5,24(s1)
  while (r) {
    80000b9e:	c785                	beqz	a5,80000bc6 <kfreemem+0x46>
  uint64 free = 0;
    80000ba0:	4481                	li	s1,0
    free += PGSIZE;
    80000ba2:	6705                	lui	a4,0x1
    80000ba4:	94ba                	add	s1,s1,a4
    r = r->next;
    80000ba6:	639c                	ld	a5,0(a5)
  while (r) {
    80000ba8:	fff5                	bnez	a5,80000ba4 <kfreemem+0x24>
  }
  release(&kmem.lock);
    80000baa:	00011517          	auipc	a0,0x11
    80000bae:	d8650513          	addi	a0,a0,-634 # 80011930 <kmem>
    80000bb2:	00000097          	auipc	ra,0x0
    80000bb6:	15c080e7          	jalr	348(ra) # 80000d0e <release>
  return free;
}
    80000bba:	8526                	mv	a0,s1
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
  uint64 free = 0;
    80000bc6:	4481                	li	s1,0
    80000bc8:	b7cd                	j	80000baa <kfreemem+0x2a>

0000000080000bca <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bca:	1141                	addi	sp,sp,-16
    80000bcc:	e422                	sd	s0,8(sp)
    80000bce:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bd0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bd2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bd6:	00053823          	sd	zero,16(a0)
}
    80000bda:	6422                	ld	s0,8(sp)
    80000bdc:	0141                	addi	sp,sp,16
    80000bde:	8082                	ret

0000000080000be0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	411c                	lw	a5,0(a0)
    80000be2:	e399                	bnez	a5,80000be8 <holding+0x8>
    80000be4:	4501                	li	a0,0
  return r;
}
    80000be6:	8082                	ret
{
    80000be8:	1101                	addi	sp,sp,-32
    80000bea:	ec06                	sd	ra,24(sp)
    80000bec:	e822                	sd	s0,16(sp)
    80000bee:	e426                	sd	s1,8(sp)
    80000bf0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bf2:	6904                	ld	s1,16(a0)
    80000bf4:	00001097          	auipc	ra,0x1
    80000bf8:	1dc080e7          	jalr	476(ra) # 80001dd0 <mycpu>
    80000bfc:	40a48533          	sub	a0,s1,a0
    80000c00:	00153513          	seqz	a0,a0
}
    80000c04:	60e2                	ld	ra,24(sp)
    80000c06:	6442                	ld	s0,16(sp)
    80000c08:	64a2                	ld	s1,8(sp)
    80000c0a:	6105                	addi	sp,sp,32
    80000c0c:	8082                	ret

0000000080000c0e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c0e:	1101                	addi	sp,sp,-32
    80000c10:	ec06                	sd	ra,24(sp)
    80000c12:	e822                	sd	s0,16(sp)
    80000c14:	e426                	sd	s1,8(sp)
    80000c16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c18:	100024f3          	csrr	s1,sstatus
    80000c1c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c22:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c26:	00001097          	auipc	ra,0x1
    80000c2a:	1aa080e7          	jalr	426(ra) # 80001dd0 <mycpu>
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	cf89                	beqz	a5,80000c4a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	19e080e7          	jalr	414(ra) # 80001dd0 <mycpu>
    80000c3a:	5d3c                	lw	a5,120(a0)
    80000c3c:	2785                	addiw	a5,a5,1
    80000c3e:	dd3c                	sw	a5,120(a0)
}
    80000c40:	60e2                	ld	ra,24(sp)
    80000c42:	6442                	ld	s0,16(sp)
    80000c44:	64a2                	ld	s1,8(sp)
    80000c46:	6105                	addi	sp,sp,32
    80000c48:	8082                	ret
    mycpu()->intena = old;
    80000c4a:	00001097          	auipc	ra,0x1
    80000c4e:	186080e7          	jalr	390(ra) # 80001dd0 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8085                	srli	s1,s1,0x1
    80000c54:	8885                	andi	s1,s1,1
    80000c56:	dd64                	sw	s1,124(a0)
    80000c58:	bfe9                	j	80000c32 <push_off+0x24>

0000000080000c5a <acquire>:
{
    80000c5a:	1101                	addi	sp,sp,-32
    80000c5c:	ec06                	sd	ra,24(sp)
    80000c5e:	e822                	sd	s0,16(sp)
    80000c60:	e426                	sd	s1,8(sp)
    80000c62:	1000                	addi	s0,sp,32
    80000c64:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c66:	00000097          	auipc	ra,0x0
    80000c6a:	fa8080e7          	jalr	-88(ra) # 80000c0e <push_off>
  if(holding(lk))
    80000c6e:	8526                	mv	a0,s1
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	f70080e7          	jalr	-144(ra) # 80000be0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c78:	4705                	li	a4,1
  if(holding(lk))
    80000c7a:	e115                	bnez	a0,80000c9e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c7c:	87ba                	mv	a5,a4
    80000c7e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c82:	2781                	sext.w	a5,a5
    80000c84:	ffe5                	bnez	a5,80000c7c <acquire+0x22>
  __sync_synchronize();
    80000c86:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c8a:	00001097          	auipc	ra,0x1
    80000c8e:	146080e7          	jalr	326(ra) # 80001dd0 <mycpu>
    80000c92:	e888                	sd	a0,16(s1)
}
    80000c94:	60e2                	ld	ra,24(sp)
    80000c96:	6442                	ld	s0,16(sp)
    80000c98:	64a2                	ld	s1,8(sp)
    80000c9a:	6105                	addi	sp,sp,32
    80000c9c:	8082                	ret
    panic("acquire");
    80000c9e:	00007517          	auipc	a0,0x7
    80000ca2:	3d250513          	addi	a0,a0,978 # 80008070 <digits+0x30>
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	8a2080e7          	jalr	-1886(ra) # 80000548 <panic>

0000000080000cae <pop_off>:

void
pop_off(void)
{
    80000cae:	1141                	addi	sp,sp,-16
    80000cb0:	e406                	sd	ra,8(sp)
    80000cb2:	e022                	sd	s0,0(sp)
    80000cb4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cb6:	00001097          	auipc	ra,0x1
    80000cba:	11a080e7          	jalr	282(ra) # 80001dd0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cbe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cc2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cc4:	e78d                	bnez	a5,80000cee <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cc6:	5d3c                	lw	a5,120(a0)
    80000cc8:	02f05b63          	blez	a5,80000cfe <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ccc:	37fd                	addiw	a5,a5,-1
    80000cce:	0007871b          	sext.w	a4,a5
    80000cd2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cd4:	eb09                	bnez	a4,80000ce6 <pop_off+0x38>
    80000cd6:	5d7c                	lw	a5,124(a0)
    80000cd8:	c799                	beqz	a5,80000ce6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cda:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cde:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ce2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ce6:	60a2                	ld	ra,8(sp)
    80000ce8:	6402                	ld	s0,0(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret
    panic("pop_off - interruptible");
    80000cee:	00007517          	auipc	a0,0x7
    80000cf2:	38a50513          	addi	a0,a0,906 # 80008078 <digits+0x38>
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	852080e7          	jalr	-1966(ra) # 80000548 <panic>
    panic("pop_off");
    80000cfe:	00007517          	auipc	a0,0x7
    80000d02:	39250513          	addi	a0,a0,914 # 80008090 <digits+0x50>
    80000d06:	00000097          	auipc	ra,0x0
    80000d0a:	842080e7          	jalr	-1982(ra) # 80000548 <panic>

0000000080000d0e <release>:
{
    80000d0e:	1101                	addi	sp,sp,-32
    80000d10:	ec06                	sd	ra,24(sp)
    80000d12:	e822                	sd	s0,16(sp)
    80000d14:	e426                	sd	s1,8(sp)
    80000d16:	1000                	addi	s0,sp,32
    80000d18:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d1a:	00000097          	auipc	ra,0x0
    80000d1e:	ec6080e7          	jalr	-314(ra) # 80000be0 <holding>
    80000d22:	c115                	beqz	a0,80000d46 <release+0x38>
  lk->cpu = 0;
    80000d24:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d28:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d2c:	0f50000f          	fence	iorw,ow
    80000d30:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d34:	00000097          	auipc	ra,0x0
    80000d38:	f7a080e7          	jalr	-134(ra) # 80000cae <pop_off>
}
    80000d3c:	60e2                	ld	ra,24(sp)
    80000d3e:	6442                	ld	s0,16(sp)
    80000d40:	64a2                	ld	s1,8(sp)
    80000d42:	6105                	addi	sp,sp,32
    80000d44:	8082                	ret
    panic("release");
    80000d46:	00007517          	auipc	a0,0x7
    80000d4a:	35250513          	addi	a0,a0,850 # 80008098 <digits+0x58>
    80000d4e:	fffff097          	auipc	ra,0xfffff
    80000d52:	7fa080e7          	jalr	2042(ra) # 80000548 <panic>

0000000080000d56 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d5c:	ce09                	beqz	a2,80000d76 <memset+0x20>
    80000d5e:	87aa                	mv	a5,a0
    80000d60:	fff6071b          	addiw	a4,a2,-1
    80000d64:	1702                	slli	a4,a4,0x20
    80000d66:	9301                	srli	a4,a4,0x20
    80000d68:	0705                	addi	a4,a4,1
    80000d6a:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d6c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d70:	0785                	addi	a5,a5,1
    80000d72:	fee79de3          	bne	a5,a4,80000d6c <memset+0x16>
  }
  return dst;
}
    80000d76:	6422                	ld	s0,8(sp)
    80000d78:	0141                	addi	sp,sp,16
    80000d7a:	8082                	ret

0000000080000d7c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d7c:	1141                	addi	sp,sp,-16
    80000d7e:	e422                	sd	s0,8(sp)
    80000d80:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d82:	ca05                	beqz	a2,80000db2 <memcmp+0x36>
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	1682                	slli	a3,a3,0x20
    80000d8a:	9281                	srli	a3,a3,0x20
    80000d8c:	0685                	addi	a3,a3,1
    80000d8e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d90:	00054783          	lbu	a5,0(a0)
    80000d94:	0005c703          	lbu	a4,0(a1)
    80000d98:	00e79863          	bne	a5,a4,80000da8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d9c:	0505                	addi	a0,a0,1
    80000d9e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000da0:	fed518e3          	bne	a0,a3,80000d90 <memcmp+0x14>
  }

  return 0;
    80000da4:	4501                	li	a0,0
    80000da6:	a019                	j	80000dac <memcmp+0x30>
      return *s1 - *s2;
    80000da8:	40e7853b          	subw	a0,a5,a4
}
    80000dac:	6422                	ld	s0,8(sp)
    80000dae:	0141                	addi	sp,sp,16
    80000db0:	8082                	ret
  return 0;
    80000db2:	4501                	li	a0,0
    80000db4:	bfe5                	j	80000dac <memcmp+0x30>

0000000080000db6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000db6:	1141                	addi	sp,sp,-16
    80000db8:	e422                	sd	s0,8(sp)
    80000dba:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dbc:	00a5f963          	bgeu	a1,a0,80000dce <memmove+0x18>
    80000dc0:	02061713          	slli	a4,a2,0x20
    80000dc4:	9301                	srli	a4,a4,0x20
    80000dc6:	00e587b3          	add	a5,a1,a4
    80000dca:	02f56563          	bltu	a0,a5,80000df4 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dce:	fff6069b          	addiw	a3,a2,-1
    80000dd2:	ce11                	beqz	a2,80000dee <memmove+0x38>
    80000dd4:	1682                	slli	a3,a3,0x20
    80000dd6:	9281                	srli	a3,a3,0x20
    80000dd8:	0685                	addi	a3,a3,1
    80000dda:	96ae                	add	a3,a3,a1
    80000ddc:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dde:	0585                	addi	a1,a1,1
    80000de0:	0785                	addi	a5,a5,1
    80000de2:	fff5c703          	lbu	a4,-1(a1)
    80000de6:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dea:	fed59ae3          	bne	a1,a3,80000dde <memmove+0x28>

  return dst;
}
    80000dee:	6422                	ld	s0,8(sp)
    80000df0:	0141                	addi	sp,sp,16
    80000df2:	8082                	ret
    d += n;
    80000df4:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000df6:	fff6069b          	addiw	a3,a2,-1
    80000dfa:	da75                	beqz	a2,80000dee <memmove+0x38>
    80000dfc:	02069613          	slli	a2,a3,0x20
    80000e00:	9201                	srli	a2,a2,0x20
    80000e02:	fff64613          	not	a2,a2
    80000e06:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e08:	17fd                	addi	a5,a5,-1
    80000e0a:	177d                	addi	a4,a4,-1
    80000e0c:	0007c683          	lbu	a3,0(a5)
    80000e10:	00d70023          	sb	a3,0(a4) # 1000 <_entry-0x7ffff000>
    while(n-- > 0)
    80000e14:	fec79ae3          	bne	a5,a2,80000e08 <memmove+0x52>
    80000e18:	bfd9                	j	80000dee <memmove+0x38>

0000000080000e1a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e1a:	1141                	addi	sp,sp,-16
    80000e1c:	e406                	sd	ra,8(sp)
    80000e1e:	e022                	sd	s0,0(sp)
    80000e20:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e22:	00000097          	auipc	ra,0x0
    80000e26:	f94080e7          	jalr	-108(ra) # 80000db6 <memmove>
}
    80000e2a:	60a2                	ld	ra,8(sp)
    80000e2c:	6402                	ld	s0,0(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e38:	ce11                	beqz	a2,80000e54 <strncmp+0x22>
    80000e3a:	00054783          	lbu	a5,0(a0)
    80000e3e:	cf89                	beqz	a5,80000e58 <strncmp+0x26>
    80000e40:	0005c703          	lbu	a4,0(a1)
    80000e44:	00f71a63          	bne	a4,a5,80000e58 <strncmp+0x26>
    n--, p++, q++;
    80000e48:	367d                	addiw	a2,a2,-1
    80000e4a:	0505                	addi	a0,a0,1
    80000e4c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e4e:	f675                	bnez	a2,80000e3a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e50:	4501                	li	a0,0
    80000e52:	a809                	j	80000e64 <strncmp+0x32>
    80000e54:	4501                	li	a0,0
    80000e56:	a039                	j	80000e64 <strncmp+0x32>
  if(n == 0)
    80000e58:	ca09                	beqz	a2,80000e6a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e5a:	00054503          	lbu	a0,0(a0)
    80000e5e:	0005c783          	lbu	a5,0(a1)
    80000e62:	9d1d                	subw	a0,a0,a5
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret
    return 0;
    80000e6a:	4501                	li	a0,0
    80000e6c:	bfe5                	j	80000e64 <strncmp+0x32>

0000000080000e6e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e6e:	1141                	addi	sp,sp,-16
    80000e70:	e422                	sd	s0,8(sp)
    80000e72:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e74:	872a                	mv	a4,a0
    80000e76:	8832                	mv	a6,a2
    80000e78:	367d                	addiw	a2,a2,-1
    80000e7a:	01005963          	blez	a6,80000e8c <strncpy+0x1e>
    80000e7e:	0705                	addi	a4,a4,1
    80000e80:	0005c783          	lbu	a5,0(a1)
    80000e84:	fef70fa3          	sb	a5,-1(a4)
    80000e88:	0585                	addi	a1,a1,1
    80000e8a:	f7f5                	bnez	a5,80000e76 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e8c:	00c05d63          	blez	a2,80000ea6 <strncpy+0x38>
    80000e90:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e92:	0685                	addi	a3,a3,1
    80000e94:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e98:	fff6c793          	not	a5,a3
    80000e9c:	9fb9                	addw	a5,a5,a4
    80000e9e:	010787bb          	addw	a5,a5,a6
    80000ea2:	fef048e3          	bgtz	a5,80000e92 <strncpy+0x24>
  return os;
}
    80000ea6:	6422                	ld	s0,8(sp)
    80000ea8:	0141                	addi	sp,sp,16
    80000eaa:	8082                	ret

0000000080000eac <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eac:	1141                	addi	sp,sp,-16
    80000eae:	e422                	sd	s0,8(sp)
    80000eb0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eb2:	02c05363          	blez	a2,80000ed8 <safestrcpy+0x2c>
    80000eb6:	fff6069b          	addiw	a3,a2,-1
    80000eba:	1682                	slli	a3,a3,0x20
    80000ebc:	9281                	srli	a3,a3,0x20
    80000ebe:	96ae                	add	a3,a3,a1
    80000ec0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ec2:	00d58963          	beq	a1,a3,80000ed4 <safestrcpy+0x28>
    80000ec6:	0585                	addi	a1,a1,1
    80000ec8:	0785                	addi	a5,a5,1
    80000eca:	fff5c703          	lbu	a4,-1(a1)
    80000ece:	fee78fa3          	sb	a4,-1(a5)
    80000ed2:	fb65                	bnez	a4,80000ec2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ed4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret

0000000080000ede <strlen>:

int
strlen(const char *s)
{
    80000ede:	1141                	addi	sp,sp,-16
    80000ee0:	e422                	sd	s0,8(sp)
    80000ee2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ee4:	00054783          	lbu	a5,0(a0)
    80000ee8:	cf91                	beqz	a5,80000f04 <strlen+0x26>
    80000eea:	0505                	addi	a0,a0,1
    80000eec:	87aa                	mv	a5,a0
    80000eee:	4685                	li	a3,1
    80000ef0:	9e89                	subw	a3,a3,a0
    80000ef2:	00f6853b          	addw	a0,a3,a5
    80000ef6:	0785                	addi	a5,a5,1
    80000ef8:	fff7c703          	lbu	a4,-1(a5)
    80000efc:	fb7d                	bnez	a4,80000ef2 <strlen+0x14>
    ;
  return n;
}
    80000efe:	6422                	ld	s0,8(sp)
    80000f00:	0141                	addi	sp,sp,16
    80000f02:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f04:	4501                	li	a0,0
    80000f06:	bfe5                	j	80000efe <strlen+0x20>

0000000080000f08 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f08:	1141                	addi	sp,sp,-16
    80000f0a:	e406                	sd	ra,8(sp)
    80000f0c:	e022                	sd	s0,0(sp)
    80000f0e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f10:	00001097          	auipc	ra,0x1
    80000f14:	eb0080e7          	jalr	-336(ra) # 80001dc0 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f18:	00008717          	auipc	a4,0x8
    80000f1c:	0f470713          	addi	a4,a4,244 # 8000900c <started>
  if(cpuid() == 0){
    80000f20:	c139                	beqz	a0,80000f66 <main+0x5e>
    while(started == 0)
    80000f22:	431c                	lw	a5,0(a4)
    80000f24:	2781                	sext.w	a5,a5
    80000f26:	dff5                	beqz	a5,80000f22 <main+0x1a>
      ;
    __sync_synchronize();
    80000f28:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f2c:	00001097          	auipc	ra,0x1
    80000f30:	e94080e7          	jalr	-364(ra) # 80001dc0 <cpuid>
    80000f34:	85aa                	mv	a1,a0
    80000f36:	00007517          	auipc	a0,0x7
    80000f3a:	18250513          	addi	a0,a0,386 # 800080b8 <digits+0x78>
    80000f3e:	fffff097          	auipc	ra,0xfffff
    80000f42:	654080e7          	jalr	1620(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	0fc080e7          	jalr	252(ra) # 80001042 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f4e:	00002097          	auipc	ra,0x2
    80000f52:	cd8080e7          	jalr	-808(ra) # 80002c26 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	38a080e7          	jalr	906(ra) # 800062e0 <plicinithart>
  }

  scheduler();        
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	536080e7          	jalr	1334(ra) # 80002494 <scheduler>
    consoleinit();
    80000f66:	fffff097          	auipc	ra,0xfffff
    80000f6a:	4f4080e7          	jalr	1268(ra) # 8000045a <consoleinit>
    statsinit();
    80000f6e:	00006097          	auipc	ra,0x6
    80000f72:	b34080e7          	jalr	-1228(ra) # 80006aa2 <statsinit>
    printfinit();
    80000f76:	00000097          	auipc	ra,0x0
    80000f7a:	802080e7          	jalr	-2046(ra) # 80000778 <printfinit>
    printf("\n");
    80000f7e:	00007517          	auipc	a0,0x7
    80000f82:	14a50513          	addi	a0,a0,330 # 800080c8 <digits+0x88>
    80000f86:	fffff097          	auipc	ra,0xfffff
    80000f8a:	60c080e7          	jalr	1548(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f8e:	00007517          	auipc	a0,0x7
    80000f92:	11250513          	addi	a0,a0,274 # 800080a0 <digits+0x60>
    80000f96:	fffff097          	auipc	ra,0xfffff
    80000f9a:	5fc080e7          	jalr	1532(ra) # 80000592 <printf>
    printf("\n");
    80000f9e:	00007517          	auipc	a0,0x7
    80000fa2:	12a50513          	addi	a0,a0,298 # 800080c8 <digits+0x88>
    80000fa6:	fffff097          	auipc	ra,0xfffff
    80000faa:	5ec080e7          	jalr	1516(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000fae:	00000097          	auipc	ra,0x0
    80000fb2:	b36080e7          	jalr	-1226(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000fb6:	00000097          	auipc	ra,0x0
    80000fba:	334080e7          	jalr	820(ra) # 800012ea <kvminit>
    kvminithart();   // turn on paging
    80000fbe:	00000097          	auipc	ra,0x0
    80000fc2:	084080e7          	jalr	132(ra) # 80001042 <kvminithart>
    procinit();      // process table
    80000fc6:	00001097          	auipc	ra,0x1
    80000fca:	d2a080e7          	jalr	-726(ra) # 80001cf0 <procinit>
    trapinit();      // trap vectors
    80000fce:	00002097          	auipc	ra,0x2
    80000fd2:	c30080e7          	jalr	-976(ra) # 80002bfe <trapinit>
    trapinithart();  // install kernel trap vector
    80000fd6:	00002097          	auipc	ra,0x2
    80000fda:	c50080e7          	jalr	-944(ra) # 80002c26 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	2ec080e7          	jalr	748(ra) # 800062ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fe6:	00005097          	auipc	ra,0x5
    80000fea:	2fa080e7          	jalr	762(ra) # 800062e0 <plicinithart>
    binit();         // buffer cache
    80000fee:	00002097          	auipc	ra,0x2
    80000ff2:	456080e7          	jalr	1110(ra) # 80003444 <binit>
    iinit();         // inode cache
    80000ff6:	00003097          	auipc	ra,0x3
    80000ffa:	ae6080e7          	jalr	-1306(ra) # 80003adc <iinit>
    fileinit();      // file table
    80000ffe:	00004097          	auipc	ra,0x4
    80001002:	a80080e7          	jalr	-1408(ra) # 80004a7e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001006:	00005097          	auipc	ra,0x5
    8000100a:	3e2080e7          	jalr	994(ra) # 800063e8 <virtio_disk_init>
    userinit();      // first user process
    8000100e:	00001097          	auipc	ra,0x1
    80001012:	150080e7          	jalr	336(ra) # 8000215e <userinit>
    __sync_synchronize();
    80001016:	0ff0000f          	fence
    started = 1;
    8000101a:	4785                	li	a5,1
    8000101c:	00008717          	auipc	a4,0x8
    80001020:	fef72823          	sw	a5,-16(a4) # 8000900c <started>
    80001024:	bf2d                	j	80000f5e <main+0x56>

0000000080001026 <ukvminithard>:
  // the highest virtual address in the kernel.
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
}

// refresh the TLB to refer the page as virtual memory mapping table
void ukvminithard(pagetable_t page) {
    80001026:	1141                	addi	sp,sp,-16
    80001028:	e422                	sd	s0,8(sp)
    8000102a:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(page));
    8000102c:	8131                	srli	a0,a0,0xc
    8000102e:	57fd                	li	a5,-1
    80001030:	17fe                	slli	a5,a5,0x3f
    80001032:	8d5d                	or	a0,a0,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    80001034:	18051073          	csrw	satp,a0
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001038:	12000073          	sfence.vma
  sfence_vma();
}
    8000103c:	6422                	ld	s0,8(sp)
    8000103e:	0141                	addi	sp,sp,16
    80001040:	8082                	ret

0000000080001042 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001042:	1141                	addi	sp,sp,-16
    80001044:	e422                	sd	s0,8(sp)
    80001046:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001048:	00008797          	auipc	a5,0x8
    8000104c:	fc87b783          	ld	a5,-56(a5) # 80009010 <kernel_pagetable>
    80001050:	83b1                	srli	a5,a5,0xc
    80001052:	577d                	li	a4,-1
    80001054:	177e                	slli	a4,a4,0x3f
    80001056:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001058:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000105c:	12000073          	sfence.vma
  sfence_vma();
}
    80001060:	6422                	ld	s0,8(sp)
    80001062:	0141                	addi	sp,sp,16
    80001064:	8082                	ret

0000000080001066 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001066:	7139                	addi	sp,sp,-64
    80001068:	fc06                	sd	ra,56(sp)
    8000106a:	f822                	sd	s0,48(sp)
    8000106c:	f426                	sd	s1,40(sp)
    8000106e:	f04a                	sd	s2,32(sp)
    80001070:	ec4e                	sd	s3,24(sp)
    80001072:	e852                	sd	s4,16(sp)
    80001074:	e456                	sd	s5,8(sp)
    80001076:	e05a                	sd	s6,0(sp)
    80001078:	0080                	addi	s0,sp,64
    8000107a:	84aa                	mv	s1,a0
    8000107c:	89ae                	mv	s3,a1
    8000107e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001080:	57fd                	li	a5,-1
    80001082:	83e9                	srli	a5,a5,0x1a
    80001084:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001086:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001088:	04b7f263          	bgeu	a5,a1,800010cc <walk+0x66>
    panic("walk");
    8000108c:	00007517          	auipc	a0,0x7
    80001090:	04450513          	addi	a0,a0,68 # 800080d0 <digits+0x90>
    80001094:	fffff097          	auipc	ra,0xfffff
    80001098:	4b4080e7          	jalr	1204(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000109c:	060a8663          	beqz	s5,80001108 <walk+0xa2>
    800010a0:	00000097          	auipc	ra,0x0
    800010a4:	a80080e7          	jalr	-1408(ra) # 80000b20 <kalloc>
    800010a8:	84aa                	mv	s1,a0
    800010aa:	c529                	beqz	a0,800010f4 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010ac:	6605                	lui	a2,0x1
    800010ae:	4581                	li	a1,0
    800010b0:	00000097          	auipc	ra,0x0
    800010b4:	ca6080e7          	jalr	-858(ra) # 80000d56 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010b8:	00c4d793          	srli	a5,s1,0xc
    800010bc:	07aa                	slli	a5,a5,0xa
    800010be:	0017e793          	ori	a5,a5,1
    800010c2:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010c6:	3a5d                	addiw	s4,s4,-9
    800010c8:	036a0063          	beq	s4,s6,800010e8 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010cc:	0149d933          	srl	s2,s3,s4
    800010d0:	1ff97913          	andi	s2,s2,511
    800010d4:	090e                	slli	s2,s2,0x3
    800010d6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010d8:	00093483          	ld	s1,0(s2)
    800010dc:	0014f793          	andi	a5,s1,1
    800010e0:	dfd5                	beqz	a5,8000109c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010e2:	80a9                	srli	s1,s1,0xa
    800010e4:	04b2                	slli	s1,s1,0xc
    800010e6:	b7c5                	j	800010c6 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010e8:	00c9d513          	srli	a0,s3,0xc
    800010ec:	1ff57513          	andi	a0,a0,511
    800010f0:	050e                	slli	a0,a0,0x3
    800010f2:	9526                	add	a0,a0,s1
}
    800010f4:	70e2                	ld	ra,56(sp)
    800010f6:	7442                	ld	s0,48(sp)
    800010f8:	74a2                	ld	s1,40(sp)
    800010fa:	7902                	ld	s2,32(sp)
    800010fc:	69e2                	ld	s3,24(sp)
    800010fe:	6a42                	ld	s4,16(sp)
    80001100:	6aa2                	ld	s5,8(sp)
    80001102:	6b02                	ld	s6,0(sp)
    80001104:	6121                	addi	sp,sp,64
    80001106:	8082                	ret
        return 0;
    80001108:	4501                	li	a0,0
    8000110a:	b7ed                	j	800010f4 <walk+0x8e>

000000008000110c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000110c:	57fd                	li	a5,-1
    8000110e:	83e9                	srli	a5,a5,0x1a
    80001110:	00b7f463          	bgeu	a5,a1,80001118 <walkaddr+0xc>
    return 0;
    80001114:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001116:	8082                	ret
{
    80001118:	1141                	addi	sp,sp,-16
    8000111a:	e406                	sd	ra,8(sp)
    8000111c:	e022                	sd	s0,0(sp)
    8000111e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001120:	4601                	li	a2,0
    80001122:	00000097          	auipc	ra,0x0
    80001126:	f44080e7          	jalr	-188(ra) # 80001066 <walk>
  if(pte == 0)
    8000112a:	c105                	beqz	a0,8000114a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000112c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000112e:	0117f693          	andi	a3,a5,17
    80001132:	4745                	li	a4,17
    return 0;
    80001134:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001136:	00e68663          	beq	a3,a4,80001142 <walkaddr+0x36>
}
    8000113a:	60a2                	ld	ra,8(sp)
    8000113c:	6402                	ld	s0,0(sp)
    8000113e:	0141                	addi	sp,sp,16
    80001140:	8082                	ret
  pa = PTE2PA(*pte);
    80001142:	00a7d513          	srli	a0,a5,0xa
    80001146:	0532                	slli	a0,a0,0xc
  return pa;
    80001148:	bfcd                	j	8000113a <walkaddr+0x2e>
    return 0;
    8000114a:	4501                	li	a0,0
    8000114c:	b7fd                	j	8000113a <walkaddr+0x2e>

000000008000114e <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000114e:	1101                	addi	sp,sp,-32
    80001150:	ec06                	sd	ra,24(sp)
    80001152:	e822                	sd	s0,16(sp)
    80001154:	e426                	sd	s1,8(sp)
    80001156:	1000                	addi	s0,sp,32
    80001158:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    8000115a:	1552                	slli	a0,a0,0x34
    8000115c:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001160:	4601                	li	a2,0
    80001162:	00008517          	auipc	a0,0x8
    80001166:	eae53503          	ld	a0,-338(a0) # 80009010 <kernel_pagetable>
    8000116a:	00000097          	auipc	ra,0x0
    8000116e:	efc080e7          	jalr	-260(ra) # 80001066 <walk>
  if(pte == 0)
    80001172:	cd09                	beqz	a0,8000118c <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001174:	6108                	ld	a0,0(a0)
    80001176:	00157793          	andi	a5,a0,1
    8000117a:	c38d                	beqz	a5,8000119c <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000117c:	8129                	srli	a0,a0,0xa
    8000117e:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001180:	9526                	add	a0,a0,s1
    80001182:	60e2                	ld	ra,24(sp)
    80001184:	6442                	ld	s0,16(sp)
    80001186:	64a2                	ld	s1,8(sp)
    80001188:	6105                	addi	sp,sp,32
    8000118a:	8082                	ret
    panic("kvmpa");
    8000118c:	00007517          	auipc	a0,0x7
    80001190:	f4c50513          	addi	a0,a0,-180 # 800080d8 <digits+0x98>
    80001194:	fffff097          	auipc	ra,0xfffff
    80001198:	3b4080e7          	jalr	948(ra) # 80000548 <panic>
    panic("kvmpa");
    8000119c:	00007517          	auipc	a0,0x7
    800011a0:	f3c50513          	addi	a0,a0,-196 # 800080d8 <digits+0x98>
    800011a4:	fffff097          	auipc	ra,0xfffff
    800011a8:	3a4080e7          	jalr	932(ra) # 80000548 <panic>

00000000800011ac <umappages>:

// Same as mappages without panic on remapping
int umappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm) {
    800011ac:	715d                	addi	sp,sp,-80
    800011ae:	e486                	sd	ra,72(sp)
    800011b0:	e0a2                	sd	s0,64(sp)
    800011b2:	fc26                	sd	s1,56(sp)
    800011b4:	f84a                	sd	s2,48(sp)
    800011b6:	f44e                	sd	s3,40(sp)
    800011b8:	f052                	sd	s4,32(sp)
    800011ba:	ec56                	sd	s5,24(sp)
    800011bc:	e85a                	sd	s6,16(sp)
    800011be:	e45e                	sd	s7,8(sp)
    800011c0:	0880                	addi	s0,sp,80
    800011c2:	8aaa                	mv	s5,a0
    800011c4:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011c6:	777d                	lui	a4,0xfffff
    800011c8:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011cc:	167d                	addi	a2,a2,-1
    800011ce:	00b609b3          	add	s3,a2,a1
    800011d2:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011d6:	893e                	mv	s2,a5
    800011d8:	40f68a33          	sub	s4,a3,a5
    if((pte = walk(pagetable, a, 1)) == 0)
      return -1;
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011dc:	6b85                	lui	s7,0x1
    800011de:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e2:	4605                	li	a2,1
    800011e4:	85ca                	mv	a1,s2
    800011e6:	8556                	mv	a0,s5
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	e7e080e7          	jalr	-386(ra) # 80001066 <walk>
    800011f0:	cd01                	beqz	a0,80001208 <umappages+0x5c>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011f2:	80b1                	srli	s1,s1,0xc
    800011f4:	04aa                	slli	s1,s1,0xa
    800011f6:	0164e4b3          	or	s1,s1,s6
    800011fa:	0014e493          	ori	s1,s1,1
    800011fe:	e104                	sd	s1,0(a0)
    if(a == last)
    80001200:	03390063          	beq	s2,s3,80001220 <umappages+0x74>
    a += PGSIZE;
    80001204:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001206:	bfe1                	j	800011de <umappages+0x32>
      return -1;
    80001208:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000120a:	60a6                	ld	ra,72(sp)
    8000120c:	6406                	ld	s0,64(sp)
    8000120e:	74e2                	ld	s1,56(sp)
    80001210:	7942                	ld	s2,48(sp)
    80001212:	79a2                	ld	s3,40(sp)
    80001214:	7a02                	ld	s4,32(sp)
    80001216:	6ae2                	ld	s5,24(sp)
    80001218:	6b42                	ld	s6,16(sp)
    8000121a:	6ba2                	ld	s7,8(sp)
    8000121c:	6161                	addi	sp,sp,80
    8000121e:	8082                	ret
  return 0;
    80001220:	4501                	li	a0,0
    80001222:	b7e5                	j	8000120a <umappages+0x5e>

0000000080001224 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001224:	715d                	addi	sp,sp,-80
    80001226:	e486                	sd	ra,72(sp)
    80001228:	e0a2                	sd	s0,64(sp)
    8000122a:	fc26                	sd	s1,56(sp)
    8000122c:	f84a                	sd	s2,48(sp)
    8000122e:	f44e                	sd	s3,40(sp)
    80001230:	f052                	sd	s4,32(sp)
    80001232:	ec56                	sd	s5,24(sp)
    80001234:	e85a                	sd	s6,16(sp)
    80001236:	e45e                	sd	s7,8(sp)
    80001238:	0880                	addi	s0,sp,80
    8000123a:	8aaa                	mv	s5,a0
    8000123c:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000123e:	777d                	lui	a4,0xfffff
    80001240:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001244:	167d                	addi	a2,a2,-1
    80001246:	00b609b3          	add	s3,a2,a1
    8000124a:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000124e:	893e                	mv	s2,a5
    80001250:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001254:	6b85                	lui	s7,0x1
    80001256:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000125a:	4605                	li	a2,1
    8000125c:	85ca                	mv	a1,s2
    8000125e:	8556                	mv	a0,s5
    80001260:	00000097          	auipc	ra,0x0
    80001264:	e06080e7          	jalr	-506(ra) # 80001066 <walk>
    80001268:	c51d                	beqz	a0,80001296 <mappages+0x72>
    if(*pte & PTE_V)
    8000126a:	611c                	ld	a5,0(a0)
    8000126c:	8b85                	andi	a5,a5,1
    8000126e:	ef81                	bnez	a5,80001286 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001270:	80b1                	srli	s1,s1,0xc
    80001272:	04aa                	slli	s1,s1,0xa
    80001274:	0164e4b3          	or	s1,s1,s6
    80001278:	0014e493          	ori	s1,s1,1
    8000127c:	e104                	sd	s1,0(a0)
    if(a == last)
    8000127e:	03390863          	beq	s2,s3,800012ae <mappages+0x8a>
    a += PGSIZE;
    80001282:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001284:	bfc9                	j	80001256 <mappages+0x32>
      panic("remap");
    80001286:	00007517          	auipc	a0,0x7
    8000128a:	e5a50513          	addi	a0,a0,-422 # 800080e0 <digits+0xa0>
    8000128e:	fffff097          	auipc	ra,0xfffff
    80001292:	2ba080e7          	jalr	698(ra) # 80000548 <panic>
      return -1;
    80001296:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001298:	60a6                	ld	ra,72(sp)
    8000129a:	6406                	ld	s0,64(sp)
    8000129c:	74e2                	ld	s1,56(sp)
    8000129e:	7942                	ld	s2,48(sp)
    800012a0:	79a2                	ld	s3,40(sp)
    800012a2:	7a02                	ld	s4,32(sp)
    800012a4:	6ae2                	ld	s5,24(sp)
    800012a6:	6b42                	ld	s6,16(sp)
    800012a8:	6ba2                	ld	s7,8(sp)
    800012aa:	6161                	addi	sp,sp,80
    800012ac:	8082                	ret
  return 0;
    800012ae:	4501                	li	a0,0
    800012b0:	b7e5                	j	80001298 <mappages+0x74>

00000000800012b2 <kvmmap>:
{
    800012b2:	1141                	addi	sp,sp,-16
    800012b4:	e406                	sd	ra,8(sp)
    800012b6:	e022                	sd	s0,0(sp)
    800012b8:	0800                	addi	s0,sp,16
    800012ba:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800012bc:	86ae                	mv	a3,a1
    800012be:	85aa                	mv	a1,a0
    800012c0:	00008517          	auipc	a0,0x8
    800012c4:	d5053503          	ld	a0,-688(a0) # 80009010 <kernel_pagetable>
    800012c8:	00000097          	auipc	ra,0x0
    800012cc:	f5c080e7          	jalr	-164(ra) # 80001224 <mappages>
    800012d0:	e509                	bnez	a0,800012da <kvmmap+0x28>
}
    800012d2:	60a2                	ld	ra,8(sp)
    800012d4:	6402                	ld	s0,0(sp)
    800012d6:	0141                	addi	sp,sp,16
    800012d8:	8082                	ret
    panic("kvmmap");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e0e50513          	addi	a0,a0,-498 # 800080e8 <digits+0xa8>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	266080e7          	jalr	614(ra) # 80000548 <panic>

00000000800012ea <kvminit>:
{
    800012ea:	1101                	addi	sp,sp,-32
    800012ec:	ec06                	sd	ra,24(sp)
    800012ee:	e822                	sd	s0,16(sp)
    800012f0:	e426                	sd	s1,8(sp)
    800012f2:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800012f4:	00000097          	auipc	ra,0x0
    800012f8:	82c080e7          	jalr	-2004(ra) # 80000b20 <kalloc>
    800012fc:	00008797          	auipc	a5,0x8
    80001300:	d0a7ba23          	sd	a0,-748(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001304:	6605                	lui	a2,0x1
    80001306:	4581                	li	a1,0
    80001308:	00000097          	auipc	ra,0x0
    8000130c:	a4e080e7          	jalr	-1458(ra) # 80000d56 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001310:	4699                	li	a3,6
    80001312:	6605                	lui	a2,0x1
    80001314:	100005b7          	lui	a1,0x10000
    80001318:	10000537          	lui	a0,0x10000
    8000131c:	00000097          	auipc	ra,0x0
    80001320:	f96080e7          	jalr	-106(ra) # 800012b2 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001324:	4699                	li	a3,6
    80001326:	6605                	lui	a2,0x1
    80001328:	100015b7          	lui	a1,0x10001
    8000132c:	10001537          	lui	a0,0x10001
    80001330:	00000097          	auipc	ra,0x0
    80001334:	f82080e7          	jalr	-126(ra) # 800012b2 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001338:	4699                	li	a3,6
    8000133a:	6641                	lui	a2,0x10
    8000133c:	020005b7          	lui	a1,0x2000
    80001340:	02000537          	lui	a0,0x2000
    80001344:	00000097          	auipc	ra,0x0
    80001348:	f6e080e7          	jalr	-146(ra) # 800012b2 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000134c:	4699                	li	a3,6
    8000134e:	00400637          	lui	a2,0x400
    80001352:	0c0005b7          	lui	a1,0xc000
    80001356:	0c000537          	lui	a0,0xc000
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	f58080e7          	jalr	-168(ra) # 800012b2 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001362:	00007497          	auipc	s1,0x7
    80001366:	c9e48493          	addi	s1,s1,-866 # 80008000 <etext>
    8000136a:	46a9                	li	a3,10
    8000136c:	80007617          	auipc	a2,0x80007
    80001370:	c9460613          	addi	a2,a2,-876 # 8000 <_entry-0x7fff8000>
    80001374:	4585                	li	a1,1
    80001376:	05fe                	slli	a1,a1,0x1f
    80001378:	852e                	mv	a0,a1
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	f38080e7          	jalr	-200(ra) # 800012b2 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001382:	4699                	li	a3,6
    80001384:	4645                	li	a2,17
    80001386:	066e                	slli	a2,a2,0x1b
    80001388:	8e05                	sub	a2,a2,s1
    8000138a:	85a6                	mv	a1,s1
    8000138c:	8526                	mv	a0,s1
    8000138e:	00000097          	auipc	ra,0x0
    80001392:	f24080e7          	jalr	-220(ra) # 800012b2 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001396:	46a9                	li	a3,10
    80001398:	6605                	lui	a2,0x1
    8000139a:	00006597          	auipc	a1,0x6
    8000139e:	c6658593          	addi	a1,a1,-922 # 80007000 <_trampoline>
    800013a2:	04000537          	lui	a0,0x4000
    800013a6:	157d                	addi	a0,a0,-1
    800013a8:	0532                	slli	a0,a0,0xc
    800013aa:	00000097          	auipc	ra,0x0
    800013ae:	f08080e7          	jalr	-248(ra) # 800012b2 <kvmmap>
}
    800013b2:	60e2                	ld	ra,24(sp)
    800013b4:	6442                	ld	s0,16(sp)
    800013b6:	64a2                	ld	s1,8(sp)
    800013b8:	6105                	addi	sp,sp,32
    800013ba:	8082                	ret

00000000800013bc <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013bc:	715d                	addi	sp,sp,-80
    800013be:	e486                	sd	ra,72(sp)
    800013c0:	e0a2                	sd	s0,64(sp)
    800013c2:	fc26                	sd	s1,56(sp)
    800013c4:	f84a                	sd	s2,48(sp)
    800013c6:	f44e                	sd	s3,40(sp)
    800013c8:	f052                	sd	s4,32(sp)
    800013ca:	ec56                	sd	s5,24(sp)
    800013cc:	e85a                	sd	s6,16(sp)
    800013ce:	e45e                	sd	s7,8(sp)
    800013d0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013d2:	03459793          	slli	a5,a1,0x34
    800013d6:	e795                	bnez	a5,80001402 <uvmunmap+0x46>
    800013d8:	8a2a                	mv	s4,a0
    800013da:	892e                	mv	s2,a1
    800013dc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013de:	0632                	slli	a2,a2,0xc
    800013e0:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013e4:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013e6:	6b05                	lui	s6,0x1
    800013e8:	0735e863          	bltu	a1,s3,80001458 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013ec:	60a6                	ld	ra,72(sp)
    800013ee:	6406                	ld	s0,64(sp)
    800013f0:	74e2                	ld	s1,56(sp)
    800013f2:	7942                	ld	s2,48(sp)
    800013f4:	79a2                	ld	s3,40(sp)
    800013f6:	7a02                	ld	s4,32(sp)
    800013f8:	6ae2                	ld	s5,24(sp)
    800013fa:	6b42                	ld	s6,16(sp)
    800013fc:	6ba2                	ld	s7,8(sp)
    800013fe:	6161                	addi	sp,sp,80
    80001400:	8082                	ret
    panic("uvmunmap: not aligned");
    80001402:	00007517          	auipc	a0,0x7
    80001406:	cee50513          	addi	a0,a0,-786 # 800080f0 <digits+0xb0>
    8000140a:	fffff097          	auipc	ra,0xfffff
    8000140e:	13e080e7          	jalr	318(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001412:	00007517          	auipc	a0,0x7
    80001416:	cf650513          	addi	a0,a0,-778 # 80008108 <digits+0xc8>
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	12e080e7          	jalr	302(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001422:	00007517          	auipc	a0,0x7
    80001426:	cf650513          	addi	a0,a0,-778 # 80008118 <digits+0xd8>
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	11e080e7          	jalr	286(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001432:	00007517          	auipc	a0,0x7
    80001436:	cfe50513          	addi	a0,a0,-770 # 80008130 <digits+0xf0>
    8000143a:	fffff097          	auipc	ra,0xfffff
    8000143e:	10e080e7          	jalr	270(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    80001442:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001444:	0532                	slli	a0,a0,0xc
    80001446:	fffff097          	auipc	ra,0xfffff
    8000144a:	5de080e7          	jalr	1502(ra) # 80000a24 <kfree>
    *pte = 0;
    8000144e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001452:	995a                	add	s2,s2,s6
    80001454:	f9397ce3          	bgeu	s2,s3,800013ec <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001458:	4601                	li	a2,0
    8000145a:	85ca                	mv	a1,s2
    8000145c:	8552                	mv	a0,s4
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	c08080e7          	jalr	-1016(ra) # 80001066 <walk>
    80001466:	84aa                	mv	s1,a0
    80001468:	d54d                	beqz	a0,80001412 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000146a:	6108                	ld	a0,0(a0)
    8000146c:	00157793          	andi	a5,a0,1
    80001470:	dbcd                	beqz	a5,80001422 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001472:	3ff57793          	andi	a5,a0,1023
    80001476:	fb778ee3          	beq	a5,s7,80001432 <uvmunmap+0x76>
    if(do_free){
    8000147a:	fc0a8ae3          	beqz	s5,8000144e <uvmunmap+0x92>
    8000147e:	b7d1                	j	80001442 <uvmunmap+0x86>

0000000080001480 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001480:	1101                	addi	sp,sp,-32
    80001482:	ec06                	sd	ra,24(sp)
    80001484:	e822                	sd	s0,16(sp)
    80001486:	e426                	sd	s1,8(sp)
    80001488:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000148a:	fffff097          	auipc	ra,0xfffff
    8000148e:	696080e7          	jalr	1686(ra) # 80000b20 <kalloc>
    80001492:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001494:	c519                	beqz	a0,800014a2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001496:	6605                	lui	a2,0x1
    80001498:	4581                	li	a1,0
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	8bc080e7          	jalr	-1860(ra) # 80000d56 <memset>
  return pagetable;
}
    800014a2:	8526                	mv	a0,s1
    800014a4:	60e2                	ld	ra,24(sp)
    800014a6:	6442                	ld	s0,16(sp)
    800014a8:	64a2                	ld	s1,8(sp)
    800014aa:	6105                	addi	sp,sp,32
    800014ac:	8082                	ret

00000000800014ae <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800014ae:	7179                	addi	sp,sp,-48
    800014b0:	f406                	sd	ra,40(sp)
    800014b2:	f022                	sd	s0,32(sp)
    800014b4:	ec26                	sd	s1,24(sp)
    800014b6:	e84a                	sd	s2,16(sp)
    800014b8:	e44e                	sd	s3,8(sp)
    800014ba:	e052                	sd	s4,0(sp)
    800014bc:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014be:	6785                	lui	a5,0x1
    800014c0:	04f67863          	bgeu	a2,a5,80001510 <uvminit+0x62>
    800014c4:	8a2a                	mv	s4,a0
    800014c6:	89ae                	mv	s3,a1
    800014c8:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014ca:	fffff097          	auipc	ra,0xfffff
    800014ce:	656080e7          	jalr	1622(ra) # 80000b20 <kalloc>
    800014d2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014d4:	6605                	lui	a2,0x1
    800014d6:	4581                	li	a1,0
    800014d8:	00000097          	auipc	ra,0x0
    800014dc:	87e080e7          	jalr	-1922(ra) # 80000d56 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014e0:	4779                	li	a4,30
    800014e2:	86ca                	mv	a3,s2
    800014e4:	6605                	lui	a2,0x1
    800014e6:	4581                	li	a1,0
    800014e8:	8552                	mv	a0,s4
    800014ea:	00000097          	auipc	ra,0x0
    800014ee:	d3a080e7          	jalr	-710(ra) # 80001224 <mappages>
  memmove(mem, src, sz);
    800014f2:	8626                	mv	a2,s1
    800014f4:	85ce                	mv	a1,s3
    800014f6:	854a                	mv	a0,s2
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	8be080e7          	jalr	-1858(ra) # 80000db6 <memmove>
}
    80001500:	70a2                	ld	ra,40(sp)
    80001502:	7402                	ld	s0,32(sp)
    80001504:	64e2                	ld	s1,24(sp)
    80001506:	6942                	ld	s2,16(sp)
    80001508:	69a2                	ld	s3,8(sp)
    8000150a:	6a02                	ld	s4,0(sp)
    8000150c:	6145                	addi	sp,sp,48
    8000150e:	8082                	ret
    panic("inituvm: more than a page");
    80001510:	00007517          	auipc	a0,0x7
    80001514:	c3850513          	addi	a0,a0,-968 # 80008148 <digits+0x108>
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	030080e7          	jalr	48(ra) # 80000548 <panic>

0000000080001520 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001520:	1101                	addi	sp,sp,-32
    80001522:	ec06                	sd	ra,24(sp)
    80001524:	e822                	sd	s0,16(sp)
    80001526:	e426                	sd	s1,8(sp)
    80001528:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000152a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000152c:	00b67d63          	bgeu	a2,a1,80001546 <uvmdealloc+0x26>
    80001530:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001532:	6785                	lui	a5,0x1
    80001534:	17fd                	addi	a5,a5,-1
    80001536:	00f60733          	add	a4,a2,a5
    8000153a:	767d                	lui	a2,0xfffff
    8000153c:	8f71                	and	a4,a4,a2
    8000153e:	97ae                	add	a5,a5,a1
    80001540:	8ff1                	and	a5,a5,a2
    80001542:	00f76863          	bltu	a4,a5,80001552 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001546:	8526                	mv	a0,s1
    80001548:	60e2                	ld	ra,24(sp)
    8000154a:	6442                	ld	s0,16(sp)
    8000154c:	64a2                	ld	s1,8(sp)
    8000154e:	6105                	addi	sp,sp,32
    80001550:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001552:	8f99                	sub	a5,a5,a4
    80001554:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001556:	4685                	li	a3,1
    80001558:	0007861b          	sext.w	a2,a5
    8000155c:	85ba                	mv	a1,a4
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	e5e080e7          	jalr	-418(ra) # 800013bc <uvmunmap>
    80001566:	b7c5                	j	80001546 <uvmdealloc+0x26>

0000000080001568 <uvmalloc>:
  if(newsz < oldsz)
    80001568:	0ab66163          	bltu	a2,a1,8000160a <uvmalloc+0xa2>
{
    8000156c:	7139                	addi	sp,sp,-64
    8000156e:	fc06                	sd	ra,56(sp)
    80001570:	f822                	sd	s0,48(sp)
    80001572:	f426                	sd	s1,40(sp)
    80001574:	f04a                	sd	s2,32(sp)
    80001576:	ec4e                	sd	s3,24(sp)
    80001578:	e852                	sd	s4,16(sp)
    8000157a:	e456                	sd	s5,8(sp)
    8000157c:	0080                	addi	s0,sp,64
    8000157e:	8aaa                	mv	s5,a0
    80001580:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001582:	6985                	lui	s3,0x1
    80001584:	19fd                	addi	s3,s3,-1
    80001586:	95ce                	add	a1,a1,s3
    80001588:	79fd                	lui	s3,0xfffff
    8000158a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000158e:	08c9f063          	bgeu	s3,a2,8000160e <uvmalloc+0xa6>
    80001592:	894e                	mv	s2,s3
    mem = kalloc();
    80001594:	fffff097          	auipc	ra,0xfffff
    80001598:	58c080e7          	jalr	1420(ra) # 80000b20 <kalloc>
    8000159c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000159e:	c51d                	beqz	a0,800015cc <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800015a0:	6605                	lui	a2,0x1
    800015a2:	4581                	li	a1,0
    800015a4:	fffff097          	auipc	ra,0xfffff
    800015a8:	7b2080e7          	jalr	1970(ra) # 80000d56 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800015ac:	4779                	li	a4,30
    800015ae:	86a6                	mv	a3,s1
    800015b0:	6605                	lui	a2,0x1
    800015b2:	85ca                	mv	a1,s2
    800015b4:	8556                	mv	a0,s5
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	c6e080e7          	jalr	-914(ra) # 80001224 <mappages>
    800015be:	e905                	bnez	a0,800015ee <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015c0:	6785                	lui	a5,0x1
    800015c2:	993e                	add	s2,s2,a5
    800015c4:	fd4968e3          	bltu	s2,s4,80001594 <uvmalloc+0x2c>
  return newsz;
    800015c8:	8552                	mv	a0,s4
    800015ca:	a809                	j	800015dc <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015cc:	864e                	mv	a2,s3
    800015ce:	85ca                	mv	a1,s2
    800015d0:	8556                	mv	a0,s5
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	f4e080e7          	jalr	-178(ra) # 80001520 <uvmdealloc>
      return 0;
    800015da:	4501                	li	a0,0
}
    800015dc:	70e2                	ld	ra,56(sp)
    800015de:	7442                	ld	s0,48(sp)
    800015e0:	74a2                	ld	s1,40(sp)
    800015e2:	7902                	ld	s2,32(sp)
    800015e4:	69e2                	ld	s3,24(sp)
    800015e6:	6a42                	ld	s4,16(sp)
    800015e8:	6aa2                	ld	s5,8(sp)
    800015ea:	6121                	addi	sp,sp,64
    800015ec:	8082                	ret
      kfree(mem);
    800015ee:	8526                	mv	a0,s1
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	434080e7          	jalr	1076(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015f8:	864e                	mv	a2,s3
    800015fa:	85ca                	mv	a1,s2
    800015fc:	8556                	mv	a0,s5
    800015fe:	00000097          	auipc	ra,0x0
    80001602:	f22080e7          	jalr	-222(ra) # 80001520 <uvmdealloc>
      return 0;
    80001606:	4501                	li	a0,0
    80001608:	bfd1                	j	800015dc <uvmalloc+0x74>
    return oldsz;
    8000160a:	852e                	mv	a0,a1
}
    8000160c:	8082                	ret
  return newsz;
    8000160e:	8532                	mv	a0,a2
    80001610:	b7f1                	j	800015dc <uvmalloc+0x74>

0000000080001612 <ufreewalk>:

// Recursively free page-table pages similar to freewalk
// not need to already free leaf node
void
ufreewalk(pagetable_t pagetable)
{
    80001612:	7139                	addi	sp,sp,-64
    80001614:	fc06                	sd	ra,56(sp)
    80001616:	f822                	sd	s0,48(sp)
    80001618:	f426                	sd	s1,40(sp)
    8000161a:	f04a                	sd	s2,32(sp)
    8000161c:	ec4e                	sd	s3,24(sp)
    8000161e:	e852                	sd	s4,16(sp)
    80001620:	e456                	sd	s5,8(sp)
    80001622:	0080                	addi	s0,sp,64
    80001624:	8aaa                	mv	s5,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001626:	84aa                	mv	s1,a0
    80001628:	6985                	lui	s3,0x1
    8000162a:	99aa                	add	s3,s3,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000162c:	4a05                	li	s4,1
    8000162e:	a821                	j	80001646 <ufreewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001630:	8129                	srli	a0,a0,0xa
      ufreewalk((pagetable_t)child);
    80001632:	0532                	slli	a0,a0,0xc
    80001634:	00000097          	auipc	ra,0x0
    80001638:	fde080e7          	jalr	-34(ra) # 80001612 <ufreewalk>
      pagetable[i] = 0;
    }
    pagetable[i] = 0;
    8000163c:	00093023          	sd	zero,0(s2)
  for(int i = 0; i < 512; i++){
    80001640:	04a1                	addi	s1,s1,8
    80001642:	01348963          	beq	s1,s3,80001654 <ufreewalk+0x42>
    pte_t pte = pagetable[i];
    80001646:	8926                	mv	s2,s1
    80001648:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000164a:	00f57793          	andi	a5,a0,15
    8000164e:	ff4797e3          	bne	a5,s4,8000163c <ufreewalk+0x2a>
    80001652:	bff9                	j	80001630 <ufreewalk+0x1e>
  }
  kfree((void*)pagetable);
    80001654:	8556                	mv	a0,s5
    80001656:	fffff097          	auipc	ra,0xfffff
    8000165a:	3ce080e7          	jalr	974(ra) # 80000a24 <kfree>
}
    8000165e:	70e2                	ld	ra,56(sp)
    80001660:	7442                	ld	s0,48(sp)
    80001662:	74a2                	ld	s1,40(sp)
    80001664:	7902                	ld	s2,32(sp)
    80001666:	69e2                	ld	s3,24(sp)
    80001668:	6a42                	ld	s4,16(sp)
    8000166a:	6aa2                	ld	s5,8(sp)
    8000166c:	6121                	addi	sp,sp,64
    8000166e:	8082                	ret

0000000080001670 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001670:	7179                	addi	sp,sp,-48
    80001672:	f406                	sd	ra,40(sp)
    80001674:	f022                	sd	s0,32(sp)
    80001676:	ec26                	sd	s1,24(sp)
    80001678:	e84a                	sd	s2,16(sp)
    8000167a:	e44e                	sd	s3,8(sp)
    8000167c:	e052                	sd	s4,0(sp)
    8000167e:	1800                	addi	s0,sp,48
    80001680:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001682:	84aa                	mv	s1,a0
    80001684:	6905                	lui	s2,0x1
    80001686:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001688:	4985                	li	s3,1
    8000168a:	a821                	j	800016a2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000168c:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000168e:	0532                	slli	a0,a0,0xc
    80001690:	00000097          	auipc	ra,0x0
    80001694:	fe0080e7          	jalr	-32(ra) # 80001670 <freewalk>
      pagetable[i] = 0;
    80001698:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000169c:	04a1                	addi	s1,s1,8
    8000169e:	03248163          	beq	s1,s2,800016c0 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800016a2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016a4:	00f57793          	andi	a5,a0,15
    800016a8:	ff3782e3          	beq	a5,s3,8000168c <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016ac:	8905                	andi	a0,a0,1
    800016ae:	d57d                	beqz	a0,8000169c <freewalk+0x2c>
      panic("freewalk: leaf");
    800016b0:	00007517          	auipc	a0,0x7
    800016b4:	ab850513          	addi	a0,a0,-1352 # 80008168 <digits+0x128>
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	e90080e7          	jalr	-368(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800016c0:	8552                	mv	a0,s4
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	362080e7          	jalr	866(ra) # 80000a24 <kfree>
}
    800016ca:	70a2                	ld	ra,40(sp)
    800016cc:	7402                	ld	s0,32(sp)
    800016ce:	64e2                	ld	s1,24(sp)
    800016d0:	6942                	ld	s2,16(sp)
    800016d2:	69a2                	ld	s3,8(sp)
    800016d4:	6a02                	ld	s4,0(sp)
    800016d6:	6145                	addi	sp,sp,48
    800016d8:	8082                	ret

00000000800016da <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016da:	1101                	addi	sp,sp,-32
    800016dc:	ec06                	sd	ra,24(sp)
    800016de:	e822                	sd	s0,16(sp)
    800016e0:	e426                	sd	s1,8(sp)
    800016e2:	1000                	addi	s0,sp,32
    800016e4:	84aa                	mv	s1,a0
  if(sz > 0)
    800016e6:	e999                	bnez	a1,800016fc <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016e8:	8526                	mv	a0,s1
    800016ea:	00000097          	auipc	ra,0x0
    800016ee:	f86080e7          	jalr	-122(ra) # 80001670 <freewalk>
}
    800016f2:	60e2                	ld	ra,24(sp)
    800016f4:	6442                	ld	s0,16(sp)
    800016f6:	64a2                	ld	s1,8(sp)
    800016f8:	6105                	addi	sp,sp,32
    800016fa:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016fc:	6605                	lui	a2,0x1
    800016fe:	167d                	addi	a2,a2,-1
    80001700:	962e                	add	a2,a2,a1
    80001702:	4685                	li	a3,1
    80001704:	8231                	srli	a2,a2,0xc
    80001706:	4581                	li	a1,0
    80001708:	00000097          	auipc	ra,0x0
    8000170c:	cb4080e7          	jalr	-844(ra) # 800013bc <uvmunmap>
    80001710:	bfe1                	j	800016e8 <uvmfree+0xe>

0000000080001712 <pagecopy>:

// copying from old page to new page from
// begin in old page to new in old page
// and mask off PTE_U bit
int
pagecopy(pagetable_t oldpage, pagetable_t newpage, uint64 begin, uint64 end) {
    80001712:	7179                	addi	sp,sp,-48
    80001714:	f406                	sd	ra,40(sp)
    80001716:	f022                	sd	s0,32(sp)
    80001718:	ec26                	sd	s1,24(sp)
    8000171a:	e84a                	sd	s2,16(sp)
    8000171c:	e44e                	sd	s3,8(sp)
    8000171e:	e052                	sd	s4,0(sp)
    80001720:	1800                	addi	s0,sp,48
    80001722:	8a2a                	mv	s4,a0
    80001724:	89ae                	mv	s3,a1
    80001726:	8936                	mv	s2,a3
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  begin = PGROUNDUP(begin);
    80001728:	6485                	lui	s1,0x1
    8000172a:	14fd                	addi	s1,s1,-1
    8000172c:	9626                	add	a2,a2,s1
    8000172e:	74fd                	lui	s1,0xfffff
    80001730:	8cf1                	and	s1,s1,a2

  for (i = begin; i < end; i += PGSIZE) {
    80001732:	08d4f263          	bgeu	s1,a3,800017b6 <pagecopy+0xa4>
    if ((pte = walk(oldpage, i, 0)) == 0)
    80001736:	4601                	li	a2,0
    80001738:	85a6                	mv	a1,s1
    8000173a:	8552                	mv	a0,s4
    8000173c:	00000097          	auipc	ra,0x0
    80001740:	92a080e7          	jalr	-1750(ra) # 80001066 <walk>
    80001744:	c51d                	beqz	a0,80001772 <pagecopy+0x60>
      panic("pagecopy walk oldpage nullptr");
    if ((*pte & PTE_V) == 0)
    80001746:	6118                	ld	a4,0(a0)
    80001748:	00177793          	andi	a5,a4,1
    8000174c:	cb9d                	beqz	a5,80001782 <pagecopy+0x70>
      panic("pagecopy oldpage pte not valid");
    pa = PTE2PA(*pte);
    8000174e:	00a75693          	srli	a3,a4,0xa
    flags = PTE_FLAGS(*pte) & (~PTE_U);
    if (umappages(newpage, i, PGSIZE, pa, flags) != 0) {
    80001752:	3ef77713          	andi	a4,a4,1007
    80001756:	06b2                	slli	a3,a3,0xc
    80001758:	6605                	lui	a2,0x1
    8000175a:	85a6                	mv	a1,s1
    8000175c:	854e                	mv	a0,s3
    8000175e:	00000097          	auipc	ra,0x0
    80001762:	a4e080e7          	jalr	-1458(ra) # 800011ac <umappages>
    80001766:	e515                	bnez	a0,80001792 <pagecopy+0x80>
  for (i = begin; i < end; i += PGSIZE) {
    80001768:	6785                	lui	a5,0x1
    8000176a:	94be                	add	s1,s1,a5
    8000176c:	fd24e5e3          	bltu	s1,s2,80001736 <pagecopy+0x24>
    80001770:	a81d                	j	800017a6 <pagecopy+0x94>
      panic("pagecopy walk oldpage nullptr");
    80001772:	00007517          	auipc	a0,0x7
    80001776:	a0650513          	addi	a0,a0,-1530 # 80008178 <digits+0x138>
    8000177a:	fffff097          	auipc	ra,0xfffff
    8000177e:	dce080e7          	jalr	-562(ra) # 80000548 <panic>
      panic("pagecopy oldpage pte not valid");
    80001782:	00007517          	auipc	a0,0x7
    80001786:	a1650513          	addi	a0,a0,-1514 # 80008198 <digits+0x158>
    8000178a:	fffff097          	auipc	ra,0xfffff
    8000178e:	dbe080e7          	jalr	-578(ra) # 80000548 <panic>
    }
  }
  return 0;

err:
  uvmunmap(newpage, 0, i / PGSIZE, 1);
    80001792:	4685                	li	a3,1
    80001794:	00c4d613          	srli	a2,s1,0xc
    80001798:	4581                	li	a1,0
    8000179a:	854e                	mv	a0,s3
    8000179c:	00000097          	auipc	ra,0x0
    800017a0:	c20080e7          	jalr	-992(ra) # 800013bc <uvmunmap>
  return -1;
    800017a4:	557d                	li	a0,-1
}
    800017a6:	70a2                	ld	ra,40(sp)
    800017a8:	7402                	ld	s0,32(sp)
    800017aa:	64e2                	ld	s1,24(sp)
    800017ac:	6942                	ld	s2,16(sp)
    800017ae:	69a2                	ld	s3,8(sp)
    800017b0:	6a02                	ld	s4,0(sp)
    800017b2:	6145                	addi	sp,sp,48
    800017b4:	8082                	ret
  return 0;
    800017b6:	4501                	li	a0,0
    800017b8:	b7fd                	j	800017a6 <pagecopy+0x94>

00000000800017ba <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800017ba:	c679                	beqz	a2,80001888 <uvmcopy+0xce>
{
    800017bc:	715d                	addi	sp,sp,-80
    800017be:	e486                	sd	ra,72(sp)
    800017c0:	e0a2                	sd	s0,64(sp)
    800017c2:	fc26                	sd	s1,56(sp)
    800017c4:	f84a                	sd	s2,48(sp)
    800017c6:	f44e                	sd	s3,40(sp)
    800017c8:	f052                	sd	s4,32(sp)
    800017ca:	ec56                	sd	s5,24(sp)
    800017cc:	e85a                	sd	s6,16(sp)
    800017ce:	e45e                	sd	s7,8(sp)
    800017d0:	0880                	addi	s0,sp,80
    800017d2:	8b2a                	mv	s6,a0
    800017d4:	8aae                	mv	s5,a1
    800017d6:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800017d8:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800017da:	4601                	li	a2,0
    800017dc:	85ce                	mv	a1,s3
    800017de:	855a                	mv	a0,s6
    800017e0:	00000097          	auipc	ra,0x0
    800017e4:	886080e7          	jalr	-1914(ra) # 80001066 <walk>
    800017e8:	c531                	beqz	a0,80001834 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800017ea:	6118                	ld	a4,0(a0)
    800017ec:	00177793          	andi	a5,a4,1
    800017f0:	cbb1                	beqz	a5,80001844 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800017f2:	00a75593          	srli	a1,a4,0xa
    800017f6:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800017fa:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800017fe:	fffff097          	auipc	ra,0xfffff
    80001802:	322080e7          	jalr	802(ra) # 80000b20 <kalloc>
    80001806:	892a                	mv	s2,a0
    80001808:	c939                	beqz	a0,8000185e <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000180a:	6605                	lui	a2,0x1
    8000180c:	85de                	mv	a1,s7
    8000180e:	fffff097          	auipc	ra,0xfffff
    80001812:	5a8080e7          	jalr	1448(ra) # 80000db6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001816:	8726                	mv	a4,s1
    80001818:	86ca                	mv	a3,s2
    8000181a:	6605                	lui	a2,0x1
    8000181c:	85ce                	mv	a1,s3
    8000181e:	8556                	mv	a0,s5
    80001820:	00000097          	auipc	ra,0x0
    80001824:	a04080e7          	jalr	-1532(ra) # 80001224 <mappages>
    80001828:	e515                	bnez	a0,80001854 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000182a:	6785                	lui	a5,0x1
    8000182c:	99be                	add	s3,s3,a5
    8000182e:	fb49e6e3          	bltu	s3,s4,800017da <uvmcopy+0x20>
    80001832:	a081                	j	80001872 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001834:	00007517          	auipc	a0,0x7
    80001838:	98450513          	addi	a0,a0,-1660 # 800081b8 <digits+0x178>
    8000183c:	fffff097          	auipc	ra,0xfffff
    80001840:	d0c080e7          	jalr	-756(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    80001844:	00007517          	auipc	a0,0x7
    80001848:	99450513          	addi	a0,a0,-1644 # 800081d8 <digits+0x198>
    8000184c:	fffff097          	auipc	ra,0xfffff
    80001850:	cfc080e7          	jalr	-772(ra) # 80000548 <panic>
      kfree(mem);
    80001854:	854a                	mv	a0,s2
    80001856:	fffff097          	auipc	ra,0xfffff
    8000185a:	1ce080e7          	jalr	462(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000185e:	4685                	li	a3,1
    80001860:	00c9d613          	srli	a2,s3,0xc
    80001864:	4581                	li	a1,0
    80001866:	8556                	mv	a0,s5
    80001868:	00000097          	auipc	ra,0x0
    8000186c:	b54080e7          	jalr	-1196(ra) # 800013bc <uvmunmap>
  return -1;
    80001870:	557d                	li	a0,-1
}
    80001872:	60a6                	ld	ra,72(sp)
    80001874:	6406                	ld	s0,64(sp)
    80001876:	74e2                	ld	s1,56(sp)
    80001878:	7942                	ld	s2,48(sp)
    8000187a:	79a2                	ld	s3,40(sp)
    8000187c:	7a02                	ld	s4,32(sp)
    8000187e:	6ae2                	ld	s5,24(sp)
    80001880:	6b42                	ld	s6,16(sp)
    80001882:	6ba2                	ld	s7,8(sp)
    80001884:	6161                	addi	sp,sp,80
    80001886:	8082                	ret
  return 0;
    80001888:	4501                	li	a0,0
}
    8000188a:	8082                	ret

000000008000188c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000188c:	1141                	addi	sp,sp,-16
    8000188e:	e406                	sd	ra,8(sp)
    80001890:	e022                	sd	s0,0(sp)
    80001892:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001894:	4601                	li	a2,0
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	7d0080e7          	jalr	2000(ra) # 80001066 <walk>
  if(pte == 0)
    8000189e:	c901                	beqz	a0,800018ae <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800018a0:	611c                	ld	a5,0(a0)
    800018a2:	9bbd                	andi	a5,a5,-17
    800018a4:	e11c                	sd	a5,0(a0)
}
    800018a6:	60a2                	ld	ra,8(sp)
    800018a8:	6402                	ld	s0,0(sp)
    800018aa:	0141                	addi	sp,sp,16
    800018ac:	8082                	ret
    panic("uvmclear");
    800018ae:	00007517          	auipc	a0,0x7
    800018b2:	94a50513          	addi	a0,a0,-1718 # 800081f8 <digits+0x1b8>
    800018b6:	fffff097          	auipc	ra,0xfffff
    800018ba:	c92080e7          	jalr	-878(ra) # 80000548 <panic>

00000000800018be <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018be:	c6bd                	beqz	a3,8000192c <copyout+0x6e>
{
    800018c0:	715d                	addi	sp,sp,-80
    800018c2:	e486                	sd	ra,72(sp)
    800018c4:	e0a2                	sd	s0,64(sp)
    800018c6:	fc26                	sd	s1,56(sp)
    800018c8:	f84a                	sd	s2,48(sp)
    800018ca:	f44e                	sd	s3,40(sp)
    800018cc:	f052                	sd	s4,32(sp)
    800018ce:	ec56                	sd	s5,24(sp)
    800018d0:	e85a                	sd	s6,16(sp)
    800018d2:	e45e                	sd	s7,8(sp)
    800018d4:	e062                	sd	s8,0(sp)
    800018d6:	0880                	addi	s0,sp,80
    800018d8:	8b2a                	mv	s6,a0
    800018da:	8c2e                	mv	s8,a1
    800018dc:	8a32                	mv	s4,a2
    800018de:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800018e0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800018e2:	6a85                	lui	s5,0x1
    800018e4:	a015                	j	80001908 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800018e6:	9562                	add	a0,a0,s8
    800018e8:	0004861b          	sext.w	a2,s1
    800018ec:	85d2                	mv	a1,s4
    800018ee:	41250533          	sub	a0,a0,s2
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	4c4080e7          	jalr	1220(ra) # 80000db6 <memmove>

    len -= n;
    800018fa:	409989b3          	sub	s3,s3,s1
    src += n;
    800018fe:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001900:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001904:	02098263          	beqz	s3,80001928 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001908:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000190c:	85ca                	mv	a1,s2
    8000190e:	855a                	mv	a0,s6
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	7fc080e7          	jalr	2044(ra) # 8000110c <walkaddr>
    if(pa0 == 0)
    80001918:	cd01                	beqz	a0,80001930 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000191a:	418904b3          	sub	s1,s2,s8
    8000191e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001920:	fc99f3e3          	bgeu	s3,s1,800018e6 <copyout+0x28>
    80001924:	84ce                	mv	s1,s3
    80001926:	b7c1                	j	800018e6 <copyout+0x28>
  }
  return 0;
    80001928:	4501                	li	a0,0
    8000192a:	a021                	j	80001932 <copyout+0x74>
    8000192c:	4501                	li	a0,0
}
    8000192e:	8082                	ret
      return -1;
    80001930:	557d                	li	a0,-1
}
    80001932:	60a6                	ld	ra,72(sp)
    80001934:	6406                	ld	s0,64(sp)
    80001936:	74e2                	ld	s1,56(sp)
    80001938:	7942                	ld	s2,48(sp)
    8000193a:	79a2                	ld	s3,40(sp)
    8000193c:	7a02                	ld	s4,32(sp)
    8000193e:	6ae2                	ld	s5,24(sp)
    80001940:	6b42                	ld	s6,16(sp)
    80001942:	6ba2                	ld	s7,8(sp)
    80001944:	6c02                	ld	s8,0(sp)
    80001946:	6161                	addi	sp,sp,80
    80001948:	8082                	ret

000000008000194a <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    8000194a:	1141                	addi	sp,sp,-16
    8000194c:	e406                	sd	ra,8(sp)
    8000194e:	e022                	sd	s0,0(sp)
    80001950:	0800                	addi	s0,sp,16
  return copyin_new(pagetable, dst, srcva, len);
    80001952:	00005097          	auipc	ra,0x5
    80001956:	f9e080e7          	jalr	-98(ra) # 800068f0 <copyin_new>
}
    8000195a:	60a2                	ld	ra,8(sp)
    8000195c:	6402                	ld	s0,0(sp)
    8000195e:	0141                	addi	sp,sp,16
    80001960:	8082                	ret

0000000080001962 <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80001962:	1141                	addi	sp,sp,-16
    80001964:	e406                	sd	ra,8(sp)
    80001966:	e022                	sd	s0,0(sp)
    80001968:	0800                	addi	s0,sp,16
  return copyinstr_new(pagetable, dst, srcva, max);
    8000196a:	00005097          	auipc	ra,0x5
    8000196e:	fee080e7          	jalr	-18(ra) # 80006958 <copyinstr_new>
}
    80001972:	60a2                	ld	ra,8(sp)
    80001974:	6402                	ld	s0,0(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <vmprint_helper>:

// Recursive helper
void vmprint_helper(pagetable_t pagetable, int depth) {
    8000197a:	715d                	addi	sp,sp,-80
    8000197c:	e486                	sd	ra,72(sp)
    8000197e:	e0a2                	sd	s0,64(sp)
    80001980:	fc26                	sd	s1,56(sp)
    80001982:	f84a                	sd	s2,48(sp)
    80001984:	f44e                	sd	s3,40(sp)
    80001986:	f052                	sd	s4,32(sp)
    80001988:	ec56                	sd	s5,24(sp)
    8000198a:	e85a                	sd	s6,16(sp)
    8000198c:	e45e                	sd	s7,8(sp)
    8000198e:	e062                	sd	s8,0(sp)
    80001990:	0880                	addi	s0,sp,80
      "",
      "..",
      ".. ..",
      ".. .. .."
  };
  if (depth <= 0 || depth >= 4) {
    80001992:	fff5871b          	addiw	a4,a1,-1
    80001996:	4789                	li	a5,2
    80001998:	02e7e463          	bltu	a5,a4,800019c0 <vmprint_helper+0x46>
    8000199c:	89aa                	mv	s3,a0
    8000199e:	4901                	li	s2,0
  }
  // there are 2^9 = 512 PTES in a page table.
  for (int i = 0; i < 512; i++) {
    pte_t pte = pagetable[i];
    if (pte & PTE_V) {
      printf("%s%d: pte %p pa %p\n", indent[depth], i, pte, PTE2PA(pte));
    800019a0:	00359793          	slli	a5,a1,0x3
    800019a4:	00007b17          	auipc	s6,0x7
    800019a8:	90cb0b13          	addi	s6,s6,-1780 # 800082b0 <indent.1822>
    800019ac:	9b3e                	add	s6,s6,a5
    800019ae:	00007b97          	auipc	s7,0x7
    800019b2:	882b8b93          	addi	s7,s7,-1918 # 80008230 <digits+0x1f0>
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
        // points to a lower-level page table
        uint64 child = PTE2PA(pte);
        vmprint_helper((pagetable_t)child, depth+1);
    800019b6:	00158c1b          	addiw	s8,a1,1
  for (int i = 0; i < 512; i++) {
    800019ba:	20000a93          	li	s5,512
    800019be:	a01d                	j	800019e4 <vmprint_helper+0x6a>
    panic("vmprint_helper: depth not in {1, 2, 3}");
    800019c0:	00007517          	auipc	a0,0x7
    800019c4:	84850513          	addi	a0,a0,-1976 # 80008208 <digits+0x1c8>
    800019c8:	fffff097          	auipc	ra,0xfffff
    800019cc:	b80080e7          	jalr	-1152(ra) # 80000548 <panic>
        vmprint_helper((pagetable_t)child, depth+1);
    800019d0:	85e2                	mv	a1,s8
    800019d2:	8552                	mv	a0,s4
    800019d4:	00000097          	auipc	ra,0x0
    800019d8:	fa6080e7          	jalr	-90(ra) # 8000197a <vmprint_helper>
  for (int i = 0; i < 512; i++) {
    800019dc:	2905                	addiw	s2,s2,1
    800019de:	09a1                	addi	s3,s3,8
    800019e0:	03590763          	beq	s2,s5,80001a0e <vmprint_helper+0x94>
    pte_t pte = pagetable[i];
    800019e4:	0009b483          	ld	s1,0(s3) # 1000 <_entry-0x7ffff000>
    if (pte & PTE_V) {
    800019e8:	0014f793          	andi	a5,s1,1
    800019ec:	dbe5                	beqz	a5,800019dc <vmprint_helper+0x62>
      printf("%s%d: pte %p pa %p\n", indent[depth], i, pte, PTE2PA(pte));
    800019ee:	00a4da13          	srli	s4,s1,0xa
    800019f2:	0a32                	slli	s4,s4,0xc
    800019f4:	8752                	mv	a4,s4
    800019f6:	86a6                	mv	a3,s1
    800019f8:	864a                	mv	a2,s2
    800019fa:	000b3583          	ld	a1,0(s6)
    800019fe:	855e                	mv	a0,s7
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	b92080e7          	jalr	-1134(ra) # 80000592 <printf>
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    80001a08:	88b9                	andi	s1,s1,14
    80001a0a:	f8e9                	bnez	s1,800019dc <vmprint_helper+0x62>
    80001a0c:	b7d1                	j	800019d0 <vmprint_helper+0x56>
      }
    }
  }
}
    80001a0e:	60a6                	ld	ra,72(sp)
    80001a10:	6406                	ld	s0,64(sp)
    80001a12:	74e2                	ld	s1,56(sp)
    80001a14:	7942                	ld	s2,48(sp)
    80001a16:	79a2                	ld	s3,40(sp)
    80001a18:	7a02                	ld	s4,32(sp)
    80001a1a:	6ae2                	ld	s5,24(sp)
    80001a1c:	6b42                	ld	s6,16(sp)
    80001a1e:	6ba2                	ld	s7,8(sp)
    80001a20:	6c02                	ld	s8,0(sp)
    80001a22:	6161                	addi	sp,sp,80
    80001a24:	8082                	ret

0000000080001a26 <vmprint>:

// Utility func to print the valid
// PTEs within a page table recursively
void vmprint(pagetable_t pagetable) {
    80001a26:	1101                	addi	sp,sp,-32
    80001a28:	ec06                	sd	ra,24(sp)
    80001a2a:	e822                	sd	s0,16(sp)
    80001a2c:	e426                	sd	s1,8(sp)
    80001a2e:	1000                	addi	s0,sp,32
    80001a30:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    80001a32:	85aa                	mv	a1,a0
    80001a34:	00007517          	auipc	a0,0x7
    80001a38:	81450513          	addi	a0,a0,-2028 # 80008248 <digits+0x208>
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	b56080e7          	jalr	-1194(ra) # 80000592 <printf>
  vmprint_helper(pagetable, 1);
    80001a44:	4585                	li	a1,1
    80001a46:	8526                	mv	a0,s1
    80001a48:	00000097          	auipc	ra,0x0
    80001a4c:	f32080e7          	jalr	-206(ra) # 8000197a <vmprint_helper>
}
    80001a50:	60e2                	ld	ra,24(sp)
    80001a52:	6442                	ld	s0,16(sp)
    80001a54:	64a2                	ld	s1,8(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <ukvmmap>:

// add a mapping to the per-process kernel page table.
void
ukvmmap(pagetable_t kpagetable, uint64 va, uint64 pa, uint64 sz, int perm)
{
    80001a5a:	1141                	addi	sp,sp,-16
    80001a5c:	e406                	sd	ra,8(sp)
    80001a5e:	e022                	sd	s0,0(sp)
    80001a60:	0800                	addi	s0,sp,16
    80001a62:	87b6                	mv	a5,a3
  if(mappages(kpagetable, va, sz, pa, perm) != 0)
    80001a64:	86b2                	mv	a3,a2
    80001a66:	863e                	mv	a2,a5
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	7bc080e7          	jalr	1980(ra) # 80001224 <mappages>
    80001a70:	e509                	bnez	a0,80001a7a <ukvmmap+0x20>
    panic("ukvmmap");
}
    80001a72:	60a2                	ld	ra,8(sp)
    80001a74:	6402                	ld	s0,0(sp)
    80001a76:	0141                	addi	sp,sp,16
    80001a78:	8082                	ret
    panic("ukvmmap");
    80001a7a:	00006517          	auipc	a0,0x6
    80001a7e:	7de50513          	addi	a0,a0,2014 # 80008258 <digits+0x218>
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	ac6080e7          	jalr	-1338(ra) # 80000548 <panic>

0000000080001a8a <ukvminit>:
 * create a direct-map page table for the per-process kernel page table.
 * return nullptr when kalloc fails
 */
pagetable_t
ukvminit()
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
  pagetable_t kpagetable = (pagetable_t) kalloc();
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	08a080e7          	jalr	138(ra) # 80000b20 <kalloc>
    80001a9e:	84aa                	mv	s1,a0
  if (kpagetable == 0) {
    80001aa0:	c161                	beqz	a0,80001b60 <ukvminit+0xd6>
    return kpagetable;
  }

  memset(kpagetable, 0, PGSIZE);
    80001aa2:	6605                	lui	a2,0x1
    80001aa4:	4581                	li	a1,0
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	2b0080e7          	jalr	688(ra) # 80000d56 <memset>

  // uart registers
  ukvmmap(kpagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001aae:	4719                	li	a4,6
    80001ab0:	6685                	lui	a3,0x1
    80001ab2:	10000637          	lui	a2,0x10000
    80001ab6:	100005b7          	lui	a1,0x10000
    80001aba:	8526                	mv	a0,s1
    80001abc:	00000097          	auipc	ra,0x0
    80001ac0:	f9e080e7          	jalr	-98(ra) # 80001a5a <ukvmmap>

  // virtio mmio disk interface
  ukvmmap(kpagetable, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001ac4:	4719                	li	a4,6
    80001ac6:	6685                	lui	a3,0x1
    80001ac8:	10001637          	lui	a2,0x10001
    80001acc:	100015b7          	lui	a1,0x10001
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	00000097          	auipc	ra,0x0
    80001ad6:	f88080e7          	jalr	-120(ra) # 80001a5a <ukvmmap>

  // CLINT
  ukvmmap(kpagetable, CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001ada:	4719                	li	a4,6
    80001adc:	66c1                	lui	a3,0x10
    80001ade:	02000637          	lui	a2,0x2000
    80001ae2:	020005b7          	lui	a1,0x2000
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	00000097          	auipc	ra,0x0
    80001aec:	f72080e7          	jalr	-142(ra) # 80001a5a <ukvmmap>

  // PLIC
  ukvmmap(kpagetable, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001af0:	4719                	li	a4,6
    80001af2:	004006b7          	lui	a3,0x400
    80001af6:	0c000637          	lui	a2,0xc000
    80001afa:	0c0005b7          	lui	a1,0xc000
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	f5a080e7          	jalr	-166(ra) # 80001a5a <ukvmmap>

  // map kernel text executable and read-only.
  ukvmmap(kpagetable, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001b08:	00006917          	auipc	s2,0x6
    80001b0c:	4f890913          	addi	s2,s2,1272 # 80008000 <etext>
    80001b10:	4729                	li	a4,10
    80001b12:	80006697          	auipc	a3,0x80006
    80001b16:	4ee68693          	addi	a3,a3,1262 # 8000 <_entry-0x7fff8000>
    80001b1a:	4605                	li	a2,1
    80001b1c:	067e                	slli	a2,a2,0x1f
    80001b1e:	85b2                	mv	a1,a2
    80001b20:	8526                	mv	a0,s1
    80001b22:	00000097          	auipc	ra,0x0
    80001b26:	f38080e7          	jalr	-200(ra) # 80001a5a <ukvmmap>

  // map kernel data and the physical RAM we'll make use of.
  ukvmmap(kpagetable, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001b2a:	4719                	li	a4,6
    80001b2c:	46c5                	li	a3,17
    80001b2e:	06ee                	slli	a3,a3,0x1b
    80001b30:	412686b3          	sub	a3,a3,s2
    80001b34:	864a                	mv	a2,s2
    80001b36:	85ca                	mv	a1,s2
    80001b38:	8526                	mv	a0,s1
    80001b3a:	00000097          	auipc	ra,0x0
    80001b3e:	f20080e7          	jalr	-224(ra) # 80001a5a <ukvmmap>

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  ukvmmap(kpagetable, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001b42:	4729                	li	a4,10
    80001b44:	6685                	lui	a3,0x1
    80001b46:	00005617          	auipc	a2,0x5
    80001b4a:	4ba60613          	addi	a2,a2,1210 # 80007000 <_trampoline>
    80001b4e:	040005b7          	lui	a1,0x4000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b2                	slli	a1,a1,0xc
    80001b56:	8526                	mv	a0,s1
    80001b58:	00000097          	auipc	ra,0x0
    80001b5c:	f02080e7          	jalr	-254(ra) # 80001a5a <ukvmmap>

  return kpagetable;
}
    80001b60:	8526                	mv	a0,s1
    80001b62:	60e2                	ld	ra,24(sp)
    80001b64:	6442                	ld	s0,16(sp)
    80001b66:	64a2                	ld	s1,8(sp)
    80001b68:	6902                	ld	s2,0(sp)
    80001b6a:	6105                	addi	sp,sp,32
    80001b6c:	8082                	ret

0000000080001b6e <ukvmunmap>:
// Unmap the leaf node mapping
// of the per-process kernel page table
// so that we could call freewalk on that
void
ukvmunmap(pagetable_t pagetable, uint64 va, uint64 npages)
{
    80001b6e:	7139                	addi	sp,sp,-64
    80001b70:	fc06                	sd	ra,56(sp)
    80001b72:	f822                	sd	s0,48(sp)
    80001b74:	f426                	sd	s1,40(sp)
    80001b76:	f04a                	sd	s2,32(sp)
    80001b78:	ec4e                	sd	s3,24(sp)
    80001b7a:	e852                	sd	s4,16(sp)
    80001b7c:	e456                	sd	s5,8(sp)
    80001b7e:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001b80:	03459793          	slli	a5,a1,0x34
    80001b84:	e39d                	bnez	a5,80001baa <ukvmunmap+0x3c>
    80001b86:	89aa                	mv	s3,a0
    80001b88:	84ae                	mv	s1,a1
    panic("ukvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001b8a:	00c61913          	slli	s2,a2,0xc
    80001b8e:	992e                	add	s2,s2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      goto clean;
    if((*pte & PTE_V) == 0)
      goto clean;
    if(PTE_FLAGS(*pte) == PTE_V)
    80001b90:	4a85                	li	s5,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001b92:	6a05                	lui	s4,0x1
    80001b94:	0325e863          	bltu	a1,s2,80001bc4 <ukvmunmap+0x56>
      panic("ukvmunmap: not a leaf");

    clean:
      *pte = 0;
  }
}
    80001b98:	70e2                	ld	ra,56(sp)
    80001b9a:	7442                	ld	s0,48(sp)
    80001b9c:	74a2                	ld	s1,40(sp)
    80001b9e:	7902                	ld	s2,32(sp)
    80001ba0:	69e2                	ld	s3,24(sp)
    80001ba2:	6a42                	ld	s4,16(sp)
    80001ba4:	6aa2                	ld	s5,8(sp)
    80001ba6:	6121                	addi	sp,sp,64
    80001ba8:	8082                	ret
    panic("ukvmunmap: not aligned");
    80001baa:	00006517          	auipc	a0,0x6
    80001bae:	6b650513          	addi	a0,a0,1718 # 80008260 <digits+0x220>
    80001bb2:	fffff097          	auipc	ra,0xfffff
    80001bb6:	996080e7          	jalr	-1642(ra) # 80000548 <panic>
      *pte = 0;
    80001bba:	00053023          	sd	zero,0(a0)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001bbe:	94d2                	add	s1,s1,s4
    80001bc0:	fd24fce3          	bgeu	s1,s2,80001b98 <ukvmunmap+0x2a>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001bc4:	4601                	li	a2,0
    80001bc6:	85a6                	mv	a1,s1
    80001bc8:	854e                	mv	a0,s3
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	49c080e7          	jalr	1180(ra) # 80001066 <walk>
    80001bd2:	d565                	beqz	a0,80001bba <ukvmunmap+0x4c>
    if((*pte & PTE_V) == 0)
    80001bd4:	611c                	ld	a5,0(a0)
    80001bd6:	0017f713          	andi	a4,a5,1
    80001bda:	d365                	beqz	a4,80001bba <ukvmunmap+0x4c>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001bdc:	3ff7f793          	andi	a5,a5,1023
    80001be0:	fd579de3          	bne	a5,s5,80001bba <ukvmunmap+0x4c>
      panic("ukvmunmap: not a leaf");
    80001be4:	00006517          	auipc	a0,0x6
    80001be8:	69450513          	addi	a0,a0,1684 # 80008278 <digits+0x238>
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	95c080e7          	jalr	-1700(ra) # 80000548 <panic>

0000000080001bf4 <freeprockvm>:

// helper function to first free all leaf mapping
// of a per-process kernel table but do not free the physical address
// and then remove all 3-levels indirection and the physical address
// for this kernel page itself
void freeprockvm(struct proc* p) {
    80001bf4:	1101                	addi	sp,sp,-32
    80001bf6:	ec06                	sd	ra,24(sp)
    80001bf8:	e822                	sd	s0,16(sp)
    80001bfa:	e426                	sd	s1,8(sp)
    80001bfc:	1000                	addi	s0,sp,32
  pagetable_t kpagetable = p->kpagetable;
    80001bfe:	17053483          	ld	s1,368(a0)
  // reverse order of allocation
  ukvmunmap(kpagetable, p->kstack, PGSIZE/PGSIZE);
    80001c02:	4605                	li	a2,1
    80001c04:	612c                	ld	a1,64(a0)
    80001c06:	8526                	mv	a0,s1
    80001c08:	00000097          	auipc	ra,0x0
    80001c0c:	f66080e7          	jalr	-154(ra) # 80001b6e <ukvmunmap>
  ukvmunmap(kpagetable, TRAMPOLINE, PGSIZE/PGSIZE);
    80001c10:	4605                	li	a2,1
    80001c12:	040005b7          	lui	a1,0x4000
    80001c16:	15fd                	addi	a1,a1,-1
    80001c18:	05b2                	slli	a1,a1,0xc
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	f52080e7          	jalr	-174(ra) # 80001b6e <ukvmunmap>
  ukvmunmap(kpagetable, (uint64)etext, (PHYSTOP-(uint64)etext)/PGSIZE);
    80001c24:	00006597          	auipc	a1,0x6
    80001c28:	3dc58593          	addi	a1,a1,988 # 80008000 <etext>
    80001c2c:	4645                	li	a2,17
    80001c2e:	066e                	slli	a2,a2,0x1b
    80001c30:	8e0d                	sub	a2,a2,a1
    80001c32:	8231                	srli	a2,a2,0xc
    80001c34:	8526                	mv	a0,s1
    80001c36:	00000097          	auipc	ra,0x0
    80001c3a:	f38080e7          	jalr	-200(ra) # 80001b6e <ukvmunmap>
  ukvmunmap(kpagetable, KERNBASE, ((uint64)etext-KERNBASE)/PGSIZE);
    80001c3e:	80006617          	auipc	a2,0x80006
    80001c42:	3c260613          	addi	a2,a2,962 # 8000 <_entry-0x7fff8000>
    80001c46:	8231                	srli	a2,a2,0xc
    80001c48:	4585                	li	a1,1
    80001c4a:	05fe                	slli	a1,a1,0x1f
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	00000097          	auipc	ra,0x0
    80001c52:	f20080e7          	jalr	-224(ra) # 80001b6e <ukvmunmap>
  ukvmunmap(kpagetable, PLIC, 0x400000/PGSIZE);
    80001c56:	40000613          	li	a2,1024
    80001c5a:	0c0005b7          	lui	a1,0xc000
    80001c5e:	8526                	mv	a0,s1
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	f0e080e7          	jalr	-242(ra) # 80001b6e <ukvmunmap>
  ukvmunmap(kpagetable, CLINT, 0x10000/PGSIZE);
    80001c68:	4641                	li	a2,16
    80001c6a:	020005b7          	lui	a1,0x2000
    80001c6e:	8526                	mv	a0,s1
    80001c70:	00000097          	auipc	ra,0x0
    80001c74:	efe080e7          	jalr	-258(ra) # 80001b6e <ukvmunmap>
  ukvmunmap(kpagetable, VIRTIO0, PGSIZE/PGSIZE);
    80001c78:	4605                	li	a2,1
    80001c7a:	100015b7          	lui	a1,0x10001
    80001c7e:	8526                	mv	a0,s1
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	eee080e7          	jalr	-274(ra) # 80001b6e <ukvmunmap>
  ukvmunmap(kpagetable, UART0, PGSIZE/PGSIZE);
    80001c88:	4605                	li	a2,1
    80001c8a:	100005b7          	lui	a1,0x10000
    80001c8e:	8526                	mv	a0,s1
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	ede080e7          	jalr	-290(ra) # 80001b6e <ukvmunmap>
  ufreewalk(kpagetable);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	978080e7          	jalr	-1672(ra) # 80001612 <ufreewalk>
}
    80001ca2:	60e2                	ld	ra,24(sp)
    80001ca4:	6442                	ld	s0,16(sp)
    80001ca6:	64a2                	ld	s1,8(sp)
    80001ca8:	6105                	addi	sp,sp,32
    80001caa:	8082                	ret

0000000080001cac <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001cac:	1101                	addi	sp,sp,-32
    80001cae:	ec06                	sd	ra,24(sp)
    80001cb0:	e822                	sd	s0,16(sp)
    80001cb2:	e426                	sd	s1,8(sp)
    80001cb4:	1000                	addi	s0,sp,32
    80001cb6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	f28080e7          	jalr	-216(ra) # 80000be0 <holding>
    80001cc0:	c909                	beqz	a0,80001cd2 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001cc2:	749c                	ld	a5,40(s1)
    80001cc4:	00978f63          	beq	a5,s1,80001ce2 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001cc8:	60e2                	ld	ra,24(sp)
    80001cca:	6442                	ld	s0,16(sp)
    80001ccc:	64a2                	ld	s1,8(sp)
    80001cce:	6105                	addi	sp,sp,32
    80001cd0:	8082                	ret
    panic("wakeup1");
    80001cd2:	00006517          	auipc	a0,0x6
    80001cd6:	5fe50513          	addi	a0,a0,1534 # 800082d0 <indent.1822+0x20>
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	86e080e7          	jalr	-1938(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001ce2:	4c98                	lw	a4,24(s1)
    80001ce4:	4785                	li	a5,1
    80001ce6:	fef711e3          	bne	a4,a5,80001cc8 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001cea:	4789                	li	a5,2
    80001cec:	cc9c                	sw	a5,24(s1)
}
    80001cee:	bfe9                	j	80001cc8 <wakeup1+0x1c>

0000000080001cf0 <procinit>:
{
    80001cf0:	715d                	addi	sp,sp,-80
    80001cf2:	e486                	sd	ra,72(sp)
    80001cf4:	e0a2                	sd	s0,64(sp)
    80001cf6:	fc26                	sd	s1,56(sp)
    80001cf8:	f84a                	sd	s2,48(sp)
    80001cfa:	f44e                	sd	s3,40(sp)
    80001cfc:	f052                	sd	s4,32(sp)
    80001cfe:	ec56                	sd	s5,24(sp)
    80001d00:	e85a                	sd	s6,16(sp)
    80001d02:	e45e                	sd	s7,8(sp)
    80001d04:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001d06:	00006597          	auipc	a1,0x6
    80001d0a:	5d258593          	addi	a1,a1,1490 # 800082d8 <indent.1822+0x28>
    80001d0e:	00010517          	auipc	a0,0x10
    80001d12:	c4250513          	addi	a0,a0,-958 # 80011950 <pid_lock>
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	eb4080e7          	jalr	-332(ra) # 80000bca <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d1e:	00010917          	auipc	s2,0x10
    80001d22:	04a90913          	addi	s2,s2,74 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001d26:	00006b97          	auipc	s7,0x6
    80001d2a:	5bab8b93          	addi	s7,s7,1466 # 800082e0 <indent.1822+0x30>
      uint64 va = KSTACK((int) (p - proc));
    80001d2e:	8b4a                	mv	s6,s2
    80001d30:	00006a97          	auipc	s5,0x6
    80001d34:	2d0a8a93          	addi	s5,s5,720 # 80008000 <etext>
    80001d38:	040009b7          	lui	s3,0x4000
    80001d3c:	19fd                	addi	s3,s3,-1
    80001d3e:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d40:	00016a17          	auipc	s4,0x16
    80001d44:	e28a0a13          	addi	s4,s4,-472 # 80017b68 <tickslock>
      initlock(&p->lock, "proc");
    80001d48:	85de                	mv	a1,s7
    80001d4a:	854a                	mv	a0,s2
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	e7e080e7          	jalr	-386(ra) # 80000bca <initlock>
      char *pa = kalloc();
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	dcc080e7          	jalr	-564(ra) # 80000b20 <kalloc>
    80001d5c:	85aa                	mv	a1,a0
      if(pa == 0)
    80001d5e:	c929                	beqz	a0,80001db0 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001d60:	416904b3          	sub	s1,s2,s6
    80001d64:	848d                	srai	s1,s1,0x3
    80001d66:	000ab783          	ld	a5,0(s5)
    80001d6a:	02f484b3          	mul	s1,s1,a5
    80001d6e:	2485                	addiw	s1,s1,1
    80001d70:	00d4949b          	slliw	s1,s1,0xd
    80001d74:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001d78:	4699                	li	a3,6
    80001d7a:	6605                	lui	a2,0x1
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	534080e7          	jalr	1332(ra) # 800012b2 <kvmmap>
      p->kstack = va;
    80001d86:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d8a:	17890913          	addi	s2,s2,376
    80001d8e:	fb491de3          	bne	s2,s4,80001d48 <procinit+0x58>
  kvminithart();
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	2b0080e7          	jalr	688(ra) # 80001042 <kvminithart>
}
    80001d9a:	60a6                	ld	ra,72(sp)
    80001d9c:	6406                	ld	s0,64(sp)
    80001d9e:	74e2                	ld	s1,56(sp)
    80001da0:	7942                	ld	s2,48(sp)
    80001da2:	79a2                	ld	s3,40(sp)
    80001da4:	7a02                	ld	s4,32(sp)
    80001da6:	6ae2                	ld	s5,24(sp)
    80001da8:	6b42                	ld	s6,16(sp)
    80001daa:	6ba2                	ld	s7,8(sp)
    80001dac:	6161                	addi	sp,sp,80
    80001dae:	8082                	ret
        panic("kalloc");
    80001db0:	00006517          	auipc	a0,0x6
    80001db4:	53850513          	addi	a0,a0,1336 # 800082e8 <indent.1822+0x38>
    80001db8:	ffffe097          	auipc	ra,0xffffe
    80001dbc:	790080e7          	jalr	1936(ra) # 80000548 <panic>

0000000080001dc0 <cpuid>:
{
    80001dc0:	1141                	addi	sp,sp,-16
    80001dc2:	e422                	sd	s0,8(sp)
    80001dc4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001dc6:	8512                	mv	a0,tp
}
    80001dc8:	2501                	sext.w	a0,a0
    80001dca:	6422                	ld	s0,8(sp)
    80001dcc:	0141                	addi	sp,sp,16
    80001dce:	8082                	ret

0000000080001dd0 <mycpu>:
mycpu(void) {
    80001dd0:	1141                	addi	sp,sp,-16
    80001dd2:	e422                	sd	s0,8(sp)
    80001dd4:	0800                	addi	s0,sp,16
    80001dd6:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001dd8:	2781                	sext.w	a5,a5
    80001dda:	079e                	slli	a5,a5,0x7
}
    80001ddc:	00010517          	auipc	a0,0x10
    80001de0:	b8c50513          	addi	a0,a0,-1140 # 80011968 <cpus>
    80001de4:	953e                	add	a0,a0,a5
    80001de6:	6422                	ld	s0,8(sp)
    80001de8:	0141                	addi	sp,sp,16
    80001dea:	8082                	ret

0000000080001dec <myproc>:
myproc(void) {
    80001dec:	1101                	addi	sp,sp,-32
    80001dee:	ec06                	sd	ra,24(sp)
    80001df0:	e822                	sd	s0,16(sp)
    80001df2:	e426                	sd	s1,8(sp)
    80001df4:	1000                	addi	s0,sp,32
  push_off();
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	e18080e7          	jalr	-488(ra) # 80000c0e <push_off>
    80001dfe:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001e00:	2781                	sext.w	a5,a5
    80001e02:	079e                	slli	a5,a5,0x7
    80001e04:	00010717          	auipc	a4,0x10
    80001e08:	b4c70713          	addi	a4,a4,-1204 # 80011950 <pid_lock>
    80001e0c:	97ba                	add	a5,a5,a4
    80001e0e:	6f84                	ld	s1,24(a5)
  pop_off();
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	e9e080e7          	jalr	-354(ra) # 80000cae <pop_off>
}
    80001e18:	8526                	mv	a0,s1
    80001e1a:	60e2                	ld	ra,24(sp)
    80001e1c:	6442                	ld	s0,16(sp)
    80001e1e:	64a2                	ld	s1,8(sp)
    80001e20:	6105                	addi	sp,sp,32
    80001e22:	8082                	ret

0000000080001e24 <forkret>:
{
    80001e24:	1141                	addi	sp,sp,-16
    80001e26:	e406                	sd	ra,8(sp)
    80001e28:	e022                	sd	s0,0(sp)
    80001e2a:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001e2c:	00000097          	auipc	ra,0x0
    80001e30:	fc0080e7          	jalr	-64(ra) # 80001dec <myproc>
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	eda080e7          	jalr	-294(ra) # 80000d0e <release>
  if (first) {
    80001e3c:	00007797          	auipc	a5,0x7
    80001e40:	ca47a783          	lw	a5,-860(a5) # 80008ae0 <first.1725>
    80001e44:	eb89                	bnez	a5,80001e56 <forkret+0x32>
  usertrapret();
    80001e46:	00001097          	auipc	ra,0x1
    80001e4a:	df8080e7          	jalr	-520(ra) # 80002c3e <usertrapret>
}
    80001e4e:	60a2                	ld	ra,8(sp)
    80001e50:	6402                	ld	s0,0(sp)
    80001e52:	0141                	addi	sp,sp,16
    80001e54:	8082                	ret
    first = 0;
    80001e56:	00007797          	auipc	a5,0x7
    80001e5a:	c807a523          	sw	zero,-886(a5) # 80008ae0 <first.1725>
    fsinit(ROOTDEV);
    80001e5e:	4505                	li	a0,1
    80001e60:	00002097          	auipc	ra,0x2
    80001e64:	bfc080e7          	jalr	-1028(ra) # 80003a5c <fsinit>
    80001e68:	bff9                	j	80001e46 <forkret+0x22>

0000000080001e6a <allocpid>:
allocpid() {
    80001e6a:	1101                	addi	sp,sp,-32
    80001e6c:	ec06                	sd	ra,24(sp)
    80001e6e:	e822                	sd	s0,16(sp)
    80001e70:	e426                	sd	s1,8(sp)
    80001e72:	e04a                	sd	s2,0(sp)
    80001e74:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001e76:	00010917          	auipc	s2,0x10
    80001e7a:	ada90913          	addi	s2,s2,-1318 # 80011950 <pid_lock>
    80001e7e:	854a                	mv	a0,s2
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	dda080e7          	jalr	-550(ra) # 80000c5a <acquire>
  pid = nextpid;
    80001e88:	00007797          	auipc	a5,0x7
    80001e8c:	c5c78793          	addi	a5,a5,-932 # 80008ae4 <nextpid>
    80001e90:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001e92:	0014871b          	addiw	a4,s1,1
    80001e96:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001e98:	854a                	mv	a0,s2
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	e74080e7          	jalr	-396(ra) # 80000d0e <release>
}
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	60e2                	ld	ra,24(sp)
    80001ea6:	6442                	ld	s0,16(sp)
    80001ea8:	64a2                	ld	s1,8(sp)
    80001eaa:	6902                	ld	s2,0(sp)
    80001eac:	6105                	addi	sp,sp,32
    80001eae:	8082                	ret

0000000080001eb0 <proc_pagetable>:
{
    80001eb0:	1101                	addi	sp,sp,-32
    80001eb2:	ec06                	sd	ra,24(sp)
    80001eb4:	e822                	sd	s0,16(sp)
    80001eb6:	e426                	sd	s1,8(sp)
    80001eb8:	e04a                	sd	s2,0(sp)
    80001eba:	1000                	addi	s0,sp,32
    80001ebc:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	5c2080e7          	jalr	1474(ra) # 80001480 <uvmcreate>
    80001ec6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ec8:	c121                	beqz	a0,80001f08 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001eca:	4729                	li	a4,10
    80001ecc:	00005697          	auipc	a3,0x5
    80001ed0:	13468693          	addi	a3,a3,308 # 80007000 <_trampoline>
    80001ed4:	6605                	lui	a2,0x1
    80001ed6:	040005b7          	lui	a1,0x4000
    80001eda:	15fd                	addi	a1,a1,-1
    80001edc:	05b2                	slli	a1,a1,0xc
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	346080e7          	jalr	838(ra) # 80001224 <mappages>
    80001ee6:	02054863          	bltz	a0,80001f16 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001eea:	4719                	li	a4,6
    80001eec:	05893683          	ld	a3,88(s2)
    80001ef0:	6605                	lui	a2,0x1
    80001ef2:	020005b7          	lui	a1,0x2000
    80001ef6:	15fd                	addi	a1,a1,-1
    80001ef8:	05b6                	slli	a1,a1,0xd
    80001efa:	8526                	mv	a0,s1
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	328080e7          	jalr	808(ra) # 80001224 <mappages>
    80001f04:	02054163          	bltz	a0,80001f26 <proc_pagetable+0x76>
}
    80001f08:	8526                	mv	a0,s1
    80001f0a:	60e2                	ld	ra,24(sp)
    80001f0c:	6442                	ld	s0,16(sp)
    80001f0e:	64a2                	ld	s1,8(sp)
    80001f10:	6902                	ld	s2,0(sp)
    80001f12:	6105                	addi	sp,sp,32
    80001f14:	8082                	ret
    uvmfree(pagetable, 0);
    80001f16:	4581                	li	a1,0
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	7c0080e7          	jalr	1984(ra) # 800016da <uvmfree>
    return 0;
    80001f22:	4481                	li	s1,0
    80001f24:	b7d5                	j	80001f08 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f26:	4681                	li	a3,0
    80001f28:	4605                	li	a2,1
    80001f2a:	040005b7          	lui	a1,0x4000
    80001f2e:	15fd                	addi	a1,a1,-1
    80001f30:	05b2                	slli	a1,a1,0xc
    80001f32:	8526                	mv	a0,s1
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	488080e7          	jalr	1160(ra) # 800013bc <uvmunmap>
    uvmfree(pagetable, 0);
    80001f3c:	4581                	li	a1,0
    80001f3e:	8526                	mv	a0,s1
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	79a080e7          	jalr	1946(ra) # 800016da <uvmfree>
    return 0;
    80001f48:	4481                	li	s1,0
    80001f4a:	bf7d                	j	80001f08 <proc_pagetable+0x58>

0000000080001f4c <proc_freepagetable>:
{
    80001f4c:	1101                	addi	sp,sp,-32
    80001f4e:	ec06                	sd	ra,24(sp)
    80001f50:	e822                	sd	s0,16(sp)
    80001f52:	e426                	sd	s1,8(sp)
    80001f54:	e04a                	sd	s2,0(sp)
    80001f56:	1000                	addi	s0,sp,32
    80001f58:	84aa                	mv	s1,a0
    80001f5a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f5c:	4681                	li	a3,0
    80001f5e:	4605                	li	a2,1
    80001f60:	040005b7          	lui	a1,0x4000
    80001f64:	15fd                	addi	a1,a1,-1
    80001f66:	05b2                	slli	a1,a1,0xc
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	454080e7          	jalr	1108(ra) # 800013bc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f70:	4681                	li	a3,0
    80001f72:	4605                	li	a2,1
    80001f74:	020005b7          	lui	a1,0x2000
    80001f78:	15fd                	addi	a1,a1,-1
    80001f7a:	05b6                	slli	a1,a1,0xd
    80001f7c:	8526                	mv	a0,s1
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	43e080e7          	jalr	1086(ra) # 800013bc <uvmunmap>
  uvmfree(pagetable, sz);
    80001f86:	85ca                	mv	a1,s2
    80001f88:	8526                	mv	a0,s1
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	750080e7          	jalr	1872(ra) # 800016da <uvmfree>
}
    80001f92:	60e2                	ld	ra,24(sp)
    80001f94:	6442                	ld	s0,16(sp)
    80001f96:	64a2                	ld	s1,8(sp)
    80001f98:	6902                	ld	s2,0(sp)
    80001f9a:	6105                	addi	sp,sp,32
    80001f9c:	8082                	ret

0000000080001f9e <freeproc>:
{
    80001f9e:	1101                	addi	sp,sp,-32
    80001fa0:	ec06                	sd	ra,24(sp)
    80001fa2:	e822                	sd	s0,16(sp)
    80001fa4:	e426                	sd	s1,8(sp)
    80001fa6:	1000                	addi	s0,sp,32
    80001fa8:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001faa:	6d28                	ld	a0,88(a0)
    80001fac:	c509                	beqz	a0,80001fb6 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	a76080e7          	jalr	-1418(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001fb6:	0404bc23          	sd	zero,88(s1) # fffffffffffff058 <end+0xffffffff7ffd8038>
  if(p->pagetable)
    80001fba:	68a8                	ld	a0,80(s1)
    80001fbc:	c511                	beqz	a0,80001fc8 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001fbe:	64ac                	ld	a1,72(s1)
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	f8c080e7          	jalr	-116(ra) # 80001f4c <proc_freepagetable>
  p->pagetable = 0;
    80001fc8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001fcc:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001fd0:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001fd4:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001fd8:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001fdc:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001fe0:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001fe4:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001fe8:	0004ac23          	sw	zero,24(s1)
  if (p->kpagetable) {
    80001fec:	1704b783          	ld	a5,368(s1)
    80001ff0:	cb81                	beqz	a5,80002000 <freeproc+0x62>
    freeprockvm(p);
    80001ff2:	8526                	mv	a0,s1
    80001ff4:	00000097          	auipc	ra,0x0
    80001ff8:	c00080e7          	jalr	-1024(ra) # 80001bf4 <freeprockvm>
    p->kpagetable = 0;
    80001ffc:	1604b823          	sd	zero,368(s1)
  if (p->kstack) {
    80002000:	60bc                	ld	a5,64(s1)
    80002002:	c399                	beqz	a5,80002008 <freeproc+0x6a>
    p->kstack = 0;
    80002004:	0404b023          	sd	zero,64(s1)
}
    80002008:	60e2                	ld	ra,24(sp)
    8000200a:	6442                	ld	s0,16(sp)
    8000200c:	64a2                	ld	s1,8(sp)
    8000200e:	6105                	addi	sp,sp,32
    80002010:	8082                	ret

0000000080002012 <allocproc>:
{
    80002012:	7179                	addi	sp,sp,-48
    80002014:	f406                	sd	ra,40(sp)
    80002016:	f022                	sd	s0,32(sp)
    80002018:	ec26                	sd	s1,24(sp)
    8000201a:	e84a                	sd	s2,16(sp)
    8000201c:	e44e                	sd	s3,8(sp)
    8000201e:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80002020:	00010497          	auipc	s1,0x10
    80002024:	d4848493          	addi	s1,s1,-696 # 80011d68 <proc>
    80002028:	00016917          	auipc	s2,0x16
    8000202c:	b4090913          	addi	s2,s2,-1216 # 80017b68 <tickslock>
    acquire(&p->lock);
    80002030:	8526                	mv	a0,s1
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	c28080e7          	jalr	-984(ra) # 80000c5a <acquire>
    if(p->state == UNUSED) {
    8000203a:	4c9c                	lw	a5,24(s1)
    8000203c:	cf81                	beqz	a5,80002054 <allocproc+0x42>
      release(&p->lock);
    8000203e:	8526                	mv	a0,s1
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	cce080e7          	jalr	-818(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002048:	17848493          	addi	s1,s1,376
    8000204c:	ff2492e3          	bne	s1,s2,80002030 <allocproc+0x1e>
  return 0;
    80002050:	4481                	li	s1,0
    80002052:	a87d                	j	80002110 <allocproc+0xfe>
  p->pid = allocpid();
    80002054:	00000097          	auipc	ra,0x0
    80002058:	e16080e7          	jalr	-490(ra) # 80001e6a <allocpid>
    8000205c:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	ac2080e7          	jalr	-1342(ra) # 80000b20 <kalloc>
    80002066:	892a                	mv	s2,a0
    80002068:	eca8                	sd	a0,88(s1)
    8000206a:	c95d                	beqz	a0,80002120 <allocproc+0x10e>
  p->pagetable = proc_pagetable(p);
    8000206c:	8526                	mv	a0,s1
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	e42080e7          	jalr	-446(ra) # 80001eb0 <proc_pagetable>
    80002076:	892a                	mv	s2,a0
    80002078:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    8000207a:	c955                	beqz	a0,8000212e <allocproc+0x11c>
  p->kpagetable = ukvminit();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	a0e080e7          	jalr	-1522(ra) # 80001a8a <ukvminit>
    80002084:	892a                	mv	s2,a0
    80002086:	16a4b823          	sd	a0,368(s1)
  if(p->kpagetable == 0) {
    8000208a:	cd55                	beqz	a0,80002146 <allocproc+0x134>
  uint64 va = KSTACK((int) (p - proc));
    8000208c:	00010797          	auipc	a5,0x10
    80002090:	cdc78793          	addi	a5,a5,-804 # 80011d68 <proc>
    80002094:	40f487b3          	sub	a5,s1,a5
    80002098:	878d                	srai	a5,a5,0x3
    8000209a:	00006717          	auipc	a4,0x6
    8000209e:	f6673703          	ld	a4,-154(a4) # 80008000 <etext>
    800020a2:	02e787b3          	mul	a5,a5,a4
    800020a6:	2785                	addiw	a5,a5,1
    800020a8:	00d7979b          	slliw	a5,a5,0xd
    800020ac:	04000937          	lui	s2,0x4000
    800020b0:	197d                	addi	s2,s2,-1
    800020b2:	0932                	slli	s2,s2,0xc
    800020b4:	40f90933          	sub	s2,s2,a5
  pte_t pa = kvmpa(va);
    800020b8:	854a                	mv	a0,s2
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	094080e7          	jalr	148(ra) # 8000114e <kvmpa>
    800020c2:	89aa                	mv	s3,a0
  memset((void *)pa, 0, PGSIZE);
    800020c4:	6605                	lui	a2,0x1
    800020c6:	4581                	li	a1,0
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	c8e080e7          	jalr	-882(ra) # 80000d56 <memset>
  ukvmmap(p->kpagetable, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800020d0:	4719                	li	a4,6
    800020d2:	6685                	lui	a3,0x1
    800020d4:	864e                	mv	a2,s3
    800020d6:	85ca                	mv	a1,s2
    800020d8:	1704b503          	ld	a0,368(s1)
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	97e080e7          	jalr	-1666(ra) # 80001a5a <ukvmmap>
  p->kstack = va;
    800020e4:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    800020e8:	07000613          	li	a2,112
    800020ec:	4581                	li	a1,0
    800020ee:	06048513          	addi	a0,s1,96
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	c64080e7          	jalr	-924(ra) # 80000d56 <memset>
  p->context.ra = (uint64)forkret;
    800020fa:	00000797          	auipc	a5,0x0
    800020fe:	d2a78793          	addi	a5,a5,-726 # 80001e24 <forkret>
    80002102:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002104:	60bc                	ld	a5,64(s1)
    80002106:	6705                	lui	a4,0x1
    80002108:	97ba                	add	a5,a5,a4
    8000210a:	f4bc                	sd	a5,104(s1)
  p->tracemask = 0;
    8000210c:	1604b423          	sd	zero,360(s1)
}
    80002110:	8526                	mv	a0,s1
    80002112:	70a2                	ld	ra,40(sp)
    80002114:	7402                	ld	s0,32(sp)
    80002116:	64e2                	ld	s1,24(sp)
    80002118:	6942                	ld	s2,16(sp)
    8000211a:	69a2                	ld	s3,8(sp)
    8000211c:	6145                	addi	sp,sp,48
    8000211e:	8082                	ret
    release(&p->lock);
    80002120:	8526                	mv	a0,s1
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	bec080e7          	jalr	-1044(ra) # 80000d0e <release>
    return 0;
    8000212a:	84ca                	mv	s1,s2
    8000212c:	b7d5                	j	80002110 <allocproc+0xfe>
    freeproc(p);
    8000212e:	8526                	mv	a0,s1
    80002130:	00000097          	auipc	ra,0x0
    80002134:	e6e080e7          	jalr	-402(ra) # 80001f9e <freeproc>
    release(&p->lock);
    80002138:	8526                	mv	a0,s1
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	bd4080e7          	jalr	-1068(ra) # 80000d0e <release>
    return 0;
    80002142:	84ca                	mv	s1,s2
    80002144:	b7f1                	j	80002110 <allocproc+0xfe>
    freeproc(p);
    80002146:	8526                	mv	a0,s1
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	e56080e7          	jalr	-426(ra) # 80001f9e <freeproc>
    release(&p->lock);
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	bbc080e7          	jalr	-1092(ra) # 80000d0e <release>
    return 0;
    8000215a:	84ca                	mv	s1,s2
    8000215c:	bf55                	j	80002110 <allocproc+0xfe>

000000008000215e <userinit>:
{
    8000215e:	1101                	addi	sp,sp,-32
    80002160:	ec06                	sd	ra,24(sp)
    80002162:	e822                	sd	s0,16(sp)
    80002164:	e426                	sd	s1,8(sp)
    80002166:	e04a                	sd	s2,0(sp)
    80002168:	1000                	addi	s0,sp,32
  p = allocproc();
    8000216a:	00000097          	auipc	ra,0x0
    8000216e:	ea8080e7          	jalr	-344(ra) # 80002012 <allocproc>
    80002172:	84aa                	mv	s1,a0
  initproc = p;
    80002174:	00007797          	auipc	a5,0x7
    80002178:	eaa7b223          	sd	a0,-348(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000217c:	03400613          	li	a2,52
    80002180:	00007597          	auipc	a1,0x7
    80002184:	97058593          	addi	a1,a1,-1680 # 80008af0 <initcode>
    80002188:	6928                	ld	a0,80(a0)
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	324080e7          	jalr	804(ra) # 800014ae <uvminit>
  p->sz = PGSIZE;
    80002192:	6905                	lui	s2,0x1
    80002194:	0524b423          	sd	s2,72(s1)
  pagecopy(p->pagetable, p->kpagetable, 0, p->sz);
    80002198:	6685                	lui	a3,0x1
    8000219a:	4601                	li	a2,0
    8000219c:	1704b583          	ld	a1,368(s1)
    800021a0:	68a8                	ld	a0,80(s1)
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	570080e7          	jalr	1392(ra) # 80001712 <pagecopy>
  p->trapframe->epc = 0;      // user program counter
    800021aa:	6cbc                	ld	a5,88(s1)
    800021ac:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021b0:	6cbc                	ld	a5,88(s1)
    800021b2:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021b6:	4641                	li	a2,16
    800021b8:	00006597          	auipc	a1,0x6
    800021bc:	13858593          	addi	a1,a1,312 # 800082f0 <indent.1822+0x40>
    800021c0:	15848513          	addi	a0,s1,344
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	ce8080e7          	jalr	-792(ra) # 80000eac <safestrcpy>
  p->cwd = namei("/");
    800021cc:	00006517          	auipc	a0,0x6
    800021d0:	13450513          	addi	a0,a0,308 # 80008300 <indent.1822+0x50>
    800021d4:	00002097          	auipc	ra,0x2
    800021d8:	2b0080e7          	jalr	688(ra) # 80004484 <namei>
    800021dc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800021e0:	4789                	li	a5,2
    800021e2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800021e4:	8526                	mv	a0,s1
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	b28080e7          	jalr	-1240(ra) # 80000d0e <release>
}
    800021ee:	60e2                	ld	ra,24(sp)
    800021f0:	6442                	ld	s0,16(sp)
    800021f2:	64a2                	ld	s1,8(sp)
    800021f4:	6902                	ld	s2,0(sp)
    800021f6:	6105                	addi	sp,sp,32
    800021f8:	8082                	ret

00000000800021fa <growproc>:
{
    800021fa:	7179                	addi	sp,sp,-48
    800021fc:	f406                	sd	ra,40(sp)
    800021fe:	f022                	sd	s0,32(sp)
    80002200:	ec26                	sd	s1,24(sp)
    80002202:	e84a                	sd	s2,16(sp)
    80002204:	e44e                	sd	s3,8(sp)
    80002206:	1800                	addi	s0,sp,48
    80002208:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	be2080e7          	jalr	-1054(ra) # 80001dec <myproc>
    80002212:	84aa                	mv	s1,a0
  sz = p->sz;
    80002214:	652c                	ld	a1,72(a0)
    80002216:	0005899b          	sext.w	s3,a1
  if(n > 0){
    8000221a:	07205663          	blez	s2,80002286 <growproc+0x8c>
    if (sz + n > PLIC || (sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000221e:	0139093b          	addw	s2,s2,s3
    80002222:	0009071b          	sext.w	a4,s2
    80002226:	0c0007b7          	lui	a5,0xc000
    8000222a:	0ae7ec63          	bltu	a5,a4,800022e2 <growproc+0xe8>
    8000222e:	02091613          	slli	a2,s2,0x20
    80002232:	9201                	srli	a2,a2,0x20
    80002234:	1582                	slli	a1,a1,0x20
    80002236:	9181                	srli	a1,a1,0x20
    80002238:	6928                	ld	a0,80(a0)
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	32e080e7          	jalr	814(ra) # 80001568 <uvmalloc>
    80002242:	0005099b          	sext.w	s3,a0
    80002246:	0a098063          	beqz	s3,800022e6 <growproc+0xec>
    if (pagecopy(p->pagetable, p->kpagetable, p->sz, sz) != 0) {
    8000224a:	02051693          	slli	a3,a0,0x20
    8000224e:	9281                	srli	a3,a3,0x20
    80002250:	64b0                	ld	a2,72(s1)
    80002252:	1704b583          	ld	a1,368(s1)
    80002256:	68a8                	ld	a0,80(s1)
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	4ba080e7          	jalr	1210(ra) # 80001712 <pagecopy>
    80002260:	e549                	bnez	a0,800022ea <growproc+0xf0>
  ukvminithard(p->kpagetable);
    80002262:	1704b503          	ld	a0,368(s1)
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	dc0080e7          	jalr	-576(ra) # 80001026 <ukvminithard>
  p->sz = sz;
    8000226e:	02099613          	slli	a2,s3,0x20
    80002272:	9201                	srli	a2,a2,0x20
    80002274:	e4b0                	sd	a2,72(s1)
  return 0;
    80002276:	4501                	li	a0,0
}
    80002278:	70a2                	ld	ra,40(sp)
    8000227a:	7402                	ld	s0,32(sp)
    8000227c:	64e2                	ld	s1,24(sp)
    8000227e:	6942                	ld	s2,16(sp)
    80002280:	69a2                	ld	s3,8(sp)
    80002282:	6145                	addi	sp,sp,48
    80002284:	8082                	ret
  } else if(n < 0){
    80002286:	fc095ee3          	bgez	s2,80002262 <growproc+0x68>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000228a:	0139063b          	addw	a2,s2,s3
    8000228e:	557d                	li	a0,-1
    80002290:	02055913          	srli	s2,a0,0x20
    80002294:	1602                	slli	a2,a2,0x20
    80002296:	9201                	srli	a2,a2,0x20
    80002298:	0125f5b3          	and	a1,a1,s2
    8000229c:	68a8                	ld	a0,80(s1)
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	282080e7          	jalr	642(ra) # 80001520 <uvmdealloc>
    800022a6:	0005099b          	sext.w	s3,a0
    if (sz != p->sz) {
    800022aa:	64bc                	ld	a5,72(s1)
    800022ac:	01257533          	and	a0,a0,s2
    800022b0:	faa789e3          	beq	a5,a0,80002262 <growproc+0x68>
      uvmunmap(p->kpagetable, PGROUNDUP(sz), (PGROUNDUP(p->sz) - PGROUNDUP(sz)) / PGSIZE, 0);
    800022b4:	6585                	lui	a1,0x1
    800022b6:	35fd                	addiw	a1,a1,-1
    800022b8:	00b985bb          	addw	a1,s3,a1
    800022bc:	777d                	lui	a4,0xfffff
    800022be:	8df9                	and	a1,a1,a4
    800022c0:	1582                	slli	a1,a1,0x20
    800022c2:	9181                	srli	a1,a1,0x20
    800022c4:	6605                	lui	a2,0x1
    800022c6:	167d                	addi	a2,a2,-1
    800022c8:	963e                	add	a2,a2,a5
    800022ca:	77fd                	lui	a5,0xfffff
    800022cc:	8e7d                	and	a2,a2,a5
    800022ce:	8e0d                	sub	a2,a2,a1
    800022d0:	4681                	li	a3,0
    800022d2:	8231                	srli	a2,a2,0xc
    800022d4:	1704b503          	ld	a0,368(s1)
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	0e4080e7          	jalr	228(ra) # 800013bc <uvmunmap>
    800022e0:	b749                	j	80002262 <growproc+0x68>
      return -1;
    800022e2:	557d                	li	a0,-1
    800022e4:	bf51                	j	80002278 <growproc+0x7e>
    800022e6:	557d                	li	a0,-1
    800022e8:	bf41                	j	80002278 <growproc+0x7e>
      return -1;
    800022ea:	557d                	li	a0,-1
    800022ec:	b771                	j	80002278 <growproc+0x7e>

00000000800022ee <fork>:
{
    800022ee:	7179                	addi	sp,sp,-48
    800022f0:	f406                	sd	ra,40(sp)
    800022f2:	f022                	sd	s0,32(sp)
    800022f4:	ec26                	sd	s1,24(sp)
    800022f6:	e84a                	sd	s2,16(sp)
    800022f8:	e44e                	sd	s3,8(sp)
    800022fa:	e052                	sd	s4,0(sp)
    800022fc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022fe:	00000097          	auipc	ra,0x0
    80002302:	aee080e7          	jalr	-1298(ra) # 80001dec <myproc>
    80002306:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002308:	00000097          	auipc	ra,0x0
    8000230c:	d0a080e7          	jalr	-758(ra) # 80002012 <allocproc>
    80002310:	10050d63          	beqz	a0,8000242a <fork+0x13c>
    80002314:	89aa                	mv	s3,a0
  np->tracemask = p->tracemask;
    80002316:	16893783          	ld	a5,360(s2) # 1168 <_entry-0x7fffee98>
    8000231a:	16f53423          	sd	a5,360(a0)
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000231e:	04893603          	ld	a2,72(s2)
    80002322:	692c                	ld	a1,80(a0)
    80002324:	05093503          	ld	a0,80(s2)
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	492080e7          	jalr	1170(ra) # 800017ba <uvmcopy>
    80002330:	06054263          	bltz	a0,80002394 <fork+0xa6>
  np->sz = p->sz;
    80002334:	04893683          	ld	a3,72(s2)
    80002338:	04d9b423          	sd	a3,72(s3) # 4000048 <_entry-0x7bffffb8>
  if (pagecopy(np->pagetable, np->kpagetable, 0, np->sz) != 0) {
    8000233c:	4601                	li	a2,0
    8000233e:	1709b583          	ld	a1,368(s3)
    80002342:	0509b503          	ld	a0,80(s3)
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	3cc080e7          	jalr	972(ra) # 80001712 <pagecopy>
    8000234e:	ed39                	bnez	a0,800023ac <fork+0xbe>
  np->parent = p;
    80002350:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80002354:	05893683          	ld	a3,88(s2)
    80002358:	87b6                	mv	a5,a3
    8000235a:	0589b703          	ld	a4,88(s3)
    8000235e:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    80002362:	0007b803          	ld	a6,0(a5) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    80002366:	6788                	ld	a0,8(a5)
    80002368:	6b8c                	ld	a1,16(a5)
    8000236a:	6f90                	ld	a2,24(a5)
    8000236c:	01073023          	sd	a6,0(a4) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    80002370:	e708                	sd	a0,8(a4)
    80002372:	eb0c                	sd	a1,16(a4)
    80002374:	ef10                	sd	a2,24(a4)
    80002376:	02078793          	addi	a5,a5,32
    8000237a:	02070713          	addi	a4,a4,32
    8000237e:	fed792e3          	bne	a5,a3,80002362 <fork+0x74>
  np->trapframe->a0 = 0;
    80002382:	0589b783          	ld	a5,88(s3)
    80002386:	0607b823          	sd	zero,112(a5)
    8000238a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    8000238e:	15000a13          	li	s4,336
    80002392:	a099                	j	800023d8 <fork+0xea>
    freeproc(np);
    80002394:	854e                	mv	a0,s3
    80002396:	00000097          	auipc	ra,0x0
    8000239a:	c08080e7          	jalr	-1016(ra) # 80001f9e <freeproc>
    release(&np->lock);
    8000239e:	854e                	mv	a0,s3
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	96e080e7          	jalr	-1682(ra) # 80000d0e <release>
    return -1;
    800023a8:	54fd                	li	s1,-1
    800023aa:	a0bd                	j	80002418 <fork+0x12a>
    freeproc(np);
    800023ac:	854e                	mv	a0,s3
    800023ae:	00000097          	auipc	ra,0x0
    800023b2:	bf0080e7          	jalr	-1040(ra) # 80001f9e <freeproc>
    release(&np->lock);
    800023b6:	854e                	mv	a0,s3
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	956080e7          	jalr	-1706(ra) # 80000d0e <release>
    return -1;
    800023c0:	54fd                	li	s1,-1
    800023c2:	a899                	j	80002418 <fork+0x12a>
      np->ofile[i] = filedup(p->ofile[i]);
    800023c4:	00002097          	auipc	ra,0x2
    800023c8:	74c080e7          	jalr	1868(ra) # 80004b10 <filedup>
    800023cc:	009987b3          	add	a5,s3,s1
    800023d0:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800023d2:	04a1                	addi	s1,s1,8
    800023d4:	01448763          	beq	s1,s4,800023e2 <fork+0xf4>
    if(p->ofile[i])
    800023d8:	009907b3          	add	a5,s2,s1
    800023dc:	6388                	ld	a0,0(a5)
    800023de:	f17d                	bnez	a0,800023c4 <fork+0xd6>
    800023e0:	bfcd                	j	800023d2 <fork+0xe4>
  np->cwd = idup(p->cwd);
    800023e2:	15093503          	ld	a0,336(s2)
    800023e6:	00002097          	auipc	ra,0x2
    800023ea:	8b0080e7          	jalr	-1872(ra) # 80003c96 <idup>
    800023ee:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800023f2:	4641                	li	a2,16
    800023f4:	15890593          	addi	a1,s2,344
    800023f8:	15898513          	addi	a0,s3,344
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	ab0080e7          	jalr	-1360(ra) # 80000eac <safestrcpy>
  pid = np->pid;
    80002404:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80002408:	4789                	li	a5,2
    8000240a:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000240e:	854e                	mv	a0,s3
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	8fe080e7          	jalr	-1794(ra) # 80000d0e <release>
}
    80002418:	8526                	mv	a0,s1
    8000241a:	70a2                	ld	ra,40(sp)
    8000241c:	7402                	ld	s0,32(sp)
    8000241e:	64e2                	ld	s1,24(sp)
    80002420:	6942                	ld	s2,16(sp)
    80002422:	69a2                	ld	s3,8(sp)
    80002424:	6a02                	ld	s4,0(sp)
    80002426:	6145                	addi	sp,sp,48
    80002428:	8082                	ret
    return -1;
    8000242a:	54fd                	li	s1,-1
    8000242c:	b7f5                	j	80002418 <fork+0x12a>

000000008000242e <reparent>:
{
    8000242e:	7179                	addi	sp,sp,-48
    80002430:	f406                	sd	ra,40(sp)
    80002432:	f022                	sd	s0,32(sp)
    80002434:	ec26                	sd	s1,24(sp)
    80002436:	e84a                	sd	s2,16(sp)
    80002438:	e44e                	sd	s3,8(sp)
    8000243a:	e052                	sd	s4,0(sp)
    8000243c:	1800                	addi	s0,sp,48
    8000243e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002440:	00010497          	auipc	s1,0x10
    80002444:	92848493          	addi	s1,s1,-1752 # 80011d68 <proc>
      pp->parent = initproc;
    80002448:	00007a17          	auipc	s4,0x7
    8000244c:	bd0a0a13          	addi	s4,s4,-1072 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002450:	00015997          	auipc	s3,0x15
    80002454:	71898993          	addi	s3,s3,1816 # 80017b68 <tickslock>
    80002458:	a029                	j	80002462 <reparent+0x34>
    8000245a:	17848493          	addi	s1,s1,376
    8000245e:	03348363          	beq	s1,s3,80002484 <reparent+0x56>
    if(pp->parent == p){
    80002462:	709c                	ld	a5,32(s1)
    80002464:	ff279be3          	bne	a5,s2,8000245a <reparent+0x2c>
      acquire(&pp->lock);
    80002468:	8526                	mv	a0,s1
    8000246a:	ffffe097          	auipc	ra,0xffffe
    8000246e:	7f0080e7          	jalr	2032(ra) # 80000c5a <acquire>
      pp->parent = initproc;
    80002472:	000a3783          	ld	a5,0(s4)
    80002476:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	894080e7          	jalr	-1900(ra) # 80000d0e <release>
    80002482:	bfe1                	j	8000245a <reparent+0x2c>
}
    80002484:	70a2                	ld	ra,40(sp)
    80002486:	7402                	ld	s0,32(sp)
    80002488:	64e2                	ld	s1,24(sp)
    8000248a:	6942                	ld	s2,16(sp)
    8000248c:	69a2                	ld	s3,8(sp)
    8000248e:	6a02                	ld	s4,0(sp)
    80002490:	6145                	addi	sp,sp,48
    80002492:	8082                	ret

0000000080002494 <scheduler>:
{
    80002494:	715d                	addi	sp,sp,-80
    80002496:	e486                	sd	ra,72(sp)
    80002498:	e0a2                	sd	s0,64(sp)
    8000249a:	fc26                	sd	s1,56(sp)
    8000249c:	f84a                	sd	s2,48(sp)
    8000249e:	f44e                	sd	s3,40(sp)
    800024a0:	f052                	sd	s4,32(sp)
    800024a2:	ec56                	sd	s5,24(sp)
    800024a4:	e85a                	sd	s6,16(sp)
    800024a6:	e45e                	sd	s7,8(sp)
    800024a8:	e062                	sd	s8,0(sp)
    800024aa:	0880                	addi	s0,sp,80
    800024ac:	8792                	mv	a5,tp
  int id = r_tp();
    800024ae:	2781                	sext.w	a5,a5
  c->proc = 0;
    800024b0:	00779b13          	slli	s6,a5,0x7
    800024b4:	0000f717          	auipc	a4,0xf
    800024b8:	49c70713          	addi	a4,a4,1180 # 80011950 <pid_lock>
    800024bc:	975a                	add	a4,a4,s6
    800024be:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    800024c2:	0000f717          	auipc	a4,0xf
    800024c6:	4ae70713          	addi	a4,a4,1198 # 80011970 <cpus+0x8>
    800024ca:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    800024cc:	4c0d                	li	s8,3
        c->proc = p;
    800024ce:	079e                	slli	a5,a5,0x7
    800024d0:	0000fa17          	auipc	s4,0xf
    800024d4:	480a0a13          	addi	s4,s4,1152 # 80011950 <pid_lock>
    800024d8:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800024da:	00015997          	auipc	s3,0x15
    800024de:	68e98993          	addi	s3,s3,1678 # 80017b68 <tickslock>
        found = 1;
    800024e2:	4b85                	li	s7,1
    800024e4:	a0ad                	j	8000254e <scheduler+0xba>
        p->state = RUNNING;
    800024e6:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    800024ea:	009a3c23          	sd	s1,24(s4)
        ukvminithard(p->kpagetable);
    800024ee:	1704b503          	ld	a0,368(s1)
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	b34080e7          	jalr	-1228(ra) # 80001026 <ukvminithard>
        swtch(&c->context, &p->context);
    800024fa:	06048593          	addi	a1,s1,96
    800024fe:	855a                	mv	a0,s6
    80002500:	00000097          	auipc	ra,0x0
    80002504:	694080e7          	jalr	1684(ra) # 80002b94 <swtch>
        kvminithart();
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	b3a080e7          	jalr	-1222(ra) # 80001042 <kvminithart>
        c->proc = 0;
    80002510:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80002514:	8ade                	mv	s5,s7
      release(&p->lock);
    80002516:	8526                	mv	a0,s1
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	7f6080e7          	jalr	2038(ra) # 80000d0e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002520:	17848493          	addi	s1,s1,376
    80002524:	01348b63          	beq	s1,s3,8000253a <scheduler+0xa6>
      acquire(&p->lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	730080e7          	jalr	1840(ra) # 80000c5a <acquire>
      if(p->state == RUNNABLE) {
    80002532:	4c9c                	lw	a5,24(s1)
    80002534:	ff2791e3          	bne	a5,s2,80002516 <scheduler+0x82>
    80002538:	b77d                	j	800024e6 <scheduler+0x52>
    if(found == 0) {
    8000253a:	000a9a63          	bnez	s5,8000254e <scheduler+0xba>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000253e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002542:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002546:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000254a:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000254e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002552:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002556:	10079073          	csrw	sstatus,a5
    int found = 0;
    8000255a:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000255c:	00010497          	auipc	s1,0x10
    80002560:	80c48493          	addi	s1,s1,-2036 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002564:	4909                	li	s2,2
    80002566:	b7c9                	j	80002528 <scheduler+0x94>

0000000080002568 <sched>:
{
    80002568:	7179                	addi	sp,sp,-48
    8000256a:	f406                	sd	ra,40(sp)
    8000256c:	f022                	sd	s0,32(sp)
    8000256e:	ec26                	sd	s1,24(sp)
    80002570:	e84a                	sd	s2,16(sp)
    80002572:	e44e                	sd	s3,8(sp)
    80002574:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002576:	00000097          	auipc	ra,0x0
    8000257a:	876080e7          	jalr	-1930(ra) # 80001dec <myproc>
    8000257e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	660080e7          	jalr	1632(ra) # 80000be0 <holding>
    80002588:	c93d                	beqz	a0,800025fe <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000258a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000258c:	2781                	sext.w	a5,a5
    8000258e:	079e                	slli	a5,a5,0x7
    80002590:	0000f717          	auipc	a4,0xf
    80002594:	3c070713          	addi	a4,a4,960 # 80011950 <pid_lock>
    80002598:	97ba                	add	a5,a5,a4
    8000259a:	0907a703          	lw	a4,144(a5)
    8000259e:	4785                	li	a5,1
    800025a0:	06f71763          	bne	a4,a5,8000260e <sched+0xa6>
  if(p->state == RUNNING)
    800025a4:	4c98                	lw	a4,24(s1)
    800025a6:	478d                	li	a5,3
    800025a8:	06f70b63          	beq	a4,a5,8000261e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025ac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800025b0:	8b89                	andi	a5,a5,2
  if(intr_get())
    800025b2:	efb5                	bnez	a5,8000262e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025b4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800025b6:	0000f917          	auipc	s2,0xf
    800025ba:	39a90913          	addi	s2,s2,922 # 80011950 <pid_lock>
    800025be:	2781                	sext.w	a5,a5
    800025c0:	079e                	slli	a5,a5,0x7
    800025c2:	97ca                	add	a5,a5,s2
    800025c4:	0947a983          	lw	s3,148(a5)
    800025c8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800025ca:	2781                	sext.w	a5,a5
    800025cc:	079e                	slli	a5,a5,0x7
    800025ce:	0000f597          	auipc	a1,0xf
    800025d2:	3a258593          	addi	a1,a1,930 # 80011970 <cpus+0x8>
    800025d6:	95be                	add	a1,a1,a5
    800025d8:	06048513          	addi	a0,s1,96
    800025dc:	00000097          	auipc	ra,0x0
    800025e0:	5b8080e7          	jalr	1464(ra) # 80002b94 <swtch>
    800025e4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800025e6:	2781                	sext.w	a5,a5
    800025e8:	079e                	slli	a5,a5,0x7
    800025ea:	97ca                	add	a5,a5,s2
    800025ec:	0937aa23          	sw	s3,148(a5)
}
    800025f0:	70a2                	ld	ra,40(sp)
    800025f2:	7402                	ld	s0,32(sp)
    800025f4:	64e2                	ld	s1,24(sp)
    800025f6:	6942                	ld	s2,16(sp)
    800025f8:	69a2                	ld	s3,8(sp)
    800025fa:	6145                	addi	sp,sp,48
    800025fc:	8082                	ret
    panic("sched p->lock");
    800025fe:	00006517          	auipc	a0,0x6
    80002602:	d0a50513          	addi	a0,a0,-758 # 80008308 <indent.1822+0x58>
    80002606:	ffffe097          	auipc	ra,0xffffe
    8000260a:	f42080e7          	jalr	-190(ra) # 80000548 <panic>
    panic("sched locks");
    8000260e:	00006517          	auipc	a0,0x6
    80002612:	d0a50513          	addi	a0,a0,-758 # 80008318 <indent.1822+0x68>
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	f32080e7          	jalr	-206(ra) # 80000548 <panic>
    panic("sched running");
    8000261e:	00006517          	auipc	a0,0x6
    80002622:	d0a50513          	addi	a0,a0,-758 # 80008328 <indent.1822+0x78>
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	f22080e7          	jalr	-222(ra) # 80000548 <panic>
    panic("sched interruptible");
    8000262e:	00006517          	auipc	a0,0x6
    80002632:	d0a50513          	addi	a0,a0,-758 # 80008338 <indent.1822+0x88>
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	f12080e7          	jalr	-238(ra) # 80000548 <panic>

000000008000263e <exit>:
{
    8000263e:	7179                	addi	sp,sp,-48
    80002640:	f406                	sd	ra,40(sp)
    80002642:	f022                	sd	s0,32(sp)
    80002644:	ec26                	sd	s1,24(sp)
    80002646:	e84a                	sd	s2,16(sp)
    80002648:	e44e                	sd	s3,8(sp)
    8000264a:	e052                	sd	s4,0(sp)
    8000264c:	1800                	addi	s0,sp,48
    8000264e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	79c080e7          	jalr	1948(ra) # 80001dec <myproc>
    80002658:	89aa                	mv	s3,a0
  if(p == initproc)
    8000265a:	00007797          	auipc	a5,0x7
    8000265e:	9be7b783          	ld	a5,-1602(a5) # 80009018 <initproc>
    80002662:	0d050493          	addi	s1,a0,208
    80002666:	15050913          	addi	s2,a0,336
    8000266a:	02a79363          	bne	a5,a0,80002690 <exit+0x52>
    panic("init exiting");
    8000266e:	00006517          	auipc	a0,0x6
    80002672:	ce250513          	addi	a0,a0,-798 # 80008350 <indent.1822+0xa0>
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	ed2080e7          	jalr	-302(ra) # 80000548 <panic>
      fileclose(f);
    8000267e:	00002097          	auipc	ra,0x2
    80002682:	4e4080e7          	jalr	1252(ra) # 80004b62 <fileclose>
      p->ofile[fd] = 0;
    80002686:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000268a:	04a1                	addi	s1,s1,8
    8000268c:	01248563          	beq	s1,s2,80002696 <exit+0x58>
    if(p->ofile[fd]){
    80002690:	6088                	ld	a0,0(s1)
    80002692:	f575                	bnez	a0,8000267e <exit+0x40>
    80002694:	bfdd                	j	8000268a <exit+0x4c>
  begin_op();
    80002696:	00002097          	auipc	ra,0x2
    8000269a:	ffa080e7          	jalr	-6(ra) # 80004690 <begin_op>
  iput(p->cwd);
    8000269e:	1509b503          	ld	a0,336(s3)
    800026a2:	00001097          	auipc	ra,0x1
    800026a6:	7ec080e7          	jalr	2028(ra) # 80003e8e <iput>
  end_op();
    800026aa:	00002097          	auipc	ra,0x2
    800026ae:	066080e7          	jalr	102(ra) # 80004710 <end_op>
  p->cwd = 0;
    800026b2:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800026b6:	00007497          	auipc	s1,0x7
    800026ba:	96248493          	addi	s1,s1,-1694 # 80009018 <initproc>
    800026be:	6088                	ld	a0,0(s1)
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	59a080e7          	jalr	1434(ra) # 80000c5a <acquire>
  wakeup1(initproc);
    800026c8:	6088                	ld	a0,0(s1)
    800026ca:	fffff097          	auipc	ra,0xfffff
    800026ce:	5e2080e7          	jalr	1506(ra) # 80001cac <wakeup1>
  release(&initproc->lock);
    800026d2:	6088                	ld	a0,0(s1)
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	63a080e7          	jalr	1594(ra) # 80000d0e <release>
  acquire(&p->lock);
    800026dc:	854e                	mv	a0,s3
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	57c080e7          	jalr	1404(ra) # 80000c5a <acquire>
  struct proc *original_parent = p->parent;
    800026e6:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800026ea:	854e                	mv	a0,s3
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	622080e7          	jalr	1570(ra) # 80000d0e <release>
  acquire(&original_parent->lock);
    800026f4:	8526                	mv	a0,s1
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	564080e7          	jalr	1380(ra) # 80000c5a <acquire>
  acquire(&p->lock);
    800026fe:	854e                	mv	a0,s3
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	55a080e7          	jalr	1370(ra) # 80000c5a <acquire>
  reparent(p);
    80002708:	854e                	mv	a0,s3
    8000270a:	00000097          	auipc	ra,0x0
    8000270e:	d24080e7          	jalr	-732(ra) # 8000242e <reparent>
  wakeup1(original_parent);
    80002712:	8526                	mv	a0,s1
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	598080e7          	jalr	1432(ra) # 80001cac <wakeup1>
  p->xstate = status;
    8000271c:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002720:	4791                	li	a5,4
    80002722:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002726:	8526                	mv	a0,s1
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	5e6080e7          	jalr	1510(ra) # 80000d0e <release>
  sched();
    80002730:	00000097          	auipc	ra,0x0
    80002734:	e38080e7          	jalr	-456(ra) # 80002568 <sched>
  panic("zombie exit");
    80002738:	00006517          	auipc	a0,0x6
    8000273c:	c2850513          	addi	a0,a0,-984 # 80008360 <indent.1822+0xb0>
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	e08080e7          	jalr	-504(ra) # 80000548 <panic>

0000000080002748 <yield>:
{
    80002748:	1101                	addi	sp,sp,-32
    8000274a:	ec06                	sd	ra,24(sp)
    8000274c:	e822                	sd	s0,16(sp)
    8000274e:	e426                	sd	s1,8(sp)
    80002750:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	69a080e7          	jalr	1690(ra) # 80001dec <myproc>
    8000275a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	4fe080e7          	jalr	1278(ra) # 80000c5a <acquire>
  p->state = RUNNABLE;
    80002764:	4789                	li	a5,2
    80002766:	cc9c                	sw	a5,24(s1)
  sched();
    80002768:	00000097          	auipc	ra,0x0
    8000276c:	e00080e7          	jalr	-512(ra) # 80002568 <sched>
  release(&p->lock);
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	59c080e7          	jalr	1436(ra) # 80000d0e <release>
}
    8000277a:	60e2                	ld	ra,24(sp)
    8000277c:	6442                	ld	s0,16(sp)
    8000277e:	64a2                	ld	s1,8(sp)
    80002780:	6105                	addi	sp,sp,32
    80002782:	8082                	ret

0000000080002784 <sleep>:
{
    80002784:	7179                	addi	sp,sp,-48
    80002786:	f406                	sd	ra,40(sp)
    80002788:	f022                	sd	s0,32(sp)
    8000278a:	ec26                	sd	s1,24(sp)
    8000278c:	e84a                	sd	s2,16(sp)
    8000278e:	e44e                	sd	s3,8(sp)
    80002790:	1800                	addi	s0,sp,48
    80002792:	89aa                	mv	s3,a0
    80002794:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002796:	fffff097          	auipc	ra,0xfffff
    8000279a:	656080e7          	jalr	1622(ra) # 80001dec <myproc>
    8000279e:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800027a0:	05250663          	beq	a0,s2,800027ec <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	4b6080e7          	jalr	1206(ra) # 80000c5a <acquire>
    release(lk);
    800027ac:	854a                	mv	a0,s2
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	560080e7          	jalr	1376(ra) # 80000d0e <release>
  p->chan = chan;
    800027b6:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800027ba:	4785                	li	a5,1
    800027bc:	cc9c                	sw	a5,24(s1)
  sched();
    800027be:	00000097          	auipc	ra,0x0
    800027c2:	daa080e7          	jalr	-598(ra) # 80002568 <sched>
  p->chan = 0;
    800027c6:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800027ca:	8526                	mv	a0,s1
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	542080e7          	jalr	1346(ra) # 80000d0e <release>
    acquire(lk);
    800027d4:	854a                	mv	a0,s2
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	484080e7          	jalr	1156(ra) # 80000c5a <acquire>
}
    800027de:	70a2                	ld	ra,40(sp)
    800027e0:	7402                	ld	s0,32(sp)
    800027e2:	64e2                	ld	s1,24(sp)
    800027e4:	6942                	ld	s2,16(sp)
    800027e6:	69a2                	ld	s3,8(sp)
    800027e8:	6145                	addi	sp,sp,48
    800027ea:	8082                	ret
  p->chan = chan;
    800027ec:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800027f0:	4785                	li	a5,1
    800027f2:	cd1c                	sw	a5,24(a0)
  sched();
    800027f4:	00000097          	auipc	ra,0x0
    800027f8:	d74080e7          	jalr	-652(ra) # 80002568 <sched>
  p->chan = 0;
    800027fc:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002800:	bff9                	j	800027de <sleep+0x5a>

0000000080002802 <wait>:
{
    80002802:	715d                	addi	sp,sp,-80
    80002804:	e486                	sd	ra,72(sp)
    80002806:	e0a2                	sd	s0,64(sp)
    80002808:	fc26                	sd	s1,56(sp)
    8000280a:	f84a                	sd	s2,48(sp)
    8000280c:	f44e                	sd	s3,40(sp)
    8000280e:	f052                	sd	s4,32(sp)
    80002810:	ec56                	sd	s5,24(sp)
    80002812:	e85a                	sd	s6,16(sp)
    80002814:	e45e                	sd	s7,8(sp)
    80002816:	e062                	sd	s8,0(sp)
    80002818:	0880                	addi	s0,sp,80
    8000281a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000281c:	fffff097          	auipc	ra,0xfffff
    80002820:	5d0080e7          	jalr	1488(ra) # 80001dec <myproc>
    80002824:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002826:	8c2a                	mv	s8,a0
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	432080e7          	jalr	1074(ra) # 80000c5a <acquire>
    havekids = 0;
    80002830:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002832:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002834:	00015997          	auipc	s3,0x15
    80002838:	33498993          	addi	s3,s3,820 # 80017b68 <tickslock>
        havekids = 1;
    8000283c:	4a85                	li	s5,1
    havekids = 0;
    8000283e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002840:	0000f497          	auipc	s1,0xf
    80002844:	52848493          	addi	s1,s1,1320 # 80011d68 <proc>
    80002848:	a08d                	j	800028aa <wait+0xa8>
          pid = np->pid;
    8000284a:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000284e:	000b0e63          	beqz	s6,8000286a <wait+0x68>
    80002852:	4691                	li	a3,4
    80002854:	03448613          	addi	a2,s1,52
    80002858:	85da                	mv	a1,s6
    8000285a:	05093503          	ld	a0,80(s2)
    8000285e:	fffff097          	auipc	ra,0xfffff
    80002862:	060080e7          	jalr	96(ra) # 800018be <copyout>
    80002866:	02054263          	bltz	a0,8000288a <wait+0x88>
          freeproc(np);
    8000286a:	8526                	mv	a0,s1
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	732080e7          	jalr	1842(ra) # 80001f9e <freeproc>
          release(&np->lock);
    80002874:	8526                	mv	a0,s1
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	498080e7          	jalr	1176(ra) # 80000d0e <release>
          release(&p->lock);
    8000287e:	854a                	mv	a0,s2
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	48e080e7          	jalr	1166(ra) # 80000d0e <release>
          return pid;
    80002888:	a8a9                	j	800028e2 <wait+0xe0>
            release(&np->lock);
    8000288a:	8526                	mv	a0,s1
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	482080e7          	jalr	1154(ra) # 80000d0e <release>
            release(&p->lock);
    80002894:	854a                	mv	a0,s2
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	478080e7          	jalr	1144(ra) # 80000d0e <release>
            return -1;
    8000289e:	59fd                	li	s3,-1
    800028a0:	a089                	j	800028e2 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800028a2:	17848493          	addi	s1,s1,376
    800028a6:	03348463          	beq	s1,s3,800028ce <wait+0xcc>
      if(np->parent == p){
    800028aa:	709c                	ld	a5,32(s1)
    800028ac:	ff279be3          	bne	a5,s2,800028a2 <wait+0xa0>
        acquire(&np->lock);
    800028b0:	8526                	mv	a0,s1
    800028b2:	ffffe097          	auipc	ra,0xffffe
    800028b6:	3a8080e7          	jalr	936(ra) # 80000c5a <acquire>
        if(np->state == ZOMBIE){
    800028ba:	4c9c                	lw	a5,24(s1)
    800028bc:	f94787e3          	beq	a5,s4,8000284a <wait+0x48>
        release(&np->lock);
    800028c0:	8526                	mv	a0,s1
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	44c080e7          	jalr	1100(ra) # 80000d0e <release>
        havekids = 1;
    800028ca:	8756                	mv	a4,s5
    800028cc:	bfd9                	j	800028a2 <wait+0xa0>
    if(!havekids || p->killed){
    800028ce:	c701                	beqz	a4,800028d6 <wait+0xd4>
    800028d0:	03092783          	lw	a5,48(s2)
    800028d4:	c785                	beqz	a5,800028fc <wait+0xfa>
      release(&p->lock);
    800028d6:	854a                	mv	a0,s2
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	436080e7          	jalr	1078(ra) # 80000d0e <release>
      return -1;
    800028e0:	59fd                	li	s3,-1
}
    800028e2:	854e                	mv	a0,s3
    800028e4:	60a6                	ld	ra,72(sp)
    800028e6:	6406                	ld	s0,64(sp)
    800028e8:	74e2                	ld	s1,56(sp)
    800028ea:	7942                	ld	s2,48(sp)
    800028ec:	79a2                	ld	s3,40(sp)
    800028ee:	7a02                	ld	s4,32(sp)
    800028f0:	6ae2                	ld	s5,24(sp)
    800028f2:	6b42                	ld	s6,16(sp)
    800028f4:	6ba2                	ld	s7,8(sp)
    800028f6:	6c02                	ld	s8,0(sp)
    800028f8:	6161                	addi	sp,sp,80
    800028fa:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800028fc:	85e2                	mv	a1,s8
    800028fe:	854a                	mv	a0,s2
    80002900:	00000097          	auipc	ra,0x0
    80002904:	e84080e7          	jalr	-380(ra) # 80002784 <sleep>
    havekids = 0;
    80002908:	bf1d                	j	8000283e <wait+0x3c>

000000008000290a <wakeup>:
{
    8000290a:	7139                	addi	sp,sp,-64
    8000290c:	fc06                	sd	ra,56(sp)
    8000290e:	f822                	sd	s0,48(sp)
    80002910:	f426                	sd	s1,40(sp)
    80002912:	f04a                	sd	s2,32(sp)
    80002914:	ec4e                	sd	s3,24(sp)
    80002916:	e852                	sd	s4,16(sp)
    80002918:	e456                	sd	s5,8(sp)
    8000291a:	0080                	addi	s0,sp,64
    8000291c:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000291e:	0000f497          	auipc	s1,0xf
    80002922:	44a48493          	addi	s1,s1,1098 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002926:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002928:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000292a:	00015917          	auipc	s2,0x15
    8000292e:	23e90913          	addi	s2,s2,574 # 80017b68 <tickslock>
    80002932:	a821                	j	8000294a <wakeup+0x40>
      p->state = RUNNABLE;
    80002934:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002938:	8526                	mv	a0,s1
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	3d4080e7          	jalr	980(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002942:	17848493          	addi	s1,s1,376
    80002946:	01248e63          	beq	s1,s2,80002962 <wakeup+0x58>
    acquire(&p->lock);
    8000294a:	8526                	mv	a0,s1
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	30e080e7          	jalr	782(ra) # 80000c5a <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002954:	4c9c                	lw	a5,24(s1)
    80002956:	ff3791e3          	bne	a5,s3,80002938 <wakeup+0x2e>
    8000295a:	749c                	ld	a5,40(s1)
    8000295c:	fd479ee3          	bne	a5,s4,80002938 <wakeup+0x2e>
    80002960:	bfd1                	j	80002934 <wakeup+0x2a>
}
    80002962:	70e2                	ld	ra,56(sp)
    80002964:	7442                	ld	s0,48(sp)
    80002966:	74a2                	ld	s1,40(sp)
    80002968:	7902                	ld	s2,32(sp)
    8000296a:	69e2                	ld	s3,24(sp)
    8000296c:	6a42                	ld	s4,16(sp)
    8000296e:	6aa2                	ld	s5,8(sp)
    80002970:	6121                	addi	sp,sp,64
    80002972:	8082                	ret

0000000080002974 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002974:	7179                	addi	sp,sp,-48
    80002976:	f406                	sd	ra,40(sp)
    80002978:	f022                	sd	s0,32(sp)
    8000297a:	ec26                	sd	s1,24(sp)
    8000297c:	e84a                	sd	s2,16(sp)
    8000297e:	e44e                	sd	s3,8(sp)
    80002980:	1800                	addi	s0,sp,48
    80002982:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002984:	0000f497          	auipc	s1,0xf
    80002988:	3e448493          	addi	s1,s1,996 # 80011d68 <proc>
    8000298c:	00015997          	auipc	s3,0x15
    80002990:	1dc98993          	addi	s3,s3,476 # 80017b68 <tickslock>
    acquire(&p->lock);
    80002994:	8526                	mv	a0,s1
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	2c4080e7          	jalr	708(ra) # 80000c5a <acquire>
    if(p->pid == pid){
    8000299e:	5c9c                	lw	a5,56(s1)
    800029a0:	01278d63          	beq	a5,s2,800029ba <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800029a4:	8526                	mv	a0,s1
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	368080e7          	jalr	872(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800029ae:	17848493          	addi	s1,s1,376
    800029b2:	ff3491e3          	bne	s1,s3,80002994 <kill+0x20>
  }
  return -1;
    800029b6:	557d                	li	a0,-1
    800029b8:	a829                	j	800029d2 <kill+0x5e>
      p->killed = 1;
    800029ba:	4785                	li	a5,1
    800029bc:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800029be:	4c98                	lw	a4,24(s1)
    800029c0:	4785                	li	a5,1
    800029c2:	00f70f63          	beq	a4,a5,800029e0 <kill+0x6c>
      release(&p->lock);
    800029c6:	8526                	mv	a0,s1
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	346080e7          	jalr	838(ra) # 80000d0e <release>
      return 0;
    800029d0:	4501                	li	a0,0
}
    800029d2:	70a2                	ld	ra,40(sp)
    800029d4:	7402                	ld	s0,32(sp)
    800029d6:	64e2                	ld	s1,24(sp)
    800029d8:	6942                	ld	s2,16(sp)
    800029da:	69a2                	ld	s3,8(sp)
    800029dc:	6145                	addi	sp,sp,48
    800029de:	8082                	ret
        p->state = RUNNABLE;
    800029e0:	4789                	li	a5,2
    800029e2:	cc9c                	sw	a5,24(s1)
    800029e4:	b7cd                	j	800029c6 <kill+0x52>

00000000800029e6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029e6:	7179                	addi	sp,sp,-48
    800029e8:	f406                	sd	ra,40(sp)
    800029ea:	f022                	sd	s0,32(sp)
    800029ec:	ec26                	sd	s1,24(sp)
    800029ee:	e84a                	sd	s2,16(sp)
    800029f0:	e44e                	sd	s3,8(sp)
    800029f2:	e052                	sd	s4,0(sp)
    800029f4:	1800                	addi	s0,sp,48
    800029f6:	84aa                	mv	s1,a0
    800029f8:	892e                	mv	s2,a1
    800029fa:	89b2                	mv	s3,a2
    800029fc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029fe:	fffff097          	auipc	ra,0xfffff
    80002a02:	3ee080e7          	jalr	1006(ra) # 80001dec <myproc>
  if(user_dst){
    80002a06:	c08d                	beqz	s1,80002a28 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002a08:	86d2                	mv	a3,s4
    80002a0a:	864e                	mv	a2,s3
    80002a0c:	85ca                	mv	a1,s2
    80002a0e:	6928                	ld	a0,80(a0)
    80002a10:	fffff097          	auipc	ra,0xfffff
    80002a14:	eae080e7          	jalr	-338(ra) # 800018be <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a18:	70a2                	ld	ra,40(sp)
    80002a1a:	7402                	ld	s0,32(sp)
    80002a1c:	64e2                	ld	s1,24(sp)
    80002a1e:	6942                	ld	s2,16(sp)
    80002a20:	69a2                	ld	s3,8(sp)
    80002a22:	6a02                	ld	s4,0(sp)
    80002a24:	6145                	addi	sp,sp,48
    80002a26:	8082                	ret
    memmove((char *)dst, src, len);
    80002a28:	000a061b          	sext.w	a2,s4
    80002a2c:	85ce                	mv	a1,s3
    80002a2e:	854a                	mv	a0,s2
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	386080e7          	jalr	902(ra) # 80000db6 <memmove>
    return 0;
    80002a38:	8526                	mv	a0,s1
    80002a3a:	bff9                	j	80002a18 <either_copyout+0x32>

0000000080002a3c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a3c:	7179                	addi	sp,sp,-48
    80002a3e:	f406                	sd	ra,40(sp)
    80002a40:	f022                	sd	s0,32(sp)
    80002a42:	ec26                	sd	s1,24(sp)
    80002a44:	e84a                	sd	s2,16(sp)
    80002a46:	e44e                	sd	s3,8(sp)
    80002a48:	e052                	sd	s4,0(sp)
    80002a4a:	1800                	addi	s0,sp,48
    80002a4c:	892a                	mv	s2,a0
    80002a4e:	84ae                	mv	s1,a1
    80002a50:	89b2                	mv	s3,a2
    80002a52:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	398080e7          	jalr	920(ra) # 80001dec <myproc>
  if(user_src){
    80002a5c:	c08d                	beqz	s1,80002a7e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a5e:	86d2                	mv	a3,s4
    80002a60:	864e                	mv	a2,s3
    80002a62:	85ca                	mv	a1,s2
    80002a64:	6928                	ld	a0,80(a0)
    80002a66:	fffff097          	auipc	ra,0xfffff
    80002a6a:	ee4080e7          	jalr	-284(ra) # 8000194a <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a6e:	70a2                	ld	ra,40(sp)
    80002a70:	7402                	ld	s0,32(sp)
    80002a72:	64e2                	ld	s1,24(sp)
    80002a74:	6942                	ld	s2,16(sp)
    80002a76:	69a2                	ld	s3,8(sp)
    80002a78:	6a02                	ld	s4,0(sp)
    80002a7a:	6145                	addi	sp,sp,48
    80002a7c:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a7e:	000a061b          	sext.w	a2,s4
    80002a82:	85ce                	mv	a1,s3
    80002a84:	854a                	mv	a0,s2
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	330080e7          	jalr	816(ra) # 80000db6 <memmove>
    return 0;
    80002a8e:	8526                	mv	a0,s1
    80002a90:	bff9                	j	80002a6e <either_copyin+0x32>

0000000080002a92 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a92:	715d                	addi	sp,sp,-80
    80002a94:	e486                	sd	ra,72(sp)
    80002a96:	e0a2                	sd	s0,64(sp)
    80002a98:	fc26                	sd	s1,56(sp)
    80002a9a:	f84a                	sd	s2,48(sp)
    80002a9c:	f44e                	sd	s3,40(sp)
    80002a9e:	f052                	sd	s4,32(sp)
    80002aa0:	ec56                	sd	s5,24(sp)
    80002aa2:	e85a                	sd	s6,16(sp)
    80002aa4:	e45e                	sd	s7,8(sp)
    80002aa6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002aa8:	00005517          	auipc	a0,0x5
    80002aac:	62050513          	addi	a0,a0,1568 # 800080c8 <digits+0x88>
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	ae2080e7          	jalr	-1310(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ab8:	0000f497          	auipc	s1,0xf
    80002abc:	40848493          	addi	s1,s1,1032 # 80011ec0 <proc+0x158>
    80002ac0:	00015917          	auipc	s2,0x15
    80002ac4:	20090913          	addi	s2,s2,512 # 80017cc0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ac8:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002aca:	00006997          	auipc	s3,0x6
    80002ace:	8a698993          	addi	s3,s3,-1882 # 80008370 <indent.1822+0xc0>
    printf("%d %s %s", p->pid, state, p->name);
    80002ad2:	00006a97          	auipc	s5,0x6
    80002ad6:	8a6a8a93          	addi	s5,s5,-1882 # 80008378 <indent.1822+0xc8>
    printf("\n");
    80002ada:	00005a17          	auipc	s4,0x5
    80002ade:	5eea0a13          	addi	s4,s4,1518 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ae2:	00006b97          	auipc	s7,0x6
    80002ae6:	8ceb8b93          	addi	s7,s7,-1842 # 800083b0 <states.1765>
    80002aea:	a00d                	j	80002b0c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002aec:	ee06a583          	lw	a1,-288(a3)
    80002af0:	8556                	mv	a0,s5
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	aa0080e7          	jalr	-1376(ra) # 80000592 <printf>
    printf("\n");
    80002afa:	8552                	mv	a0,s4
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	a96080e7          	jalr	-1386(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b04:	17848493          	addi	s1,s1,376
    80002b08:	03248163          	beq	s1,s2,80002b2a <procdump+0x98>
    if(p->state == UNUSED)
    80002b0c:	86a6                	mv	a3,s1
    80002b0e:	ec04a783          	lw	a5,-320(s1)
    80002b12:	dbed                	beqz	a5,80002b04 <procdump+0x72>
      state = "???";
    80002b14:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b16:	fcfb6be3          	bltu	s6,a5,80002aec <procdump+0x5a>
    80002b1a:	1782                	slli	a5,a5,0x20
    80002b1c:	9381                	srli	a5,a5,0x20
    80002b1e:	078e                	slli	a5,a5,0x3
    80002b20:	97de                	add	a5,a5,s7
    80002b22:	6390                	ld	a2,0(a5)
    80002b24:	f661                	bnez	a2,80002aec <procdump+0x5a>
      state = "???";
    80002b26:	864e                	mv	a2,s3
    80002b28:	b7d1                	j	80002aec <procdump+0x5a>
  }
}
    80002b2a:	60a6                	ld	ra,72(sp)
    80002b2c:	6406                	ld	s0,64(sp)
    80002b2e:	74e2                	ld	s1,56(sp)
    80002b30:	7942                	ld	s2,48(sp)
    80002b32:	79a2                	ld	s3,40(sp)
    80002b34:	7a02                	ld	s4,32(sp)
    80002b36:	6ae2                	ld	s5,24(sp)
    80002b38:	6b42                	ld	s6,16(sp)
    80002b3a:	6ba2                	ld	s7,8(sp)
    80002b3c:	6161                	addi	sp,sp,80
    80002b3e:	8082                	ret

0000000080002b40 <count_free_proc>:

// Count how many processes are not in the state of UNUSED
uint64
count_free_proc(void) {
    80002b40:	7179                	addi	sp,sp,-48
    80002b42:	f406                	sd	ra,40(sp)
    80002b44:	f022                	sd	s0,32(sp)
    80002b46:	ec26                	sd	s1,24(sp)
    80002b48:	e84a                	sd	s2,16(sp)
    80002b4a:	e44e                	sd	s3,8(sp)
    80002b4c:	1800                	addi	s0,sp,48
  struct proc *p;
  uint64 count = 0;
    80002b4e:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002b50:	0000f497          	auipc	s1,0xf
    80002b54:	21848493          	addi	s1,s1,536 # 80011d68 <proc>
    80002b58:	00015997          	auipc	s3,0x15
    80002b5c:	01098993          	addi	s3,s3,16 # 80017b68 <tickslock>
    acquire(&p->lock);
    80002b60:	8526                	mv	a0,s1
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	0f8080e7          	jalr	248(ra) # 80000c5a <acquire>
    if(p->state != UNUSED) {
    80002b6a:	4c9c                	lw	a5,24(s1)
      count += 1;
    80002b6c:	00f037b3          	snez	a5,a5
    80002b70:	993e                	add	s2,s2,a5
    }
    release(&p->lock);
    80002b72:	8526                	mv	a0,s1
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	19a080e7          	jalr	410(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002b7c:	17848493          	addi	s1,s1,376
    80002b80:	ff3490e3          	bne	s1,s3,80002b60 <count_free_proc+0x20>
  }
  return count;
}
    80002b84:	854a                	mv	a0,s2
    80002b86:	70a2                	ld	ra,40(sp)
    80002b88:	7402                	ld	s0,32(sp)
    80002b8a:	64e2                	ld	s1,24(sp)
    80002b8c:	6942                	ld	s2,16(sp)
    80002b8e:	69a2                	ld	s3,8(sp)
    80002b90:	6145                	addi	sp,sp,48
    80002b92:	8082                	ret

0000000080002b94 <swtch>:
    80002b94:	00153023          	sd	ra,0(a0)
    80002b98:	00253423          	sd	sp,8(a0)
    80002b9c:	e900                	sd	s0,16(a0)
    80002b9e:	ed04                	sd	s1,24(a0)
    80002ba0:	03253023          	sd	s2,32(a0)
    80002ba4:	03353423          	sd	s3,40(a0)
    80002ba8:	03453823          	sd	s4,48(a0)
    80002bac:	03553c23          	sd	s5,56(a0)
    80002bb0:	05653023          	sd	s6,64(a0)
    80002bb4:	05753423          	sd	s7,72(a0)
    80002bb8:	05853823          	sd	s8,80(a0)
    80002bbc:	05953c23          	sd	s9,88(a0)
    80002bc0:	07a53023          	sd	s10,96(a0)
    80002bc4:	07b53423          	sd	s11,104(a0)
    80002bc8:	0005b083          	ld	ra,0(a1)
    80002bcc:	0085b103          	ld	sp,8(a1)
    80002bd0:	6980                	ld	s0,16(a1)
    80002bd2:	6d84                	ld	s1,24(a1)
    80002bd4:	0205b903          	ld	s2,32(a1)
    80002bd8:	0285b983          	ld	s3,40(a1)
    80002bdc:	0305ba03          	ld	s4,48(a1)
    80002be0:	0385ba83          	ld	s5,56(a1)
    80002be4:	0405bb03          	ld	s6,64(a1)
    80002be8:	0485bb83          	ld	s7,72(a1)
    80002bec:	0505bc03          	ld	s8,80(a1)
    80002bf0:	0585bc83          	ld	s9,88(a1)
    80002bf4:	0605bd03          	ld	s10,96(a1)
    80002bf8:	0685bd83          	ld	s11,104(a1)
    80002bfc:	8082                	ret

0000000080002bfe <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002bfe:	1141                	addi	sp,sp,-16
    80002c00:	e406                	sd	ra,8(sp)
    80002c02:	e022                	sd	s0,0(sp)
    80002c04:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c06:	00005597          	auipc	a1,0x5
    80002c0a:	7d258593          	addi	a1,a1,2002 # 800083d8 <states.1765+0x28>
    80002c0e:	00015517          	auipc	a0,0x15
    80002c12:	f5a50513          	addi	a0,a0,-166 # 80017b68 <tickslock>
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	fb4080e7          	jalr	-76(ra) # 80000bca <initlock>
}
    80002c1e:	60a2                	ld	ra,8(sp)
    80002c20:	6402                	ld	s0,0(sp)
    80002c22:	0141                	addi	sp,sp,16
    80002c24:	8082                	ret

0000000080002c26 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c26:	1141                	addi	sp,sp,-16
    80002c28:	e422                	sd	s0,8(sp)
    80002c2a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c2c:	00003797          	auipc	a5,0x3
    80002c30:	5e478793          	addi	a5,a5,1508 # 80006210 <kernelvec>
    80002c34:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c38:	6422                	ld	s0,8(sp)
    80002c3a:	0141                	addi	sp,sp,16
    80002c3c:	8082                	ret

0000000080002c3e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c3e:	1141                	addi	sp,sp,-16
    80002c40:	e406                	sd	ra,8(sp)
    80002c42:	e022                	sd	s0,0(sp)
    80002c44:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	1a6080e7          	jalr	422(ra) # 80001dec <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c4e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c52:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c54:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c58:	00004617          	auipc	a2,0x4
    80002c5c:	3a860613          	addi	a2,a2,936 # 80007000 <_trampoline>
    80002c60:	00004697          	auipc	a3,0x4
    80002c64:	3a068693          	addi	a3,a3,928 # 80007000 <_trampoline>
    80002c68:	8e91                	sub	a3,a3,a2
    80002c6a:	040007b7          	lui	a5,0x4000
    80002c6e:	17fd                	addi	a5,a5,-1
    80002c70:	07b2                	slli	a5,a5,0xc
    80002c72:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c74:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c78:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c7a:	180026f3          	csrr	a3,satp
    80002c7e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c80:	6d38                	ld	a4,88(a0)
    80002c82:	6134                	ld	a3,64(a0)
    80002c84:	6585                	lui	a1,0x1
    80002c86:	96ae                	add	a3,a3,a1
    80002c88:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c8a:	6d38                	ld	a4,88(a0)
    80002c8c:	00000697          	auipc	a3,0x0
    80002c90:	13868693          	addi	a3,a3,312 # 80002dc4 <usertrap>
    80002c94:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c96:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c98:	8692                	mv	a3,tp
    80002c9a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c9c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ca0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ca4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ca8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cac:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cae:	6f18                	ld	a4,24(a4)
    80002cb0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cb4:	692c                	ld	a1,80(a0)
    80002cb6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002cb8:	00004717          	auipc	a4,0x4
    80002cbc:	3d870713          	addi	a4,a4,984 # 80007090 <userret>
    80002cc0:	8f11                	sub	a4,a4,a2
    80002cc2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002cc4:	577d                	li	a4,-1
    80002cc6:	177e                	slli	a4,a4,0x3f
    80002cc8:	8dd9                	or	a1,a1,a4
    80002cca:	02000537          	lui	a0,0x2000
    80002cce:	157d                	addi	a0,a0,-1
    80002cd0:	0536                	slli	a0,a0,0xd
    80002cd2:	9782                	jalr	a5
}
    80002cd4:	60a2                	ld	ra,8(sp)
    80002cd6:	6402                	ld	s0,0(sp)
    80002cd8:	0141                	addi	sp,sp,16
    80002cda:	8082                	ret

0000000080002cdc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002cdc:	1101                	addi	sp,sp,-32
    80002cde:	ec06                	sd	ra,24(sp)
    80002ce0:	e822                	sd	s0,16(sp)
    80002ce2:	e426                	sd	s1,8(sp)
    80002ce4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ce6:	00015497          	auipc	s1,0x15
    80002cea:	e8248493          	addi	s1,s1,-382 # 80017b68 <tickslock>
    80002cee:	8526                	mv	a0,s1
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	f6a080e7          	jalr	-150(ra) # 80000c5a <acquire>
  ticks++;
    80002cf8:	00006517          	auipc	a0,0x6
    80002cfc:	32850513          	addi	a0,a0,808 # 80009020 <ticks>
    80002d00:	411c                	lw	a5,0(a0)
    80002d02:	2785                	addiw	a5,a5,1
    80002d04:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d06:	00000097          	auipc	ra,0x0
    80002d0a:	c04080e7          	jalr	-1020(ra) # 8000290a <wakeup>
  release(&tickslock);
    80002d0e:	8526                	mv	a0,s1
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	ffe080e7          	jalr	-2(ra) # 80000d0e <release>
}
    80002d18:	60e2                	ld	ra,24(sp)
    80002d1a:	6442                	ld	s0,16(sp)
    80002d1c:	64a2                	ld	s1,8(sp)
    80002d1e:	6105                	addi	sp,sp,32
    80002d20:	8082                	ret

0000000080002d22 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d22:	1101                	addi	sp,sp,-32
    80002d24:	ec06                	sd	ra,24(sp)
    80002d26:	e822                	sd	s0,16(sp)
    80002d28:	e426                	sd	s1,8(sp)
    80002d2a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d2c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d30:	00074d63          	bltz	a4,80002d4a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d34:	57fd                	li	a5,-1
    80002d36:	17fe                	slli	a5,a5,0x3f
    80002d38:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d3a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d3c:	06f70363          	beq	a4,a5,80002da2 <devintr+0x80>
  }
}
    80002d40:	60e2                	ld	ra,24(sp)
    80002d42:	6442                	ld	s0,16(sp)
    80002d44:	64a2                	ld	s1,8(sp)
    80002d46:	6105                	addi	sp,sp,32
    80002d48:	8082                	ret
     (scause & 0xff) == 9){
    80002d4a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d4e:	46a5                	li	a3,9
    80002d50:	fed792e3          	bne	a5,a3,80002d34 <devintr+0x12>
    int irq = plic_claim();
    80002d54:	00003097          	auipc	ra,0x3
    80002d58:	5c4080e7          	jalr	1476(ra) # 80006318 <plic_claim>
    80002d5c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d5e:	47a9                	li	a5,10
    80002d60:	02f50763          	beq	a0,a5,80002d8e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d64:	4785                	li	a5,1
    80002d66:	02f50963          	beq	a0,a5,80002d98 <devintr+0x76>
    return 1;
    80002d6a:	4505                	li	a0,1
    } else if(irq){
    80002d6c:	d8f1                	beqz	s1,80002d40 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d6e:	85a6                	mv	a1,s1
    80002d70:	00005517          	auipc	a0,0x5
    80002d74:	67050513          	addi	a0,a0,1648 # 800083e0 <states.1765+0x30>
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	81a080e7          	jalr	-2022(ra) # 80000592 <printf>
      plic_complete(irq);
    80002d80:	8526                	mv	a0,s1
    80002d82:	00003097          	auipc	ra,0x3
    80002d86:	5ba080e7          	jalr	1466(ra) # 8000633c <plic_complete>
    return 1;
    80002d8a:	4505                	li	a0,1
    80002d8c:	bf55                	j	80002d40 <devintr+0x1e>
      uartintr();
    80002d8e:	ffffe097          	auipc	ra,0xffffe
    80002d92:	c46080e7          	jalr	-954(ra) # 800009d4 <uartintr>
    80002d96:	b7ed                	j	80002d80 <devintr+0x5e>
      virtio_disk_intr();
    80002d98:	00004097          	auipc	ra,0x4
    80002d9c:	a3e080e7          	jalr	-1474(ra) # 800067d6 <virtio_disk_intr>
    80002da0:	b7c5                	j	80002d80 <devintr+0x5e>
    if(cpuid() == 0){
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	01e080e7          	jalr	30(ra) # 80001dc0 <cpuid>
    80002daa:	c901                	beqz	a0,80002dba <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002dac:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002db0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002db2:	14479073          	csrw	sip,a5
    return 2;
    80002db6:	4509                	li	a0,2
    80002db8:	b761                	j	80002d40 <devintr+0x1e>
      clockintr();
    80002dba:	00000097          	auipc	ra,0x0
    80002dbe:	f22080e7          	jalr	-222(ra) # 80002cdc <clockintr>
    80002dc2:	b7ed                	j	80002dac <devintr+0x8a>

0000000080002dc4 <usertrap>:
{
    80002dc4:	1101                	addi	sp,sp,-32
    80002dc6:	ec06                	sd	ra,24(sp)
    80002dc8:	e822                	sd	s0,16(sp)
    80002dca:	e426                	sd	s1,8(sp)
    80002dcc:	e04a                	sd	s2,0(sp)
    80002dce:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dd0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002dd4:	1007f793          	andi	a5,a5,256
    80002dd8:	e3ad                	bnez	a5,80002e3a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dda:	00003797          	auipc	a5,0x3
    80002dde:	43678793          	addi	a5,a5,1078 # 80006210 <kernelvec>
    80002de2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	006080e7          	jalr	6(ra) # 80001dec <myproc>
    80002dee:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002df0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002df2:	14102773          	csrr	a4,sepc
    80002df6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002df8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002dfc:	47a1                	li	a5,8
    80002dfe:	04f71c63          	bne	a4,a5,80002e56 <usertrap+0x92>
    if(p->killed)
    80002e02:	591c                	lw	a5,48(a0)
    80002e04:	e3b9                	bnez	a5,80002e4a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002e06:	6cb8                	ld	a4,88(s1)
    80002e08:	6f1c                	ld	a5,24(a4)
    80002e0a:	0791                	addi	a5,a5,4
    80002e0c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e0e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e12:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e16:	10079073          	csrw	sstatus,a5
    syscall();
    80002e1a:	00000097          	auipc	ra,0x0
    80002e1e:	2e0080e7          	jalr	736(ra) # 800030fa <syscall>
  if(p->killed)
    80002e22:	589c                	lw	a5,48(s1)
    80002e24:	ebc1                	bnez	a5,80002eb4 <usertrap+0xf0>
  usertrapret();
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	e18080e7          	jalr	-488(ra) # 80002c3e <usertrapret>
}
    80002e2e:	60e2                	ld	ra,24(sp)
    80002e30:	6442                	ld	s0,16(sp)
    80002e32:	64a2                	ld	s1,8(sp)
    80002e34:	6902                	ld	s2,0(sp)
    80002e36:	6105                	addi	sp,sp,32
    80002e38:	8082                	ret
    panic("usertrap: not from user mode");
    80002e3a:	00005517          	auipc	a0,0x5
    80002e3e:	5c650513          	addi	a0,a0,1478 # 80008400 <states.1765+0x50>
    80002e42:	ffffd097          	auipc	ra,0xffffd
    80002e46:	706080e7          	jalr	1798(ra) # 80000548 <panic>
      exit(-1);
    80002e4a:	557d                	li	a0,-1
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	7f2080e7          	jalr	2034(ra) # 8000263e <exit>
    80002e54:	bf4d                	j	80002e06 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	ecc080e7          	jalr	-308(ra) # 80002d22 <devintr>
    80002e5e:	892a                	mv	s2,a0
    80002e60:	c501                	beqz	a0,80002e68 <usertrap+0xa4>
  if(p->killed)
    80002e62:	589c                	lw	a5,48(s1)
    80002e64:	c3a1                	beqz	a5,80002ea4 <usertrap+0xe0>
    80002e66:	a815                	j	80002e9a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e68:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e6c:	5c90                	lw	a2,56(s1)
    80002e6e:	00005517          	auipc	a0,0x5
    80002e72:	5b250513          	addi	a0,a0,1458 # 80008420 <states.1765+0x70>
    80002e76:	ffffd097          	auipc	ra,0xffffd
    80002e7a:	71c080e7          	jalr	1820(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e7e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e82:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e86:	00005517          	auipc	a0,0x5
    80002e8a:	5ca50513          	addi	a0,a0,1482 # 80008450 <states.1765+0xa0>
    80002e8e:	ffffd097          	auipc	ra,0xffffd
    80002e92:	704080e7          	jalr	1796(ra) # 80000592 <printf>
    p->killed = 1;
    80002e96:	4785                	li	a5,1
    80002e98:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002e9a:	557d                	li	a0,-1
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	7a2080e7          	jalr	1954(ra) # 8000263e <exit>
  if(which_dev == 2)
    80002ea4:	4789                	li	a5,2
    80002ea6:	f8f910e3          	bne	s2,a5,80002e26 <usertrap+0x62>
    yield();
    80002eaa:	00000097          	auipc	ra,0x0
    80002eae:	89e080e7          	jalr	-1890(ra) # 80002748 <yield>
    80002eb2:	bf95                	j	80002e26 <usertrap+0x62>
  int which_dev = 0;
    80002eb4:	4901                	li	s2,0
    80002eb6:	b7d5                	j	80002e9a <usertrap+0xd6>

0000000080002eb8 <kerneltrap>:
{
    80002eb8:	7179                	addi	sp,sp,-48
    80002eba:	f406                	sd	ra,40(sp)
    80002ebc:	f022                	sd	s0,32(sp)
    80002ebe:	ec26                	sd	s1,24(sp)
    80002ec0:	e84a                	sd	s2,16(sp)
    80002ec2:	e44e                	sd	s3,8(sp)
    80002ec4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ec6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eca:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ece:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ed2:	1004f793          	andi	a5,s1,256
    80002ed6:	cb85                	beqz	a5,80002f06 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ed8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002edc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ede:	ef85                	bnez	a5,80002f16 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ee0:	00000097          	auipc	ra,0x0
    80002ee4:	e42080e7          	jalr	-446(ra) # 80002d22 <devintr>
    80002ee8:	cd1d                	beqz	a0,80002f26 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002eea:	4789                	li	a5,2
    80002eec:	06f50a63          	beq	a0,a5,80002f60 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ef0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ef4:	10049073          	csrw	sstatus,s1
}
    80002ef8:	70a2                	ld	ra,40(sp)
    80002efa:	7402                	ld	s0,32(sp)
    80002efc:	64e2                	ld	s1,24(sp)
    80002efe:	6942                	ld	s2,16(sp)
    80002f00:	69a2                	ld	s3,8(sp)
    80002f02:	6145                	addi	sp,sp,48
    80002f04:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f06:	00005517          	auipc	a0,0x5
    80002f0a:	56a50513          	addi	a0,a0,1386 # 80008470 <states.1765+0xc0>
    80002f0e:	ffffd097          	auipc	ra,0xffffd
    80002f12:	63a080e7          	jalr	1594(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002f16:	00005517          	auipc	a0,0x5
    80002f1a:	58250513          	addi	a0,a0,1410 # 80008498 <states.1765+0xe8>
    80002f1e:	ffffd097          	auipc	ra,0xffffd
    80002f22:	62a080e7          	jalr	1578(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002f26:	85ce                	mv	a1,s3
    80002f28:	00005517          	auipc	a0,0x5
    80002f2c:	59050513          	addi	a0,a0,1424 # 800084b8 <states.1765+0x108>
    80002f30:	ffffd097          	auipc	ra,0xffffd
    80002f34:	662080e7          	jalr	1634(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f38:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f3c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f40:	00005517          	auipc	a0,0x5
    80002f44:	58850513          	addi	a0,a0,1416 # 800084c8 <states.1765+0x118>
    80002f48:	ffffd097          	auipc	ra,0xffffd
    80002f4c:	64a080e7          	jalr	1610(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002f50:	00005517          	auipc	a0,0x5
    80002f54:	59050513          	addi	a0,a0,1424 # 800084e0 <states.1765+0x130>
    80002f58:	ffffd097          	auipc	ra,0xffffd
    80002f5c:	5f0080e7          	jalr	1520(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	e8c080e7          	jalr	-372(ra) # 80001dec <myproc>
    80002f68:	d541                	beqz	a0,80002ef0 <kerneltrap+0x38>
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	e82080e7          	jalr	-382(ra) # 80001dec <myproc>
    80002f72:	4d18                	lw	a4,24(a0)
    80002f74:	478d                	li	a5,3
    80002f76:	f6f71de3          	bne	a4,a5,80002ef0 <kerneltrap+0x38>
    yield();
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	7ce080e7          	jalr	1998(ra) # 80002748 <yield>
    80002f82:	b7bd                	j	80002ef0 <kerneltrap+0x38>

0000000080002f84 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f84:	1101                	addi	sp,sp,-32
    80002f86:	ec06                	sd	ra,24(sp)
    80002f88:	e822                	sd	s0,16(sp)
    80002f8a:	e426                	sd	s1,8(sp)
    80002f8c:	1000                	addi	s0,sp,32
    80002f8e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	e5c080e7          	jalr	-420(ra) # 80001dec <myproc>
  switch (n) {
    80002f98:	4795                	li	a5,5
    80002f9a:	0497e163          	bltu	a5,s1,80002fdc <argraw+0x58>
    80002f9e:	048a                	slli	s1,s1,0x2
    80002fa0:	00005717          	auipc	a4,0x5
    80002fa4:	64070713          	addi	a4,a4,1600 # 800085e0 <states.1765+0x230>
    80002fa8:	94ba                	add	s1,s1,a4
    80002faa:	409c                	lw	a5,0(s1)
    80002fac:	97ba                	add	a5,a5,a4
    80002fae:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fb0:	6d3c                	ld	a5,88(a0)
    80002fb2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002fb4:	60e2                	ld	ra,24(sp)
    80002fb6:	6442                	ld	s0,16(sp)
    80002fb8:	64a2                	ld	s1,8(sp)
    80002fba:	6105                	addi	sp,sp,32
    80002fbc:	8082                	ret
    return p->trapframe->a1;
    80002fbe:	6d3c                	ld	a5,88(a0)
    80002fc0:	7fa8                	ld	a0,120(a5)
    80002fc2:	bfcd                	j	80002fb4 <argraw+0x30>
    return p->trapframe->a2;
    80002fc4:	6d3c                	ld	a5,88(a0)
    80002fc6:	63c8                	ld	a0,128(a5)
    80002fc8:	b7f5                	j	80002fb4 <argraw+0x30>
    return p->trapframe->a3;
    80002fca:	6d3c                	ld	a5,88(a0)
    80002fcc:	67c8                	ld	a0,136(a5)
    80002fce:	b7dd                	j	80002fb4 <argraw+0x30>
    return p->trapframe->a4;
    80002fd0:	6d3c                	ld	a5,88(a0)
    80002fd2:	6bc8                	ld	a0,144(a5)
    80002fd4:	b7c5                	j	80002fb4 <argraw+0x30>
    return p->trapframe->a5;
    80002fd6:	6d3c                	ld	a5,88(a0)
    80002fd8:	6fc8                	ld	a0,152(a5)
    80002fda:	bfe9                	j	80002fb4 <argraw+0x30>
  panic("argraw");
    80002fdc:	00005517          	auipc	a0,0x5
    80002fe0:	51450513          	addi	a0,a0,1300 # 800084f0 <states.1765+0x140>
    80002fe4:	ffffd097          	auipc	ra,0xffffd
    80002fe8:	564080e7          	jalr	1380(ra) # 80000548 <panic>

0000000080002fec <fetchaddr>:
{
    80002fec:	1101                	addi	sp,sp,-32
    80002fee:	ec06                	sd	ra,24(sp)
    80002ff0:	e822                	sd	s0,16(sp)
    80002ff2:	e426                	sd	s1,8(sp)
    80002ff4:	e04a                	sd	s2,0(sp)
    80002ff6:	1000                	addi	s0,sp,32
    80002ff8:	84aa                	mv	s1,a0
    80002ffa:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ffc:	fffff097          	auipc	ra,0xfffff
    80003000:	df0080e7          	jalr	-528(ra) # 80001dec <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003004:	653c                	ld	a5,72(a0)
    80003006:	02f4f863          	bgeu	s1,a5,80003036 <fetchaddr+0x4a>
    8000300a:	00848713          	addi	a4,s1,8
    8000300e:	02e7e663          	bltu	a5,a4,8000303a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003012:	46a1                	li	a3,8
    80003014:	8626                	mv	a2,s1
    80003016:	85ca                	mv	a1,s2
    80003018:	6928                	ld	a0,80(a0)
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	930080e7          	jalr	-1744(ra) # 8000194a <copyin>
    80003022:	00a03533          	snez	a0,a0
    80003026:	40a00533          	neg	a0,a0
}
    8000302a:	60e2                	ld	ra,24(sp)
    8000302c:	6442                	ld	s0,16(sp)
    8000302e:	64a2                	ld	s1,8(sp)
    80003030:	6902                	ld	s2,0(sp)
    80003032:	6105                	addi	sp,sp,32
    80003034:	8082                	ret
    return -1;
    80003036:	557d                	li	a0,-1
    80003038:	bfcd                	j	8000302a <fetchaddr+0x3e>
    8000303a:	557d                	li	a0,-1
    8000303c:	b7fd                	j	8000302a <fetchaddr+0x3e>

000000008000303e <fetchstr>:
{
    8000303e:	7179                	addi	sp,sp,-48
    80003040:	f406                	sd	ra,40(sp)
    80003042:	f022                	sd	s0,32(sp)
    80003044:	ec26                	sd	s1,24(sp)
    80003046:	e84a                	sd	s2,16(sp)
    80003048:	e44e                	sd	s3,8(sp)
    8000304a:	1800                	addi	s0,sp,48
    8000304c:	892a                	mv	s2,a0
    8000304e:	84ae                	mv	s1,a1
    80003050:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003052:	fffff097          	auipc	ra,0xfffff
    80003056:	d9a080e7          	jalr	-614(ra) # 80001dec <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000305a:	86ce                	mv	a3,s3
    8000305c:	864a                	mv	a2,s2
    8000305e:	85a6                	mv	a1,s1
    80003060:	6928                	ld	a0,80(a0)
    80003062:	fffff097          	auipc	ra,0xfffff
    80003066:	900080e7          	jalr	-1792(ra) # 80001962 <copyinstr>
  if(err < 0)
    8000306a:	00054763          	bltz	a0,80003078 <fetchstr+0x3a>
  return strlen(buf);
    8000306e:	8526                	mv	a0,s1
    80003070:	ffffe097          	auipc	ra,0xffffe
    80003074:	e6e080e7          	jalr	-402(ra) # 80000ede <strlen>
}
    80003078:	70a2                	ld	ra,40(sp)
    8000307a:	7402                	ld	s0,32(sp)
    8000307c:	64e2                	ld	s1,24(sp)
    8000307e:	6942                	ld	s2,16(sp)
    80003080:	69a2                	ld	s3,8(sp)
    80003082:	6145                	addi	sp,sp,48
    80003084:	8082                	ret

0000000080003086 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003086:	1101                	addi	sp,sp,-32
    80003088:	ec06                	sd	ra,24(sp)
    8000308a:	e822                	sd	s0,16(sp)
    8000308c:	e426                	sd	s1,8(sp)
    8000308e:	1000                	addi	s0,sp,32
    80003090:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003092:	00000097          	auipc	ra,0x0
    80003096:	ef2080e7          	jalr	-270(ra) # 80002f84 <argraw>
    8000309a:	c088                	sw	a0,0(s1)
  return 0;
}
    8000309c:	4501                	li	a0,0
    8000309e:	60e2                	ld	ra,24(sp)
    800030a0:	6442                	ld	s0,16(sp)
    800030a2:	64a2                	ld	s1,8(sp)
    800030a4:	6105                	addi	sp,sp,32
    800030a6:	8082                	ret

00000000800030a8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800030a8:	1101                	addi	sp,sp,-32
    800030aa:	ec06                	sd	ra,24(sp)
    800030ac:	e822                	sd	s0,16(sp)
    800030ae:	e426                	sd	s1,8(sp)
    800030b0:	1000                	addi	s0,sp,32
    800030b2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030b4:	00000097          	auipc	ra,0x0
    800030b8:	ed0080e7          	jalr	-304(ra) # 80002f84 <argraw>
    800030bc:	e088                	sd	a0,0(s1)
  return 0;
}
    800030be:	4501                	li	a0,0
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	64a2                	ld	s1,8(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret

00000000800030ca <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030ca:	1101                	addi	sp,sp,-32
    800030cc:	ec06                	sd	ra,24(sp)
    800030ce:	e822                	sd	s0,16(sp)
    800030d0:	e426                	sd	s1,8(sp)
    800030d2:	e04a                	sd	s2,0(sp)
    800030d4:	1000                	addi	s0,sp,32
    800030d6:	84ae                	mv	s1,a1
    800030d8:	8932                	mv	s2,a2
  *ip = argraw(n);
    800030da:	00000097          	auipc	ra,0x0
    800030de:	eaa080e7          	jalr	-342(ra) # 80002f84 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800030e2:	864a                	mv	a2,s2
    800030e4:	85a6                	mv	a1,s1
    800030e6:	00000097          	auipc	ra,0x0
    800030ea:	f58080e7          	jalr	-168(ra) # 8000303e <fetchstr>
}
    800030ee:	60e2                	ld	ra,24(sp)
    800030f0:	6442                	ld	s0,16(sp)
    800030f2:	64a2                	ld	s1,8(sp)
    800030f4:	6902                	ld	s2,0(sp)
    800030f6:	6105                	addi	sp,sp,32
    800030f8:	8082                	ret

00000000800030fa <syscall>:
    "sysinfo",
};

void
syscall(void)
{
    800030fa:	7179                	addi	sp,sp,-48
    800030fc:	f406                	sd	ra,40(sp)
    800030fe:	f022                	sd	s0,32(sp)
    80003100:	ec26                	sd	s1,24(sp)
    80003102:	e84a                	sd	s2,16(sp)
    80003104:	e44e                	sd	s3,8(sp)
    80003106:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	ce4080e7          	jalr	-796(ra) # 80001dec <myproc>
    80003110:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003112:	05853903          	ld	s2,88(a0)
    80003116:	0a893783          	ld	a5,168(s2)
    8000311a:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000311e:	37fd                	addiw	a5,a5,-1
    80003120:	4759                	li	a4,22
    80003122:	04f76963          	bltu	a4,a5,80003174 <syscall+0x7a>
    80003126:	00399713          	slli	a4,s3,0x3
    8000312a:	00005797          	auipc	a5,0x5
    8000312e:	4ce78793          	addi	a5,a5,1230 # 800085f8 <syscalls>
    80003132:	97ba                	add	a5,a5,a4
    80003134:	639c                	ld	a5,0(a5)
    80003136:	cf9d                	beqz	a5,80003174 <syscall+0x7a>
    p->trapframe->a0 = syscalls[num]();
    80003138:	9782                	jalr	a5
    8000313a:	06a93823          	sd	a0,112(s2)
    if (p->tracemask & (1 << num)) {
    8000313e:	4785                	li	a5,1
    80003140:	013797bb          	sllw	a5,a5,s3
    80003144:	1684b703          	ld	a4,360(s1)
    80003148:	8ff9                	and	a5,a5,a4
    8000314a:	c7a1                	beqz	a5,80003192 <syscall+0x98>
      // this process traces this sys call num
      printf("%d: syscall %s -> %d\n", p->pid, sysnames[num], p->trapframe->a0);
    8000314c:	6cb8                	ld	a4,88(s1)
    8000314e:	098e                	slli	s3,s3,0x3
    80003150:	00005797          	auipc	a5,0x5
    80003154:	4a878793          	addi	a5,a5,1192 # 800085f8 <syscalls>
    80003158:	99be                	add	s3,s3,a5
    8000315a:	7b34                	ld	a3,112(a4)
    8000315c:	0c09b603          	ld	a2,192(s3)
    80003160:	5c8c                	lw	a1,56(s1)
    80003162:	00005517          	auipc	a0,0x5
    80003166:	39650513          	addi	a0,a0,918 # 800084f8 <states.1765+0x148>
    8000316a:	ffffd097          	auipc	ra,0xffffd
    8000316e:	428080e7          	jalr	1064(ra) # 80000592 <printf>
    80003172:	a005                	j	80003192 <syscall+0x98>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003174:	86ce                	mv	a3,s3
    80003176:	15848613          	addi	a2,s1,344
    8000317a:	5c8c                	lw	a1,56(s1)
    8000317c:	00005517          	auipc	a0,0x5
    80003180:	39450513          	addi	a0,a0,916 # 80008510 <states.1765+0x160>
    80003184:	ffffd097          	auipc	ra,0xffffd
    80003188:	40e080e7          	jalr	1038(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000318c:	6cbc                	ld	a5,88(s1)
    8000318e:	577d                	li	a4,-1
    80003190:	fbb8                	sd	a4,112(a5)
  }
}
    80003192:	70a2                	ld	ra,40(sp)
    80003194:	7402                	ld	s0,32(sp)
    80003196:	64e2                	ld	s1,24(sp)
    80003198:	6942                	ld	s2,16(sp)
    8000319a:	69a2                	ld	s3,8(sp)
    8000319c:	6145                	addi	sp,sp,48
    8000319e:	8082                	ret

00000000800031a0 <sys_exit>:
#include "sysinfo.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800031a0:	1101                	addi	sp,sp,-32
    800031a2:	ec06                	sd	ra,24(sp)
    800031a4:	e822                	sd	s0,16(sp)
    800031a6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800031a8:	fec40593          	addi	a1,s0,-20
    800031ac:	4501                	li	a0,0
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	ed8080e7          	jalr	-296(ra) # 80003086 <argint>
    return -1;
    800031b6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031b8:	00054963          	bltz	a0,800031ca <sys_exit+0x2a>
  exit(n);
    800031bc:	fec42503          	lw	a0,-20(s0)
    800031c0:	fffff097          	auipc	ra,0xfffff
    800031c4:	47e080e7          	jalr	1150(ra) # 8000263e <exit>
  return 0;  // not reached
    800031c8:	4781                	li	a5,0
}
    800031ca:	853e                	mv	a0,a5
    800031cc:	60e2                	ld	ra,24(sp)
    800031ce:	6442                	ld	s0,16(sp)
    800031d0:	6105                	addi	sp,sp,32
    800031d2:	8082                	ret

00000000800031d4 <sys_getpid>:

uint64
sys_getpid(void)
{
    800031d4:	1141                	addi	sp,sp,-16
    800031d6:	e406                	sd	ra,8(sp)
    800031d8:	e022                	sd	s0,0(sp)
    800031da:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800031dc:	fffff097          	auipc	ra,0xfffff
    800031e0:	c10080e7          	jalr	-1008(ra) # 80001dec <myproc>
}
    800031e4:	5d08                	lw	a0,56(a0)
    800031e6:	60a2                	ld	ra,8(sp)
    800031e8:	6402                	ld	s0,0(sp)
    800031ea:	0141                	addi	sp,sp,16
    800031ec:	8082                	ret

00000000800031ee <sys_fork>:

uint64
sys_fork(void)
{
    800031ee:	1141                	addi	sp,sp,-16
    800031f0:	e406                	sd	ra,8(sp)
    800031f2:	e022                	sd	s0,0(sp)
    800031f4:	0800                	addi	s0,sp,16
  return fork();
    800031f6:	fffff097          	auipc	ra,0xfffff
    800031fa:	0f8080e7          	jalr	248(ra) # 800022ee <fork>
}
    800031fe:	60a2                	ld	ra,8(sp)
    80003200:	6402                	ld	s0,0(sp)
    80003202:	0141                	addi	sp,sp,16
    80003204:	8082                	ret

0000000080003206 <sys_wait>:

uint64
sys_wait(void)
{
    80003206:	1101                	addi	sp,sp,-32
    80003208:	ec06                	sd	ra,24(sp)
    8000320a:	e822                	sd	s0,16(sp)
    8000320c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000320e:	fe840593          	addi	a1,s0,-24
    80003212:	4501                	li	a0,0
    80003214:	00000097          	auipc	ra,0x0
    80003218:	e94080e7          	jalr	-364(ra) # 800030a8 <argaddr>
    8000321c:	87aa                	mv	a5,a0
    return -1;
    8000321e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003220:	0007c863          	bltz	a5,80003230 <sys_wait+0x2a>
  return wait(p);
    80003224:	fe843503          	ld	a0,-24(s0)
    80003228:	fffff097          	auipc	ra,0xfffff
    8000322c:	5da080e7          	jalr	1498(ra) # 80002802 <wait>
}
    80003230:	60e2                	ld	ra,24(sp)
    80003232:	6442                	ld	s0,16(sp)
    80003234:	6105                	addi	sp,sp,32
    80003236:	8082                	ret

0000000080003238 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003238:	7179                	addi	sp,sp,-48
    8000323a:	f406                	sd	ra,40(sp)
    8000323c:	f022                	sd	s0,32(sp)
    8000323e:	ec26                	sd	s1,24(sp)
    80003240:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003242:	fdc40593          	addi	a1,s0,-36
    80003246:	4501                	li	a0,0
    80003248:	00000097          	auipc	ra,0x0
    8000324c:	e3e080e7          	jalr	-450(ra) # 80003086 <argint>
    80003250:	87aa                	mv	a5,a0
    return -1;
    80003252:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003254:	0207c063          	bltz	a5,80003274 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003258:	fffff097          	auipc	ra,0xfffff
    8000325c:	b94080e7          	jalr	-1132(ra) # 80001dec <myproc>
    80003260:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003262:	fdc42503          	lw	a0,-36(s0)
    80003266:	fffff097          	auipc	ra,0xfffff
    8000326a:	f94080e7          	jalr	-108(ra) # 800021fa <growproc>
    8000326e:	00054863          	bltz	a0,8000327e <sys_sbrk+0x46>
    return -1;
  return addr;
    80003272:	8526                	mv	a0,s1
}
    80003274:	70a2                	ld	ra,40(sp)
    80003276:	7402                	ld	s0,32(sp)
    80003278:	64e2                	ld	s1,24(sp)
    8000327a:	6145                	addi	sp,sp,48
    8000327c:	8082                	ret
    return -1;
    8000327e:	557d                	li	a0,-1
    80003280:	bfd5                	j	80003274 <sys_sbrk+0x3c>

0000000080003282 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003282:	7139                	addi	sp,sp,-64
    80003284:	fc06                	sd	ra,56(sp)
    80003286:	f822                	sd	s0,48(sp)
    80003288:	f426                	sd	s1,40(sp)
    8000328a:	f04a                	sd	s2,32(sp)
    8000328c:	ec4e                	sd	s3,24(sp)
    8000328e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003290:	fcc40593          	addi	a1,s0,-52
    80003294:	4501                	li	a0,0
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	df0080e7          	jalr	-528(ra) # 80003086 <argint>
    return -1;
    8000329e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032a0:	06054563          	bltz	a0,8000330a <sys_sleep+0x88>
  acquire(&tickslock);
    800032a4:	00015517          	auipc	a0,0x15
    800032a8:	8c450513          	addi	a0,a0,-1852 # 80017b68 <tickslock>
    800032ac:	ffffe097          	auipc	ra,0xffffe
    800032b0:	9ae080e7          	jalr	-1618(ra) # 80000c5a <acquire>
  ticks0 = ticks;
    800032b4:	00006917          	auipc	s2,0x6
    800032b8:	d6c92903          	lw	s2,-660(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    800032bc:	fcc42783          	lw	a5,-52(s0)
    800032c0:	cf85                	beqz	a5,800032f8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032c2:	00015997          	auipc	s3,0x15
    800032c6:	8a698993          	addi	s3,s3,-1882 # 80017b68 <tickslock>
    800032ca:	00006497          	auipc	s1,0x6
    800032ce:	d5648493          	addi	s1,s1,-682 # 80009020 <ticks>
    if(myproc()->killed){
    800032d2:	fffff097          	auipc	ra,0xfffff
    800032d6:	b1a080e7          	jalr	-1254(ra) # 80001dec <myproc>
    800032da:	591c                	lw	a5,48(a0)
    800032dc:	ef9d                	bnez	a5,8000331a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800032de:	85ce                	mv	a1,s3
    800032e0:	8526                	mv	a0,s1
    800032e2:	fffff097          	auipc	ra,0xfffff
    800032e6:	4a2080e7          	jalr	1186(ra) # 80002784 <sleep>
  while(ticks - ticks0 < n){
    800032ea:	409c                	lw	a5,0(s1)
    800032ec:	412787bb          	subw	a5,a5,s2
    800032f0:	fcc42703          	lw	a4,-52(s0)
    800032f4:	fce7efe3          	bltu	a5,a4,800032d2 <sys_sleep+0x50>
  }
  release(&tickslock);
    800032f8:	00015517          	auipc	a0,0x15
    800032fc:	87050513          	addi	a0,a0,-1936 # 80017b68 <tickslock>
    80003300:	ffffe097          	auipc	ra,0xffffe
    80003304:	a0e080e7          	jalr	-1522(ra) # 80000d0e <release>
  return 0;
    80003308:	4781                	li	a5,0
}
    8000330a:	853e                	mv	a0,a5
    8000330c:	70e2                	ld	ra,56(sp)
    8000330e:	7442                	ld	s0,48(sp)
    80003310:	74a2                	ld	s1,40(sp)
    80003312:	7902                	ld	s2,32(sp)
    80003314:	69e2                	ld	s3,24(sp)
    80003316:	6121                	addi	sp,sp,64
    80003318:	8082                	ret
      release(&tickslock);
    8000331a:	00015517          	auipc	a0,0x15
    8000331e:	84e50513          	addi	a0,a0,-1970 # 80017b68 <tickslock>
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	9ec080e7          	jalr	-1556(ra) # 80000d0e <release>
      return -1;
    8000332a:	57fd                	li	a5,-1
    8000332c:	bff9                	j	8000330a <sys_sleep+0x88>

000000008000332e <sys_kill>:

uint64
sys_kill(void)
{
    8000332e:	1101                	addi	sp,sp,-32
    80003330:	ec06                	sd	ra,24(sp)
    80003332:	e822                	sd	s0,16(sp)
    80003334:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003336:	fec40593          	addi	a1,s0,-20
    8000333a:	4501                	li	a0,0
    8000333c:	00000097          	auipc	ra,0x0
    80003340:	d4a080e7          	jalr	-694(ra) # 80003086 <argint>
    80003344:	87aa                	mv	a5,a0
    return -1;
    80003346:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003348:	0007c863          	bltz	a5,80003358 <sys_kill+0x2a>
  return kill(pid);
    8000334c:	fec42503          	lw	a0,-20(s0)
    80003350:	fffff097          	auipc	ra,0xfffff
    80003354:	624080e7          	jalr	1572(ra) # 80002974 <kill>
}
    80003358:	60e2                	ld	ra,24(sp)
    8000335a:	6442                	ld	s0,16(sp)
    8000335c:	6105                	addi	sp,sp,32
    8000335e:	8082                	ret

0000000080003360 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003360:	1101                	addi	sp,sp,-32
    80003362:	ec06                	sd	ra,24(sp)
    80003364:	e822                	sd	s0,16(sp)
    80003366:	e426                	sd	s1,8(sp)
    80003368:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000336a:	00014517          	auipc	a0,0x14
    8000336e:	7fe50513          	addi	a0,a0,2046 # 80017b68 <tickslock>
    80003372:	ffffe097          	auipc	ra,0xffffe
    80003376:	8e8080e7          	jalr	-1816(ra) # 80000c5a <acquire>
  xticks = ticks;
    8000337a:	00006497          	auipc	s1,0x6
    8000337e:	ca64a483          	lw	s1,-858(s1) # 80009020 <ticks>
  release(&tickslock);
    80003382:	00014517          	auipc	a0,0x14
    80003386:	7e650513          	addi	a0,a0,2022 # 80017b68 <tickslock>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	984080e7          	jalr	-1660(ra) # 80000d0e <release>
  return xticks;
}
    80003392:	02049513          	slli	a0,s1,0x20
    80003396:	9101                	srli	a0,a0,0x20
    80003398:	60e2                	ld	ra,24(sp)
    8000339a:	6442                	ld	s0,16(sp)
    8000339c:	64a2                	ld	s1,8(sp)
    8000339e:	6105                	addi	sp,sp,32
    800033a0:	8082                	ret

00000000800033a2 <sys_trace>:

// click the sys call number in p->tracemask
// so as to tracing its calling afterwards
uint64
sys_trace(void) {
    800033a2:	1101                	addi	sp,sp,-32
    800033a4:	ec06                	sd	ra,24(sp)
    800033a6:	e822                	sd	s0,16(sp)
    800033a8:	1000                	addi	s0,sp,32
  int trace_sys_mask;
  if (argint(0, &trace_sys_mask) < 0)
    800033aa:	fec40593          	addi	a1,s0,-20
    800033ae:	4501                	li	a0,0
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	cd6080e7          	jalr	-810(ra) # 80003086 <argint>
    return -1;
    800033b8:	57fd                	li	a5,-1
  if (argint(0, &trace_sys_mask) < 0)
    800033ba:	00054e63          	bltz	a0,800033d6 <sys_trace+0x34>
  myproc()->tracemask |= trace_sys_mask;
    800033be:	fffff097          	auipc	ra,0xfffff
    800033c2:	a2e080e7          	jalr	-1490(ra) # 80001dec <myproc>
    800033c6:	fec42703          	lw	a4,-20(s0)
    800033ca:	16853783          	ld	a5,360(a0)
    800033ce:	8fd9                	or	a5,a5,a4
    800033d0:	16f53423          	sd	a5,360(a0)
  return 0;
    800033d4:	4781                	li	a5,0
}
    800033d6:	853e                	mv	a0,a5
    800033d8:	60e2                	ld	ra,24(sp)
    800033da:	6442                	ld	s0,16(sp)
    800033dc:	6105                	addi	sp,sp,32
    800033de:	8082                	ret

00000000800033e0 <sys_sysinfo>:

// collect system info
uint64
sys_sysinfo(void) {
    800033e0:	7139                	addi	sp,sp,-64
    800033e2:	fc06                	sd	ra,56(sp)
    800033e4:	f822                	sd	s0,48(sp)
    800033e6:	f426                	sd	s1,40(sp)
    800033e8:	0080                	addi	s0,sp,64
  struct proc *my_proc = myproc();
    800033ea:	fffff097          	auipc	ra,0xfffff
    800033ee:	a02080e7          	jalr	-1534(ra) # 80001dec <myproc>
    800033f2:	84aa                	mv	s1,a0
  uint64 p;
  if(argaddr(0, &p) < 0)
    800033f4:	fd840593          	addi	a1,s0,-40
    800033f8:	4501                	li	a0,0
    800033fa:	00000097          	auipc	ra,0x0
    800033fe:	cae080e7          	jalr	-850(ra) # 800030a8 <argaddr>
    return -1;
    80003402:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80003404:	02054a63          	bltz	a0,80003438 <sys_sysinfo+0x58>
  // construct in kernel first
  struct sysinfo s;
  s.freemem = kfreemem();
    80003408:	ffffd097          	auipc	ra,0xffffd
    8000340c:	778080e7          	jalr	1912(ra) # 80000b80 <kfreemem>
    80003410:	fca43423          	sd	a0,-56(s0)
  s.nproc = count_free_proc();
    80003414:	fffff097          	auipc	ra,0xfffff
    80003418:	72c080e7          	jalr	1836(ra) # 80002b40 <count_free_proc>
    8000341c:	fca43823          	sd	a0,-48(s0)
  // copy to user space
  if(copyout(my_proc->pagetable, p, (char *)&s, sizeof(s)) < 0)
    80003420:	46c1                	li	a3,16
    80003422:	fc840613          	addi	a2,s0,-56
    80003426:	fd843583          	ld	a1,-40(s0)
    8000342a:	68a8                	ld	a0,80(s1)
    8000342c:	ffffe097          	auipc	ra,0xffffe
    80003430:	492080e7          	jalr	1170(ra) # 800018be <copyout>
    80003434:	43f55793          	srai	a5,a0,0x3f
    return -1;
  return 0;
}
    80003438:	853e                	mv	a0,a5
    8000343a:	70e2                	ld	ra,56(sp)
    8000343c:	7442                	ld	s0,48(sp)
    8000343e:	74a2                	ld	s1,40(sp)
    80003440:	6121                	addi	sp,sp,64
    80003442:	8082                	ret

0000000080003444 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003444:	7179                	addi	sp,sp,-48
    80003446:	f406                	sd	ra,40(sp)
    80003448:	f022                	sd	s0,32(sp)
    8000344a:	ec26                	sd	s1,24(sp)
    8000344c:	e84a                	sd	s2,16(sp)
    8000344e:	e44e                	sd	s3,8(sp)
    80003450:	e052                	sd	s4,0(sp)
    80003452:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003454:	00005597          	auipc	a1,0x5
    80003458:	32458593          	addi	a1,a1,804 # 80008778 <sysnames+0xc0>
    8000345c:	00014517          	auipc	a0,0x14
    80003460:	72450513          	addi	a0,a0,1828 # 80017b80 <bcache>
    80003464:	ffffd097          	auipc	ra,0xffffd
    80003468:	766080e7          	jalr	1894(ra) # 80000bca <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000346c:	0001c797          	auipc	a5,0x1c
    80003470:	71478793          	addi	a5,a5,1812 # 8001fb80 <bcache+0x8000>
    80003474:	0001d717          	auipc	a4,0x1d
    80003478:	97470713          	addi	a4,a4,-1676 # 8001fde8 <bcache+0x8268>
    8000347c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003480:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003484:	00014497          	auipc	s1,0x14
    80003488:	71448493          	addi	s1,s1,1812 # 80017b98 <bcache+0x18>
    b->next = bcache.head.next;
    8000348c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000348e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003490:	00005a17          	auipc	s4,0x5
    80003494:	2f0a0a13          	addi	s4,s4,752 # 80008780 <sysnames+0xc8>
    b->next = bcache.head.next;
    80003498:	2b893783          	ld	a5,696(s2)
    8000349c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000349e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034a2:	85d2                	mv	a1,s4
    800034a4:	01048513          	addi	a0,s1,16
    800034a8:	00001097          	auipc	ra,0x1
    800034ac:	4ac080e7          	jalr	1196(ra) # 80004954 <initsleeplock>
    bcache.head.next->prev = b;
    800034b0:	2b893783          	ld	a5,696(s2)
    800034b4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034b6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034ba:	45848493          	addi	s1,s1,1112
    800034be:	fd349de3          	bne	s1,s3,80003498 <binit+0x54>
  }
}
    800034c2:	70a2                	ld	ra,40(sp)
    800034c4:	7402                	ld	s0,32(sp)
    800034c6:	64e2                	ld	s1,24(sp)
    800034c8:	6942                	ld	s2,16(sp)
    800034ca:	69a2                	ld	s3,8(sp)
    800034cc:	6a02                	ld	s4,0(sp)
    800034ce:	6145                	addi	sp,sp,48
    800034d0:	8082                	ret

00000000800034d2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034d2:	7179                	addi	sp,sp,-48
    800034d4:	f406                	sd	ra,40(sp)
    800034d6:	f022                	sd	s0,32(sp)
    800034d8:	ec26                	sd	s1,24(sp)
    800034da:	e84a                	sd	s2,16(sp)
    800034dc:	e44e                	sd	s3,8(sp)
    800034de:	1800                	addi	s0,sp,48
    800034e0:	89aa                	mv	s3,a0
    800034e2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800034e4:	00014517          	auipc	a0,0x14
    800034e8:	69c50513          	addi	a0,a0,1692 # 80017b80 <bcache>
    800034ec:	ffffd097          	auipc	ra,0xffffd
    800034f0:	76e080e7          	jalr	1902(ra) # 80000c5a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034f4:	0001d497          	auipc	s1,0x1d
    800034f8:	9444b483          	ld	s1,-1724(s1) # 8001fe38 <bcache+0x82b8>
    800034fc:	0001d797          	auipc	a5,0x1d
    80003500:	8ec78793          	addi	a5,a5,-1812 # 8001fde8 <bcache+0x8268>
    80003504:	02f48f63          	beq	s1,a5,80003542 <bread+0x70>
    80003508:	873e                	mv	a4,a5
    8000350a:	a021                	j	80003512 <bread+0x40>
    8000350c:	68a4                	ld	s1,80(s1)
    8000350e:	02e48a63          	beq	s1,a4,80003542 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003512:	449c                	lw	a5,8(s1)
    80003514:	ff379ce3          	bne	a5,s3,8000350c <bread+0x3a>
    80003518:	44dc                	lw	a5,12(s1)
    8000351a:	ff2799e3          	bne	a5,s2,8000350c <bread+0x3a>
      b->refcnt++;
    8000351e:	40bc                	lw	a5,64(s1)
    80003520:	2785                	addiw	a5,a5,1
    80003522:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003524:	00014517          	auipc	a0,0x14
    80003528:	65c50513          	addi	a0,a0,1628 # 80017b80 <bcache>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	7e2080e7          	jalr	2018(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80003534:	01048513          	addi	a0,s1,16
    80003538:	00001097          	auipc	ra,0x1
    8000353c:	456080e7          	jalr	1110(ra) # 8000498e <acquiresleep>
      return b;
    80003540:	a8b9                	j	8000359e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003542:	0001d497          	auipc	s1,0x1d
    80003546:	8ee4b483          	ld	s1,-1810(s1) # 8001fe30 <bcache+0x82b0>
    8000354a:	0001d797          	auipc	a5,0x1d
    8000354e:	89e78793          	addi	a5,a5,-1890 # 8001fde8 <bcache+0x8268>
    80003552:	00f48863          	beq	s1,a5,80003562 <bread+0x90>
    80003556:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003558:	40bc                	lw	a5,64(s1)
    8000355a:	cf81                	beqz	a5,80003572 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000355c:	64a4                	ld	s1,72(s1)
    8000355e:	fee49de3          	bne	s1,a4,80003558 <bread+0x86>
  panic("bget: no buffers");
    80003562:	00005517          	auipc	a0,0x5
    80003566:	22650513          	addi	a0,a0,550 # 80008788 <sysnames+0xd0>
    8000356a:	ffffd097          	auipc	ra,0xffffd
    8000356e:	fde080e7          	jalr	-34(ra) # 80000548 <panic>
      b->dev = dev;
    80003572:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003576:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000357a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000357e:	4785                	li	a5,1
    80003580:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003582:	00014517          	auipc	a0,0x14
    80003586:	5fe50513          	addi	a0,a0,1534 # 80017b80 <bcache>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	784080e7          	jalr	1924(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80003592:	01048513          	addi	a0,s1,16
    80003596:	00001097          	auipc	ra,0x1
    8000359a:	3f8080e7          	jalr	1016(ra) # 8000498e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000359e:	409c                	lw	a5,0(s1)
    800035a0:	cb89                	beqz	a5,800035b2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035a2:	8526                	mv	a0,s1
    800035a4:	70a2                	ld	ra,40(sp)
    800035a6:	7402                	ld	s0,32(sp)
    800035a8:	64e2                	ld	s1,24(sp)
    800035aa:	6942                	ld	s2,16(sp)
    800035ac:	69a2                	ld	s3,8(sp)
    800035ae:	6145                	addi	sp,sp,48
    800035b0:	8082                	ret
    virtio_disk_rw(b, 0);
    800035b2:	4581                	li	a1,0
    800035b4:	8526                	mv	a0,s1
    800035b6:	00003097          	auipc	ra,0x3
    800035ba:	f76080e7          	jalr	-138(ra) # 8000652c <virtio_disk_rw>
    b->valid = 1;
    800035be:	4785                	li	a5,1
    800035c0:	c09c                	sw	a5,0(s1)
  return b;
    800035c2:	b7c5                	j	800035a2 <bread+0xd0>

00000000800035c4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035c4:	1101                	addi	sp,sp,-32
    800035c6:	ec06                	sd	ra,24(sp)
    800035c8:	e822                	sd	s0,16(sp)
    800035ca:	e426                	sd	s1,8(sp)
    800035cc:	1000                	addi	s0,sp,32
    800035ce:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035d0:	0541                	addi	a0,a0,16
    800035d2:	00001097          	auipc	ra,0x1
    800035d6:	456080e7          	jalr	1110(ra) # 80004a28 <holdingsleep>
    800035da:	cd01                	beqz	a0,800035f2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035dc:	4585                	li	a1,1
    800035de:	8526                	mv	a0,s1
    800035e0:	00003097          	auipc	ra,0x3
    800035e4:	f4c080e7          	jalr	-180(ra) # 8000652c <virtio_disk_rw>
}
    800035e8:	60e2                	ld	ra,24(sp)
    800035ea:	6442                	ld	s0,16(sp)
    800035ec:	64a2                	ld	s1,8(sp)
    800035ee:	6105                	addi	sp,sp,32
    800035f0:	8082                	ret
    panic("bwrite");
    800035f2:	00005517          	auipc	a0,0x5
    800035f6:	1ae50513          	addi	a0,a0,430 # 800087a0 <sysnames+0xe8>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	f4e080e7          	jalr	-178(ra) # 80000548 <panic>

0000000080003602 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003602:	1101                	addi	sp,sp,-32
    80003604:	ec06                	sd	ra,24(sp)
    80003606:	e822                	sd	s0,16(sp)
    80003608:	e426                	sd	s1,8(sp)
    8000360a:	e04a                	sd	s2,0(sp)
    8000360c:	1000                	addi	s0,sp,32
    8000360e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003610:	01050913          	addi	s2,a0,16
    80003614:	854a                	mv	a0,s2
    80003616:	00001097          	auipc	ra,0x1
    8000361a:	412080e7          	jalr	1042(ra) # 80004a28 <holdingsleep>
    8000361e:	c92d                	beqz	a0,80003690 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003620:	854a                	mv	a0,s2
    80003622:	00001097          	auipc	ra,0x1
    80003626:	3c2080e7          	jalr	962(ra) # 800049e4 <releasesleep>

  acquire(&bcache.lock);
    8000362a:	00014517          	auipc	a0,0x14
    8000362e:	55650513          	addi	a0,a0,1366 # 80017b80 <bcache>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	628080e7          	jalr	1576(ra) # 80000c5a <acquire>
  b->refcnt--;
    8000363a:	40bc                	lw	a5,64(s1)
    8000363c:	37fd                	addiw	a5,a5,-1
    8000363e:	0007871b          	sext.w	a4,a5
    80003642:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003644:	eb05                	bnez	a4,80003674 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003646:	68bc                	ld	a5,80(s1)
    80003648:	64b8                	ld	a4,72(s1)
    8000364a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000364c:	64bc                	ld	a5,72(s1)
    8000364e:	68b8                	ld	a4,80(s1)
    80003650:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003652:	0001c797          	auipc	a5,0x1c
    80003656:	52e78793          	addi	a5,a5,1326 # 8001fb80 <bcache+0x8000>
    8000365a:	2b87b703          	ld	a4,696(a5)
    8000365e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003660:	0001c717          	auipc	a4,0x1c
    80003664:	78870713          	addi	a4,a4,1928 # 8001fde8 <bcache+0x8268>
    80003668:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000366a:	2b87b703          	ld	a4,696(a5)
    8000366e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003670:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003674:	00014517          	auipc	a0,0x14
    80003678:	50c50513          	addi	a0,a0,1292 # 80017b80 <bcache>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	692080e7          	jalr	1682(ra) # 80000d0e <release>
}
    80003684:	60e2                	ld	ra,24(sp)
    80003686:	6442                	ld	s0,16(sp)
    80003688:	64a2                	ld	s1,8(sp)
    8000368a:	6902                	ld	s2,0(sp)
    8000368c:	6105                	addi	sp,sp,32
    8000368e:	8082                	ret
    panic("brelse");
    80003690:	00005517          	auipc	a0,0x5
    80003694:	11850513          	addi	a0,a0,280 # 800087a8 <sysnames+0xf0>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	eb0080e7          	jalr	-336(ra) # 80000548 <panic>

00000000800036a0 <bpin>:

void
bpin(struct buf *b) {
    800036a0:	1101                	addi	sp,sp,-32
    800036a2:	ec06                	sd	ra,24(sp)
    800036a4:	e822                	sd	s0,16(sp)
    800036a6:	e426                	sd	s1,8(sp)
    800036a8:	1000                	addi	s0,sp,32
    800036aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036ac:	00014517          	auipc	a0,0x14
    800036b0:	4d450513          	addi	a0,a0,1236 # 80017b80 <bcache>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	5a6080e7          	jalr	1446(ra) # 80000c5a <acquire>
  b->refcnt++;
    800036bc:	40bc                	lw	a5,64(s1)
    800036be:	2785                	addiw	a5,a5,1
    800036c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036c2:	00014517          	auipc	a0,0x14
    800036c6:	4be50513          	addi	a0,a0,1214 # 80017b80 <bcache>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	644080e7          	jalr	1604(ra) # 80000d0e <release>
}
    800036d2:	60e2                	ld	ra,24(sp)
    800036d4:	6442                	ld	s0,16(sp)
    800036d6:	64a2                	ld	s1,8(sp)
    800036d8:	6105                	addi	sp,sp,32
    800036da:	8082                	ret

00000000800036dc <bunpin>:

void
bunpin(struct buf *b) {
    800036dc:	1101                	addi	sp,sp,-32
    800036de:	ec06                	sd	ra,24(sp)
    800036e0:	e822                	sd	s0,16(sp)
    800036e2:	e426                	sd	s1,8(sp)
    800036e4:	1000                	addi	s0,sp,32
    800036e6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036e8:	00014517          	auipc	a0,0x14
    800036ec:	49850513          	addi	a0,a0,1176 # 80017b80 <bcache>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	56a080e7          	jalr	1386(ra) # 80000c5a <acquire>
  b->refcnt--;
    800036f8:	40bc                	lw	a5,64(s1)
    800036fa:	37fd                	addiw	a5,a5,-1
    800036fc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036fe:	00014517          	auipc	a0,0x14
    80003702:	48250513          	addi	a0,a0,1154 # 80017b80 <bcache>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	608080e7          	jalr	1544(ra) # 80000d0e <release>
}
    8000370e:	60e2                	ld	ra,24(sp)
    80003710:	6442                	ld	s0,16(sp)
    80003712:	64a2                	ld	s1,8(sp)
    80003714:	6105                	addi	sp,sp,32
    80003716:	8082                	ret

0000000080003718 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003718:	1101                	addi	sp,sp,-32
    8000371a:	ec06                	sd	ra,24(sp)
    8000371c:	e822                	sd	s0,16(sp)
    8000371e:	e426                	sd	s1,8(sp)
    80003720:	e04a                	sd	s2,0(sp)
    80003722:	1000                	addi	s0,sp,32
    80003724:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003726:	00d5d59b          	srliw	a1,a1,0xd
    8000372a:	0001d797          	auipc	a5,0x1d
    8000372e:	b327a783          	lw	a5,-1230(a5) # 8002025c <sb+0x1c>
    80003732:	9dbd                	addw	a1,a1,a5
    80003734:	00000097          	auipc	ra,0x0
    80003738:	d9e080e7          	jalr	-610(ra) # 800034d2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000373c:	0074f713          	andi	a4,s1,7
    80003740:	4785                	li	a5,1
    80003742:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003746:	14ce                	slli	s1,s1,0x33
    80003748:	90d9                	srli	s1,s1,0x36
    8000374a:	00950733          	add	a4,a0,s1
    8000374e:	05874703          	lbu	a4,88(a4)
    80003752:	00e7f6b3          	and	a3,a5,a4
    80003756:	c69d                	beqz	a3,80003784 <bfree+0x6c>
    80003758:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000375a:	94aa                	add	s1,s1,a0
    8000375c:	fff7c793          	not	a5,a5
    80003760:	8ff9                	and	a5,a5,a4
    80003762:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003766:	00001097          	auipc	ra,0x1
    8000376a:	100080e7          	jalr	256(ra) # 80004866 <log_write>
  brelse(bp);
    8000376e:	854a                	mv	a0,s2
    80003770:	00000097          	auipc	ra,0x0
    80003774:	e92080e7          	jalr	-366(ra) # 80003602 <brelse>
}
    80003778:	60e2                	ld	ra,24(sp)
    8000377a:	6442                	ld	s0,16(sp)
    8000377c:	64a2                	ld	s1,8(sp)
    8000377e:	6902                	ld	s2,0(sp)
    80003780:	6105                	addi	sp,sp,32
    80003782:	8082                	ret
    panic("freeing free block");
    80003784:	00005517          	auipc	a0,0x5
    80003788:	02c50513          	addi	a0,a0,44 # 800087b0 <sysnames+0xf8>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	dbc080e7          	jalr	-580(ra) # 80000548 <panic>

0000000080003794 <balloc>:
{
    80003794:	711d                	addi	sp,sp,-96
    80003796:	ec86                	sd	ra,88(sp)
    80003798:	e8a2                	sd	s0,80(sp)
    8000379a:	e4a6                	sd	s1,72(sp)
    8000379c:	e0ca                	sd	s2,64(sp)
    8000379e:	fc4e                	sd	s3,56(sp)
    800037a0:	f852                	sd	s4,48(sp)
    800037a2:	f456                	sd	s5,40(sp)
    800037a4:	f05a                	sd	s6,32(sp)
    800037a6:	ec5e                	sd	s7,24(sp)
    800037a8:	e862                	sd	s8,16(sp)
    800037aa:	e466                	sd	s9,8(sp)
    800037ac:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037ae:	0001d797          	auipc	a5,0x1d
    800037b2:	a967a783          	lw	a5,-1386(a5) # 80020244 <sb+0x4>
    800037b6:	cbd1                	beqz	a5,8000384a <balloc+0xb6>
    800037b8:	8baa                	mv	s7,a0
    800037ba:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037bc:	0001db17          	auipc	s6,0x1d
    800037c0:	a84b0b13          	addi	s6,s6,-1404 # 80020240 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037c6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037ca:	6c89                	lui	s9,0x2
    800037cc:	a831                	j	800037e8 <balloc+0x54>
    brelse(bp);
    800037ce:	854a                	mv	a0,s2
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	e32080e7          	jalr	-462(ra) # 80003602 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037d8:	015c87bb          	addw	a5,s9,s5
    800037dc:	00078a9b          	sext.w	s5,a5
    800037e0:	004b2703          	lw	a4,4(s6)
    800037e4:	06eaf363          	bgeu	s5,a4,8000384a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800037e8:	41fad79b          	sraiw	a5,s5,0x1f
    800037ec:	0137d79b          	srliw	a5,a5,0x13
    800037f0:	015787bb          	addw	a5,a5,s5
    800037f4:	40d7d79b          	sraiw	a5,a5,0xd
    800037f8:	01cb2583          	lw	a1,28(s6)
    800037fc:	9dbd                	addw	a1,a1,a5
    800037fe:	855e                	mv	a0,s7
    80003800:	00000097          	auipc	ra,0x0
    80003804:	cd2080e7          	jalr	-814(ra) # 800034d2 <bread>
    80003808:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000380a:	004b2503          	lw	a0,4(s6)
    8000380e:	000a849b          	sext.w	s1,s5
    80003812:	8662                	mv	a2,s8
    80003814:	faa4fde3          	bgeu	s1,a0,800037ce <balloc+0x3a>
      m = 1 << (bi % 8);
    80003818:	41f6579b          	sraiw	a5,a2,0x1f
    8000381c:	01d7d69b          	srliw	a3,a5,0x1d
    80003820:	00c6873b          	addw	a4,a3,a2
    80003824:	00777793          	andi	a5,a4,7
    80003828:	9f95                	subw	a5,a5,a3
    8000382a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000382e:	4037571b          	sraiw	a4,a4,0x3
    80003832:	00e906b3          	add	a3,s2,a4
    80003836:	0586c683          	lbu	a3,88(a3)
    8000383a:	00d7f5b3          	and	a1,a5,a3
    8000383e:	cd91                	beqz	a1,8000385a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003840:	2605                	addiw	a2,a2,1
    80003842:	2485                	addiw	s1,s1,1
    80003844:	fd4618e3          	bne	a2,s4,80003814 <balloc+0x80>
    80003848:	b759                	j	800037ce <balloc+0x3a>
  panic("balloc: out of blocks");
    8000384a:	00005517          	auipc	a0,0x5
    8000384e:	f7e50513          	addi	a0,a0,-130 # 800087c8 <sysnames+0x110>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	cf6080e7          	jalr	-778(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000385a:	974a                	add	a4,a4,s2
    8000385c:	8fd5                	or	a5,a5,a3
    8000385e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003862:	854a                	mv	a0,s2
    80003864:	00001097          	auipc	ra,0x1
    80003868:	002080e7          	jalr	2(ra) # 80004866 <log_write>
        brelse(bp);
    8000386c:	854a                	mv	a0,s2
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	d94080e7          	jalr	-620(ra) # 80003602 <brelse>
  bp = bread(dev, bno);
    80003876:	85a6                	mv	a1,s1
    80003878:	855e                	mv	a0,s7
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	c58080e7          	jalr	-936(ra) # 800034d2 <bread>
    80003882:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003884:	40000613          	li	a2,1024
    80003888:	4581                	li	a1,0
    8000388a:	05850513          	addi	a0,a0,88
    8000388e:	ffffd097          	auipc	ra,0xffffd
    80003892:	4c8080e7          	jalr	1224(ra) # 80000d56 <memset>
  log_write(bp);
    80003896:	854a                	mv	a0,s2
    80003898:	00001097          	auipc	ra,0x1
    8000389c:	fce080e7          	jalr	-50(ra) # 80004866 <log_write>
  brelse(bp);
    800038a0:	854a                	mv	a0,s2
    800038a2:	00000097          	auipc	ra,0x0
    800038a6:	d60080e7          	jalr	-672(ra) # 80003602 <brelse>
}
    800038aa:	8526                	mv	a0,s1
    800038ac:	60e6                	ld	ra,88(sp)
    800038ae:	6446                	ld	s0,80(sp)
    800038b0:	64a6                	ld	s1,72(sp)
    800038b2:	6906                	ld	s2,64(sp)
    800038b4:	79e2                	ld	s3,56(sp)
    800038b6:	7a42                	ld	s4,48(sp)
    800038b8:	7aa2                	ld	s5,40(sp)
    800038ba:	7b02                	ld	s6,32(sp)
    800038bc:	6be2                	ld	s7,24(sp)
    800038be:	6c42                	ld	s8,16(sp)
    800038c0:	6ca2                	ld	s9,8(sp)
    800038c2:	6125                	addi	sp,sp,96
    800038c4:	8082                	ret

00000000800038c6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800038c6:	7179                	addi	sp,sp,-48
    800038c8:	f406                	sd	ra,40(sp)
    800038ca:	f022                	sd	s0,32(sp)
    800038cc:	ec26                	sd	s1,24(sp)
    800038ce:	e84a                	sd	s2,16(sp)
    800038d0:	e44e                	sd	s3,8(sp)
    800038d2:	e052                	sd	s4,0(sp)
    800038d4:	1800                	addi	s0,sp,48
    800038d6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038d8:	47ad                	li	a5,11
    800038da:	04b7fe63          	bgeu	a5,a1,80003936 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800038de:	ff45849b          	addiw	s1,a1,-12
    800038e2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038e6:	0ff00793          	li	a5,255
    800038ea:	0ae7e363          	bltu	a5,a4,80003990 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800038ee:	08052583          	lw	a1,128(a0)
    800038f2:	c5ad                	beqz	a1,8000395c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800038f4:	00092503          	lw	a0,0(s2)
    800038f8:	00000097          	auipc	ra,0x0
    800038fc:	bda080e7          	jalr	-1062(ra) # 800034d2 <bread>
    80003900:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003902:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003906:	02049593          	slli	a1,s1,0x20
    8000390a:	9181                	srli	a1,a1,0x20
    8000390c:	058a                	slli	a1,a1,0x2
    8000390e:	00b784b3          	add	s1,a5,a1
    80003912:	0004a983          	lw	s3,0(s1)
    80003916:	04098d63          	beqz	s3,80003970 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000391a:	8552                	mv	a0,s4
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	ce6080e7          	jalr	-794(ra) # 80003602 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003924:	854e                	mv	a0,s3
    80003926:	70a2                	ld	ra,40(sp)
    80003928:	7402                	ld	s0,32(sp)
    8000392a:	64e2                	ld	s1,24(sp)
    8000392c:	6942                	ld	s2,16(sp)
    8000392e:	69a2                	ld	s3,8(sp)
    80003930:	6a02                	ld	s4,0(sp)
    80003932:	6145                	addi	sp,sp,48
    80003934:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003936:	02059493          	slli	s1,a1,0x20
    8000393a:	9081                	srli	s1,s1,0x20
    8000393c:	048a                	slli	s1,s1,0x2
    8000393e:	94aa                	add	s1,s1,a0
    80003940:	0504a983          	lw	s3,80(s1)
    80003944:	fe0990e3          	bnez	s3,80003924 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003948:	4108                	lw	a0,0(a0)
    8000394a:	00000097          	auipc	ra,0x0
    8000394e:	e4a080e7          	jalr	-438(ra) # 80003794 <balloc>
    80003952:	0005099b          	sext.w	s3,a0
    80003956:	0534a823          	sw	s3,80(s1)
    8000395a:	b7e9                	j	80003924 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000395c:	4108                	lw	a0,0(a0)
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	e36080e7          	jalr	-458(ra) # 80003794 <balloc>
    80003966:	0005059b          	sext.w	a1,a0
    8000396a:	08b92023          	sw	a1,128(s2)
    8000396e:	b759                	j	800038f4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003970:	00092503          	lw	a0,0(s2)
    80003974:	00000097          	auipc	ra,0x0
    80003978:	e20080e7          	jalr	-480(ra) # 80003794 <balloc>
    8000397c:	0005099b          	sext.w	s3,a0
    80003980:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003984:	8552                	mv	a0,s4
    80003986:	00001097          	auipc	ra,0x1
    8000398a:	ee0080e7          	jalr	-288(ra) # 80004866 <log_write>
    8000398e:	b771                	j	8000391a <bmap+0x54>
  panic("bmap: out of range");
    80003990:	00005517          	auipc	a0,0x5
    80003994:	e5050513          	addi	a0,a0,-432 # 800087e0 <sysnames+0x128>
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	bb0080e7          	jalr	-1104(ra) # 80000548 <panic>

00000000800039a0 <iget>:
{
    800039a0:	7179                	addi	sp,sp,-48
    800039a2:	f406                	sd	ra,40(sp)
    800039a4:	f022                	sd	s0,32(sp)
    800039a6:	ec26                	sd	s1,24(sp)
    800039a8:	e84a                	sd	s2,16(sp)
    800039aa:	e44e                	sd	s3,8(sp)
    800039ac:	e052                	sd	s4,0(sp)
    800039ae:	1800                	addi	s0,sp,48
    800039b0:	89aa                	mv	s3,a0
    800039b2:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800039b4:	0001d517          	auipc	a0,0x1d
    800039b8:	8ac50513          	addi	a0,a0,-1876 # 80020260 <icache>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	29e080e7          	jalr	670(ra) # 80000c5a <acquire>
  empty = 0;
    800039c4:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800039c6:	0001d497          	auipc	s1,0x1d
    800039ca:	8b248493          	addi	s1,s1,-1870 # 80020278 <icache+0x18>
    800039ce:	0001e697          	auipc	a3,0x1e
    800039d2:	33a68693          	addi	a3,a3,826 # 80021d08 <log>
    800039d6:	a039                	j	800039e4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039d8:	02090b63          	beqz	s2,80003a0e <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800039dc:	08848493          	addi	s1,s1,136
    800039e0:	02d48a63          	beq	s1,a3,80003a14 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039e4:	449c                	lw	a5,8(s1)
    800039e6:	fef059e3          	blez	a5,800039d8 <iget+0x38>
    800039ea:	4098                	lw	a4,0(s1)
    800039ec:	ff3716e3          	bne	a4,s3,800039d8 <iget+0x38>
    800039f0:	40d8                	lw	a4,4(s1)
    800039f2:	ff4713e3          	bne	a4,s4,800039d8 <iget+0x38>
      ip->ref++;
    800039f6:	2785                	addiw	a5,a5,1
    800039f8:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800039fa:	0001d517          	auipc	a0,0x1d
    800039fe:	86650513          	addi	a0,a0,-1946 # 80020260 <icache>
    80003a02:	ffffd097          	auipc	ra,0xffffd
    80003a06:	30c080e7          	jalr	780(ra) # 80000d0e <release>
      return ip;
    80003a0a:	8926                	mv	s2,s1
    80003a0c:	a03d                	j	80003a3a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a0e:	f7f9                	bnez	a5,800039dc <iget+0x3c>
    80003a10:	8926                	mv	s2,s1
    80003a12:	b7e9                	j	800039dc <iget+0x3c>
  if(empty == 0)
    80003a14:	02090c63          	beqz	s2,80003a4c <iget+0xac>
  ip->dev = dev;
    80003a18:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a1c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a20:	4785                	li	a5,1
    80003a22:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a26:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003a2a:	0001d517          	auipc	a0,0x1d
    80003a2e:	83650513          	addi	a0,a0,-1994 # 80020260 <icache>
    80003a32:	ffffd097          	auipc	ra,0xffffd
    80003a36:	2dc080e7          	jalr	732(ra) # 80000d0e <release>
}
    80003a3a:	854a                	mv	a0,s2
    80003a3c:	70a2                	ld	ra,40(sp)
    80003a3e:	7402                	ld	s0,32(sp)
    80003a40:	64e2                	ld	s1,24(sp)
    80003a42:	6942                	ld	s2,16(sp)
    80003a44:	69a2                	ld	s3,8(sp)
    80003a46:	6a02                	ld	s4,0(sp)
    80003a48:	6145                	addi	sp,sp,48
    80003a4a:	8082                	ret
    panic("iget: no inodes");
    80003a4c:	00005517          	auipc	a0,0x5
    80003a50:	dac50513          	addi	a0,a0,-596 # 800087f8 <sysnames+0x140>
    80003a54:	ffffd097          	auipc	ra,0xffffd
    80003a58:	af4080e7          	jalr	-1292(ra) # 80000548 <panic>

0000000080003a5c <fsinit>:
fsinit(int dev) {
    80003a5c:	7179                	addi	sp,sp,-48
    80003a5e:	f406                	sd	ra,40(sp)
    80003a60:	f022                	sd	s0,32(sp)
    80003a62:	ec26                	sd	s1,24(sp)
    80003a64:	e84a                	sd	s2,16(sp)
    80003a66:	e44e                	sd	s3,8(sp)
    80003a68:	1800                	addi	s0,sp,48
    80003a6a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a6c:	4585                	li	a1,1
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	a64080e7          	jalr	-1436(ra) # 800034d2 <bread>
    80003a76:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a78:	0001c997          	auipc	s3,0x1c
    80003a7c:	7c898993          	addi	s3,s3,1992 # 80020240 <sb>
    80003a80:	02000613          	li	a2,32
    80003a84:	05850593          	addi	a1,a0,88
    80003a88:	854e                	mv	a0,s3
    80003a8a:	ffffd097          	auipc	ra,0xffffd
    80003a8e:	32c080e7          	jalr	812(ra) # 80000db6 <memmove>
  brelse(bp);
    80003a92:	8526                	mv	a0,s1
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	b6e080e7          	jalr	-1170(ra) # 80003602 <brelse>
  if(sb.magic != FSMAGIC)
    80003a9c:	0009a703          	lw	a4,0(s3)
    80003aa0:	102037b7          	lui	a5,0x10203
    80003aa4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003aa8:	02f71263          	bne	a4,a5,80003acc <fsinit+0x70>
  initlog(dev, &sb);
    80003aac:	0001c597          	auipc	a1,0x1c
    80003ab0:	79458593          	addi	a1,a1,1940 # 80020240 <sb>
    80003ab4:	854a                	mv	a0,s2
    80003ab6:	00001097          	auipc	ra,0x1
    80003aba:	b38080e7          	jalr	-1224(ra) # 800045ee <initlog>
}
    80003abe:	70a2                	ld	ra,40(sp)
    80003ac0:	7402                	ld	s0,32(sp)
    80003ac2:	64e2                	ld	s1,24(sp)
    80003ac4:	6942                	ld	s2,16(sp)
    80003ac6:	69a2                	ld	s3,8(sp)
    80003ac8:	6145                	addi	sp,sp,48
    80003aca:	8082                	ret
    panic("invalid file system");
    80003acc:	00005517          	auipc	a0,0x5
    80003ad0:	d3c50513          	addi	a0,a0,-708 # 80008808 <sysnames+0x150>
    80003ad4:	ffffd097          	auipc	ra,0xffffd
    80003ad8:	a74080e7          	jalr	-1420(ra) # 80000548 <panic>

0000000080003adc <iinit>:
{
    80003adc:	7179                	addi	sp,sp,-48
    80003ade:	f406                	sd	ra,40(sp)
    80003ae0:	f022                	sd	s0,32(sp)
    80003ae2:	ec26                	sd	s1,24(sp)
    80003ae4:	e84a                	sd	s2,16(sp)
    80003ae6:	e44e                	sd	s3,8(sp)
    80003ae8:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003aea:	00005597          	auipc	a1,0x5
    80003aee:	d3658593          	addi	a1,a1,-714 # 80008820 <sysnames+0x168>
    80003af2:	0001c517          	auipc	a0,0x1c
    80003af6:	76e50513          	addi	a0,a0,1902 # 80020260 <icache>
    80003afa:	ffffd097          	auipc	ra,0xffffd
    80003afe:	0d0080e7          	jalr	208(ra) # 80000bca <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b02:	0001c497          	auipc	s1,0x1c
    80003b06:	78648493          	addi	s1,s1,1926 # 80020288 <icache+0x28>
    80003b0a:	0001e997          	auipc	s3,0x1e
    80003b0e:	20e98993          	addi	s3,s3,526 # 80021d18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003b12:	00005917          	auipc	s2,0x5
    80003b16:	d1690913          	addi	s2,s2,-746 # 80008828 <sysnames+0x170>
    80003b1a:	85ca                	mv	a1,s2
    80003b1c:	8526                	mv	a0,s1
    80003b1e:	00001097          	auipc	ra,0x1
    80003b22:	e36080e7          	jalr	-458(ra) # 80004954 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b26:	08848493          	addi	s1,s1,136
    80003b2a:	ff3498e3          	bne	s1,s3,80003b1a <iinit+0x3e>
}
    80003b2e:	70a2                	ld	ra,40(sp)
    80003b30:	7402                	ld	s0,32(sp)
    80003b32:	64e2                	ld	s1,24(sp)
    80003b34:	6942                	ld	s2,16(sp)
    80003b36:	69a2                	ld	s3,8(sp)
    80003b38:	6145                	addi	sp,sp,48
    80003b3a:	8082                	ret

0000000080003b3c <ialloc>:
{
    80003b3c:	715d                	addi	sp,sp,-80
    80003b3e:	e486                	sd	ra,72(sp)
    80003b40:	e0a2                	sd	s0,64(sp)
    80003b42:	fc26                	sd	s1,56(sp)
    80003b44:	f84a                	sd	s2,48(sp)
    80003b46:	f44e                	sd	s3,40(sp)
    80003b48:	f052                	sd	s4,32(sp)
    80003b4a:	ec56                	sd	s5,24(sp)
    80003b4c:	e85a                	sd	s6,16(sp)
    80003b4e:	e45e                	sd	s7,8(sp)
    80003b50:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b52:	0001c717          	auipc	a4,0x1c
    80003b56:	6fa72703          	lw	a4,1786(a4) # 8002024c <sb+0xc>
    80003b5a:	4785                	li	a5,1
    80003b5c:	04e7fa63          	bgeu	a5,a4,80003bb0 <ialloc+0x74>
    80003b60:	8aaa                	mv	s5,a0
    80003b62:	8bae                	mv	s7,a1
    80003b64:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b66:	0001ca17          	auipc	s4,0x1c
    80003b6a:	6daa0a13          	addi	s4,s4,1754 # 80020240 <sb>
    80003b6e:	00048b1b          	sext.w	s6,s1
    80003b72:	0044d593          	srli	a1,s1,0x4
    80003b76:	018a2783          	lw	a5,24(s4)
    80003b7a:	9dbd                	addw	a1,a1,a5
    80003b7c:	8556                	mv	a0,s5
    80003b7e:	00000097          	auipc	ra,0x0
    80003b82:	954080e7          	jalr	-1708(ra) # 800034d2 <bread>
    80003b86:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b88:	05850993          	addi	s3,a0,88
    80003b8c:	00f4f793          	andi	a5,s1,15
    80003b90:	079a                	slli	a5,a5,0x6
    80003b92:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b94:	00099783          	lh	a5,0(s3)
    80003b98:	c785                	beqz	a5,80003bc0 <ialloc+0x84>
    brelse(bp);
    80003b9a:	00000097          	auipc	ra,0x0
    80003b9e:	a68080e7          	jalr	-1432(ra) # 80003602 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ba2:	0485                	addi	s1,s1,1
    80003ba4:	00ca2703          	lw	a4,12(s4)
    80003ba8:	0004879b          	sext.w	a5,s1
    80003bac:	fce7e1e3          	bltu	a5,a4,80003b6e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003bb0:	00005517          	auipc	a0,0x5
    80003bb4:	c8050513          	addi	a0,a0,-896 # 80008830 <sysnames+0x178>
    80003bb8:	ffffd097          	auipc	ra,0xffffd
    80003bbc:	990080e7          	jalr	-1648(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003bc0:	04000613          	li	a2,64
    80003bc4:	4581                	li	a1,0
    80003bc6:	854e                	mv	a0,s3
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	18e080e7          	jalr	398(ra) # 80000d56 <memset>
      dip->type = type;
    80003bd0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	00001097          	auipc	ra,0x1
    80003bda:	c90080e7          	jalr	-880(ra) # 80004866 <log_write>
      brelse(bp);
    80003bde:	854a                	mv	a0,s2
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	a22080e7          	jalr	-1502(ra) # 80003602 <brelse>
      return iget(dev, inum);
    80003be8:	85da                	mv	a1,s6
    80003bea:	8556                	mv	a0,s5
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	db4080e7          	jalr	-588(ra) # 800039a0 <iget>
}
    80003bf4:	60a6                	ld	ra,72(sp)
    80003bf6:	6406                	ld	s0,64(sp)
    80003bf8:	74e2                	ld	s1,56(sp)
    80003bfa:	7942                	ld	s2,48(sp)
    80003bfc:	79a2                	ld	s3,40(sp)
    80003bfe:	7a02                	ld	s4,32(sp)
    80003c00:	6ae2                	ld	s5,24(sp)
    80003c02:	6b42                	ld	s6,16(sp)
    80003c04:	6ba2                	ld	s7,8(sp)
    80003c06:	6161                	addi	sp,sp,80
    80003c08:	8082                	ret

0000000080003c0a <iupdate>:
{
    80003c0a:	1101                	addi	sp,sp,-32
    80003c0c:	ec06                	sd	ra,24(sp)
    80003c0e:	e822                	sd	s0,16(sp)
    80003c10:	e426                	sd	s1,8(sp)
    80003c12:	e04a                	sd	s2,0(sp)
    80003c14:	1000                	addi	s0,sp,32
    80003c16:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c18:	415c                	lw	a5,4(a0)
    80003c1a:	0047d79b          	srliw	a5,a5,0x4
    80003c1e:	0001c597          	auipc	a1,0x1c
    80003c22:	63a5a583          	lw	a1,1594(a1) # 80020258 <sb+0x18>
    80003c26:	9dbd                	addw	a1,a1,a5
    80003c28:	4108                	lw	a0,0(a0)
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	8a8080e7          	jalr	-1880(ra) # 800034d2 <bread>
    80003c32:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c34:	05850793          	addi	a5,a0,88
    80003c38:	40c8                	lw	a0,4(s1)
    80003c3a:	893d                	andi	a0,a0,15
    80003c3c:	051a                	slli	a0,a0,0x6
    80003c3e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c40:	04449703          	lh	a4,68(s1)
    80003c44:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c48:	04649703          	lh	a4,70(s1)
    80003c4c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c50:	04849703          	lh	a4,72(s1)
    80003c54:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c58:	04a49703          	lh	a4,74(s1)
    80003c5c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c60:	44f8                	lw	a4,76(s1)
    80003c62:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c64:	03400613          	li	a2,52
    80003c68:	05048593          	addi	a1,s1,80
    80003c6c:	0531                	addi	a0,a0,12
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	148080e7          	jalr	328(ra) # 80000db6 <memmove>
  log_write(bp);
    80003c76:	854a                	mv	a0,s2
    80003c78:	00001097          	auipc	ra,0x1
    80003c7c:	bee080e7          	jalr	-1042(ra) # 80004866 <log_write>
  brelse(bp);
    80003c80:	854a                	mv	a0,s2
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	980080e7          	jalr	-1664(ra) # 80003602 <brelse>
}
    80003c8a:	60e2                	ld	ra,24(sp)
    80003c8c:	6442                	ld	s0,16(sp)
    80003c8e:	64a2                	ld	s1,8(sp)
    80003c90:	6902                	ld	s2,0(sp)
    80003c92:	6105                	addi	sp,sp,32
    80003c94:	8082                	ret

0000000080003c96 <idup>:
{
    80003c96:	1101                	addi	sp,sp,-32
    80003c98:	ec06                	sd	ra,24(sp)
    80003c9a:	e822                	sd	s0,16(sp)
    80003c9c:	e426                	sd	s1,8(sp)
    80003c9e:	1000                	addi	s0,sp,32
    80003ca0:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003ca2:	0001c517          	auipc	a0,0x1c
    80003ca6:	5be50513          	addi	a0,a0,1470 # 80020260 <icache>
    80003caa:	ffffd097          	auipc	ra,0xffffd
    80003cae:	fb0080e7          	jalr	-80(ra) # 80000c5a <acquire>
  ip->ref++;
    80003cb2:	449c                	lw	a5,8(s1)
    80003cb4:	2785                	addiw	a5,a5,1
    80003cb6:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003cb8:	0001c517          	auipc	a0,0x1c
    80003cbc:	5a850513          	addi	a0,a0,1448 # 80020260 <icache>
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	04e080e7          	jalr	78(ra) # 80000d0e <release>
}
    80003cc8:	8526                	mv	a0,s1
    80003cca:	60e2                	ld	ra,24(sp)
    80003ccc:	6442                	ld	s0,16(sp)
    80003cce:	64a2                	ld	s1,8(sp)
    80003cd0:	6105                	addi	sp,sp,32
    80003cd2:	8082                	ret

0000000080003cd4 <ilock>:
{
    80003cd4:	1101                	addi	sp,sp,-32
    80003cd6:	ec06                	sd	ra,24(sp)
    80003cd8:	e822                	sd	s0,16(sp)
    80003cda:	e426                	sd	s1,8(sp)
    80003cdc:	e04a                	sd	s2,0(sp)
    80003cde:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ce0:	c115                	beqz	a0,80003d04 <ilock+0x30>
    80003ce2:	84aa                	mv	s1,a0
    80003ce4:	451c                	lw	a5,8(a0)
    80003ce6:	00f05f63          	blez	a5,80003d04 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003cea:	0541                	addi	a0,a0,16
    80003cec:	00001097          	auipc	ra,0x1
    80003cf0:	ca2080e7          	jalr	-862(ra) # 8000498e <acquiresleep>
  if(ip->valid == 0){
    80003cf4:	40bc                	lw	a5,64(s1)
    80003cf6:	cf99                	beqz	a5,80003d14 <ilock+0x40>
}
    80003cf8:	60e2                	ld	ra,24(sp)
    80003cfa:	6442                	ld	s0,16(sp)
    80003cfc:	64a2                	ld	s1,8(sp)
    80003cfe:	6902                	ld	s2,0(sp)
    80003d00:	6105                	addi	sp,sp,32
    80003d02:	8082                	ret
    panic("ilock");
    80003d04:	00005517          	auipc	a0,0x5
    80003d08:	b4450513          	addi	a0,a0,-1212 # 80008848 <sysnames+0x190>
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	83c080e7          	jalr	-1988(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d14:	40dc                	lw	a5,4(s1)
    80003d16:	0047d79b          	srliw	a5,a5,0x4
    80003d1a:	0001c597          	auipc	a1,0x1c
    80003d1e:	53e5a583          	lw	a1,1342(a1) # 80020258 <sb+0x18>
    80003d22:	9dbd                	addw	a1,a1,a5
    80003d24:	4088                	lw	a0,0(s1)
    80003d26:	fffff097          	auipc	ra,0xfffff
    80003d2a:	7ac080e7          	jalr	1964(ra) # 800034d2 <bread>
    80003d2e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d30:	05850593          	addi	a1,a0,88
    80003d34:	40dc                	lw	a5,4(s1)
    80003d36:	8bbd                	andi	a5,a5,15
    80003d38:	079a                	slli	a5,a5,0x6
    80003d3a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d3c:	00059783          	lh	a5,0(a1)
    80003d40:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d44:	00259783          	lh	a5,2(a1)
    80003d48:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d4c:	00459783          	lh	a5,4(a1)
    80003d50:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d54:	00659783          	lh	a5,6(a1)
    80003d58:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d5c:	459c                	lw	a5,8(a1)
    80003d5e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d60:	03400613          	li	a2,52
    80003d64:	05b1                	addi	a1,a1,12
    80003d66:	05048513          	addi	a0,s1,80
    80003d6a:	ffffd097          	auipc	ra,0xffffd
    80003d6e:	04c080e7          	jalr	76(ra) # 80000db6 <memmove>
    brelse(bp);
    80003d72:	854a                	mv	a0,s2
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	88e080e7          	jalr	-1906(ra) # 80003602 <brelse>
    ip->valid = 1;
    80003d7c:	4785                	li	a5,1
    80003d7e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d80:	04449783          	lh	a5,68(s1)
    80003d84:	fbb5                	bnez	a5,80003cf8 <ilock+0x24>
      panic("ilock: no type");
    80003d86:	00005517          	auipc	a0,0x5
    80003d8a:	aca50513          	addi	a0,a0,-1334 # 80008850 <sysnames+0x198>
    80003d8e:	ffffc097          	auipc	ra,0xffffc
    80003d92:	7ba080e7          	jalr	1978(ra) # 80000548 <panic>

0000000080003d96 <iunlock>:
{
    80003d96:	1101                	addi	sp,sp,-32
    80003d98:	ec06                	sd	ra,24(sp)
    80003d9a:	e822                	sd	s0,16(sp)
    80003d9c:	e426                	sd	s1,8(sp)
    80003d9e:	e04a                	sd	s2,0(sp)
    80003da0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003da2:	c905                	beqz	a0,80003dd2 <iunlock+0x3c>
    80003da4:	84aa                	mv	s1,a0
    80003da6:	01050913          	addi	s2,a0,16
    80003daa:	854a                	mv	a0,s2
    80003dac:	00001097          	auipc	ra,0x1
    80003db0:	c7c080e7          	jalr	-900(ra) # 80004a28 <holdingsleep>
    80003db4:	cd19                	beqz	a0,80003dd2 <iunlock+0x3c>
    80003db6:	449c                	lw	a5,8(s1)
    80003db8:	00f05d63          	blez	a5,80003dd2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003dbc:	854a                	mv	a0,s2
    80003dbe:	00001097          	auipc	ra,0x1
    80003dc2:	c26080e7          	jalr	-986(ra) # 800049e4 <releasesleep>
}
    80003dc6:	60e2                	ld	ra,24(sp)
    80003dc8:	6442                	ld	s0,16(sp)
    80003dca:	64a2                	ld	s1,8(sp)
    80003dcc:	6902                	ld	s2,0(sp)
    80003dce:	6105                	addi	sp,sp,32
    80003dd0:	8082                	ret
    panic("iunlock");
    80003dd2:	00005517          	auipc	a0,0x5
    80003dd6:	a8e50513          	addi	a0,a0,-1394 # 80008860 <sysnames+0x1a8>
    80003dda:	ffffc097          	auipc	ra,0xffffc
    80003dde:	76e080e7          	jalr	1902(ra) # 80000548 <panic>

0000000080003de2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003de2:	7179                	addi	sp,sp,-48
    80003de4:	f406                	sd	ra,40(sp)
    80003de6:	f022                	sd	s0,32(sp)
    80003de8:	ec26                	sd	s1,24(sp)
    80003dea:	e84a                	sd	s2,16(sp)
    80003dec:	e44e                	sd	s3,8(sp)
    80003dee:	e052                	sd	s4,0(sp)
    80003df0:	1800                	addi	s0,sp,48
    80003df2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003df4:	05050493          	addi	s1,a0,80
    80003df8:	08050913          	addi	s2,a0,128
    80003dfc:	a021                	j	80003e04 <itrunc+0x22>
    80003dfe:	0491                	addi	s1,s1,4
    80003e00:	01248d63          	beq	s1,s2,80003e1a <itrunc+0x38>
    if(ip->addrs[i]){
    80003e04:	408c                	lw	a1,0(s1)
    80003e06:	dde5                	beqz	a1,80003dfe <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e08:	0009a503          	lw	a0,0(s3)
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	90c080e7          	jalr	-1780(ra) # 80003718 <bfree>
      ip->addrs[i] = 0;
    80003e14:	0004a023          	sw	zero,0(s1)
    80003e18:	b7dd                	j	80003dfe <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e1a:	0809a583          	lw	a1,128(s3)
    80003e1e:	e185                	bnez	a1,80003e3e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e20:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e24:	854e                	mv	a0,s3
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	de4080e7          	jalr	-540(ra) # 80003c0a <iupdate>
}
    80003e2e:	70a2                	ld	ra,40(sp)
    80003e30:	7402                	ld	s0,32(sp)
    80003e32:	64e2                	ld	s1,24(sp)
    80003e34:	6942                	ld	s2,16(sp)
    80003e36:	69a2                	ld	s3,8(sp)
    80003e38:	6a02                	ld	s4,0(sp)
    80003e3a:	6145                	addi	sp,sp,48
    80003e3c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e3e:	0009a503          	lw	a0,0(s3)
    80003e42:	fffff097          	auipc	ra,0xfffff
    80003e46:	690080e7          	jalr	1680(ra) # 800034d2 <bread>
    80003e4a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e4c:	05850493          	addi	s1,a0,88
    80003e50:	45850913          	addi	s2,a0,1112
    80003e54:	a811                	j	80003e68 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e56:	0009a503          	lw	a0,0(s3)
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	8be080e7          	jalr	-1858(ra) # 80003718 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e62:	0491                	addi	s1,s1,4
    80003e64:	01248563          	beq	s1,s2,80003e6e <itrunc+0x8c>
      if(a[j])
    80003e68:	408c                	lw	a1,0(s1)
    80003e6a:	dde5                	beqz	a1,80003e62 <itrunc+0x80>
    80003e6c:	b7ed                	j	80003e56 <itrunc+0x74>
    brelse(bp);
    80003e6e:	8552                	mv	a0,s4
    80003e70:	fffff097          	auipc	ra,0xfffff
    80003e74:	792080e7          	jalr	1938(ra) # 80003602 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e78:	0809a583          	lw	a1,128(s3)
    80003e7c:	0009a503          	lw	a0,0(s3)
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	898080e7          	jalr	-1896(ra) # 80003718 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e88:	0809a023          	sw	zero,128(s3)
    80003e8c:	bf51                	j	80003e20 <itrunc+0x3e>

0000000080003e8e <iput>:
{
    80003e8e:	1101                	addi	sp,sp,-32
    80003e90:	ec06                	sd	ra,24(sp)
    80003e92:	e822                	sd	s0,16(sp)
    80003e94:	e426                	sd	s1,8(sp)
    80003e96:	e04a                	sd	s2,0(sp)
    80003e98:	1000                	addi	s0,sp,32
    80003e9a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003e9c:	0001c517          	auipc	a0,0x1c
    80003ea0:	3c450513          	addi	a0,a0,964 # 80020260 <icache>
    80003ea4:	ffffd097          	auipc	ra,0xffffd
    80003ea8:	db6080e7          	jalr	-586(ra) # 80000c5a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003eac:	4498                	lw	a4,8(s1)
    80003eae:	4785                	li	a5,1
    80003eb0:	02f70363          	beq	a4,a5,80003ed6 <iput+0x48>
  ip->ref--;
    80003eb4:	449c                	lw	a5,8(s1)
    80003eb6:	37fd                	addiw	a5,a5,-1
    80003eb8:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003eba:	0001c517          	auipc	a0,0x1c
    80003ebe:	3a650513          	addi	a0,a0,934 # 80020260 <icache>
    80003ec2:	ffffd097          	auipc	ra,0xffffd
    80003ec6:	e4c080e7          	jalr	-436(ra) # 80000d0e <release>
}
    80003eca:	60e2                	ld	ra,24(sp)
    80003ecc:	6442                	ld	s0,16(sp)
    80003ece:	64a2                	ld	s1,8(sp)
    80003ed0:	6902                	ld	s2,0(sp)
    80003ed2:	6105                	addi	sp,sp,32
    80003ed4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ed6:	40bc                	lw	a5,64(s1)
    80003ed8:	dff1                	beqz	a5,80003eb4 <iput+0x26>
    80003eda:	04a49783          	lh	a5,74(s1)
    80003ede:	fbf9                	bnez	a5,80003eb4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ee0:	01048913          	addi	s2,s1,16
    80003ee4:	854a                	mv	a0,s2
    80003ee6:	00001097          	auipc	ra,0x1
    80003eea:	aa8080e7          	jalr	-1368(ra) # 8000498e <acquiresleep>
    release(&icache.lock);
    80003eee:	0001c517          	auipc	a0,0x1c
    80003ef2:	37250513          	addi	a0,a0,882 # 80020260 <icache>
    80003ef6:	ffffd097          	auipc	ra,0xffffd
    80003efa:	e18080e7          	jalr	-488(ra) # 80000d0e <release>
    itrunc(ip);
    80003efe:	8526                	mv	a0,s1
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	ee2080e7          	jalr	-286(ra) # 80003de2 <itrunc>
    ip->type = 0;
    80003f08:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f0c:	8526                	mv	a0,s1
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	cfc080e7          	jalr	-772(ra) # 80003c0a <iupdate>
    ip->valid = 0;
    80003f16:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f1a:	854a                	mv	a0,s2
    80003f1c:	00001097          	auipc	ra,0x1
    80003f20:	ac8080e7          	jalr	-1336(ra) # 800049e4 <releasesleep>
    acquire(&icache.lock);
    80003f24:	0001c517          	auipc	a0,0x1c
    80003f28:	33c50513          	addi	a0,a0,828 # 80020260 <icache>
    80003f2c:	ffffd097          	auipc	ra,0xffffd
    80003f30:	d2e080e7          	jalr	-722(ra) # 80000c5a <acquire>
    80003f34:	b741                	j	80003eb4 <iput+0x26>

0000000080003f36 <iunlockput>:
{
    80003f36:	1101                	addi	sp,sp,-32
    80003f38:	ec06                	sd	ra,24(sp)
    80003f3a:	e822                	sd	s0,16(sp)
    80003f3c:	e426                	sd	s1,8(sp)
    80003f3e:	1000                	addi	s0,sp,32
    80003f40:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	e54080e7          	jalr	-428(ra) # 80003d96 <iunlock>
  iput(ip);
    80003f4a:	8526                	mv	a0,s1
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	f42080e7          	jalr	-190(ra) # 80003e8e <iput>
}
    80003f54:	60e2                	ld	ra,24(sp)
    80003f56:	6442                	ld	s0,16(sp)
    80003f58:	64a2                	ld	s1,8(sp)
    80003f5a:	6105                	addi	sp,sp,32
    80003f5c:	8082                	ret

0000000080003f5e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f5e:	1141                	addi	sp,sp,-16
    80003f60:	e422                	sd	s0,8(sp)
    80003f62:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f64:	411c                	lw	a5,0(a0)
    80003f66:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f68:	415c                	lw	a5,4(a0)
    80003f6a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f6c:	04451783          	lh	a5,68(a0)
    80003f70:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f74:	04a51783          	lh	a5,74(a0)
    80003f78:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f7c:	04c56783          	lwu	a5,76(a0)
    80003f80:	e99c                	sd	a5,16(a1)
}
    80003f82:	6422                	ld	s0,8(sp)
    80003f84:	0141                	addi	sp,sp,16
    80003f86:	8082                	ret

0000000080003f88 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f88:	457c                	lw	a5,76(a0)
    80003f8a:	0ed7e863          	bltu	a5,a3,8000407a <readi+0xf2>
{
    80003f8e:	7159                	addi	sp,sp,-112
    80003f90:	f486                	sd	ra,104(sp)
    80003f92:	f0a2                	sd	s0,96(sp)
    80003f94:	eca6                	sd	s1,88(sp)
    80003f96:	e8ca                	sd	s2,80(sp)
    80003f98:	e4ce                	sd	s3,72(sp)
    80003f9a:	e0d2                	sd	s4,64(sp)
    80003f9c:	fc56                	sd	s5,56(sp)
    80003f9e:	f85a                	sd	s6,48(sp)
    80003fa0:	f45e                	sd	s7,40(sp)
    80003fa2:	f062                	sd	s8,32(sp)
    80003fa4:	ec66                	sd	s9,24(sp)
    80003fa6:	e86a                	sd	s10,16(sp)
    80003fa8:	e46e                	sd	s11,8(sp)
    80003faa:	1880                	addi	s0,sp,112
    80003fac:	8baa                	mv	s7,a0
    80003fae:	8c2e                	mv	s8,a1
    80003fb0:	8ab2                	mv	s5,a2
    80003fb2:	84b6                	mv	s1,a3
    80003fb4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fb6:	9f35                	addw	a4,a4,a3
    return 0;
    80003fb8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003fba:	08d76f63          	bltu	a4,a3,80004058 <readi+0xd0>
  if(off + n > ip->size)
    80003fbe:	00e7f463          	bgeu	a5,a4,80003fc6 <readi+0x3e>
    n = ip->size - off;
    80003fc2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fc6:	0a0b0863          	beqz	s6,80004076 <readi+0xee>
    80003fca:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fcc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fd0:	5cfd                	li	s9,-1
    80003fd2:	a82d                	j	8000400c <readi+0x84>
    80003fd4:	020a1d93          	slli	s11,s4,0x20
    80003fd8:	020ddd93          	srli	s11,s11,0x20
    80003fdc:	05890613          	addi	a2,s2,88
    80003fe0:	86ee                	mv	a3,s11
    80003fe2:	963a                	add	a2,a2,a4
    80003fe4:	85d6                	mv	a1,s5
    80003fe6:	8562                	mv	a0,s8
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	9fe080e7          	jalr	-1538(ra) # 800029e6 <either_copyout>
    80003ff0:	05950d63          	beq	a0,s9,8000404a <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003ff4:	854a                	mv	a0,s2
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	60c080e7          	jalr	1548(ra) # 80003602 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ffe:	013a09bb          	addw	s3,s4,s3
    80004002:	009a04bb          	addw	s1,s4,s1
    80004006:	9aee                	add	s5,s5,s11
    80004008:	0569f663          	bgeu	s3,s6,80004054 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000400c:	000ba903          	lw	s2,0(s7)
    80004010:	00a4d59b          	srliw	a1,s1,0xa
    80004014:	855e                	mv	a0,s7
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	8b0080e7          	jalr	-1872(ra) # 800038c6 <bmap>
    8000401e:	0005059b          	sext.w	a1,a0
    80004022:	854a                	mv	a0,s2
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	4ae080e7          	jalr	1198(ra) # 800034d2 <bread>
    8000402c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000402e:	3ff4f713          	andi	a4,s1,1023
    80004032:	40ed07bb          	subw	a5,s10,a4
    80004036:	413b06bb          	subw	a3,s6,s3
    8000403a:	8a3e                	mv	s4,a5
    8000403c:	2781                	sext.w	a5,a5
    8000403e:	0006861b          	sext.w	a2,a3
    80004042:	f8f679e3          	bgeu	a2,a5,80003fd4 <readi+0x4c>
    80004046:	8a36                	mv	s4,a3
    80004048:	b771                	j	80003fd4 <readi+0x4c>
      brelse(bp);
    8000404a:	854a                	mv	a0,s2
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	5b6080e7          	jalr	1462(ra) # 80003602 <brelse>
  }
  return tot;
    80004054:	0009851b          	sext.w	a0,s3
}
    80004058:	70a6                	ld	ra,104(sp)
    8000405a:	7406                	ld	s0,96(sp)
    8000405c:	64e6                	ld	s1,88(sp)
    8000405e:	6946                	ld	s2,80(sp)
    80004060:	69a6                	ld	s3,72(sp)
    80004062:	6a06                	ld	s4,64(sp)
    80004064:	7ae2                	ld	s5,56(sp)
    80004066:	7b42                	ld	s6,48(sp)
    80004068:	7ba2                	ld	s7,40(sp)
    8000406a:	7c02                	ld	s8,32(sp)
    8000406c:	6ce2                	ld	s9,24(sp)
    8000406e:	6d42                	ld	s10,16(sp)
    80004070:	6da2                	ld	s11,8(sp)
    80004072:	6165                	addi	sp,sp,112
    80004074:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004076:	89da                	mv	s3,s6
    80004078:	bff1                	j	80004054 <readi+0xcc>
    return 0;
    8000407a:	4501                	li	a0,0
}
    8000407c:	8082                	ret

000000008000407e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000407e:	457c                	lw	a5,76(a0)
    80004080:	10d7e663          	bltu	a5,a3,8000418c <writei+0x10e>
{
    80004084:	7159                	addi	sp,sp,-112
    80004086:	f486                	sd	ra,104(sp)
    80004088:	f0a2                	sd	s0,96(sp)
    8000408a:	eca6                	sd	s1,88(sp)
    8000408c:	e8ca                	sd	s2,80(sp)
    8000408e:	e4ce                	sd	s3,72(sp)
    80004090:	e0d2                	sd	s4,64(sp)
    80004092:	fc56                	sd	s5,56(sp)
    80004094:	f85a                	sd	s6,48(sp)
    80004096:	f45e                	sd	s7,40(sp)
    80004098:	f062                	sd	s8,32(sp)
    8000409a:	ec66                	sd	s9,24(sp)
    8000409c:	e86a                	sd	s10,16(sp)
    8000409e:	e46e                	sd	s11,8(sp)
    800040a0:	1880                	addi	s0,sp,112
    800040a2:	8baa                	mv	s7,a0
    800040a4:	8c2e                	mv	s8,a1
    800040a6:	8ab2                	mv	s5,a2
    800040a8:	8936                	mv	s2,a3
    800040aa:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040ac:	00e687bb          	addw	a5,a3,a4
    800040b0:	0ed7e063          	bltu	a5,a3,80004190 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040b4:	00043737          	lui	a4,0x43
    800040b8:	0cf76e63          	bltu	a4,a5,80004194 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040bc:	0a0b0763          	beqz	s6,8000416a <writei+0xec>
    800040c0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040c2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040c6:	5cfd                	li	s9,-1
    800040c8:	a091                	j	8000410c <writei+0x8e>
    800040ca:	02099d93          	slli	s11,s3,0x20
    800040ce:	020ddd93          	srli	s11,s11,0x20
    800040d2:	05848513          	addi	a0,s1,88
    800040d6:	86ee                	mv	a3,s11
    800040d8:	8656                	mv	a2,s5
    800040da:	85e2                	mv	a1,s8
    800040dc:	953a                	add	a0,a0,a4
    800040de:	fffff097          	auipc	ra,0xfffff
    800040e2:	95e080e7          	jalr	-1698(ra) # 80002a3c <either_copyin>
    800040e6:	07950263          	beq	a0,s9,8000414a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040ea:	8526                	mv	a0,s1
    800040ec:	00000097          	auipc	ra,0x0
    800040f0:	77a080e7          	jalr	1914(ra) # 80004866 <log_write>
    brelse(bp);
    800040f4:	8526                	mv	a0,s1
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	50c080e7          	jalr	1292(ra) # 80003602 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040fe:	01498a3b          	addw	s4,s3,s4
    80004102:	0129893b          	addw	s2,s3,s2
    80004106:	9aee                	add	s5,s5,s11
    80004108:	056a7663          	bgeu	s4,s6,80004154 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000410c:	000ba483          	lw	s1,0(s7)
    80004110:	00a9559b          	srliw	a1,s2,0xa
    80004114:	855e                	mv	a0,s7
    80004116:	fffff097          	auipc	ra,0xfffff
    8000411a:	7b0080e7          	jalr	1968(ra) # 800038c6 <bmap>
    8000411e:	0005059b          	sext.w	a1,a0
    80004122:	8526                	mv	a0,s1
    80004124:	fffff097          	auipc	ra,0xfffff
    80004128:	3ae080e7          	jalr	942(ra) # 800034d2 <bread>
    8000412c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000412e:	3ff97713          	andi	a4,s2,1023
    80004132:	40ed07bb          	subw	a5,s10,a4
    80004136:	414b06bb          	subw	a3,s6,s4
    8000413a:	89be                	mv	s3,a5
    8000413c:	2781                	sext.w	a5,a5
    8000413e:	0006861b          	sext.w	a2,a3
    80004142:	f8f674e3          	bgeu	a2,a5,800040ca <writei+0x4c>
    80004146:	89b6                	mv	s3,a3
    80004148:	b749                	j	800040ca <writei+0x4c>
      brelse(bp);
    8000414a:	8526                	mv	a0,s1
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	4b6080e7          	jalr	1206(ra) # 80003602 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80004154:	04cba783          	lw	a5,76(s7)
    80004158:	0127f463          	bgeu	a5,s2,80004160 <writei+0xe2>
      ip->size = off;
    8000415c:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80004160:	855e                	mv	a0,s7
    80004162:	00000097          	auipc	ra,0x0
    80004166:	aa8080e7          	jalr	-1368(ra) # 80003c0a <iupdate>
  }

  return n;
    8000416a:	000b051b          	sext.w	a0,s6
}
    8000416e:	70a6                	ld	ra,104(sp)
    80004170:	7406                	ld	s0,96(sp)
    80004172:	64e6                	ld	s1,88(sp)
    80004174:	6946                	ld	s2,80(sp)
    80004176:	69a6                	ld	s3,72(sp)
    80004178:	6a06                	ld	s4,64(sp)
    8000417a:	7ae2                	ld	s5,56(sp)
    8000417c:	7b42                	ld	s6,48(sp)
    8000417e:	7ba2                	ld	s7,40(sp)
    80004180:	7c02                	ld	s8,32(sp)
    80004182:	6ce2                	ld	s9,24(sp)
    80004184:	6d42                	ld	s10,16(sp)
    80004186:	6da2                	ld	s11,8(sp)
    80004188:	6165                	addi	sp,sp,112
    8000418a:	8082                	ret
    return -1;
    8000418c:	557d                	li	a0,-1
}
    8000418e:	8082                	ret
    return -1;
    80004190:	557d                	li	a0,-1
    80004192:	bff1                	j	8000416e <writei+0xf0>
    return -1;
    80004194:	557d                	li	a0,-1
    80004196:	bfe1                	j	8000416e <writei+0xf0>

0000000080004198 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004198:	1141                	addi	sp,sp,-16
    8000419a:	e406                	sd	ra,8(sp)
    8000419c:	e022                	sd	s0,0(sp)
    8000419e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041a0:	4639                	li	a2,14
    800041a2:	ffffd097          	auipc	ra,0xffffd
    800041a6:	c90080e7          	jalr	-880(ra) # 80000e32 <strncmp>
}
    800041aa:	60a2                	ld	ra,8(sp)
    800041ac:	6402                	ld	s0,0(sp)
    800041ae:	0141                	addi	sp,sp,16
    800041b0:	8082                	ret

00000000800041b2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041b2:	7139                	addi	sp,sp,-64
    800041b4:	fc06                	sd	ra,56(sp)
    800041b6:	f822                	sd	s0,48(sp)
    800041b8:	f426                	sd	s1,40(sp)
    800041ba:	f04a                	sd	s2,32(sp)
    800041bc:	ec4e                	sd	s3,24(sp)
    800041be:	e852                	sd	s4,16(sp)
    800041c0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041c2:	04451703          	lh	a4,68(a0)
    800041c6:	4785                	li	a5,1
    800041c8:	00f71a63          	bne	a4,a5,800041dc <dirlookup+0x2a>
    800041cc:	892a                	mv	s2,a0
    800041ce:	89ae                	mv	s3,a1
    800041d0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041d2:	457c                	lw	a5,76(a0)
    800041d4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041d6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041d8:	e79d                	bnez	a5,80004206 <dirlookup+0x54>
    800041da:	a8a5                	j	80004252 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041dc:	00004517          	auipc	a0,0x4
    800041e0:	68c50513          	addi	a0,a0,1676 # 80008868 <sysnames+0x1b0>
    800041e4:	ffffc097          	auipc	ra,0xffffc
    800041e8:	364080e7          	jalr	868(ra) # 80000548 <panic>
      panic("dirlookup read");
    800041ec:	00004517          	auipc	a0,0x4
    800041f0:	69450513          	addi	a0,a0,1684 # 80008880 <sysnames+0x1c8>
    800041f4:	ffffc097          	auipc	ra,0xffffc
    800041f8:	354080e7          	jalr	852(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041fc:	24c1                	addiw	s1,s1,16
    800041fe:	04c92783          	lw	a5,76(s2)
    80004202:	04f4f763          	bgeu	s1,a5,80004250 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004206:	4741                	li	a4,16
    80004208:	86a6                	mv	a3,s1
    8000420a:	fc040613          	addi	a2,s0,-64
    8000420e:	4581                	li	a1,0
    80004210:	854a                	mv	a0,s2
    80004212:	00000097          	auipc	ra,0x0
    80004216:	d76080e7          	jalr	-650(ra) # 80003f88 <readi>
    8000421a:	47c1                	li	a5,16
    8000421c:	fcf518e3          	bne	a0,a5,800041ec <dirlookup+0x3a>
    if(de.inum == 0)
    80004220:	fc045783          	lhu	a5,-64(s0)
    80004224:	dfe1                	beqz	a5,800041fc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004226:	fc240593          	addi	a1,s0,-62
    8000422a:	854e                	mv	a0,s3
    8000422c:	00000097          	auipc	ra,0x0
    80004230:	f6c080e7          	jalr	-148(ra) # 80004198 <namecmp>
    80004234:	f561                	bnez	a0,800041fc <dirlookup+0x4a>
      if(poff)
    80004236:	000a0463          	beqz	s4,8000423e <dirlookup+0x8c>
        *poff = off;
    8000423a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000423e:	fc045583          	lhu	a1,-64(s0)
    80004242:	00092503          	lw	a0,0(s2)
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	75a080e7          	jalr	1882(ra) # 800039a0 <iget>
    8000424e:	a011                	j	80004252 <dirlookup+0xa0>
  return 0;
    80004250:	4501                	li	a0,0
}
    80004252:	70e2                	ld	ra,56(sp)
    80004254:	7442                	ld	s0,48(sp)
    80004256:	74a2                	ld	s1,40(sp)
    80004258:	7902                	ld	s2,32(sp)
    8000425a:	69e2                	ld	s3,24(sp)
    8000425c:	6a42                	ld	s4,16(sp)
    8000425e:	6121                	addi	sp,sp,64
    80004260:	8082                	ret

0000000080004262 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004262:	711d                	addi	sp,sp,-96
    80004264:	ec86                	sd	ra,88(sp)
    80004266:	e8a2                	sd	s0,80(sp)
    80004268:	e4a6                	sd	s1,72(sp)
    8000426a:	e0ca                	sd	s2,64(sp)
    8000426c:	fc4e                	sd	s3,56(sp)
    8000426e:	f852                	sd	s4,48(sp)
    80004270:	f456                	sd	s5,40(sp)
    80004272:	f05a                	sd	s6,32(sp)
    80004274:	ec5e                	sd	s7,24(sp)
    80004276:	e862                	sd	s8,16(sp)
    80004278:	e466                	sd	s9,8(sp)
    8000427a:	1080                	addi	s0,sp,96
    8000427c:	84aa                	mv	s1,a0
    8000427e:	8b2e                	mv	s6,a1
    80004280:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004282:	00054703          	lbu	a4,0(a0)
    80004286:	02f00793          	li	a5,47
    8000428a:	02f70363          	beq	a4,a5,800042b0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000428e:	ffffe097          	auipc	ra,0xffffe
    80004292:	b5e080e7          	jalr	-1186(ra) # 80001dec <myproc>
    80004296:	15053503          	ld	a0,336(a0)
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	9fc080e7          	jalr	-1540(ra) # 80003c96 <idup>
    800042a2:	89aa                	mv	s3,a0
  while(*path == '/')
    800042a4:	02f00913          	li	s2,47
  len = path - s;
    800042a8:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800042aa:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042ac:	4c05                	li	s8,1
    800042ae:	a865                	j	80004366 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042b0:	4585                	li	a1,1
    800042b2:	4505                	li	a0,1
    800042b4:	fffff097          	auipc	ra,0xfffff
    800042b8:	6ec080e7          	jalr	1772(ra) # 800039a0 <iget>
    800042bc:	89aa                	mv	s3,a0
    800042be:	b7dd                	j	800042a4 <namex+0x42>
      iunlockput(ip);
    800042c0:	854e                	mv	a0,s3
    800042c2:	00000097          	auipc	ra,0x0
    800042c6:	c74080e7          	jalr	-908(ra) # 80003f36 <iunlockput>
      return 0;
    800042ca:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042cc:	854e                	mv	a0,s3
    800042ce:	60e6                	ld	ra,88(sp)
    800042d0:	6446                	ld	s0,80(sp)
    800042d2:	64a6                	ld	s1,72(sp)
    800042d4:	6906                	ld	s2,64(sp)
    800042d6:	79e2                	ld	s3,56(sp)
    800042d8:	7a42                	ld	s4,48(sp)
    800042da:	7aa2                	ld	s5,40(sp)
    800042dc:	7b02                	ld	s6,32(sp)
    800042de:	6be2                	ld	s7,24(sp)
    800042e0:	6c42                	ld	s8,16(sp)
    800042e2:	6ca2                	ld	s9,8(sp)
    800042e4:	6125                	addi	sp,sp,96
    800042e6:	8082                	ret
      iunlock(ip);
    800042e8:	854e                	mv	a0,s3
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	aac080e7          	jalr	-1364(ra) # 80003d96 <iunlock>
      return ip;
    800042f2:	bfe9                	j	800042cc <namex+0x6a>
      iunlockput(ip);
    800042f4:	854e                	mv	a0,s3
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	c40080e7          	jalr	-960(ra) # 80003f36 <iunlockput>
      return 0;
    800042fe:	89d2                	mv	s3,s4
    80004300:	b7f1                	j	800042cc <namex+0x6a>
  len = path - s;
    80004302:	40b48633          	sub	a2,s1,a1
    80004306:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000430a:	094cd463          	bge	s9,s4,80004392 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000430e:	4639                	li	a2,14
    80004310:	8556                	mv	a0,s5
    80004312:	ffffd097          	auipc	ra,0xffffd
    80004316:	aa4080e7          	jalr	-1372(ra) # 80000db6 <memmove>
  while(*path == '/')
    8000431a:	0004c783          	lbu	a5,0(s1)
    8000431e:	01279763          	bne	a5,s2,8000432c <namex+0xca>
    path++;
    80004322:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004324:	0004c783          	lbu	a5,0(s1)
    80004328:	ff278de3          	beq	a5,s2,80004322 <namex+0xc0>
    ilock(ip);
    8000432c:	854e                	mv	a0,s3
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	9a6080e7          	jalr	-1626(ra) # 80003cd4 <ilock>
    if(ip->type != T_DIR){
    80004336:	04499783          	lh	a5,68(s3)
    8000433a:	f98793e3          	bne	a5,s8,800042c0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000433e:	000b0563          	beqz	s6,80004348 <namex+0xe6>
    80004342:	0004c783          	lbu	a5,0(s1)
    80004346:	d3cd                	beqz	a5,800042e8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004348:	865e                	mv	a2,s7
    8000434a:	85d6                	mv	a1,s5
    8000434c:	854e                	mv	a0,s3
    8000434e:	00000097          	auipc	ra,0x0
    80004352:	e64080e7          	jalr	-412(ra) # 800041b2 <dirlookup>
    80004356:	8a2a                	mv	s4,a0
    80004358:	dd51                	beqz	a0,800042f4 <namex+0x92>
    iunlockput(ip);
    8000435a:	854e                	mv	a0,s3
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	bda080e7          	jalr	-1062(ra) # 80003f36 <iunlockput>
    ip = next;
    80004364:	89d2                	mv	s3,s4
  while(*path == '/')
    80004366:	0004c783          	lbu	a5,0(s1)
    8000436a:	05279763          	bne	a5,s2,800043b8 <namex+0x156>
    path++;
    8000436e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004370:	0004c783          	lbu	a5,0(s1)
    80004374:	ff278de3          	beq	a5,s2,8000436e <namex+0x10c>
  if(*path == 0)
    80004378:	c79d                	beqz	a5,800043a6 <namex+0x144>
    path++;
    8000437a:	85a6                	mv	a1,s1
  len = path - s;
    8000437c:	8a5e                	mv	s4,s7
    8000437e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004380:	01278963          	beq	a5,s2,80004392 <namex+0x130>
    80004384:	dfbd                	beqz	a5,80004302 <namex+0xa0>
    path++;
    80004386:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004388:	0004c783          	lbu	a5,0(s1)
    8000438c:	ff279ce3          	bne	a5,s2,80004384 <namex+0x122>
    80004390:	bf8d                	j	80004302 <namex+0xa0>
    memmove(name, s, len);
    80004392:	2601                	sext.w	a2,a2
    80004394:	8556                	mv	a0,s5
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	a20080e7          	jalr	-1504(ra) # 80000db6 <memmove>
    name[len] = 0;
    8000439e:	9a56                	add	s4,s4,s5
    800043a0:	000a0023          	sb	zero,0(s4)
    800043a4:	bf9d                	j	8000431a <namex+0xb8>
  if(nameiparent){
    800043a6:	f20b03e3          	beqz	s6,800042cc <namex+0x6a>
    iput(ip);
    800043aa:	854e                	mv	a0,s3
    800043ac:	00000097          	auipc	ra,0x0
    800043b0:	ae2080e7          	jalr	-1310(ra) # 80003e8e <iput>
    return 0;
    800043b4:	4981                	li	s3,0
    800043b6:	bf19                	j	800042cc <namex+0x6a>
  if(*path == 0)
    800043b8:	d7fd                	beqz	a5,800043a6 <namex+0x144>
  while(*path != '/' && *path != 0)
    800043ba:	0004c783          	lbu	a5,0(s1)
    800043be:	85a6                	mv	a1,s1
    800043c0:	b7d1                	j	80004384 <namex+0x122>

00000000800043c2 <dirlink>:
{
    800043c2:	7139                	addi	sp,sp,-64
    800043c4:	fc06                	sd	ra,56(sp)
    800043c6:	f822                	sd	s0,48(sp)
    800043c8:	f426                	sd	s1,40(sp)
    800043ca:	f04a                	sd	s2,32(sp)
    800043cc:	ec4e                	sd	s3,24(sp)
    800043ce:	e852                	sd	s4,16(sp)
    800043d0:	0080                	addi	s0,sp,64
    800043d2:	892a                	mv	s2,a0
    800043d4:	8a2e                	mv	s4,a1
    800043d6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043d8:	4601                	li	a2,0
    800043da:	00000097          	auipc	ra,0x0
    800043de:	dd8080e7          	jalr	-552(ra) # 800041b2 <dirlookup>
    800043e2:	e93d                	bnez	a0,80004458 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043e4:	04c92483          	lw	s1,76(s2)
    800043e8:	c49d                	beqz	s1,80004416 <dirlink+0x54>
    800043ea:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043ec:	4741                	li	a4,16
    800043ee:	86a6                	mv	a3,s1
    800043f0:	fc040613          	addi	a2,s0,-64
    800043f4:	4581                	li	a1,0
    800043f6:	854a                	mv	a0,s2
    800043f8:	00000097          	auipc	ra,0x0
    800043fc:	b90080e7          	jalr	-1136(ra) # 80003f88 <readi>
    80004400:	47c1                	li	a5,16
    80004402:	06f51163          	bne	a0,a5,80004464 <dirlink+0xa2>
    if(de.inum == 0)
    80004406:	fc045783          	lhu	a5,-64(s0)
    8000440a:	c791                	beqz	a5,80004416 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000440c:	24c1                	addiw	s1,s1,16
    8000440e:	04c92783          	lw	a5,76(s2)
    80004412:	fcf4ede3          	bltu	s1,a5,800043ec <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004416:	4639                	li	a2,14
    80004418:	85d2                	mv	a1,s4
    8000441a:	fc240513          	addi	a0,s0,-62
    8000441e:	ffffd097          	auipc	ra,0xffffd
    80004422:	a50080e7          	jalr	-1456(ra) # 80000e6e <strncpy>
  de.inum = inum;
    80004426:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000442a:	4741                	li	a4,16
    8000442c:	86a6                	mv	a3,s1
    8000442e:	fc040613          	addi	a2,s0,-64
    80004432:	4581                	li	a1,0
    80004434:	854a                	mv	a0,s2
    80004436:	00000097          	auipc	ra,0x0
    8000443a:	c48080e7          	jalr	-952(ra) # 8000407e <writei>
    8000443e:	872a                	mv	a4,a0
    80004440:	47c1                	li	a5,16
  return 0;
    80004442:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004444:	02f71863          	bne	a4,a5,80004474 <dirlink+0xb2>
}
    80004448:	70e2                	ld	ra,56(sp)
    8000444a:	7442                	ld	s0,48(sp)
    8000444c:	74a2                	ld	s1,40(sp)
    8000444e:	7902                	ld	s2,32(sp)
    80004450:	69e2                	ld	s3,24(sp)
    80004452:	6a42                	ld	s4,16(sp)
    80004454:	6121                	addi	sp,sp,64
    80004456:	8082                	ret
    iput(ip);
    80004458:	00000097          	auipc	ra,0x0
    8000445c:	a36080e7          	jalr	-1482(ra) # 80003e8e <iput>
    return -1;
    80004460:	557d                	li	a0,-1
    80004462:	b7dd                	j	80004448 <dirlink+0x86>
      panic("dirlink read");
    80004464:	00004517          	auipc	a0,0x4
    80004468:	42c50513          	addi	a0,a0,1068 # 80008890 <sysnames+0x1d8>
    8000446c:	ffffc097          	auipc	ra,0xffffc
    80004470:	0dc080e7          	jalr	220(ra) # 80000548 <panic>
    panic("dirlink");
    80004474:	00004517          	auipc	a0,0x4
    80004478:	52c50513          	addi	a0,a0,1324 # 800089a0 <sysnames+0x2e8>
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	0cc080e7          	jalr	204(ra) # 80000548 <panic>

0000000080004484 <namei>:

struct inode*
namei(char *path)
{
    80004484:	1101                	addi	sp,sp,-32
    80004486:	ec06                	sd	ra,24(sp)
    80004488:	e822                	sd	s0,16(sp)
    8000448a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000448c:	fe040613          	addi	a2,s0,-32
    80004490:	4581                	li	a1,0
    80004492:	00000097          	auipc	ra,0x0
    80004496:	dd0080e7          	jalr	-560(ra) # 80004262 <namex>
}
    8000449a:	60e2                	ld	ra,24(sp)
    8000449c:	6442                	ld	s0,16(sp)
    8000449e:	6105                	addi	sp,sp,32
    800044a0:	8082                	ret

00000000800044a2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044a2:	1141                	addi	sp,sp,-16
    800044a4:	e406                	sd	ra,8(sp)
    800044a6:	e022                	sd	s0,0(sp)
    800044a8:	0800                	addi	s0,sp,16
    800044aa:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044ac:	4585                	li	a1,1
    800044ae:	00000097          	auipc	ra,0x0
    800044b2:	db4080e7          	jalr	-588(ra) # 80004262 <namex>
}
    800044b6:	60a2                	ld	ra,8(sp)
    800044b8:	6402                	ld	s0,0(sp)
    800044ba:	0141                	addi	sp,sp,16
    800044bc:	8082                	ret

00000000800044be <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044be:	1101                	addi	sp,sp,-32
    800044c0:	ec06                	sd	ra,24(sp)
    800044c2:	e822                	sd	s0,16(sp)
    800044c4:	e426                	sd	s1,8(sp)
    800044c6:	e04a                	sd	s2,0(sp)
    800044c8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044ca:	0001e917          	auipc	s2,0x1e
    800044ce:	83e90913          	addi	s2,s2,-1986 # 80021d08 <log>
    800044d2:	01892583          	lw	a1,24(s2)
    800044d6:	02892503          	lw	a0,40(s2)
    800044da:	fffff097          	auipc	ra,0xfffff
    800044de:	ff8080e7          	jalr	-8(ra) # 800034d2 <bread>
    800044e2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044e4:	02c92683          	lw	a3,44(s2)
    800044e8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044ea:	02d05763          	blez	a3,80004518 <write_head+0x5a>
    800044ee:	0001e797          	auipc	a5,0x1e
    800044f2:	84a78793          	addi	a5,a5,-1974 # 80021d38 <log+0x30>
    800044f6:	05c50713          	addi	a4,a0,92
    800044fa:	36fd                	addiw	a3,a3,-1
    800044fc:	1682                	slli	a3,a3,0x20
    800044fe:	9281                	srli	a3,a3,0x20
    80004500:	068a                	slli	a3,a3,0x2
    80004502:	0001e617          	auipc	a2,0x1e
    80004506:	83a60613          	addi	a2,a2,-1990 # 80021d3c <log+0x34>
    8000450a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000450c:	4390                	lw	a2,0(a5)
    8000450e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004510:	0791                	addi	a5,a5,4
    80004512:	0711                	addi	a4,a4,4
    80004514:	fed79ce3          	bne	a5,a3,8000450c <write_head+0x4e>
  }
  bwrite(buf);
    80004518:	8526                	mv	a0,s1
    8000451a:	fffff097          	auipc	ra,0xfffff
    8000451e:	0aa080e7          	jalr	170(ra) # 800035c4 <bwrite>
  brelse(buf);
    80004522:	8526                	mv	a0,s1
    80004524:	fffff097          	auipc	ra,0xfffff
    80004528:	0de080e7          	jalr	222(ra) # 80003602 <brelse>
}
    8000452c:	60e2                	ld	ra,24(sp)
    8000452e:	6442                	ld	s0,16(sp)
    80004530:	64a2                	ld	s1,8(sp)
    80004532:	6902                	ld	s2,0(sp)
    80004534:	6105                	addi	sp,sp,32
    80004536:	8082                	ret

0000000080004538 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004538:	0001d797          	auipc	a5,0x1d
    8000453c:	7fc7a783          	lw	a5,2044(a5) # 80021d34 <log+0x2c>
    80004540:	0af05663          	blez	a5,800045ec <install_trans+0xb4>
{
    80004544:	7139                	addi	sp,sp,-64
    80004546:	fc06                	sd	ra,56(sp)
    80004548:	f822                	sd	s0,48(sp)
    8000454a:	f426                	sd	s1,40(sp)
    8000454c:	f04a                	sd	s2,32(sp)
    8000454e:	ec4e                	sd	s3,24(sp)
    80004550:	e852                	sd	s4,16(sp)
    80004552:	e456                	sd	s5,8(sp)
    80004554:	0080                	addi	s0,sp,64
    80004556:	0001da97          	auipc	s5,0x1d
    8000455a:	7e2a8a93          	addi	s5,s5,2018 # 80021d38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000455e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004560:	0001d997          	auipc	s3,0x1d
    80004564:	7a898993          	addi	s3,s3,1960 # 80021d08 <log>
    80004568:	0189a583          	lw	a1,24(s3)
    8000456c:	014585bb          	addw	a1,a1,s4
    80004570:	2585                	addiw	a1,a1,1
    80004572:	0289a503          	lw	a0,40(s3)
    80004576:	fffff097          	auipc	ra,0xfffff
    8000457a:	f5c080e7          	jalr	-164(ra) # 800034d2 <bread>
    8000457e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004580:	000aa583          	lw	a1,0(s5)
    80004584:	0289a503          	lw	a0,40(s3)
    80004588:	fffff097          	auipc	ra,0xfffff
    8000458c:	f4a080e7          	jalr	-182(ra) # 800034d2 <bread>
    80004590:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004592:	40000613          	li	a2,1024
    80004596:	05890593          	addi	a1,s2,88
    8000459a:	05850513          	addi	a0,a0,88
    8000459e:	ffffd097          	auipc	ra,0xffffd
    800045a2:	818080e7          	jalr	-2024(ra) # 80000db6 <memmove>
    bwrite(dbuf);  // write dst to disk
    800045a6:	8526                	mv	a0,s1
    800045a8:	fffff097          	auipc	ra,0xfffff
    800045ac:	01c080e7          	jalr	28(ra) # 800035c4 <bwrite>
    bunpin(dbuf);
    800045b0:	8526                	mv	a0,s1
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	12a080e7          	jalr	298(ra) # 800036dc <bunpin>
    brelse(lbuf);
    800045ba:	854a                	mv	a0,s2
    800045bc:	fffff097          	auipc	ra,0xfffff
    800045c0:	046080e7          	jalr	70(ra) # 80003602 <brelse>
    brelse(dbuf);
    800045c4:	8526                	mv	a0,s1
    800045c6:	fffff097          	auipc	ra,0xfffff
    800045ca:	03c080e7          	jalr	60(ra) # 80003602 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ce:	2a05                	addiw	s4,s4,1
    800045d0:	0a91                	addi	s5,s5,4
    800045d2:	02c9a783          	lw	a5,44(s3)
    800045d6:	f8fa49e3          	blt	s4,a5,80004568 <install_trans+0x30>
}
    800045da:	70e2                	ld	ra,56(sp)
    800045dc:	7442                	ld	s0,48(sp)
    800045de:	74a2                	ld	s1,40(sp)
    800045e0:	7902                	ld	s2,32(sp)
    800045e2:	69e2                	ld	s3,24(sp)
    800045e4:	6a42                	ld	s4,16(sp)
    800045e6:	6aa2                	ld	s5,8(sp)
    800045e8:	6121                	addi	sp,sp,64
    800045ea:	8082                	ret
    800045ec:	8082                	ret

00000000800045ee <initlog>:
{
    800045ee:	7179                	addi	sp,sp,-48
    800045f0:	f406                	sd	ra,40(sp)
    800045f2:	f022                	sd	s0,32(sp)
    800045f4:	ec26                	sd	s1,24(sp)
    800045f6:	e84a                	sd	s2,16(sp)
    800045f8:	e44e                	sd	s3,8(sp)
    800045fa:	1800                	addi	s0,sp,48
    800045fc:	892a                	mv	s2,a0
    800045fe:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004600:	0001d497          	auipc	s1,0x1d
    80004604:	70848493          	addi	s1,s1,1800 # 80021d08 <log>
    80004608:	00004597          	auipc	a1,0x4
    8000460c:	29858593          	addi	a1,a1,664 # 800088a0 <sysnames+0x1e8>
    80004610:	8526                	mv	a0,s1
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	5b8080e7          	jalr	1464(ra) # 80000bca <initlock>
  log.start = sb->logstart;
    8000461a:	0149a583          	lw	a1,20(s3)
    8000461e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004620:	0109a783          	lw	a5,16(s3)
    80004624:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004626:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000462a:	854a                	mv	a0,s2
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	ea6080e7          	jalr	-346(ra) # 800034d2 <bread>
  log.lh.n = lh->n;
    80004634:	4d3c                	lw	a5,88(a0)
    80004636:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004638:	02f05563          	blez	a5,80004662 <initlog+0x74>
    8000463c:	05c50713          	addi	a4,a0,92
    80004640:	0001d697          	auipc	a3,0x1d
    80004644:	6f868693          	addi	a3,a3,1784 # 80021d38 <log+0x30>
    80004648:	37fd                	addiw	a5,a5,-1
    8000464a:	1782                	slli	a5,a5,0x20
    8000464c:	9381                	srli	a5,a5,0x20
    8000464e:	078a                	slli	a5,a5,0x2
    80004650:	06050613          	addi	a2,a0,96
    80004654:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004656:	4310                	lw	a2,0(a4)
    80004658:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000465a:	0711                	addi	a4,a4,4
    8000465c:	0691                	addi	a3,a3,4
    8000465e:	fef71ce3          	bne	a4,a5,80004656 <initlog+0x68>
  brelse(buf);
    80004662:	fffff097          	auipc	ra,0xfffff
    80004666:	fa0080e7          	jalr	-96(ra) # 80003602 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000466a:	00000097          	auipc	ra,0x0
    8000466e:	ece080e7          	jalr	-306(ra) # 80004538 <install_trans>
  log.lh.n = 0;
    80004672:	0001d797          	auipc	a5,0x1d
    80004676:	6c07a123          	sw	zero,1730(a5) # 80021d34 <log+0x2c>
  write_head(); // clear the log
    8000467a:	00000097          	auipc	ra,0x0
    8000467e:	e44080e7          	jalr	-444(ra) # 800044be <write_head>
}
    80004682:	70a2                	ld	ra,40(sp)
    80004684:	7402                	ld	s0,32(sp)
    80004686:	64e2                	ld	s1,24(sp)
    80004688:	6942                	ld	s2,16(sp)
    8000468a:	69a2                	ld	s3,8(sp)
    8000468c:	6145                	addi	sp,sp,48
    8000468e:	8082                	ret

0000000080004690 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004690:	1101                	addi	sp,sp,-32
    80004692:	ec06                	sd	ra,24(sp)
    80004694:	e822                	sd	s0,16(sp)
    80004696:	e426                	sd	s1,8(sp)
    80004698:	e04a                	sd	s2,0(sp)
    8000469a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000469c:	0001d517          	auipc	a0,0x1d
    800046a0:	66c50513          	addi	a0,a0,1644 # 80021d08 <log>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	5b6080e7          	jalr	1462(ra) # 80000c5a <acquire>
  while(1){
    if(log.committing){
    800046ac:	0001d497          	auipc	s1,0x1d
    800046b0:	65c48493          	addi	s1,s1,1628 # 80021d08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046b4:	4979                	li	s2,30
    800046b6:	a039                	j	800046c4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800046b8:	85a6                	mv	a1,s1
    800046ba:	8526                	mv	a0,s1
    800046bc:	ffffe097          	auipc	ra,0xffffe
    800046c0:	0c8080e7          	jalr	200(ra) # 80002784 <sleep>
    if(log.committing){
    800046c4:	50dc                	lw	a5,36(s1)
    800046c6:	fbed                	bnez	a5,800046b8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046c8:	509c                	lw	a5,32(s1)
    800046ca:	0017871b          	addiw	a4,a5,1
    800046ce:	0007069b          	sext.w	a3,a4
    800046d2:	0027179b          	slliw	a5,a4,0x2
    800046d6:	9fb9                	addw	a5,a5,a4
    800046d8:	0017979b          	slliw	a5,a5,0x1
    800046dc:	54d8                	lw	a4,44(s1)
    800046de:	9fb9                	addw	a5,a5,a4
    800046e0:	00f95963          	bge	s2,a5,800046f2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046e4:	85a6                	mv	a1,s1
    800046e6:	8526                	mv	a0,s1
    800046e8:	ffffe097          	auipc	ra,0xffffe
    800046ec:	09c080e7          	jalr	156(ra) # 80002784 <sleep>
    800046f0:	bfd1                	j	800046c4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046f2:	0001d517          	auipc	a0,0x1d
    800046f6:	61650513          	addi	a0,a0,1558 # 80021d08 <log>
    800046fa:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	612080e7          	jalr	1554(ra) # 80000d0e <release>
      break;
    }
  }
}
    80004704:	60e2                	ld	ra,24(sp)
    80004706:	6442                	ld	s0,16(sp)
    80004708:	64a2                	ld	s1,8(sp)
    8000470a:	6902                	ld	s2,0(sp)
    8000470c:	6105                	addi	sp,sp,32
    8000470e:	8082                	ret

0000000080004710 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004710:	7139                	addi	sp,sp,-64
    80004712:	fc06                	sd	ra,56(sp)
    80004714:	f822                	sd	s0,48(sp)
    80004716:	f426                	sd	s1,40(sp)
    80004718:	f04a                	sd	s2,32(sp)
    8000471a:	ec4e                	sd	s3,24(sp)
    8000471c:	e852                	sd	s4,16(sp)
    8000471e:	e456                	sd	s5,8(sp)
    80004720:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004722:	0001d497          	auipc	s1,0x1d
    80004726:	5e648493          	addi	s1,s1,1510 # 80021d08 <log>
    8000472a:	8526                	mv	a0,s1
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	52e080e7          	jalr	1326(ra) # 80000c5a <acquire>
  log.outstanding -= 1;
    80004734:	509c                	lw	a5,32(s1)
    80004736:	37fd                	addiw	a5,a5,-1
    80004738:	0007891b          	sext.w	s2,a5
    8000473c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000473e:	50dc                	lw	a5,36(s1)
    80004740:	efb9                	bnez	a5,8000479e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004742:	06091663          	bnez	s2,800047ae <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004746:	0001d497          	auipc	s1,0x1d
    8000474a:	5c248493          	addi	s1,s1,1474 # 80021d08 <log>
    8000474e:	4785                	li	a5,1
    80004750:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004752:	8526                	mv	a0,s1
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	5ba080e7          	jalr	1466(ra) # 80000d0e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000475c:	54dc                	lw	a5,44(s1)
    8000475e:	06f04763          	bgtz	a5,800047cc <end_op+0xbc>
    acquire(&log.lock);
    80004762:	0001d497          	auipc	s1,0x1d
    80004766:	5a648493          	addi	s1,s1,1446 # 80021d08 <log>
    8000476a:	8526                	mv	a0,s1
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	4ee080e7          	jalr	1262(ra) # 80000c5a <acquire>
    log.committing = 0;
    80004774:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004778:	8526                	mv	a0,s1
    8000477a:	ffffe097          	auipc	ra,0xffffe
    8000477e:	190080e7          	jalr	400(ra) # 8000290a <wakeup>
    release(&log.lock);
    80004782:	8526                	mv	a0,s1
    80004784:	ffffc097          	auipc	ra,0xffffc
    80004788:	58a080e7          	jalr	1418(ra) # 80000d0e <release>
}
    8000478c:	70e2                	ld	ra,56(sp)
    8000478e:	7442                	ld	s0,48(sp)
    80004790:	74a2                	ld	s1,40(sp)
    80004792:	7902                	ld	s2,32(sp)
    80004794:	69e2                	ld	s3,24(sp)
    80004796:	6a42                	ld	s4,16(sp)
    80004798:	6aa2                	ld	s5,8(sp)
    8000479a:	6121                	addi	sp,sp,64
    8000479c:	8082                	ret
    panic("log.committing");
    8000479e:	00004517          	auipc	a0,0x4
    800047a2:	10a50513          	addi	a0,a0,266 # 800088a8 <sysnames+0x1f0>
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	da2080e7          	jalr	-606(ra) # 80000548 <panic>
    wakeup(&log);
    800047ae:	0001d497          	auipc	s1,0x1d
    800047b2:	55a48493          	addi	s1,s1,1370 # 80021d08 <log>
    800047b6:	8526                	mv	a0,s1
    800047b8:	ffffe097          	auipc	ra,0xffffe
    800047bc:	152080e7          	jalr	338(ra) # 8000290a <wakeup>
  release(&log.lock);
    800047c0:	8526                	mv	a0,s1
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	54c080e7          	jalr	1356(ra) # 80000d0e <release>
  if(do_commit){
    800047ca:	b7c9                	j	8000478c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047cc:	0001da97          	auipc	s5,0x1d
    800047d0:	56ca8a93          	addi	s5,s5,1388 # 80021d38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047d4:	0001da17          	auipc	s4,0x1d
    800047d8:	534a0a13          	addi	s4,s4,1332 # 80021d08 <log>
    800047dc:	018a2583          	lw	a1,24(s4)
    800047e0:	012585bb          	addw	a1,a1,s2
    800047e4:	2585                	addiw	a1,a1,1
    800047e6:	028a2503          	lw	a0,40(s4)
    800047ea:	fffff097          	auipc	ra,0xfffff
    800047ee:	ce8080e7          	jalr	-792(ra) # 800034d2 <bread>
    800047f2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047f4:	000aa583          	lw	a1,0(s5)
    800047f8:	028a2503          	lw	a0,40(s4)
    800047fc:	fffff097          	auipc	ra,0xfffff
    80004800:	cd6080e7          	jalr	-810(ra) # 800034d2 <bread>
    80004804:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004806:	40000613          	li	a2,1024
    8000480a:	05850593          	addi	a1,a0,88
    8000480e:	05848513          	addi	a0,s1,88
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	5a4080e7          	jalr	1444(ra) # 80000db6 <memmove>
    bwrite(to);  // write the log
    8000481a:	8526                	mv	a0,s1
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	da8080e7          	jalr	-600(ra) # 800035c4 <bwrite>
    brelse(from);
    80004824:	854e                	mv	a0,s3
    80004826:	fffff097          	auipc	ra,0xfffff
    8000482a:	ddc080e7          	jalr	-548(ra) # 80003602 <brelse>
    brelse(to);
    8000482e:	8526                	mv	a0,s1
    80004830:	fffff097          	auipc	ra,0xfffff
    80004834:	dd2080e7          	jalr	-558(ra) # 80003602 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004838:	2905                	addiw	s2,s2,1
    8000483a:	0a91                	addi	s5,s5,4
    8000483c:	02ca2783          	lw	a5,44(s4)
    80004840:	f8f94ee3          	blt	s2,a5,800047dc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004844:	00000097          	auipc	ra,0x0
    80004848:	c7a080e7          	jalr	-902(ra) # 800044be <write_head>
    install_trans(); // Now install writes to home locations
    8000484c:	00000097          	auipc	ra,0x0
    80004850:	cec080e7          	jalr	-788(ra) # 80004538 <install_trans>
    log.lh.n = 0;
    80004854:	0001d797          	auipc	a5,0x1d
    80004858:	4e07a023          	sw	zero,1248(a5) # 80021d34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000485c:	00000097          	auipc	ra,0x0
    80004860:	c62080e7          	jalr	-926(ra) # 800044be <write_head>
    80004864:	bdfd                	j	80004762 <end_op+0x52>

0000000080004866 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004866:	1101                	addi	sp,sp,-32
    80004868:	ec06                	sd	ra,24(sp)
    8000486a:	e822                	sd	s0,16(sp)
    8000486c:	e426                	sd	s1,8(sp)
    8000486e:	e04a                	sd	s2,0(sp)
    80004870:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004872:	0001d717          	auipc	a4,0x1d
    80004876:	4c272703          	lw	a4,1218(a4) # 80021d34 <log+0x2c>
    8000487a:	47f5                	li	a5,29
    8000487c:	08e7c063          	blt	a5,a4,800048fc <log_write+0x96>
    80004880:	84aa                	mv	s1,a0
    80004882:	0001d797          	auipc	a5,0x1d
    80004886:	4a27a783          	lw	a5,1186(a5) # 80021d24 <log+0x1c>
    8000488a:	37fd                	addiw	a5,a5,-1
    8000488c:	06f75863          	bge	a4,a5,800048fc <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004890:	0001d797          	auipc	a5,0x1d
    80004894:	4987a783          	lw	a5,1176(a5) # 80021d28 <log+0x20>
    80004898:	06f05a63          	blez	a5,8000490c <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000489c:	0001d917          	auipc	s2,0x1d
    800048a0:	46c90913          	addi	s2,s2,1132 # 80021d08 <log>
    800048a4:	854a                	mv	a0,s2
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	3b4080e7          	jalr	948(ra) # 80000c5a <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800048ae:	02c92603          	lw	a2,44(s2)
    800048b2:	06c05563          	blez	a2,8000491c <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800048b6:	44cc                	lw	a1,12(s1)
    800048b8:	0001d717          	auipc	a4,0x1d
    800048bc:	48070713          	addi	a4,a4,1152 # 80021d38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048c0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800048c2:	4314                	lw	a3,0(a4)
    800048c4:	04b68d63          	beq	a3,a1,8000491e <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800048c8:	2785                	addiw	a5,a5,1
    800048ca:	0711                	addi	a4,a4,4
    800048cc:	fec79be3          	bne	a5,a2,800048c2 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048d0:	0621                	addi	a2,a2,8
    800048d2:	060a                	slli	a2,a2,0x2
    800048d4:	0001d797          	auipc	a5,0x1d
    800048d8:	43478793          	addi	a5,a5,1076 # 80021d08 <log>
    800048dc:	963e                	add	a2,a2,a5
    800048de:	44dc                	lw	a5,12(s1)
    800048e0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048e2:	8526                	mv	a0,s1
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	dbc080e7          	jalr	-580(ra) # 800036a0 <bpin>
    log.lh.n++;
    800048ec:	0001d717          	auipc	a4,0x1d
    800048f0:	41c70713          	addi	a4,a4,1052 # 80021d08 <log>
    800048f4:	575c                	lw	a5,44(a4)
    800048f6:	2785                	addiw	a5,a5,1
    800048f8:	d75c                	sw	a5,44(a4)
    800048fa:	a83d                	j	80004938 <log_write+0xd2>
    panic("too big a transaction");
    800048fc:	00004517          	auipc	a0,0x4
    80004900:	fbc50513          	addi	a0,a0,-68 # 800088b8 <sysnames+0x200>
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	c44080e7          	jalr	-956(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    8000490c:	00004517          	auipc	a0,0x4
    80004910:	fc450513          	addi	a0,a0,-60 # 800088d0 <sysnames+0x218>
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	c34080e7          	jalr	-972(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000491c:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000491e:	00878713          	addi	a4,a5,8
    80004922:	00271693          	slli	a3,a4,0x2
    80004926:	0001d717          	auipc	a4,0x1d
    8000492a:	3e270713          	addi	a4,a4,994 # 80021d08 <log>
    8000492e:	9736                	add	a4,a4,a3
    80004930:	44d4                	lw	a3,12(s1)
    80004932:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004934:	faf607e3          	beq	a2,a5,800048e2 <log_write+0x7c>
  }
  release(&log.lock);
    80004938:	0001d517          	auipc	a0,0x1d
    8000493c:	3d050513          	addi	a0,a0,976 # 80021d08 <log>
    80004940:	ffffc097          	auipc	ra,0xffffc
    80004944:	3ce080e7          	jalr	974(ra) # 80000d0e <release>
}
    80004948:	60e2                	ld	ra,24(sp)
    8000494a:	6442                	ld	s0,16(sp)
    8000494c:	64a2                	ld	s1,8(sp)
    8000494e:	6902                	ld	s2,0(sp)
    80004950:	6105                	addi	sp,sp,32
    80004952:	8082                	ret

0000000080004954 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004954:	1101                	addi	sp,sp,-32
    80004956:	ec06                	sd	ra,24(sp)
    80004958:	e822                	sd	s0,16(sp)
    8000495a:	e426                	sd	s1,8(sp)
    8000495c:	e04a                	sd	s2,0(sp)
    8000495e:	1000                	addi	s0,sp,32
    80004960:	84aa                	mv	s1,a0
    80004962:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004964:	00004597          	auipc	a1,0x4
    80004968:	f8c58593          	addi	a1,a1,-116 # 800088f0 <sysnames+0x238>
    8000496c:	0521                	addi	a0,a0,8
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	25c080e7          	jalr	604(ra) # 80000bca <initlock>
  lk->name = name;
    80004976:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000497a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000497e:	0204a423          	sw	zero,40(s1)
}
    80004982:	60e2                	ld	ra,24(sp)
    80004984:	6442                	ld	s0,16(sp)
    80004986:	64a2                	ld	s1,8(sp)
    80004988:	6902                	ld	s2,0(sp)
    8000498a:	6105                	addi	sp,sp,32
    8000498c:	8082                	ret

000000008000498e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000498e:	1101                	addi	sp,sp,-32
    80004990:	ec06                	sd	ra,24(sp)
    80004992:	e822                	sd	s0,16(sp)
    80004994:	e426                	sd	s1,8(sp)
    80004996:	e04a                	sd	s2,0(sp)
    80004998:	1000                	addi	s0,sp,32
    8000499a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000499c:	00850913          	addi	s2,a0,8
    800049a0:	854a                	mv	a0,s2
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	2b8080e7          	jalr	696(ra) # 80000c5a <acquire>
  while (lk->locked) {
    800049aa:	409c                	lw	a5,0(s1)
    800049ac:	cb89                	beqz	a5,800049be <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049ae:	85ca                	mv	a1,s2
    800049b0:	8526                	mv	a0,s1
    800049b2:	ffffe097          	auipc	ra,0xffffe
    800049b6:	dd2080e7          	jalr	-558(ra) # 80002784 <sleep>
  while (lk->locked) {
    800049ba:	409c                	lw	a5,0(s1)
    800049bc:	fbed                	bnez	a5,800049ae <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049be:	4785                	li	a5,1
    800049c0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049c2:	ffffd097          	auipc	ra,0xffffd
    800049c6:	42a080e7          	jalr	1066(ra) # 80001dec <myproc>
    800049ca:	5d1c                	lw	a5,56(a0)
    800049cc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049ce:	854a                	mv	a0,s2
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	33e080e7          	jalr	830(ra) # 80000d0e <release>
}
    800049d8:	60e2                	ld	ra,24(sp)
    800049da:	6442                	ld	s0,16(sp)
    800049dc:	64a2                	ld	s1,8(sp)
    800049de:	6902                	ld	s2,0(sp)
    800049e0:	6105                	addi	sp,sp,32
    800049e2:	8082                	ret

00000000800049e4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049e4:	1101                	addi	sp,sp,-32
    800049e6:	ec06                	sd	ra,24(sp)
    800049e8:	e822                	sd	s0,16(sp)
    800049ea:	e426                	sd	s1,8(sp)
    800049ec:	e04a                	sd	s2,0(sp)
    800049ee:	1000                	addi	s0,sp,32
    800049f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049f2:	00850913          	addi	s2,a0,8
    800049f6:	854a                	mv	a0,s2
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	262080e7          	jalr	610(ra) # 80000c5a <acquire>
  lk->locked = 0;
    80004a00:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a04:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a08:	8526                	mv	a0,s1
    80004a0a:	ffffe097          	auipc	ra,0xffffe
    80004a0e:	f00080e7          	jalr	-256(ra) # 8000290a <wakeup>
  release(&lk->lk);
    80004a12:	854a                	mv	a0,s2
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	2fa080e7          	jalr	762(ra) # 80000d0e <release>
}
    80004a1c:	60e2                	ld	ra,24(sp)
    80004a1e:	6442                	ld	s0,16(sp)
    80004a20:	64a2                	ld	s1,8(sp)
    80004a22:	6902                	ld	s2,0(sp)
    80004a24:	6105                	addi	sp,sp,32
    80004a26:	8082                	ret

0000000080004a28 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a28:	7179                	addi	sp,sp,-48
    80004a2a:	f406                	sd	ra,40(sp)
    80004a2c:	f022                	sd	s0,32(sp)
    80004a2e:	ec26                	sd	s1,24(sp)
    80004a30:	e84a                	sd	s2,16(sp)
    80004a32:	e44e                	sd	s3,8(sp)
    80004a34:	1800                	addi	s0,sp,48
    80004a36:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a38:	00850913          	addi	s2,a0,8
    80004a3c:	854a                	mv	a0,s2
    80004a3e:	ffffc097          	auipc	ra,0xffffc
    80004a42:	21c080e7          	jalr	540(ra) # 80000c5a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a46:	409c                	lw	a5,0(s1)
    80004a48:	ef99                	bnez	a5,80004a66 <holdingsleep+0x3e>
    80004a4a:	4481                	li	s1,0
  release(&lk->lk);
    80004a4c:	854a                	mv	a0,s2
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	2c0080e7          	jalr	704(ra) # 80000d0e <release>
  return r;
}
    80004a56:	8526                	mv	a0,s1
    80004a58:	70a2                	ld	ra,40(sp)
    80004a5a:	7402                	ld	s0,32(sp)
    80004a5c:	64e2                	ld	s1,24(sp)
    80004a5e:	6942                	ld	s2,16(sp)
    80004a60:	69a2                	ld	s3,8(sp)
    80004a62:	6145                	addi	sp,sp,48
    80004a64:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a66:	0284a983          	lw	s3,40(s1)
    80004a6a:	ffffd097          	auipc	ra,0xffffd
    80004a6e:	382080e7          	jalr	898(ra) # 80001dec <myproc>
    80004a72:	5d04                	lw	s1,56(a0)
    80004a74:	413484b3          	sub	s1,s1,s3
    80004a78:	0014b493          	seqz	s1,s1
    80004a7c:	bfc1                	j	80004a4c <holdingsleep+0x24>

0000000080004a7e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a7e:	1141                	addi	sp,sp,-16
    80004a80:	e406                	sd	ra,8(sp)
    80004a82:	e022                	sd	s0,0(sp)
    80004a84:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a86:	00004597          	auipc	a1,0x4
    80004a8a:	e7a58593          	addi	a1,a1,-390 # 80008900 <sysnames+0x248>
    80004a8e:	0001d517          	auipc	a0,0x1d
    80004a92:	3c250513          	addi	a0,a0,962 # 80021e50 <ftable>
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	134080e7          	jalr	308(ra) # 80000bca <initlock>
}
    80004a9e:	60a2                	ld	ra,8(sp)
    80004aa0:	6402                	ld	s0,0(sp)
    80004aa2:	0141                	addi	sp,sp,16
    80004aa4:	8082                	ret

0000000080004aa6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004aa6:	1101                	addi	sp,sp,-32
    80004aa8:	ec06                	sd	ra,24(sp)
    80004aaa:	e822                	sd	s0,16(sp)
    80004aac:	e426                	sd	s1,8(sp)
    80004aae:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ab0:	0001d517          	auipc	a0,0x1d
    80004ab4:	3a050513          	addi	a0,a0,928 # 80021e50 <ftable>
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	1a2080e7          	jalr	418(ra) # 80000c5a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ac0:	0001d497          	auipc	s1,0x1d
    80004ac4:	3a848493          	addi	s1,s1,936 # 80021e68 <ftable+0x18>
    80004ac8:	0001e717          	auipc	a4,0x1e
    80004acc:	34070713          	addi	a4,a4,832 # 80022e08 <ftable+0xfb8>
    if(f->ref == 0){
    80004ad0:	40dc                	lw	a5,4(s1)
    80004ad2:	cf99                	beqz	a5,80004af0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ad4:	02848493          	addi	s1,s1,40
    80004ad8:	fee49ce3          	bne	s1,a4,80004ad0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004adc:	0001d517          	auipc	a0,0x1d
    80004ae0:	37450513          	addi	a0,a0,884 # 80021e50 <ftable>
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	22a080e7          	jalr	554(ra) # 80000d0e <release>
  return 0;
    80004aec:	4481                	li	s1,0
    80004aee:	a819                	j	80004b04 <filealloc+0x5e>
      f->ref = 1;
    80004af0:	4785                	li	a5,1
    80004af2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004af4:	0001d517          	auipc	a0,0x1d
    80004af8:	35c50513          	addi	a0,a0,860 # 80021e50 <ftable>
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	212080e7          	jalr	530(ra) # 80000d0e <release>
}
    80004b04:	8526                	mv	a0,s1
    80004b06:	60e2                	ld	ra,24(sp)
    80004b08:	6442                	ld	s0,16(sp)
    80004b0a:	64a2                	ld	s1,8(sp)
    80004b0c:	6105                	addi	sp,sp,32
    80004b0e:	8082                	ret

0000000080004b10 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b10:	1101                	addi	sp,sp,-32
    80004b12:	ec06                	sd	ra,24(sp)
    80004b14:	e822                	sd	s0,16(sp)
    80004b16:	e426                	sd	s1,8(sp)
    80004b18:	1000                	addi	s0,sp,32
    80004b1a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b1c:	0001d517          	auipc	a0,0x1d
    80004b20:	33450513          	addi	a0,a0,820 # 80021e50 <ftable>
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	136080e7          	jalr	310(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    80004b2c:	40dc                	lw	a5,4(s1)
    80004b2e:	02f05263          	blez	a5,80004b52 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b32:	2785                	addiw	a5,a5,1
    80004b34:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b36:	0001d517          	auipc	a0,0x1d
    80004b3a:	31a50513          	addi	a0,a0,794 # 80021e50 <ftable>
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	1d0080e7          	jalr	464(ra) # 80000d0e <release>
  return f;
}
    80004b46:	8526                	mv	a0,s1
    80004b48:	60e2                	ld	ra,24(sp)
    80004b4a:	6442                	ld	s0,16(sp)
    80004b4c:	64a2                	ld	s1,8(sp)
    80004b4e:	6105                	addi	sp,sp,32
    80004b50:	8082                	ret
    panic("filedup");
    80004b52:	00004517          	auipc	a0,0x4
    80004b56:	db650513          	addi	a0,a0,-586 # 80008908 <sysnames+0x250>
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	9ee080e7          	jalr	-1554(ra) # 80000548 <panic>

0000000080004b62 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b62:	7139                	addi	sp,sp,-64
    80004b64:	fc06                	sd	ra,56(sp)
    80004b66:	f822                	sd	s0,48(sp)
    80004b68:	f426                	sd	s1,40(sp)
    80004b6a:	f04a                	sd	s2,32(sp)
    80004b6c:	ec4e                	sd	s3,24(sp)
    80004b6e:	e852                	sd	s4,16(sp)
    80004b70:	e456                	sd	s5,8(sp)
    80004b72:	0080                	addi	s0,sp,64
    80004b74:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b76:	0001d517          	auipc	a0,0x1d
    80004b7a:	2da50513          	addi	a0,a0,730 # 80021e50 <ftable>
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	0dc080e7          	jalr	220(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    80004b86:	40dc                	lw	a5,4(s1)
    80004b88:	06f05163          	blez	a5,80004bea <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b8c:	37fd                	addiw	a5,a5,-1
    80004b8e:	0007871b          	sext.w	a4,a5
    80004b92:	c0dc                	sw	a5,4(s1)
    80004b94:	06e04363          	bgtz	a4,80004bfa <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b98:	0004a903          	lw	s2,0(s1)
    80004b9c:	0094ca83          	lbu	s5,9(s1)
    80004ba0:	0104ba03          	ld	s4,16(s1)
    80004ba4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ba8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bac:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bb0:	0001d517          	auipc	a0,0x1d
    80004bb4:	2a050513          	addi	a0,a0,672 # 80021e50 <ftable>
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	156080e7          	jalr	342(ra) # 80000d0e <release>

  if(ff.type == FD_PIPE){
    80004bc0:	4785                	li	a5,1
    80004bc2:	04f90d63          	beq	s2,a5,80004c1c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004bc6:	3979                	addiw	s2,s2,-2
    80004bc8:	4785                	li	a5,1
    80004bca:	0527e063          	bltu	a5,s2,80004c0a <fileclose+0xa8>
    begin_op();
    80004bce:	00000097          	auipc	ra,0x0
    80004bd2:	ac2080e7          	jalr	-1342(ra) # 80004690 <begin_op>
    iput(ff.ip);
    80004bd6:	854e                	mv	a0,s3
    80004bd8:	fffff097          	auipc	ra,0xfffff
    80004bdc:	2b6080e7          	jalr	694(ra) # 80003e8e <iput>
    end_op();
    80004be0:	00000097          	auipc	ra,0x0
    80004be4:	b30080e7          	jalr	-1232(ra) # 80004710 <end_op>
    80004be8:	a00d                	j	80004c0a <fileclose+0xa8>
    panic("fileclose");
    80004bea:	00004517          	auipc	a0,0x4
    80004bee:	d2650513          	addi	a0,a0,-730 # 80008910 <sysnames+0x258>
    80004bf2:	ffffc097          	auipc	ra,0xffffc
    80004bf6:	956080e7          	jalr	-1706(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004bfa:	0001d517          	auipc	a0,0x1d
    80004bfe:	25650513          	addi	a0,a0,598 # 80021e50 <ftable>
    80004c02:	ffffc097          	auipc	ra,0xffffc
    80004c06:	10c080e7          	jalr	268(ra) # 80000d0e <release>
  }
}
    80004c0a:	70e2                	ld	ra,56(sp)
    80004c0c:	7442                	ld	s0,48(sp)
    80004c0e:	74a2                	ld	s1,40(sp)
    80004c10:	7902                	ld	s2,32(sp)
    80004c12:	69e2                	ld	s3,24(sp)
    80004c14:	6a42                	ld	s4,16(sp)
    80004c16:	6aa2                	ld	s5,8(sp)
    80004c18:	6121                	addi	sp,sp,64
    80004c1a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c1c:	85d6                	mv	a1,s5
    80004c1e:	8552                	mv	a0,s4
    80004c20:	00000097          	auipc	ra,0x0
    80004c24:	372080e7          	jalr	882(ra) # 80004f92 <pipeclose>
    80004c28:	b7cd                	j	80004c0a <fileclose+0xa8>

0000000080004c2a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c2a:	715d                	addi	sp,sp,-80
    80004c2c:	e486                	sd	ra,72(sp)
    80004c2e:	e0a2                	sd	s0,64(sp)
    80004c30:	fc26                	sd	s1,56(sp)
    80004c32:	f84a                	sd	s2,48(sp)
    80004c34:	f44e                	sd	s3,40(sp)
    80004c36:	0880                	addi	s0,sp,80
    80004c38:	84aa                	mv	s1,a0
    80004c3a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	1b0080e7          	jalr	432(ra) # 80001dec <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c44:	409c                	lw	a5,0(s1)
    80004c46:	37f9                	addiw	a5,a5,-2
    80004c48:	4705                	li	a4,1
    80004c4a:	04f76763          	bltu	a4,a5,80004c98 <filestat+0x6e>
    80004c4e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c50:	6c88                	ld	a0,24(s1)
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	082080e7          	jalr	130(ra) # 80003cd4 <ilock>
    stati(f->ip, &st);
    80004c5a:	fb840593          	addi	a1,s0,-72
    80004c5e:	6c88                	ld	a0,24(s1)
    80004c60:	fffff097          	auipc	ra,0xfffff
    80004c64:	2fe080e7          	jalr	766(ra) # 80003f5e <stati>
    iunlock(f->ip);
    80004c68:	6c88                	ld	a0,24(s1)
    80004c6a:	fffff097          	auipc	ra,0xfffff
    80004c6e:	12c080e7          	jalr	300(ra) # 80003d96 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c72:	46e1                	li	a3,24
    80004c74:	fb840613          	addi	a2,s0,-72
    80004c78:	85ce                	mv	a1,s3
    80004c7a:	05093503          	ld	a0,80(s2)
    80004c7e:	ffffd097          	auipc	ra,0xffffd
    80004c82:	c40080e7          	jalr	-960(ra) # 800018be <copyout>
    80004c86:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c8a:	60a6                	ld	ra,72(sp)
    80004c8c:	6406                	ld	s0,64(sp)
    80004c8e:	74e2                	ld	s1,56(sp)
    80004c90:	7942                	ld	s2,48(sp)
    80004c92:	79a2                	ld	s3,40(sp)
    80004c94:	6161                	addi	sp,sp,80
    80004c96:	8082                	ret
  return -1;
    80004c98:	557d                	li	a0,-1
    80004c9a:	bfc5                	j	80004c8a <filestat+0x60>

0000000080004c9c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c9c:	7179                	addi	sp,sp,-48
    80004c9e:	f406                	sd	ra,40(sp)
    80004ca0:	f022                	sd	s0,32(sp)
    80004ca2:	ec26                	sd	s1,24(sp)
    80004ca4:	e84a                	sd	s2,16(sp)
    80004ca6:	e44e                	sd	s3,8(sp)
    80004ca8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004caa:	00854783          	lbu	a5,8(a0)
    80004cae:	c3d5                	beqz	a5,80004d52 <fileread+0xb6>
    80004cb0:	84aa                	mv	s1,a0
    80004cb2:	89ae                	mv	s3,a1
    80004cb4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cb6:	411c                	lw	a5,0(a0)
    80004cb8:	4705                	li	a4,1
    80004cba:	04e78963          	beq	a5,a4,80004d0c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cbe:	470d                	li	a4,3
    80004cc0:	04e78d63          	beq	a5,a4,80004d1a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cc4:	4709                	li	a4,2
    80004cc6:	06e79e63          	bne	a5,a4,80004d42 <fileread+0xa6>
    ilock(f->ip);
    80004cca:	6d08                	ld	a0,24(a0)
    80004ccc:	fffff097          	auipc	ra,0xfffff
    80004cd0:	008080e7          	jalr	8(ra) # 80003cd4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004cd4:	874a                	mv	a4,s2
    80004cd6:	5094                	lw	a3,32(s1)
    80004cd8:	864e                	mv	a2,s3
    80004cda:	4585                	li	a1,1
    80004cdc:	6c88                	ld	a0,24(s1)
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	2aa080e7          	jalr	682(ra) # 80003f88 <readi>
    80004ce6:	892a                	mv	s2,a0
    80004ce8:	00a05563          	blez	a0,80004cf2 <fileread+0x56>
      f->off += r;
    80004cec:	509c                	lw	a5,32(s1)
    80004cee:	9fa9                	addw	a5,a5,a0
    80004cf0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cf2:	6c88                	ld	a0,24(s1)
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	0a2080e7          	jalr	162(ra) # 80003d96 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004cfc:	854a                	mv	a0,s2
    80004cfe:	70a2                	ld	ra,40(sp)
    80004d00:	7402                	ld	s0,32(sp)
    80004d02:	64e2                	ld	s1,24(sp)
    80004d04:	6942                	ld	s2,16(sp)
    80004d06:	69a2                	ld	s3,8(sp)
    80004d08:	6145                	addi	sp,sp,48
    80004d0a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d0c:	6908                	ld	a0,16(a0)
    80004d0e:	00000097          	auipc	ra,0x0
    80004d12:	418080e7          	jalr	1048(ra) # 80005126 <piperead>
    80004d16:	892a                	mv	s2,a0
    80004d18:	b7d5                	j	80004cfc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d1a:	02451783          	lh	a5,36(a0)
    80004d1e:	03079693          	slli	a3,a5,0x30
    80004d22:	92c1                	srli	a3,a3,0x30
    80004d24:	4725                	li	a4,9
    80004d26:	02d76863          	bltu	a4,a3,80004d56 <fileread+0xba>
    80004d2a:	0792                	slli	a5,a5,0x4
    80004d2c:	0001d717          	auipc	a4,0x1d
    80004d30:	08470713          	addi	a4,a4,132 # 80021db0 <devsw>
    80004d34:	97ba                	add	a5,a5,a4
    80004d36:	639c                	ld	a5,0(a5)
    80004d38:	c38d                	beqz	a5,80004d5a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d3a:	4505                	li	a0,1
    80004d3c:	9782                	jalr	a5
    80004d3e:	892a                	mv	s2,a0
    80004d40:	bf75                	j	80004cfc <fileread+0x60>
    panic("fileread");
    80004d42:	00004517          	auipc	a0,0x4
    80004d46:	bde50513          	addi	a0,a0,-1058 # 80008920 <sysnames+0x268>
    80004d4a:	ffffb097          	auipc	ra,0xffffb
    80004d4e:	7fe080e7          	jalr	2046(ra) # 80000548 <panic>
    return -1;
    80004d52:	597d                	li	s2,-1
    80004d54:	b765                	j	80004cfc <fileread+0x60>
      return -1;
    80004d56:	597d                	li	s2,-1
    80004d58:	b755                	j	80004cfc <fileread+0x60>
    80004d5a:	597d                	li	s2,-1
    80004d5c:	b745                	j	80004cfc <fileread+0x60>

0000000080004d5e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004d5e:	00954783          	lbu	a5,9(a0)
    80004d62:	14078563          	beqz	a5,80004eac <filewrite+0x14e>
{
    80004d66:	715d                	addi	sp,sp,-80
    80004d68:	e486                	sd	ra,72(sp)
    80004d6a:	e0a2                	sd	s0,64(sp)
    80004d6c:	fc26                	sd	s1,56(sp)
    80004d6e:	f84a                	sd	s2,48(sp)
    80004d70:	f44e                	sd	s3,40(sp)
    80004d72:	f052                	sd	s4,32(sp)
    80004d74:	ec56                	sd	s5,24(sp)
    80004d76:	e85a                	sd	s6,16(sp)
    80004d78:	e45e                	sd	s7,8(sp)
    80004d7a:	e062                	sd	s8,0(sp)
    80004d7c:	0880                	addi	s0,sp,80
    80004d7e:	892a                	mv	s2,a0
    80004d80:	8aae                	mv	s5,a1
    80004d82:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d84:	411c                	lw	a5,0(a0)
    80004d86:	4705                	li	a4,1
    80004d88:	02e78263          	beq	a5,a4,80004dac <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d8c:	470d                	li	a4,3
    80004d8e:	02e78563          	beq	a5,a4,80004db8 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d92:	4709                	li	a4,2
    80004d94:	10e79463          	bne	a5,a4,80004e9c <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d98:	0ec05e63          	blez	a2,80004e94 <filewrite+0x136>
    int i = 0;
    80004d9c:	4981                	li	s3,0
    80004d9e:	6b05                	lui	s6,0x1
    80004da0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004da4:	6b85                	lui	s7,0x1
    80004da6:	c00b8b9b          	addiw	s7,s7,-1024
    80004daa:	a851                	j	80004e3e <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004dac:	6908                	ld	a0,16(a0)
    80004dae:	00000097          	auipc	ra,0x0
    80004db2:	254080e7          	jalr	596(ra) # 80005002 <pipewrite>
    80004db6:	a85d                	j	80004e6c <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004db8:	02451783          	lh	a5,36(a0)
    80004dbc:	03079693          	slli	a3,a5,0x30
    80004dc0:	92c1                	srli	a3,a3,0x30
    80004dc2:	4725                	li	a4,9
    80004dc4:	0ed76663          	bltu	a4,a3,80004eb0 <filewrite+0x152>
    80004dc8:	0792                	slli	a5,a5,0x4
    80004dca:	0001d717          	auipc	a4,0x1d
    80004dce:	fe670713          	addi	a4,a4,-26 # 80021db0 <devsw>
    80004dd2:	97ba                	add	a5,a5,a4
    80004dd4:	679c                	ld	a5,8(a5)
    80004dd6:	cff9                	beqz	a5,80004eb4 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004dd8:	4505                	li	a0,1
    80004dda:	9782                	jalr	a5
    80004ddc:	a841                	j	80004e6c <filewrite+0x10e>
    80004dde:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004de2:	00000097          	auipc	ra,0x0
    80004de6:	8ae080e7          	jalr	-1874(ra) # 80004690 <begin_op>
      ilock(f->ip);
    80004dea:	01893503          	ld	a0,24(s2)
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	ee6080e7          	jalr	-282(ra) # 80003cd4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004df6:	8762                	mv	a4,s8
    80004df8:	02092683          	lw	a3,32(s2)
    80004dfc:	01598633          	add	a2,s3,s5
    80004e00:	4585                	li	a1,1
    80004e02:	01893503          	ld	a0,24(s2)
    80004e06:	fffff097          	auipc	ra,0xfffff
    80004e0a:	278080e7          	jalr	632(ra) # 8000407e <writei>
    80004e0e:	84aa                	mv	s1,a0
    80004e10:	02a05f63          	blez	a0,80004e4e <filewrite+0xf0>
        f->off += r;
    80004e14:	02092783          	lw	a5,32(s2)
    80004e18:	9fa9                	addw	a5,a5,a0
    80004e1a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e1e:	01893503          	ld	a0,24(s2)
    80004e22:	fffff097          	auipc	ra,0xfffff
    80004e26:	f74080e7          	jalr	-140(ra) # 80003d96 <iunlock>
      end_op();
    80004e2a:	00000097          	auipc	ra,0x0
    80004e2e:	8e6080e7          	jalr	-1818(ra) # 80004710 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004e32:	049c1963          	bne	s8,s1,80004e84 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004e36:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e3a:	0349d663          	bge	s3,s4,80004e66 <filewrite+0x108>
      int n1 = n - i;
    80004e3e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e42:	84be                	mv	s1,a5
    80004e44:	2781                	sext.w	a5,a5
    80004e46:	f8fb5ce3          	bge	s6,a5,80004dde <filewrite+0x80>
    80004e4a:	84de                	mv	s1,s7
    80004e4c:	bf49                	j	80004dde <filewrite+0x80>
      iunlock(f->ip);
    80004e4e:	01893503          	ld	a0,24(s2)
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	f44080e7          	jalr	-188(ra) # 80003d96 <iunlock>
      end_op();
    80004e5a:	00000097          	auipc	ra,0x0
    80004e5e:	8b6080e7          	jalr	-1866(ra) # 80004710 <end_op>
      if(r < 0)
    80004e62:	fc04d8e3          	bgez	s1,80004e32 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004e66:	8552                	mv	a0,s4
    80004e68:	033a1863          	bne	s4,s3,80004e98 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e6c:	60a6                	ld	ra,72(sp)
    80004e6e:	6406                	ld	s0,64(sp)
    80004e70:	74e2                	ld	s1,56(sp)
    80004e72:	7942                	ld	s2,48(sp)
    80004e74:	79a2                	ld	s3,40(sp)
    80004e76:	7a02                	ld	s4,32(sp)
    80004e78:	6ae2                	ld	s5,24(sp)
    80004e7a:	6b42                	ld	s6,16(sp)
    80004e7c:	6ba2                	ld	s7,8(sp)
    80004e7e:	6c02                	ld	s8,0(sp)
    80004e80:	6161                	addi	sp,sp,80
    80004e82:	8082                	ret
        panic("short filewrite");
    80004e84:	00004517          	auipc	a0,0x4
    80004e88:	aac50513          	addi	a0,a0,-1364 # 80008930 <sysnames+0x278>
    80004e8c:	ffffb097          	auipc	ra,0xffffb
    80004e90:	6bc080e7          	jalr	1724(ra) # 80000548 <panic>
    int i = 0;
    80004e94:	4981                	li	s3,0
    80004e96:	bfc1                	j	80004e66 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004e98:	557d                	li	a0,-1
    80004e9a:	bfc9                	j	80004e6c <filewrite+0x10e>
    panic("filewrite");
    80004e9c:	00004517          	auipc	a0,0x4
    80004ea0:	aa450513          	addi	a0,a0,-1372 # 80008940 <sysnames+0x288>
    80004ea4:	ffffb097          	auipc	ra,0xffffb
    80004ea8:	6a4080e7          	jalr	1700(ra) # 80000548 <panic>
    return -1;
    80004eac:	557d                	li	a0,-1
}
    80004eae:	8082                	ret
      return -1;
    80004eb0:	557d                	li	a0,-1
    80004eb2:	bf6d                	j	80004e6c <filewrite+0x10e>
    80004eb4:	557d                	li	a0,-1
    80004eb6:	bf5d                	j	80004e6c <filewrite+0x10e>

0000000080004eb8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004eb8:	7179                	addi	sp,sp,-48
    80004eba:	f406                	sd	ra,40(sp)
    80004ebc:	f022                	sd	s0,32(sp)
    80004ebe:	ec26                	sd	s1,24(sp)
    80004ec0:	e84a                	sd	s2,16(sp)
    80004ec2:	e44e                	sd	s3,8(sp)
    80004ec4:	e052                	sd	s4,0(sp)
    80004ec6:	1800                	addi	s0,sp,48
    80004ec8:	84aa                	mv	s1,a0
    80004eca:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ecc:	0005b023          	sd	zero,0(a1)
    80004ed0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ed4:	00000097          	auipc	ra,0x0
    80004ed8:	bd2080e7          	jalr	-1070(ra) # 80004aa6 <filealloc>
    80004edc:	e088                	sd	a0,0(s1)
    80004ede:	c551                	beqz	a0,80004f6a <pipealloc+0xb2>
    80004ee0:	00000097          	auipc	ra,0x0
    80004ee4:	bc6080e7          	jalr	-1082(ra) # 80004aa6 <filealloc>
    80004ee8:	00aa3023          	sd	a0,0(s4)
    80004eec:	c92d                	beqz	a0,80004f5e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	c32080e7          	jalr	-974(ra) # 80000b20 <kalloc>
    80004ef6:	892a                	mv	s2,a0
    80004ef8:	c125                	beqz	a0,80004f58 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004efa:	4985                	li	s3,1
    80004efc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f00:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f04:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f08:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f0c:	00003597          	auipc	a1,0x3
    80004f10:	63c58593          	addi	a1,a1,1596 # 80008548 <states.1765+0x198>
    80004f14:	ffffc097          	auipc	ra,0xffffc
    80004f18:	cb6080e7          	jalr	-842(ra) # 80000bca <initlock>
  (*f0)->type = FD_PIPE;
    80004f1c:	609c                	ld	a5,0(s1)
    80004f1e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f22:	609c                	ld	a5,0(s1)
    80004f24:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f28:	609c                	ld	a5,0(s1)
    80004f2a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f2e:	609c                	ld	a5,0(s1)
    80004f30:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f34:	000a3783          	ld	a5,0(s4)
    80004f38:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f3c:	000a3783          	ld	a5,0(s4)
    80004f40:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f44:	000a3783          	ld	a5,0(s4)
    80004f48:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f4c:	000a3783          	ld	a5,0(s4)
    80004f50:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f54:	4501                	li	a0,0
    80004f56:	a025                	j	80004f7e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f58:	6088                	ld	a0,0(s1)
    80004f5a:	e501                	bnez	a0,80004f62 <pipealloc+0xaa>
    80004f5c:	a039                	j	80004f6a <pipealloc+0xb2>
    80004f5e:	6088                	ld	a0,0(s1)
    80004f60:	c51d                	beqz	a0,80004f8e <pipealloc+0xd6>
    fileclose(*f0);
    80004f62:	00000097          	auipc	ra,0x0
    80004f66:	c00080e7          	jalr	-1024(ra) # 80004b62 <fileclose>
  if(*f1)
    80004f6a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f6e:	557d                	li	a0,-1
  if(*f1)
    80004f70:	c799                	beqz	a5,80004f7e <pipealloc+0xc6>
    fileclose(*f1);
    80004f72:	853e                	mv	a0,a5
    80004f74:	00000097          	auipc	ra,0x0
    80004f78:	bee080e7          	jalr	-1042(ra) # 80004b62 <fileclose>
  return -1;
    80004f7c:	557d                	li	a0,-1
}
    80004f7e:	70a2                	ld	ra,40(sp)
    80004f80:	7402                	ld	s0,32(sp)
    80004f82:	64e2                	ld	s1,24(sp)
    80004f84:	6942                	ld	s2,16(sp)
    80004f86:	69a2                	ld	s3,8(sp)
    80004f88:	6a02                	ld	s4,0(sp)
    80004f8a:	6145                	addi	sp,sp,48
    80004f8c:	8082                	ret
  return -1;
    80004f8e:	557d                	li	a0,-1
    80004f90:	b7fd                	j	80004f7e <pipealloc+0xc6>

0000000080004f92 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f92:	1101                	addi	sp,sp,-32
    80004f94:	ec06                	sd	ra,24(sp)
    80004f96:	e822                	sd	s0,16(sp)
    80004f98:	e426                	sd	s1,8(sp)
    80004f9a:	e04a                	sd	s2,0(sp)
    80004f9c:	1000                	addi	s0,sp,32
    80004f9e:	84aa                	mv	s1,a0
    80004fa0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fa2:	ffffc097          	auipc	ra,0xffffc
    80004fa6:	cb8080e7          	jalr	-840(ra) # 80000c5a <acquire>
  if(writable){
    80004faa:	02090d63          	beqz	s2,80004fe4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004fae:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fb2:	21848513          	addi	a0,s1,536
    80004fb6:	ffffe097          	auipc	ra,0xffffe
    80004fba:	954080e7          	jalr	-1708(ra) # 8000290a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fbe:	2204b783          	ld	a5,544(s1)
    80004fc2:	eb95                	bnez	a5,80004ff6 <pipeclose+0x64>
    release(&pi->lock);
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	d48080e7          	jalr	-696(ra) # 80000d0e <release>
    kfree((char*)pi);
    80004fce:	8526                	mv	a0,s1
    80004fd0:	ffffc097          	auipc	ra,0xffffc
    80004fd4:	a54080e7          	jalr	-1452(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004fd8:	60e2                	ld	ra,24(sp)
    80004fda:	6442                	ld	s0,16(sp)
    80004fdc:	64a2                	ld	s1,8(sp)
    80004fde:	6902                	ld	s2,0(sp)
    80004fe0:	6105                	addi	sp,sp,32
    80004fe2:	8082                	ret
    pi->readopen = 0;
    80004fe4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004fe8:	21c48513          	addi	a0,s1,540
    80004fec:	ffffe097          	auipc	ra,0xffffe
    80004ff0:	91e080e7          	jalr	-1762(ra) # 8000290a <wakeup>
    80004ff4:	b7e9                	j	80004fbe <pipeclose+0x2c>
    release(&pi->lock);
    80004ff6:	8526                	mv	a0,s1
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	d16080e7          	jalr	-746(ra) # 80000d0e <release>
}
    80005000:	bfe1                	j	80004fd8 <pipeclose+0x46>

0000000080005002 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005002:	7119                	addi	sp,sp,-128
    80005004:	fc86                	sd	ra,120(sp)
    80005006:	f8a2                	sd	s0,112(sp)
    80005008:	f4a6                	sd	s1,104(sp)
    8000500a:	f0ca                	sd	s2,96(sp)
    8000500c:	ecce                	sd	s3,88(sp)
    8000500e:	e8d2                	sd	s4,80(sp)
    80005010:	e4d6                	sd	s5,72(sp)
    80005012:	e0da                	sd	s6,64(sp)
    80005014:	fc5e                	sd	s7,56(sp)
    80005016:	f862                	sd	s8,48(sp)
    80005018:	f466                	sd	s9,40(sp)
    8000501a:	f06a                	sd	s10,32(sp)
    8000501c:	ec6e                	sd	s11,24(sp)
    8000501e:	0100                	addi	s0,sp,128
    80005020:	84aa                	mv	s1,a0
    80005022:	8cae                	mv	s9,a1
    80005024:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80005026:	ffffd097          	auipc	ra,0xffffd
    8000502a:	dc6080e7          	jalr	-570(ra) # 80001dec <myproc>
    8000502e:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80005030:	8526                	mv	a0,s1
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	c28080e7          	jalr	-984(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    8000503a:	0d605963          	blez	s6,8000510c <pipewrite+0x10a>
    8000503e:	89a6                	mv	s3,s1
    80005040:	3b7d                	addiw	s6,s6,-1
    80005042:	1b02                	slli	s6,s6,0x20
    80005044:	020b5b13          	srli	s6,s6,0x20
    80005048:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    8000504a:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000504e:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005052:	5dfd                	li	s11,-1
    80005054:	000b8d1b          	sext.w	s10,s7
    80005058:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    8000505a:	2184a783          	lw	a5,536(s1)
    8000505e:	21c4a703          	lw	a4,540(s1)
    80005062:	2007879b          	addiw	a5,a5,512
    80005066:	02f71b63          	bne	a4,a5,8000509c <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    8000506a:	2204a783          	lw	a5,544(s1)
    8000506e:	cbad                	beqz	a5,800050e0 <pipewrite+0xde>
    80005070:	03092783          	lw	a5,48(s2)
    80005074:	e7b5                	bnez	a5,800050e0 <pipewrite+0xde>
      wakeup(&pi->nread);
    80005076:	8556                	mv	a0,s5
    80005078:	ffffe097          	auipc	ra,0xffffe
    8000507c:	892080e7          	jalr	-1902(ra) # 8000290a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005080:	85ce                	mv	a1,s3
    80005082:	8552                	mv	a0,s4
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	700080e7          	jalr	1792(ra) # 80002784 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    8000508c:	2184a783          	lw	a5,536(s1)
    80005090:	21c4a703          	lw	a4,540(s1)
    80005094:	2007879b          	addiw	a5,a5,512
    80005098:	fcf709e3          	beq	a4,a5,8000506a <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000509c:	4685                	li	a3,1
    8000509e:	019b8633          	add	a2,s7,s9
    800050a2:	f8f40593          	addi	a1,s0,-113
    800050a6:	05093503          	ld	a0,80(s2)
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	8a0080e7          	jalr	-1888(ra) # 8000194a <copyin>
    800050b2:	05b50e63          	beq	a0,s11,8000510e <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050b6:	21c4a783          	lw	a5,540(s1)
    800050ba:	0017871b          	addiw	a4,a5,1
    800050be:	20e4ae23          	sw	a4,540(s1)
    800050c2:	1ff7f793          	andi	a5,a5,511
    800050c6:	97a6                	add	a5,a5,s1
    800050c8:	f8f44703          	lbu	a4,-113(s0)
    800050cc:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    800050d0:	001d0c1b          	addiw	s8,s10,1
    800050d4:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    800050d8:	036b8b63          	beq	s7,s6,8000510e <pipewrite+0x10c>
    800050dc:	8bbe                	mv	s7,a5
    800050de:	bf9d                	j	80005054 <pipewrite+0x52>
        release(&pi->lock);
    800050e0:	8526                	mv	a0,s1
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	c2c080e7          	jalr	-980(ra) # 80000d0e <release>
        return -1;
    800050ea:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    800050ec:	8562                	mv	a0,s8
    800050ee:	70e6                	ld	ra,120(sp)
    800050f0:	7446                	ld	s0,112(sp)
    800050f2:	74a6                	ld	s1,104(sp)
    800050f4:	7906                	ld	s2,96(sp)
    800050f6:	69e6                	ld	s3,88(sp)
    800050f8:	6a46                	ld	s4,80(sp)
    800050fa:	6aa6                	ld	s5,72(sp)
    800050fc:	6b06                	ld	s6,64(sp)
    800050fe:	7be2                	ld	s7,56(sp)
    80005100:	7c42                	ld	s8,48(sp)
    80005102:	7ca2                	ld	s9,40(sp)
    80005104:	7d02                	ld	s10,32(sp)
    80005106:	6de2                	ld	s11,24(sp)
    80005108:	6109                	addi	sp,sp,128
    8000510a:	8082                	ret
  for(i = 0; i < n; i++){
    8000510c:	4c01                	li	s8,0
  wakeup(&pi->nread);
    8000510e:	21848513          	addi	a0,s1,536
    80005112:	ffffd097          	auipc	ra,0xffffd
    80005116:	7f8080e7          	jalr	2040(ra) # 8000290a <wakeup>
  release(&pi->lock);
    8000511a:	8526                	mv	a0,s1
    8000511c:	ffffc097          	auipc	ra,0xffffc
    80005120:	bf2080e7          	jalr	-1038(ra) # 80000d0e <release>
  return i;
    80005124:	b7e1                	j	800050ec <pipewrite+0xea>

0000000080005126 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005126:	715d                	addi	sp,sp,-80
    80005128:	e486                	sd	ra,72(sp)
    8000512a:	e0a2                	sd	s0,64(sp)
    8000512c:	fc26                	sd	s1,56(sp)
    8000512e:	f84a                	sd	s2,48(sp)
    80005130:	f44e                	sd	s3,40(sp)
    80005132:	f052                	sd	s4,32(sp)
    80005134:	ec56                	sd	s5,24(sp)
    80005136:	e85a                	sd	s6,16(sp)
    80005138:	0880                	addi	s0,sp,80
    8000513a:	84aa                	mv	s1,a0
    8000513c:	892e                	mv	s2,a1
    8000513e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005140:	ffffd097          	auipc	ra,0xffffd
    80005144:	cac080e7          	jalr	-852(ra) # 80001dec <myproc>
    80005148:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000514a:	8b26                	mv	s6,s1
    8000514c:	8526                	mv	a0,s1
    8000514e:	ffffc097          	auipc	ra,0xffffc
    80005152:	b0c080e7          	jalr	-1268(ra) # 80000c5a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005156:	2184a703          	lw	a4,536(s1)
    8000515a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000515e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005162:	02f71463          	bne	a4,a5,8000518a <piperead+0x64>
    80005166:	2244a783          	lw	a5,548(s1)
    8000516a:	c385                	beqz	a5,8000518a <piperead+0x64>
    if(pr->killed){
    8000516c:	030a2783          	lw	a5,48(s4)
    80005170:	ebc1                	bnez	a5,80005200 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005172:	85da                	mv	a1,s6
    80005174:	854e                	mv	a0,s3
    80005176:	ffffd097          	auipc	ra,0xffffd
    8000517a:	60e080e7          	jalr	1550(ra) # 80002784 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000517e:	2184a703          	lw	a4,536(s1)
    80005182:	21c4a783          	lw	a5,540(s1)
    80005186:	fef700e3          	beq	a4,a5,80005166 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000518a:	09505263          	blez	s5,8000520e <piperead+0xe8>
    8000518e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005190:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005192:	2184a783          	lw	a5,536(s1)
    80005196:	21c4a703          	lw	a4,540(s1)
    8000519a:	02f70d63          	beq	a4,a5,800051d4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000519e:	0017871b          	addiw	a4,a5,1
    800051a2:	20e4ac23          	sw	a4,536(s1)
    800051a6:	1ff7f793          	andi	a5,a5,511
    800051aa:	97a6                	add	a5,a5,s1
    800051ac:	0187c783          	lbu	a5,24(a5)
    800051b0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051b4:	4685                	li	a3,1
    800051b6:	fbf40613          	addi	a2,s0,-65
    800051ba:	85ca                	mv	a1,s2
    800051bc:	050a3503          	ld	a0,80(s4)
    800051c0:	ffffc097          	auipc	ra,0xffffc
    800051c4:	6fe080e7          	jalr	1790(ra) # 800018be <copyout>
    800051c8:	01650663          	beq	a0,s6,800051d4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051cc:	2985                	addiw	s3,s3,1
    800051ce:	0905                	addi	s2,s2,1
    800051d0:	fd3a91e3          	bne	s5,s3,80005192 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051d4:	21c48513          	addi	a0,s1,540
    800051d8:	ffffd097          	auipc	ra,0xffffd
    800051dc:	732080e7          	jalr	1842(ra) # 8000290a <wakeup>
  release(&pi->lock);
    800051e0:	8526                	mv	a0,s1
    800051e2:	ffffc097          	auipc	ra,0xffffc
    800051e6:	b2c080e7          	jalr	-1236(ra) # 80000d0e <release>
  return i;
}
    800051ea:	854e                	mv	a0,s3
    800051ec:	60a6                	ld	ra,72(sp)
    800051ee:	6406                	ld	s0,64(sp)
    800051f0:	74e2                	ld	s1,56(sp)
    800051f2:	7942                	ld	s2,48(sp)
    800051f4:	79a2                	ld	s3,40(sp)
    800051f6:	7a02                	ld	s4,32(sp)
    800051f8:	6ae2                	ld	s5,24(sp)
    800051fa:	6b42                	ld	s6,16(sp)
    800051fc:	6161                	addi	sp,sp,80
    800051fe:	8082                	ret
      release(&pi->lock);
    80005200:	8526                	mv	a0,s1
    80005202:	ffffc097          	auipc	ra,0xffffc
    80005206:	b0c080e7          	jalr	-1268(ra) # 80000d0e <release>
      return -1;
    8000520a:	59fd                	li	s3,-1
    8000520c:	bff9                	j	800051ea <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000520e:	4981                	li	s3,0
    80005210:	b7d1                	j	800051d4 <piperead+0xae>

0000000080005212 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005212:	df010113          	addi	sp,sp,-528
    80005216:	20113423          	sd	ra,520(sp)
    8000521a:	20813023          	sd	s0,512(sp)
    8000521e:	ffa6                	sd	s1,504(sp)
    80005220:	fbca                	sd	s2,496(sp)
    80005222:	f7ce                	sd	s3,488(sp)
    80005224:	f3d2                	sd	s4,480(sp)
    80005226:	efd6                	sd	s5,472(sp)
    80005228:	ebda                	sd	s6,464(sp)
    8000522a:	e7de                	sd	s7,456(sp)
    8000522c:	e3e2                	sd	s8,448(sp)
    8000522e:	ff66                	sd	s9,440(sp)
    80005230:	fb6a                	sd	s10,432(sp)
    80005232:	f76e                	sd	s11,424(sp)
    80005234:	0c00                	addi	s0,sp,528
    80005236:	84aa                	mv	s1,a0
    80005238:	dea43c23          	sd	a0,-520(s0)
    8000523c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005240:	ffffd097          	auipc	ra,0xffffd
    80005244:	bac080e7          	jalr	-1108(ra) # 80001dec <myproc>
    80005248:	892a                	mv	s2,a0

  begin_op();
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	446080e7          	jalr	1094(ra) # 80004690 <begin_op>

  if((ip = namei(path)) == 0){
    80005252:	8526                	mv	a0,s1
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	230080e7          	jalr	560(ra) # 80004484 <namei>
    8000525c:	c92d                	beqz	a0,800052ce <exec+0xbc>
    8000525e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005260:	fffff097          	auipc	ra,0xfffff
    80005264:	a74080e7          	jalr	-1420(ra) # 80003cd4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005268:	04000713          	li	a4,64
    8000526c:	4681                	li	a3,0
    8000526e:	e4840613          	addi	a2,s0,-440
    80005272:	4581                	li	a1,0
    80005274:	8526                	mv	a0,s1
    80005276:	fffff097          	auipc	ra,0xfffff
    8000527a:	d12080e7          	jalr	-750(ra) # 80003f88 <readi>
    8000527e:	04000793          	li	a5,64
    80005282:	00f51a63          	bne	a0,a5,80005296 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005286:	e4842703          	lw	a4,-440(s0)
    8000528a:	464c47b7          	lui	a5,0x464c4
    8000528e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005292:	04f70463          	beq	a4,a5,800052da <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005296:	8526                	mv	a0,s1
    80005298:	fffff097          	auipc	ra,0xfffff
    8000529c:	c9e080e7          	jalr	-866(ra) # 80003f36 <iunlockput>
    end_op();
    800052a0:	fffff097          	auipc	ra,0xfffff
    800052a4:	470080e7          	jalr	1136(ra) # 80004710 <end_op>
  }
  return -1;
    800052a8:	557d                	li	a0,-1
}
    800052aa:	20813083          	ld	ra,520(sp)
    800052ae:	20013403          	ld	s0,512(sp)
    800052b2:	74fe                	ld	s1,504(sp)
    800052b4:	795e                	ld	s2,496(sp)
    800052b6:	79be                	ld	s3,488(sp)
    800052b8:	7a1e                	ld	s4,480(sp)
    800052ba:	6afe                	ld	s5,472(sp)
    800052bc:	6b5e                	ld	s6,464(sp)
    800052be:	6bbe                	ld	s7,456(sp)
    800052c0:	6c1e                	ld	s8,448(sp)
    800052c2:	7cfa                	ld	s9,440(sp)
    800052c4:	7d5a                	ld	s10,432(sp)
    800052c6:	7dba                	ld	s11,424(sp)
    800052c8:	21010113          	addi	sp,sp,528
    800052cc:	8082                	ret
    end_op();
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	442080e7          	jalr	1090(ra) # 80004710 <end_op>
    return -1;
    800052d6:	557d                	li	a0,-1
    800052d8:	bfc9                	j	800052aa <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800052da:	854a                	mv	a0,s2
    800052dc:	ffffd097          	auipc	ra,0xffffd
    800052e0:	bd4080e7          	jalr	-1068(ra) # 80001eb0 <proc_pagetable>
    800052e4:	8baa                	mv	s7,a0
    800052e6:	d945                	beqz	a0,80005296 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052e8:	e6842983          	lw	s3,-408(s0)
    800052ec:	e8045783          	lhu	a5,-384(s0)
    800052f0:	c7ad                	beqz	a5,8000535a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800052f2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052f4:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    800052f6:	6c85                	lui	s9,0x1
    800052f8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800052fc:	def43823          	sd	a5,-528(s0)
    80005300:	a4bd                	j	8000556e <exec+0x35c>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005302:	00003517          	auipc	a0,0x3
    80005306:	64e50513          	addi	a0,a0,1614 # 80008950 <sysnames+0x298>
    8000530a:	ffffb097          	auipc	ra,0xffffb
    8000530e:	23e080e7          	jalr	574(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005312:	8756                	mv	a4,s5
    80005314:	012d86bb          	addw	a3,s11,s2
    80005318:	4581                	li	a1,0
    8000531a:	8526                	mv	a0,s1
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	c6c080e7          	jalr	-916(ra) # 80003f88 <readi>
    80005324:	2501                	sext.w	a0,a0
    80005326:	1eaa9b63          	bne	s5,a0,8000551c <exec+0x30a>
  for(i = 0; i < sz; i += PGSIZE){
    8000532a:	6785                	lui	a5,0x1
    8000532c:	0127893b          	addw	s2,a5,s2
    80005330:	77fd                	lui	a5,0xfffff
    80005332:	01478a3b          	addw	s4,a5,s4
    80005336:	23897363          	bgeu	s2,s8,8000555c <exec+0x34a>
    pa = walkaddr(pagetable, va + i);
    8000533a:	02091593          	slli	a1,s2,0x20
    8000533e:	9181                	srli	a1,a1,0x20
    80005340:	95ea                	add	a1,a1,s10
    80005342:	855e                	mv	a0,s7
    80005344:	ffffc097          	auipc	ra,0xffffc
    80005348:	dc8080e7          	jalr	-568(ra) # 8000110c <walkaddr>
    8000534c:	862a                	mv	a2,a0
    if(pa == 0)
    8000534e:	d955                	beqz	a0,80005302 <exec+0xf0>
      n = PGSIZE;
    80005350:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005352:	fd9a70e3          	bgeu	s4,s9,80005312 <exec+0x100>
      n = sz - i;
    80005356:	8ad2                	mv	s5,s4
    80005358:	bf6d                	j	80005312 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000535a:	4901                	li	s2,0
  iunlockput(ip);
    8000535c:	8526                	mv	a0,s1
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	bd8080e7          	jalr	-1064(ra) # 80003f36 <iunlockput>
  end_op();
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	3aa080e7          	jalr	938(ra) # 80004710 <end_op>
  p = myproc();
    8000536e:	ffffd097          	auipc	ra,0xffffd
    80005372:	a7e080e7          	jalr	-1410(ra) # 80001dec <myproc>
    80005376:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005378:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000537c:	6785                	lui	a5,0x1
    8000537e:	17fd                	addi	a5,a5,-1
    80005380:	993e                	add	s2,s2,a5
    80005382:	757d                	lui	a0,0xfffff
    80005384:	00a977b3          	and	a5,s2,a0
    80005388:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000538c:	6609                	lui	a2,0x2
    8000538e:	963e                	add	a2,a2,a5
    80005390:	85be                	mv	a1,a5
    80005392:	855e                	mv	a0,s7
    80005394:	ffffc097          	auipc	ra,0xffffc
    80005398:	1d4080e7          	jalr	468(ra) # 80001568 <uvmalloc>
    8000539c:	8b2a                	mv	s6,a0
  ip = 0;
    8000539e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800053a0:	16050e63          	beqz	a0,8000551c <exec+0x30a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053a4:	75f9                	lui	a1,0xffffe
    800053a6:	95aa                	add	a1,a1,a0
    800053a8:	855e                	mv	a0,s7
    800053aa:	ffffc097          	auipc	ra,0xffffc
    800053ae:	4e2080e7          	jalr	1250(ra) # 8000188c <uvmclear>
  stackbase = sp - PGSIZE;
    800053b2:	7c7d                	lui	s8,0xfffff
    800053b4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800053b6:	e0043783          	ld	a5,-512(s0)
    800053ba:	6388                	ld	a0,0(a5)
    800053bc:	c535                	beqz	a0,80005428 <exec+0x216>
    800053be:	e8840993          	addi	s3,s0,-376
    800053c2:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800053c6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800053c8:	ffffc097          	auipc	ra,0xffffc
    800053cc:	b16080e7          	jalr	-1258(ra) # 80000ede <strlen>
    800053d0:	2505                	addiw	a0,a0,1
    800053d2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053d6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800053da:	17896563          	bltu	s2,s8,80005544 <exec+0x332>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053de:	e0043d83          	ld	s11,-512(s0)
    800053e2:	000dba03          	ld	s4,0(s11)
    800053e6:	8552                	mv	a0,s4
    800053e8:	ffffc097          	auipc	ra,0xffffc
    800053ec:	af6080e7          	jalr	-1290(ra) # 80000ede <strlen>
    800053f0:	0015069b          	addiw	a3,a0,1
    800053f4:	8652                	mv	a2,s4
    800053f6:	85ca                	mv	a1,s2
    800053f8:	855e                	mv	a0,s7
    800053fa:	ffffc097          	auipc	ra,0xffffc
    800053fe:	4c4080e7          	jalr	1220(ra) # 800018be <copyout>
    80005402:	14054563          	bltz	a0,8000554c <exec+0x33a>
    ustack[argc] = sp;
    80005406:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000540a:	0485                	addi	s1,s1,1
    8000540c:	008d8793          	addi	a5,s11,8
    80005410:	e0f43023          	sd	a5,-512(s0)
    80005414:	008db503          	ld	a0,8(s11)
    80005418:	c911                	beqz	a0,8000542c <exec+0x21a>
    if(argc >= MAXARG)
    8000541a:	09a1                	addi	s3,s3,8
    8000541c:	fb3c96e3          	bne	s9,s3,800053c8 <exec+0x1b6>
  sz = sz1;
    80005420:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005424:	4481                	li	s1,0
    80005426:	a8dd                	j	8000551c <exec+0x30a>
  sp = sz;
    80005428:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000542a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000542c:	00349793          	slli	a5,s1,0x3
    80005430:	f9040713          	addi	a4,s0,-112
    80005434:	97ba                	add	a5,a5,a4
    80005436:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    8000543a:	00148693          	addi	a3,s1,1
    8000543e:	068e                	slli	a3,a3,0x3
    80005440:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005444:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005448:	01897663          	bgeu	s2,s8,80005454 <exec+0x242>
  sz = sz1;
    8000544c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005450:	4481                	li	s1,0
    80005452:	a0e9                	j	8000551c <exec+0x30a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005454:	e8840613          	addi	a2,s0,-376
    80005458:	85ca                	mv	a1,s2
    8000545a:	855e                	mv	a0,s7
    8000545c:	ffffc097          	auipc	ra,0xffffc
    80005460:	462080e7          	jalr	1122(ra) # 800018be <copyout>
    80005464:	0e054863          	bltz	a0,80005554 <exec+0x342>
  p->trapframe->a1 = sp;
    80005468:	058ab783          	ld	a5,88(s5)
    8000546c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005470:	df843783          	ld	a5,-520(s0)
    80005474:	0007c703          	lbu	a4,0(a5)
    80005478:	cf11                	beqz	a4,80005494 <exec+0x282>
    8000547a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000547c:	02f00693          	li	a3,47
    80005480:	a029                	j	8000548a <exec+0x278>
  for(last=s=path; *s; s++)
    80005482:	0785                	addi	a5,a5,1
    80005484:	fff7c703          	lbu	a4,-1(a5)
    80005488:	c711                	beqz	a4,80005494 <exec+0x282>
    if(*s == '/')
    8000548a:	fed71ce3          	bne	a4,a3,80005482 <exec+0x270>
      last = s+1;
    8000548e:	def43c23          	sd	a5,-520(s0)
    80005492:	bfc5                	j	80005482 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005494:	4641                	li	a2,16
    80005496:	df843583          	ld	a1,-520(s0)
    8000549a:	158a8513          	addi	a0,s5,344
    8000549e:	ffffc097          	auipc	ra,0xffffc
    800054a2:	a0e080e7          	jalr	-1522(ra) # 80000eac <safestrcpy>
  oldpagetable = p->pagetable;
    800054a6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800054aa:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800054ae:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054b2:	058ab783          	ld	a5,88(s5)
    800054b6:	e6043703          	ld	a4,-416(s0)
    800054ba:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054bc:	058ab783          	ld	a5,88(s5)
    800054c0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054c4:	85ea                	mv	a1,s10
    800054c6:	ffffd097          	auipc	ra,0xffffd
    800054ca:	a86080e7          	jalr	-1402(ra) # 80001f4c <proc_freepagetable>
  if (pagecopy(p->pagetable, p->kpagetable, 0, p->sz) != 0) {
    800054ce:	048ab683          	ld	a3,72(s5)
    800054d2:	4601                	li	a2,0
    800054d4:	170ab583          	ld	a1,368(s5)
    800054d8:	050ab503          	ld	a0,80(s5)
    800054dc:	ffffc097          	auipc	ra,0xffffc
    800054e0:	236080e7          	jalr	566(ra) # 80001712 <pagecopy>
    800054e4:	c509                	beqz	a0,800054ee <exec+0x2dc>
  sz = sz1;
    800054e6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054ea:	4481                	li	s1,0
    800054ec:	a805                	j	8000551c <exec+0x30a>
  ukvminithard(p->kpagetable);
    800054ee:	170ab503          	ld	a0,368(s5)
    800054f2:	ffffc097          	auipc	ra,0xffffc
    800054f6:	b34080e7          	jalr	-1228(ra) # 80001026 <ukvminithard>
  if (p->pid == 1)
    800054fa:	038aa703          	lw	a4,56(s5)
    800054fe:	4785                	li	a5,1
    80005500:	00f70563          	beq	a4,a5,8000550a <exec+0x2f8>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005504:	0004851b          	sext.w	a0,s1
    80005508:	b34d                	j	800052aa <exec+0x98>
    vmprint(p->pagetable);
    8000550a:	050ab503          	ld	a0,80(s5)
    8000550e:	ffffc097          	auipc	ra,0xffffc
    80005512:	518080e7          	jalr	1304(ra) # 80001a26 <vmprint>
    80005516:	b7fd                	j	80005504 <exec+0x2f2>
    80005518:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000551c:	e0843583          	ld	a1,-504(s0)
    80005520:	855e                	mv	a0,s7
    80005522:	ffffd097          	auipc	ra,0xffffd
    80005526:	a2a080e7          	jalr	-1494(ra) # 80001f4c <proc_freepagetable>
  if(ip){
    8000552a:	d60496e3          	bnez	s1,80005296 <exec+0x84>
  return -1;
    8000552e:	557d                	li	a0,-1
    80005530:	bbad                	j	800052aa <exec+0x98>
    80005532:	e1243423          	sd	s2,-504(s0)
    80005536:	b7dd                	j	8000551c <exec+0x30a>
    80005538:	e1243423          	sd	s2,-504(s0)
    8000553c:	b7c5                	j	8000551c <exec+0x30a>
    8000553e:	e1243423          	sd	s2,-504(s0)
    80005542:	bfe9                	j	8000551c <exec+0x30a>
  sz = sz1;
    80005544:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005548:	4481                	li	s1,0
    8000554a:	bfc9                	j	8000551c <exec+0x30a>
  sz = sz1;
    8000554c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005550:	4481                	li	s1,0
    80005552:	b7e9                	j	8000551c <exec+0x30a>
  sz = sz1;
    80005554:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005558:	4481                	li	s1,0
    8000555a:	b7c9                	j	8000551c <exec+0x30a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000555c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005560:	2b05                	addiw	s6,s6,1
    80005562:	0389899b          	addiw	s3,s3,56
    80005566:	e8045783          	lhu	a5,-384(s0)
    8000556a:	defb59e3          	bge	s6,a5,8000535c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000556e:	2981                	sext.w	s3,s3
    80005570:	03800713          	li	a4,56
    80005574:	86ce                	mv	a3,s3
    80005576:	e1040613          	addi	a2,s0,-496
    8000557a:	4581                	li	a1,0
    8000557c:	8526                	mv	a0,s1
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	a0a080e7          	jalr	-1526(ra) # 80003f88 <readi>
    80005586:	03800793          	li	a5,56
    8000558a:	f8f517e3          	bne	a0,a5,80005518 <exec+0x306>
    if(ph.type != ELF_PROG_LOAD)
    8000558e:	e1042783          	lw	a5,-496(s0)
    80005592:	4705                	li	a4,1
    80005594:	fce796e3          	bne	a5,a4,80005560 <exec+0x34e>
    if(ph.memsz < ph.filesz)
    80005598:	e3843603          	ld	a2,-456(s0)
    8000559c:	e3043783          	ld	a5,-464(s0)
    800055a0:	f8f669e3          	bltu	a2,a5,80005532 <exec+0x320>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800055a4:	e2043783          	ld	a5,-480(s0)
    800055a8:	963e                	add	a2,a2,a5
    800055aa:	f8f667e3          	bltu	a2,a5,80005538 <exec+0x326>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055ae:	85ca                	mv	a1,s2
    800055b0:	855e                	mv	a0,s7
    800055b2:	ffffc097          	auipc	ra,0xffffc
    800055b6:	fb6080e7          	jalr	-74(ra) # 80001568 <uvmalloc>
    800055ba:	e0a43423          	sd	a0,-504(s0)
    800055be:	d141                	beqz	a0,8000553e <exec+0x32c>
    if(ph.vaddr % PGSIZE != 0)
    800055c0:	e2043d03          	ld	s10,-480(s0)
    800055c4:	df043783          	ld	a5,-528(s0)
    800055c8:	00fd77b3          	and	a5,s10,a5
    800055cc:	fba1                	bnez	a5,8000551c <exec+0x30a>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800055ce:	e1842d83          	lw	s11,-488(s0)
    800055d2:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800055d6:	f80c03e3          	beqz	s8,8000555c <exec+0x34a>
    800055da:	8a62                	mv	s4,s8
    800055dc:	4901                	li	s2,0
    800055de:	bbb1                	j	8000533a <exec+0x128>

00000000800055e0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055e0:	7179                	addi	sp,sp,-48
    800055e2:	f406                	sd	ra,40(sp)
    800055e4:	f022                	sd	s0,32(sp)
    800055e6:	ec26                	sd	s1,24(sp)
    800055e8:	e84a                	sd	s2,16(sp)
    800055ea:	1800                	addi	s0,sp,48
    800055ec:	892e                	mv	s2,a1
    800055ee:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800055f0:	fdc40593          	addi	a1,s0,-36
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	a92080e7          	jalr	-1390(ra) # 80003086 <argint>
    800055fc:	04054063          	bltz	a0,8000563c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005600:	fdc42703          	lw	a4,-36(s0)
    80005604:	47bd                	li	a5,15
    80005606:	02e7ed63          	bltu	a5,a4,80005640 <argfd+0x60>
    8000560a:	ffffc097          	auipc	ra,0xffffc
    8000560e:	7e2080e7          	jalr	2018(ra) # 80001dec <myproc>
    80005612:	fdc42703          	lw	a4,-36(s0)
    80005616:	01a70793          	addi	a5,a4,26
    8000561a:	078e                	slli	a5,a5,0x3
    8000561c:	953e                	add	a0,a0,a5
    8000561e:	611c                	ld	a5,0(a0)
    80005620:	c395                	beqz	a5,80005644 <argfd+0x64>
    return -1;
  if(pfd)
    80005622:	00090463          	beqz	s2,8000562a <argfd+0x4a>
    *pfd = fd;
    80005626:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000562a:	4501                	li	a0,0
  if(pf)
    8000562c:	c091                	beqz	s1,80005630 <argfd+0x50>
    *pf = f;
    8000562e:	e09c                	sd	a5,0(s1)
}
    80005630:	70a2                	ld	ra,40(sp)
    80005632:	7402                	ld	s0,32(sp)
    80005634:	64e2                	ld	s1,24(sp)
    80005636:	6942                	ld	s2,16(sp)
    80005638:	6145                	addi	sp,sp,48
    8000563a:	8082                	ret
    return -1;
    8000563c:	557d                	li	a0,-1
    8000563e:	bfcd                	j	80005630 <argfd+0x50>
    return -1;
    80005640:	557d                	li	a0,-1
    80005642:	b7fd                	j	80005630 <argfd+0x50>
    80005644:	557d                	li	a0,-1
    80005646:	b7ed                	j	80005630 <argfd+0x50>

0000000080005648 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005648:	1101                	addi	sp,sp,-32
    8000564a:	ec06                	sd	ra,24(sp)
    8000564c:	e822                	sd	s0,16(sp)
    8000564e:	e426                	sd	s1,8(sp)
    80005650:	1000                	addi	s0,sp,32
    80005652:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005654:	ffffc097          	auipc	ra,0xffffc
    80005658:	798080e7          	jalr	1944(ra) # 80001dec <myproc>
    8000565c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000565e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80b0>
    80005662:	4501                	li	a0,0
    80005664:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005666:	6398                	ld	a4,0(a5)
    80005668:	cb19                	beqz	a4,8000567e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000566a:	2505                	addiw	a0,a0,1
    8000566c:	07a1                	addi	a5,a5,8
    8000566e:	fed51ce3          	bne	a0,a3,80005666 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005672:	557d                	li	a0,-1
}
    80005674:	60e2                	ld	ra,24(sp)
    80005676:	6442                	ld	s0,16(sp)
    80005678:	64a2                	ld	s1,8(sp)
    8000567a:	6105                	addi	sp,sp,32
    8000567c:	8082                	ret
      p->ofile[fd] = f;
    8000567e:	01a50793          	addi	a5,a0,26
    80005682:	078e                	slli	a5,a5,0x3
    80005684:	963e                	add	a2,a2,a5
    80005686:	e204                	sd	s1,0(a2)
      return fd;
    80005688:	b7f5                	j	80005674 <fdalloc+0x2c>

000000008000568a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000568a:	715d                	addi	sp,sp,-80
    8000568c:	e486                	sd	ra,72(sp)
    8000568e:	e0a2                	sd	s0,64(sp)
    80005690:	fc26                	sd	s1,56(sp)
    80005692:	f84a                	sd	s2,48(sp)
    80005694:	f44e                	sd	s3,40(sp)
    80005696:	f052                	sd	s4,32(sp)
    80005698:	ec56                	sd	s5,24(sp)
    8000569a:	0880                	addi	s0,sp,80
    8000569c:	89ae                	mv	s3,a1
    8000569e:	8ab2                	mv	s5,a2
    800056a0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800056a2:	fb040593          	addi	a1,s0,-80
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	dfc080e7          	jalr	-516(ra) # 800044a2 <nameiparent>
    800056ae:	892a                	mv	s2,a0
    800056b0:	12050f63          	beqz	a0,800057ee <create+0x164>
    return 0;

  ilock(dp);
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	620080e7          	jalr	1568(ra) # 80003cd4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800056bc:	4601                	li	a2,0
    800056be:	fb040593          	addi	a1,s0,-80
    800056c2:	854a                	mv	a0,s2
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	aee080e7          	jalr	-1298(ra) # 800041b2 <dirlookup>
    800056cc:	84aa                	mv	s1,a0
    800056ce:	c921                	beqz	a0,8000571e <create+0x94>
    iunlockput(dp);
    800056d0:	854a                	mv	a0,s2
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	864080e7          	jalr	-1948(ra) # 80003f36 <iunlockput>
    ilock(ip);
    800056da:	8526                	mv	a0,s1
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	5f8080e7          	jalr	1528(ra) # 80003cd4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056e4:	2981                	sext.w	s3,s3
    800056e6:	4789                	li	a5,2
    800056e8:	02f99463          	bne	s3,a5,80005710 <create+0x86>
    800056ec:	0444d783          	lhu	a5,68(s1)
    800056f0:	37f9                	addiw	a5,a5,-2
    800056f2:	17c2                	slli	a5,a5,0x30
    800056f4:	93c1                	srli	a5,a5,0x30
    800056f6:	4705                	li	a4,1
    800056f8:	00f76c63          	bltu	a4,a5,80005710 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056fc:	8526                	mv	a0,s1
    800056fe:	60a6                	ld	ra,72(sp)
    80005700:	6406                	ld	s0,64(sp)
    80005702:	74e2                	ld	s1,56(sp)
    80005704:	7942                	ld	s2,48(sp)
    80005706:	79a2                	ld	s3,40(sp)
    80005708:	7a02                	ld	s4,32(sp)
    8000570a:	6ae2                	ld	s5,24(sp)
    8000570c:	6161                	addi	sp,sp,80
    8000570e:	8082                	ret
    iunlockput(ip);
    80005710:	8526                	mv	a0,s1
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	824080e7          	jalr	-2012(ra) # 80003f36 <iunlockput>
    return 0;
    8000571a:	4481                	li	s1,0
    8000571c:	b7c5                	j	800056fc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000571e:	85ce                	mv	a1,s3
    80005720:	00092503          	lw	a0,0(s2)
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	418080e7          	jalr	1048(ra) # 80003b3c <ialloc>
    8000572c:	84aa                	mv	s1,a0
    8000572e:	c529                	beqz	a0,80005778 <create+0xee>
  ilock(ip);
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	5a4080e7          	jalr	1444(ra) # 80003cd4 <ilock>
  ip->major = major;
    80005738:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000573c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005740:	4785                	li	a5,1
    80005742:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005746:	8526                	mv	a0,s1
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	4c2080e7          	jalr	1218(ra) # 80003c0a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005750:	2981                	sext.w	s3,s3
    80005752:	4785                	li	a5,1
    80005754:	02f98a63          	beq	s3,a5,80005788 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005758:	40d0                	lw	a2,4(s1)
    8000575a:	fb040593          	addi	a1,s0,-80
    8000575e:	854a                	mv	a0,s2
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	c62080e7          	jalr	-926(ra) # 800043c2 <dirlink>
    80005768:	06054b63          	bltz	a0,800057de <create+0x154>
  iunlockput(dp);
    8000576c:	854a                	mv	a0,s2
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	7c8080e7          	jalr	1992(ra) # 80003f36 <iunlockput>
  return ip;
    80005776:	b759                	j	800056fc <create+0x72>
    panic("create: ialloc");
    80005778:	00003517          	auipc	a0,0x3
    8000577c:	1f850513          	addi	a0,a0,504 # 80008970 <sysnames+0x2b8>
    80005780:	ffffb097          	auipc	ra,0xffffb
    80005784:	dc8080e7          	jalr	-568(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005788:	04a95783          	lhu	a5,74(s2)
    8000578c:	2785                	addiw	a5,a5,1
    8000578e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005792:	854a                	mv	a0,s2
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	476080e7          	jalr	1142(ra) # 80003c0a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000579c:	40d0                	lw	a2,4(s1)
    8000579e:	00003597          	auipc	a1,0x3
    800057a2:	1e258593          	addi	a1,a1,482 # 80008980 <sysnames+0x2c8>
    800057a6:	8526                	mv	a0,s1
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	c1a080e7          	jalr	-998(ra) # 800043c2 <dirlink>
    800057b0:	00054f63          	bltz	a0,800057ce <create+0x144>
    800057b4:	00492603          	lw	a2,4(s2)
    800057b8:	00003597          	auipc	a1,0x3
    800057bc:	ad858593          	addi	a1,a1,-1320 # 80008290 <digits+0x250>
    800057c0:	8526                	mv	a0,s1
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	c00080e7          	jalr	-1024(ra) # 800043c2 <dirlink>
    800057ca:	f80557e3          	bgez	a0,80005758 <create+0xce>
      panic("create dots");
    800057ce:	00003517          	auipc	a0,0x3
    800057d2:	1ba50513          	addi	a0,a0,442 # 80008988 <sysnames+0x2d0>
    800057d6:	ffffb097          	auipc	ra,0xffffb
    800057da:	d72080e7          	jalr	-654(ra) # 80000548 <panic>
    panic("create: dirlink");
    800057de:	00003517          	auipc	a0,0x3
    800057e2:	1ba50513          	addi	a0,a0,442 # 80008998 <sysnames+0x2e0>
    800057e6:	ffffb097          	auipc	ra,0xffffb
    800057ea:	d62080e7          	jalr	-670(ra) # 80000548 <panic>
    return 0;
    800057ee:	84aa                	mv	s1,a0
    800057f0:	b731                	j	800056fc <create+0x72>

00000000800057f2 <sys_dup>:
{
    800057f2:	7179                	addi	sp,sp,-48
    800057f4:	f406                	sd	ra,40(sp)
    800057f6:	f022                	sd	s0,32(sp)
    800057f8:	ec26                	sd	s1,24(sp)
    800057fa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057fc:	fd840613          	addi	a2,s0,-40
    80005800:	4581                	li	a1,0
    80005802:	4501                	li	a0,0
    80005804:	00000097          	auipc	ra,0x0
    80005808:	ddc080e7          	jalr	-548(ra) # 800055e0 <argfd>
    return -1;
    8000580c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000580e:	02054363          	bltz	a0,80005834 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005812:	fd843503          	ld	a0,-40(s0)
    80005816:	00000097          	auipc	ra,0x0
    8000581a:	e32080e7          	jalr	-462(ra) # 80005648 <fdalloc>
    8000581e:	84aa                	mv	s1,a0
    return -1;
    80005820:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005822:	00054963          	bltz	a0,80005834 <sys_dup+0x42>
  filedup(f);
    80005826:	fd843503          	ld	a0,-40(s0)
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	2e6080e7          	jalr	742(ra) # 80004b10 <filedup>
  return fd;
    80005832:	87a6                	mv	a5,s1
}
    80005834:	853e                	mv	a0,a5
    80005836:	70a2                	ld	ra,40(sp)
    80005838:	7402                	ld	s0,32(sp)
    8000583a:	64e2                	ld	s1,24(sp)
    8000583c:	6145                	addi	sp,sp,48
    8000583e:	8082                	ret

0000000080005840 <sys_read>:
{
    80005840:	7179                	addi	sp,sp,-48
    80005842:	f406                	sd	ra,40(sp)
    80005844:	f022                	sd	s0,32(sp)
    80005846:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005848:	fe840613          	addi	a2,s0,-24
    8000584c:	4581                	li	a1,0
    8000584e:	4501                	li	a0,0
    80005850:	00000097          	auipc	ra,0x0
    80005854:	d90080e7          	jalr	-624(ra) # 800055e0 <argfd>
    return -1;
    80005858:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000585a:	04054163          	bltz	a0,8000589c <sys_read+0x5c>
    8000585e:	fe440593          	addi	a1,s0,-28
    80005862:	4509                	li	a0,2
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	822080e7          	jalr	-2014(ra) # 80003086 <argint>
    return -1;
    8000586c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000586e:	02054763          	bltz	a0,8000589c <sys_read+0x5c>
    80005872:	fd840593          	addi	a1,s0,-40
    80005876:	4505                	li	a0,1
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	830080e7          	jalr	-2000(ra) # 800030a8 <argaddr>
    return -1;
    80005880:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005882:	00054d63          	bltz	a0,8000589c <sys_read+0x5c>
  return fileread(f, p, n);
    80005886:	fe442603          	lw	a2,-28(s0)
    8000588a:	fd843583          	ld	a1,-40(s0)
    8000588e:	fe843503          	ld	a0,-24(s0)
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	40a080e7          	jalr	1034(ra) # 80004c9c <fileread>
    8000589a:	87aa                	mv	a5,a0
}
    8000589c:	853e                	mv	a0,a5
    8000589e:	70a2                	ld	ra,40(sp)
    800058a0:	7402                	ld	s0,32(sp)
    800058a2:	6145                	addi	sp,sp,48
    800058a4:	8082                	ret

00000000800058a6 <sys_write>:
{
    800058a6:	7179                	addi	sp,sp,-48
    800058a8:	f406                	sd	ra,40(sp)
    800058aa:	f022                	sd	s0,32(sp)
    800058ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058ae:	fe840613          	addi	a2,s0,-24
    800058b2:	4581                	li	a1,0
    800058b4:	4501                	li	a0,0
    800058b6:	00000097          	auipc	ra,0x0
    800058ba:	d2a080e7          	jalr	-726(ra) # 800055e0 <argfd>
    return -1;
    800058be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058c0:	04054163          	bltz	a0,80005902 <sys_write+0x5c>
    800058c4:	fe440593          	addi	a1,s0,-28
    800058c8:	4509                	li	a0,2
    800058ca:	ffffd097          	auipc	ra,0xffffd
    800058ce:	7bc080e7          	jalr	1980(ra) # 80003086 <argint>
    return -1;
    800058d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058d4:	02054763          	bltz	a0,80005902 <sys_write+0x5c>
    800058d8:	fd840593          	addi	a1,s0,-40
    800058dc:	4505                	li	a0,1
    800058de:	ffffd097          	auipc	ra,0xffffd
    800058e2:	7ca080e7          	jalr	1994(ra) # 800030a8 <argaddr>
    return -1;
    800058e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058e8:	00054d63          	bltz	a0,80005902 <sys_write+0x5c>
  return filewrite(f, p, n);
    800058ec:	fe442603          	lw	a2,-28(s0)
    800058f0:	fd843583          	ld	a1,-40(s0)
    800058f4:	fe843503          	ld	a0,-24(s0)
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	466080e7          	jalr	1126(ra) # 80004d5e <filewrite>
    80005900:	87aa                	mv	a5,a0
}
    80005902:	853e                	mv	a0,a5
    80005904:	70a2                	ld	ra,40(sp)
    80005906:	7402                	ld	s0,32(sp)
    80005908:	6145                	addi	sp,sp,48
    8000590a:	8082                	ret

000000008000590c <sys_close>:
{
    8000590c:	1101                	addi	sp,sp,-32
    8000590e:	ec06                	sd	ra,24(sp)
    80005910:	e822                	sd	s0,16(sp)
    80005912:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005914:	fe040613          	addi	a2,s0,-32
    80005918:	fec40593          	addi	a1,s0,-20
    8000591c:	4501                	li	a0,0
    8000591e:	00000097          	auipc	ra,0x0
    80005922:	cc2080e7          	jalr	-830(ra) # 800055e0 <argfd>
    return -1;
    80005926:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005928:	02054463          	bltz	a0,80005950 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000592c:	ffffc097          	auipc	ra,0xffffc
    80005930:	4c0080e7          	jalr	1216(ra) # 80001dec <myproc>
    80005934:	fec42783          	lw	a5,-20(s0)
    80005938:	07e9                	addi	a5,a5,26
    8000593a:	078e                	slli	a5,a5,0x3
    8000593c:	97aa                	add	a5,a5,a0
    8000593e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005942:	fe043503          	ld	a0,-32(s0)
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	21c080e7          	jalr	540(ra) # 80004b62 <fileclose>
  return 0;
    8000594e:	4781                	li	a5,0
}
    80005950:	853e                	mv	a0,a5
    80005952:	60e2                	ld	ra,24(sp)
    80005954:	6442                	ld	s0,16(sp)
    80005956:	6105                	addi	sp,sp,32
    80005958:	8082                	ret

000000008000595a <sys_fstat>:
{
    8000595a:	1101                	addi	sp,sp,-32
    8000595c:	ec06                	sd	ra,24(sp)
    8000595e:	e822                	sd	s0,16(sp)
    80005960:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005962:	fe840613          	addi	a2,s0,-24
    80005966:	4581                	li	a1,0
    80005968:	4501                	li	a0,0
    8000596a:	00000097          	auipc	ra,0x0
    8000596e:	c76080e7          	jalr	-906(ra) # 800055e0 <argfd>
    return -1;
    80005972:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005974:	02054563          	bltz	a0,8000599e <sys_fstat+0x44>
    80005978:	fe040593          	addi	a1,s0,-32
    8000597c:	4505                	li	a0,1
    8000597e:	ffffd097          	auipc	ra,0xffffd
    80005982:	72a080e7          	jalr	1834(ra) # 800030a8 <argaddr>
    return -1;
    80005986:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005988:	00054b63          	bltz	a0,8000599e <sys_fstat+0x44>
  return filestat(f, st);
    8000598c:	fe043583          	ld	a1,-32(s0)
    80005990:	fe843503          	ld	a0,-24(s0)
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	296080e7          	jalr	662(ra) # 80004c2a <filestat>
    8000599c:	87aa                	mv	a5,a0
}
    8000599e:	853e                	mv	a0,a5
    800059a0:	60e2                	ld	ra,24(sp)
    800059a2:	6442                	ld	s0,16(sp)
    800059a4:	6105                	addi	sp,sp,32
    800059a6:	8082                	ret

00000000800059a8 <sys_link>:
{
    800059a8:	7169                	addi	sp,sp,-304
    800059aa:	f606                	sd	ra,296(sp)
    800059ac:	f222                	sd	s0,288(sp)
    800059ae:	ee26                	sd	s1,280(sp)
    800059b0:	ea4a                	sd	s2,272(sp)
    800059b2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059b4:	08000613          	li	a2,128
    800059b8:	ed040593          	addi	a1,s0,-304
    800059bc:	4501                	li	a0,0
    800059be:	ffffd097          	auipc	ra,0xffffd
    800059c2:	70c080e7          	jalr	1804(ra) # 800030ca <argstr>
    return -1;
    800059c6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059c8:	10054e63          	bltz	a0,80005ae4 <sys_link+0x13c>
    800059cc:	08000613          	li	a2,128
    800059d0:	f5040593          	addi	a1,s0,-176
    800059d4:	4505                	li	a0,1
    800059d6:	ffffd097          	auipc	ra,0xffffd
    800059da:	6f4080e7          	jalr	1780(ra) # 800030ca <argstr>
    return -1;
    800059de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059e0:	10054263          	bltz	a0,80005ae4 <sys_link+0x13c>
  begin_op();
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	cac080e7          	jalr	-852(ra) # 80004690 <begin_op>
  if((ip = namei(old)) == 0){
    800059ec:	ed040513          	addi	a0,s0,-304
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	a94080e7          	jalr	-1388(ra) # 80004484 <namei>
    800059f8:	84aa                	mv	s1,a0
    800059fa:	c551                	beqz	a0,80005a86 <sys_link+0xde>
  ilock(ip);
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	2d8080e7          	jalr	728(ra) # 80003cd4 <ilock>
  if(ip->type == T_DIR){
    80005a04:	04449703          	lh	a4,68(s1)
    80005a08:	4785                	li	a5,1
    80005a0a:	08f70463          	beq	a4,a5,80005a92 <sys_link+0xea>
  ip->nlink++;
    80005a0e:	04a4d783          	lhu	a5,74(s1)
    80005a12:	2785                	addiw	a5,a5,1
    80005a14:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a18:	8526                	mv	a0,s1
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	1f0080e7          	jalr	496(ra) # 80003c0a <iupdate>
  iunlock(ip);
    80005a22:	8526                	mv	a0,s1
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	372080e7          	jalr	882(ra) # 80003d96 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a2c:	fd040593          	addi	a1,s0,-48
    80005a30:	f5040513          	addi	a0,s0,-176
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	a6e080e7          	jalr	-1426(ra) # 800044a2 <nameiparent>
    80005a3c:	892a                	mv	s2,a0
    80005a3e:	c935                	beqz	a0,80005ab2 <sys_link+0x10a>
  ilock(dp);
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	294080e7          	jalr	660(ra) # 80003cd4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a48:	00092703          	lw	a4,0(s2)
    80005a4c:	409c                	lw	a5,0(s1)
    80005a4e:	04f71d63          	bne	a4,a5,80005aa8 <sys_link+0x100>
    80005a52:	40d0                	lw	a2,4(s1)
    80005a54:	fd040593          	addi	a1,s0,-48
    80005a58:	854a                	mv	a0,s2
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	968080e7          	jalr	-1688(ra) # 800043c2 <dirlink>
    80005a62:	04054363          	bltz	a0,80005aa8 <sys_link+0x100>
  iunlockput(dp);
    80005a66:	854a                	mv	a0,s2
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	4ce080e7          	jalr	1230(ra) # 80003f36 <iunlockput>
  iput(ip);
    80005a70:	8526                	mv	a0,s1
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	41c080e7          	jalr	1052(ra) # 80003e8e <iput>
  end_op();
    80005a7a:	fffff097          	auipc	ra,0xfffff
    80005a7e:	c96080e7          	jalr	-874(ra) # 80004710 <end_op>
  return 0;
    80005a82:	4781                	li	a5,0
    80005a84:	a085                	j	80005ae4 <sys_link+0x13c>
    end_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	c8a080e7          	jalr	-886(ra) # 80004710 <end_op>
    return -1;
    80005a8e:	57fd                	li	a5,-1
    80005a90:	a891                	j	80005ae4 <sys_link+0x13c>
    iunlockput(ip);
    80005a92:	8526                	mv	a0,s1
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	4a2080e7          	jalr	1186(ra) # 80003f36 <iunlockput>
    end_op();
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	c74080e7          	jalr	-908(ra) # 80004710 <end_op>
    return -1;
    80005aa4:	57fd                	li	a5,-1
    80005aa6:	a83d                	j	80005ae4 <sys_link+0x13c>
    iunlockput(dp);
    80005aa8:	854a                	mv	a0,s2
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	48c080e7          	jalr	1164(ra) # 80003f36 <iunlockput>
  ilock(ip);
    80005ab2:	8526                	mv	a0,s1
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	220080e7          	jalr	544(ra) # 80003cd4 <ilock>
  ip->nlink--;
    80005abc:	04a4d783          	lhu	a5,74(s1)
    80005ac0:	37fd                	addiw	a5,a5,-1
    80005ac2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	142080e7          	jalr	322(ra) # 80003c0a <iupdate>
  iunlockput(ip);
    80005ad0:	8526                	mv	a0,s1
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	464080e7          	jalr	1124(ra) # 80003f36 <iunlockput>
  end_op();
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	c36080e7          	jalr	-970(ra) # 80004710 <end_op>
  return -1;
    80005ae2:	57fd                	li	a5,-1
}
    80005ae4:	853e                	mv	a0,a5
    80005ae6:	70b2                	ld	ra,296(sp)
    80005ae8:	7412                	ld	s0,288(sp)
    80005aea:	64f2                	ld	s1,280(sp)
    80005aec:	6952                	ld	s2,272(sp)
    80005aee:	6155                	addi	sp,sp,304
    80005af0:	8082                	ret

0000000080005af2 <sys_unlink>:
{
    80005af2:	7151                	addi	sp,sp,-240
    80005af4:	f586                	sd	ra,232(sp)
    80005af6:	f1a2                	sd	s0,224(sp)
    80005af8:	eda6                	sd	s1,216(sp)
    80005afa:	e9ca                	sd	s2,208(sp)
    80005afc:	e5ce                	sd	s3,200(sp)
    80005afe:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b00:	08000613          	li	a2,128
    80005b04:	f3040593          	addi	a1,s0,-208
    80005b08:	4501                	li	a0,0
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	5c0080e7          	jalr	1472(ra) # 800030ca <argstr>
    80005b12:	18054163          	bltz	a0,80005c94 <sys_unlink+0x1a2>
  begin_op();
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	b7a080e7          	jalr	-1158(ra) # 80004690 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b1e:	fb040593          	addi	a1,s0,-80
    80005b22:	f3040513          	addi	a0,s0,-208
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	97c080e7          	jalr	-1668(ra) # 800044a2 <nameiparent>
    80005b2e:	84aa                	mv	s1,a0
    80005b30:	c979                	beqz	a0,80005c06 <sys_unlink+0x114>
  ilock(dp);
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	1a2080e7          	jalr	418(ra) # 80003cd4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b3a:	00003597          	auipc	a1,0x3
    80005b3e:	e4658593          	addi	a1,a1,-442 # 80008980 <sysnames+0x2c8>
    80005b42:	fb040513          	addi	a0,s0,-80
    80005b46:	ffffe097          	auipc	ra,0xffffe
    80005b4a:	652080e7          	jalr	1618(ra) # 80004198 <namecmp>
    80005b4e:	14050a63          	beqz	a0,80005ca2 <sys_unlink+0x1b0>
    80005b52:	00002597          	auipc	a1,0x2
    80005b56:	73e58593          	addi	a1,a1,1854 # 80008290 <digits+0x250>
    80005b5a:	fb040513          	addi	a0,s0,-80
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	63a080e7          	jalr	1594(ra) # 80004198 <namecmp>
    80005b66:	12050e63          	beqz	a0,80005ca2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b6a:	f2c40613          	addi	a2,s0,-212
    80005b6e:	fb040593          	addi	a1,s0,-80
    80005b72:	8526                	mv	a0,s1
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	63e080e7          	jalr	1598(ra) # 800041b2 <dirlookup>
    80005b7c:	892a                	mv	s2,a0
    80005b7e:	12050263          	beqz	a0,80005ca2 <sys_unlink+0x1b0>
  ilock(ip);
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	152080e7          	jalr	338(ra) # 80003cd4 <ilock>
  if(ip->nlink < 1)
    80005b8a:	04a91783          	lh	a5,74(s2)
    80005b8e:	08f05263          	blez	a5,80005c12 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b92:	04491703          	lh	a4,68(s2)
    80005b96:	4785                	li	a5,1
    80005b98:	08f70563          	beq	a4,a5,80005c22 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b9c:	4641                	li	a2,16
    80005b9e:	4581                	li	a1,0
    80005ba0:	fc040513          	addi	a0,s0,-64
    80005ba4:	ffffb097          	auipc	ra,0xffffb
    80005ba8:	1b2080e7          	jalr	434(ra) # 80000d56 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bac:	4741                	li	a4,16
    80005bae:	f2c42683          	lw	a3,-212(s0)
    80005bb2:	fc040613          	addi	a2,s0,-64
    80005bb6:	4581                	li	a1,0
    80005bb8:	8526                	mv	a0,s1
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	4c4080e7          	jalr	1220(ra) # 8000407e <writei>
    80005bc2:	47c1                	li	a5,16
    80005bc4:	0af51563          	bne	a0,a5,80005c6e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005bc8:	04491703          	lh	a4,68(s2)
    80005bcc:	4785                	li	a5,1
    80005bce:	0af70863          	beq	a4,a5,80005c7e <sys_unlink+0x18c>
  iunlockput(dp);
    80005bd2:	8526                	mv	a0,s1
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	362080e7          	jalr	866(ra) # 80003f36 <iunlockput>
  ip->nlink--;
    80005bdc:	04a95783          	lhu	a5,74(s2)
    80005be0:	37fd                	addiw	a5,a5,-1
    80005be2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005be6:	854a                	mv	a0,s2
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	022080e7          	jalr	34(ra) # 80003c0a <iupdate>
  iunlockput(ip);
    80005bf0:	854a                	mv	a0,s2
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	344080e7          	jalr	836(ra) # 80003f36 <iunlockput>
  end_op();
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	b16080e7          	jalr	-1258(ra) # 80004710 <end_op>
  return 0;
    80005c02:	4501                	li	a0,0
    80005c04:	a84d                	j	80005cb6 <sys_unlink+0x1c4>
    end_op();
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	b0a080e7          	jalr	-1270(ra) # 80004710 <end_op>
    return -1;
    80005c0e:	557d                	li	a0,-1
    80005c10:	a05d                	j	80005cb6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c12:	00003517          	auipc	a0,0x3
    80005c16:	d9650513          	addi	a0,a0,-618 # 800089a8 <sysnames+0x2f0>
    80005c1a:	ffffb097          	auipc	ra,0xffffb
    80005c1e:	92e080e7          	jalr	-1746(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c22:	04c92703          	lw	a4,76(s2)
    80005c26:	02000793          	li	a5,32
    80005c2a:	f6e7f9e3          	bgeu	a5,a4,80005b9c <sys_unlink+0xaa>
    80005c2e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c32:	4741                	li	a4,16
    80005c34:	86ce                	mv	a3,s3
    80005c36:	f1840613          	addi	a2,s0,-232
    80005c3a:	4581                	li	a1,0
    80005c3c:	854a                	mv	a0,s2
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	34a080e7          	jalr	842(ra) # 80003f88 <readi>
    80005c46:	47c1                	li	a5,16
    80005c48:	00f51b63          	bne	a0,a5,80005c5e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c4c:	f1845783          	lhu	a5,-232(s0)
    80005c50:	e7a1                	bnez	a5,80005c98 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c52:	29c1                	addiw	s3,s3,16
    80005c54:	04c92783          	lw	a5,76(s2)
    80005c58:	fcf9ede3          	bltu	s3,a5,80005c32 <sys_unlink+0x140>
    80005c5c:	b781                	j	80005b9c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c5e:	00003517          	auipc	a0,0x3
    80005c62:	d6250513          	addi	a0,a0,-670 # 800089c0 <sysnames+0x308>
    80005c66:	ffffb097          	auipc	ra,0xffffb
    80005c6a:	8e2080e7          	jalr	-1822(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005c6e:	00003517          	auipc	a0,0x3
    80005c72:	d6a50513          	addi	a0,a0,-662 # 800089d8 <sysnames+0x320>
    80005c76:	ffffb097          	auipc	ra,0xffffb
    80005c7a:	8d2080e7          	jalr	-1838(ra) # 80000548 <panic>
    dp->nlink--;
    80005c7e:	04a4d783          	lhu	a5,74(s1)
    80005c82:	37fd                	addiw	a5,a5,-1
    80005c84:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c88:	8526                	mv	a0,s1
    80005c8a:	ffffe097          	auipc	ra,0xffffe
    80005c8e:	f80080e7          	jalr	-128(ra) # 80003c0a <iupdate>
    80005c92:	b781                	j	80005bd2 <sys_unlink+0xe0>
    return -1;
    80005c94:	557d                	li	a0,-1
    80005c96:	a005                	j	80005cb6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c98:	854a                	mv	a0,s2
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	29c080e7          	jalr	668(ra) # 80003f36 <iunlockput>
  iunlockput(dp);
    80005ca2:	8526                	mv	a0,s1
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	292080e7          	jalr	658(ra) # 80003f36 <iunlockput>
  end_op();
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	a64080e7          	jalr	-1436(ra) # 80004710 <end_op>
  return -1;
    80005cb4:	557d                	li	a0,-1
}
    80005cb6:	70ae                	ld	ra,232(sp)
    80005cb8:	740e                	ld	s0,224(sp)
    80005cba:	64ee                	ld	s1,216(sp)
    80005cbc:	694e                	ld	s2,208(sp)
    80005cbe:	69ae                	ld	s3,200(sp)
    80005cc0:	616d                	addi	sp,sp,240
    80005cc2:	8082                	ret

0000000080005cc4 <sys_open>:

uint64
sys_open(void)
{
    80005cc4:	7131                	addi	sp,sp,-192
    80005cc6:	fd06                	sd	ra,184(sp)
    80005cc8:	f922                	sd	s0,176(sp)
    80005cca:	f526                	sd	s1,168(sp)
    80005ccc:	f14a                	sd	s2,160(sp)
    80005cce:	ed4e                	sd	s3,152(sp)
    80005cd0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005cd2:	08000613          	li	a2,128
    80005cd6:	f5040593          	addi	a1,s0,-176
    80005cda:	4501                	li	a0,0
    80005cdc:	ffffd097          	auipc	ra,0xffffd
    80005ce0:	3ee080e7          	jalr	1006(ra) # 800030ca <argstr>
    return -1;
    80005ce4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ce6:	0c054163          	bltz	a0,80005da8 <sys_open+0xe4>
    80005cea:	f4c40593          	addi	a1,s0,-180
    80005cee:	4505                	li	a0,1
    80005cf0:	ffffd097          	auipc	ra,0xffffd
    80005cf4:	396080e7          	jalr	918(ra) # 80003086 <argint>
    80005cf8:	0a054863          	bltz	a0,80005da8 <sys_open+0xe4>

  begin_op();
    80005cfc:	fffff097          	auipc	ra,0xfffff
    80005d00:	994080e7          	jalr	-1644(ra) # 80004690 <begin_op>

  if(omode & O_CREATE){
    80005d04:	f4c42783          	lw	a5,-180(s0)
    80005d08:	2007f793          	andi	a5,a5,512
    80005d0c:	cbdd                	beqz	a5,80005dc2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d0e:	4681                	li	a3,0
    80005d10:	4601                	li	a2,0
    80005d12:	4589                	li	a1,2
    80005d14:	f5040513          	addi	a0,s0,-176
    80005d18:	00000097          	auipc	ra,0x0
    80005d1c:	972080e7          	jalr	-1678(ra) # 8000568a <create>
    80005d20:	892a                	mv	s2,a0
    if(ip == 0){
    80005d22:	c959                	beqz	a0,80005db8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d24:	04491703          	lh	a4,68(s2)
    80005d28:	478d                	li	a5,3
    80005d2a:	00f71763          	bne	a4,a5,80005d38 <sys_open+0x74>
    80005d2e:	04695703          	lhu	a4,70(s2)
    80005d32:	47a5                	li	a5,9
    80005d34:	0ce7ec63          	bltu	a5,a4,80005e0c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	d6e080e7          	jalr	-658(ra) # 80004aa6 <filealloc>
    80005d40:	89aa                	mv	s3,a0
    80005d42:	10050263          	beqz	a0,80005e46 <sys_open+0x182>
    80005d46:	00000097          	auipc	ra,0x0
    80005d4a:	902080e7          	jalr	-1790(ra) # 80005648 <fdalloc>
    80005d4e:	84aa                	mv	s1,a0
    80005d50:	0e054663          	bltz	a0,80005e3c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d54:	04491703          	lh	a4,68(s2)
    80005d58:	478d                	li	a5,3
    80005d5a:	0cf70463          	beq	a4,a5,80005e22 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d5e:	4789                	li	a5,2
    80005d60:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d64:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d68:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d6c:	f4c42783          	lw	a5,-180(s0)
    80005d70:	0017c713          	xori	a4,a5,1
    80005d74:	8b05                	andi	a4,a4,1
    80005d76:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d7a:	0037f713          	andi	a4,a5,3
    80005d7e:	00e03733          	snez	a4,a4
    80005d82:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d86:	4007f793          	andi	a5,a5,1024
    80005d8a:	c791                	beqz	a5,80005d96 <sys_open+0xd2>
    80005d8c:	04491703          	lh	a4,68(s2)
    80005d90:	4789                	li	a5,2
    80005d92:	08f70f63          	beq	a4,a5,80005e30 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d96:	854a                	mv	a0,s2
    80005d98:	ffffe097          	auipc	ra,0xffffe
    80005d9c:	ffe080e7          	jalr	-2(ra) # 80003d96 <iunlock>
  end_op();
    80005da0:	fffff097          	auipc	ra,0xfffff
    80005da4:	970080e7          	jalr	-1680(ra) # 80004710 <end_op>

  return fd;
}
    80005da8:	8526                	mv	a0,s1
    80005daa:	70ea                	ld	ra,184(sp)
    80005dac:	744a                	ld	s0,176(sp)
    80005dae:	74aa                	ld	s1,168(sp)
    80005db0:	790a                	ld	s2,160(sp)
    80005db2:	69ea                	ld	s3,152(sp)
    80005db4:	6129                	addi	sp,sp,192
    80005db6:	8082                	ret
      end_op();
    80005db8:	fffff097          	auipc	ra,0xfffff
    80005dbc:	958080e7          	jalr	-1704(ra) # 80004710 <end_op>
      return -1;
    80005dc0:	b7e5                	j	80005da8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005dc2:	f5040513          	addi	a0,s0,-176
    80005dc6:	ffffe097          	auipc	ra,0xffffe
    80005dca:	6be080e7          	jalr	1726(ra) # 80004484 <namei>
    80005dce:	892a                	mv	s2,a0
    80005dd0:	c905                	beqz	a0,80005e00 <sys_open+0x13c>
    ilock(ip);
    80005dd2:	ffffe097          	auipc	ra,0xffffe
    80005dd6:	f02080e7          	jalr	-254(ra) # 80003cd4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005dda:	04491703          	lh	a4,68(s2)
    80005dde:	4785                	li	a5,1
    80005de0:	f4f712e3          	bne	a4,a5,80005d24 <sys_open+0x60>
    80005de4:	f4c42783          	lw	a5,-180(s0)
    80005de8:	dba1                	beqz	a5,80005d38 <sys_open+0x74>
      iunlockput(ip);
    80005dea:	854a                	mv	a0,s2
    80005dec:	ffffe097          	auipc	ra,0xffffe
    80005df0:	14a080e7          	jalr	330(ra) # 80003f36 <iunlockput>
      end_op();
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	91c080e7          	jalr	-1764(ra) # 80004710 <end_op>
      return -1;
    80005dfc:	54fd                	li	s1,-1
    80005dfe:	b76d                	j	80005da8 <sys_open+0xe4>
      end_op();
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	910080e7          	jalr	-1776(ra) # 80004710 <end_op>
      return -1;
    80005e08:	54fd                	li	s1,-1
    80005e0a:	bf79                	j	80005da8 <sys_open+0xe4>
    iunlockput(ip);
    80005e0c:	854a                	mv	a0,s2
    80005e0e:	ffffe097          	auipc	ra,0xffffe
    80005e12:	128080e7          	jalr	296(ra) # 80003f36 <iunlockput>
    end_op();
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	8fa080e7          	jalr	-1798(ra) # 80004710 <end_op>
    return -1;
    80005e1e:	54fd                	li	s1,-1
    80005e20:	b761                	j	80005da8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e22:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e26:	04691783          	lh	a5,70(s2)
    80005e2a:	02f99223          	sh	a5,36(s3)
    80005e2e:	bf2d                	j	80005d68 <sys_open+0xa4>
    itrunc(ip);
    80005e30:	854a                	mv	a0,s2
    80005e32:	ffffe097          	auipc	ra,0xffffe
    80005e36:	fb0080e7          	jalr	-80(ra) # 80003de2 <itrunc>
    80005e3a:	bfb1                	j	80005d96 <sys_open+0xd2>
      fileclose(f);
    80005e3c:	854e                	mv	a0,s3
    80005e3e:	fffff097          	auipc	ra,0xfffff
    80005e42:	d24080e7          	jalr	-732(ra) # 80004b62 <fileclose>
    iunlockput(ip);
    80005e46:	854a                	mv	a0,s2
    80005e48:	ffffe097          	auipc	ra,0xffffe
    80005e4c:	0ee080e7          	jalr	238(ra) # 80003f36 <iunlockput>
    end_op();
    80005e50:	fffff097          	auipc	ra,0xfffff
    80005e54:	8c0080e7          	jalr	-1856(ra) # 80004710 <end_op>
    return -1;
    80005e58:	54fd                	li	s1,-1
    80005e5a:	b7b9                	j	80005da8 <sys_open+0xe4>

0000000080005e5c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e5c:	7175                	addi	sp,sp,-144
    80005e5e:	e506                	sd	ra,136(sp)
    80005e60:	e122                	sd	s0,128(sp)
    80005e62:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	82c080e7          	jalr	-2004(ra) # 80004690 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e6c:	08000613          	li	a2,128
    80005e70:	f7040593          	addi	a1,s0,-144
    80005e74:	4501                	li	a0,0
    80005e76:	ffffd097          	auipc	ra,0xffffd
    80005e7a:	254080e7          	jalr	596(ra) # 800030ca <argstr>
    80005e7e:	02054963          	bltz	a0,80005eb0 <sys_mkdir+0x54>
    80005e82:	4681                	li	a3,0
    80005e84:	4601                	li	a2,0
    80005e86:	4585                	li	a1,1
    80005e88:	f7040513          	addi	a0,s0,-144
    80005e8c:	fffff097          	auipc	ra,0xfffff
    80005e90:	7fe080e7          	jalr	2046(ra) # 8000568a <create>
    80005e94:	cd11                	beqz	a0,80005eb0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e96:	ffffe097          	auipc	ra,0xffffe
    80005e9a:	0a0080e7          	jalr	160(ra) # 80003f36 <iunlockput>
  end_op();
    80005e9e:	fffff097          	auipc	ra,0xfffff
    80005ea2:	872080e7          	jalr	-1934(ra) # 80004710 <end_op>
  return 0;
    80005ea6:	4501                	li	a0,0
}
    80005ea8:	60aa                	ld	ra,136(sp)
    80005eaa:	640a                	ld	s0,128(sp)
    80005eac:	6149                	addi	sp,sp,144
    80005eae:	8082                	ret
    end_op();
    80005eb0:	fffff097          	auipc	ra,0xfffff
    80005eb4:	860080e7          	jalr	-1952(ra) # 80004710 <end_op>
    return -1;
    80005eb8:	557d                	li	a0,-1
    80005eba:	b7fd                	j	80005ea8 <sys_mkdir+0x4c>

0000000080005ebc <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ebc:	7135                	addi	sp,sp,-160
    80005ebe:	ed06                	sd	ra,152(sp)
    80005ec0:	e922                	sd	s0,144(sp)
    80005ec2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ec4:	ffffe097          	auipc	ra,0xffffe
    80005ec8:	7cc080e7          	jalr	1996(ra) # 80004690 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ecc:	08000613          	li	a2,128
    80005ed0:	f7040593          	addi	a1,s0,-144
    80005ed4:	4501                	li	a0,0
    80005ed6:	ffffd097          	auipc	ra,0xffffd
    80005eda:	1f4080e7          	jalr	500(ra) # 800030ca <argstr>
    80005ede:	04054a63          	bltz	a0,80005f32 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ee2:	f6c40593          	addi	a1,s0,-148
    80005ee6:	4505                	li	a0,1
    80005ee8:	ffffd097          	auipc	ra,0xffffd
    80005eec:	19e080e7          	jalr	414(ra) # 80003086 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ef0:	04054163          	bltz	a0,80005f32 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ef4:	f6840593          	addi	a1,s0,-152
    80005ef8:	4509                	li	a0,2
    80005efa:	ffffd097          	auipc	ra,0xffffd
    80005efe:	18c080e7          	jalr	396(ra) # 80003086 <argint>
     argint(1, &major) < 0 ||
    80005f02:	02054863          	bltz	a0,80005f32 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f06:	f6841683          	lh	a3,-152(s0)
    80005f0a:	f6c41603          	lh	a2,-148(s0)
    80005f0e:	458d                	li	a1,3
    80005f10:	f7040513          	addi	a0,s0,-144
    80005f14:	fffff097          	auipc	ra,0xfffff
    80005f18:	776080e7          	jalr	1910(ra) # 8000568a <create>
     argint(2, &minor) < 0 ||
    80005f1c:	c919                	beqz	a0,80005f32 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f1e:	ffffe097          	auipc	ra,0xffffe
    80005f22:	018080e7          	jalr	24(ra) # 80003f36 <iunlockput>
  end_op();
    80005f26:	ffffe097          	auipc	ra,0xffffe
    80005f2a:	7ea080e7          	jalr	2026(ra) # 80004710 <end_op>
  return 0;
    80005f2e:	4501                	li	a0,0
    80005f30:	a031                	j	80005f3c <sys_mknod+0x80>
    end_op();
    80005f32:	ffffe097          	auipc	ra,0xffffe
    80005f36:	7de080e7          	jalr	2014(ra) # 80004710 <end_op>
    return -1;
    80005f3a:	557d                	li	a0,-1
}
    80005f3c:	60ea                	ld	ra,152(sp)
    80005f3e:	644a                	ld	s0,144(sp)
    80005f40:	610d                	addi	sp,sp,160
    80005f42:	8082                	ret

0000000080005f44 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f44:	7135                	addi	sp,sp,-160
    80005f46:	ed06                	sd	ra,152(sp)
    80005f48:	e922                	sd	s0,144(sp)
    80005f4a:	e526                	sd	s1,136(sp)
    80005f4c:	e14a                	sd	s2,128(sp)
    80005f4e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f50:	ffffc097          	auipc	ra,0xffffc
    80005f54:	e9c080e7          	jalr	-356(ra) # 80001dec <myproc>
    80005f58:	892a                	mv	s2,a0
  
  begin_op();
    80005f5a:	ffffe097          	auipc	ra,0xffffe
    80005f5e:	736080e7          	jalr	1846(ra) # 80004690 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f62:	08000613          	li	a2,128
    80005f66:	f6040593          	addi	a1,s0,-160
    80005f6a:	4501                	li	a0,0
    80005f6c:	ffffd097          	auipc	ra,0xffffd
    80005f70:	15e080e7          	jalr	350(ra) # 800030ca <argstr>
    80005f74:	04054b63          	bltz	a0,80005fca <sys_chdir+0x86>
    80005f78:	f6040513          	addi	a0,s0,-160
    80005f7c:	ffffe097          	auipc	ra,0xffffe
    80005f80:	508080e7          	jalr	1288(ra) # 80004484 <namei>
    80005f84:	84aa                	mv	s1,a0
    80005f86:	c131                	beqz	a0,80005fca <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f88:	ffffe097          	auipc	ra,0xffffe
    80005f8c:	d4c080e7          	jalr	-692(ra) # 80003cd4 <ilock>
  if(ip->type != T_DIR){
    80005f90:	04449703          	lh	a4,68(s1)
    80005f94:	4785                	li	a5,1
    80005f96:	04f71063          	bne	a4,a5,80005fd6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f9a:	8526                	mv	a0,s1
    80005f9c:	ffffe097          	auipc	ra,0xffffe
    80005fa0:	dfa080e7          	jalr	-518(ra) # 80003d96 <iunlock>
  iput(p->cwd);
    80005fa4:	15093503          	ld	a0,336(s2)
    80005fa8:	ffffe097          	auipc	ra,0xffffe
    80005fac:	ee6080e7          	jalr	-282(ra) # 80003e8e <iput>
  end_op();
    80005fb0:	ffffe097          	auipc	ra,0xffffe
    80005fb4:	760080e7          	jalr	1888(ra) # 80004710 <end_op>
  p->cwd = ip;
    80005fb8:	14993823          	sd	s1,336(s2)
  return 0;
    80005fbc:	4501                	li	a0,0
}
    80005fbe:	60ea                	ld	ra,152(sp)
    80005fc0:	644a                	ld	s0,144(sp)
    80005fc2:	64aa                	ld	s1,136(sp)
    80005fc4:	690a                	ld	s2,128(sp)
    80005fc6:	610d                	addi	sp,sp,160
    80005fc8:	8082                	ret
    end_op();
    80005fca:	ffffe097          	auipc	ra,0xffffe
    80005fce:	746080e7          	jalr	1862(ra) # 80004710 <end_op>
    return -1;
    80005fd2:	557d                	li	a0,-1
    80005fd4:	b7ed                	j	80005fbe <sys_chdir+0x7a>
    iunlockput(ip);
    80005fd6:	8526                	mv	a0,s1
    80005fd8:	ffffe097          	auipc	ra,0xffffe
    80005fdc:	f5e080e7          	jalr	-162(ra) # 80003f36 <iunlockput>
    end_op();
    80005fe0:	ffffe097          	auipc	ra,0xffffe
    80005fe4:	730080e7          	jalr	1840(ra) # 80004710 <end_op>
    return -1;
    80005fe8:	557d                	li	a0,-1
    80005fea:	bfd1                	j	80005fbe <sys_chdir+0x7a>

0000000080005fec <sys_exec>:

uint64
sys_exec(void)
{
    80005fec:	7145                	addi	sp,sp,-464
    80005fee:	e786                	sd	ra,456(sp)
    80005ff0:	e3a2                	sd	s0,448(sp)
    80005ff2:	ff26                	sd	s1,440(sp)
    80005ff4:	fb4a                	sd	s2,432(sp)
    80005ff6:	f74e                	sd	s3,424(sp)
    80005ff8:	f352                	sd	s4,416(sp)
    80005ffa:	ef56                	sd	s5,408(sp)
    80005ffc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ffe:	08000613          	li	a2,128
    80006002:	f4040593          	addi	a1,s0,-192
    80006006:	4501                	li	a0,0
    80006008:	ffffd097          	auipc	ra,0xffffd
    8000600c:	0c2080e7          	jalr	194(ra) # 800030ca <argstr>
    return -1;
    80006010:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006012:	0c054a63          	bltz	a0,800060e6 <sys_exec+0xfa>
    80006016:	e3840593          	addi	a1,s0,-456
    8000601a:	4505                	li	a0,1
    8000601c:	ffffd097          	auipc	ra,0xffffd
    80006020:	08c080e7          	jalr	140(ra) # 800030a8 <argaddr>
    80006024:	0c054163          	bltz	a0,800060e6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006028:	10000613          	li	a2,256
    8000602c:	4581                	li	a1,0
    8000602e:	e4040513          	addi	a0,s0,-448
    80006032:	ffffb097          	auipc	ra,0xffffb
    80006036:	d24080e7          	jalr	-732(ra) # 80000d56 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000603a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000603e:	89a6                	mv	s3,s1
    80006040:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006042:	02000a13          	li	s4,32
    80006046:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000604a:	00391513          	slli	a0,s2,0x3
    8000604e:	e3040593          	addi	a1,s0,-464
    80006052:	e3843783          	ld	a5,-456(s0)
    80006056:	953e                	add	a0,a0,a5
    80006058:	ffffd097          	auipc	ra,0xffffd
    8000605c:	f94080e7          	jalr	-108(ra) # 80002fec <fetchaddr>
    80006060:	02054a63          	bltz	a0,80006094 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006064:	e3043783          	ld	a5,-464(s0)
    80006068:	c3b9                	beqz	a5,800060ae <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000606a:	ffffb097          	auipc	ra,0xffffb
    8000606e:	ab6080e7          	jalr	-1354(ra) # 80000b20 <kalloc>
    80006072:	85aa                	mv	a1,a0
    80006074:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006078:	cd11                	beqz	a0,80006094 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000607a:	6605                	lui	a2,0x1
    8000607c:	e3043503          	ld	a0,-464(s0)
    80006080:	ffffd097          	auipc	ra,0xffffd
    80006084:	fbe080e7          	jalr	-66(ra) # 8000303e <fetchstr>
    80006088:	00054663          	bltz	a0,80006094 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000608c:	0905                	addi	s2,s2,1
    8000608e:	09a1                	addi	s3,s3,8
    80006090:	fb491be3          	bne	s2,s4,80006046 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006094:	10048913          	addi	s2,s1,256
    80006098:	6088                	ld	a0,0(s1)
    8000609a:	c529                	beqz	a0,800060e4 <sys_exec+0xf8>
    kfree(argv[i]);
    8000609c:	ffffb097          	auipc	ra,0xffffb
    800060a0:	988080e7          	jalr	-1656(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060a4:	04a1                	addi	s1,s1,8
    800060a6:	ff2499e3          	bne	s1,s2,80006098 <sys_exec+0xac>
  return -1;
    800060aa:	597d                	li	s2,-1
    800060ac:	a82d                	j	800060e6 <sys_exec+0xfa>
      argv[i] = 0;
    800060ae:	0a8e                	slli	s5,s5,0x3
    800060b0:	fc040793          	addi	a5,s0,-64
    800060b4:	9abe                	add	s5,s5,a5
    800060b6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800060ba:	e4040593          	addi	a1,s0,-448
    800060be:	f4040513          	addi	a0,s0,-192
    800060c2:	fffff097          	auipc	ra,0xfffff
    800060c6:	150080e7          	jalr	336(ra) # 80005212 <exec>
    800060ca:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060cc:	10048993          	addi	s3,s1,256
    800060d0:	6088                	ld	a0,0(s1)
    800060d2:	c911                	beqz	a0,800060e6 <sys_exec+0xfa>
    kfree(argv[i]);
    800060d4:	ffffb097          	auipc	ra,0xffffb
    800060d8:	950080e7          	jalr	-1712(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060dc:	04a1                	addi	s1,s1,8
    800060de:	ff3499e3          	bne	s1,s3,800060d0 <sys_exec+0xe4>
    800060e2:	a011                	j	800060e6 <sys_exec+0xfa>
  return -1;
    800060e4:	597d                	li	s2,-1
}
    800060e6:	854a                	mv	a0,s2
    800060e8:	60be                	ld	ra,456(sp)
    800060ea:	641e                	ld	s0,448(sp)
    800060ec:	74fa                	ld	s1,440(sp)
    800060ee:	795a                	ld	s2,432(sp)
    800060f0:	79ba                	ld	s3,424(sp)
    800060f2:	7a1a                	ld	s4,416(sp)
    800060f4:	6afa                	ld	s5,408(sp)
    800060f6:	6179                	addi	sp,sp,464
    800060f8:	8082                	ret

00000000800060fa <sys_pipe>:

uint64
sys_pipe(void)
{
    800060fa:	7139                	addi	sp,sp,-64
    800060fc:	fc06                	sd	ra,56(sp)
    800060fe:	f822                	sd	s0,48(sp)
    80006100:	f426                	sd	s1,40(sp)
    80006102:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006104:	ffffc097          	auipc	ra,0xffffc
    80006108:	ce8080e7          	jalr	-792(ra) # 80001dec <myproc>
    8000610c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000610e:	fd840593          	addi	a1,s0,-40
    80006112:	4501                	li	a0,0
    80006114:	ffffd097          	auipc	ra,0xffffd
    80006118:	f94080e7          	jalr	-108(ra) # 800030a8 <argaddr>
    return -1;
    8000611c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000611e:	0e054063          	bltz	a0,800061fe <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006122:	fc840593          	addi	a1,s0,-56
    80006126:	fd040513          	addi	a0,s0,-48
    8000612a:	fffff097          	auipc	ra,0xfffff
    8000612e:	d8e080e7          	jalr	-626(ra) # 80004eb8 <pipealloc>
    return -1;
    80006132:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006134:	0c054563          	bltz	a0,800061fe <sys_pipe+0x104>
  fd0 = -1;
    80006138:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000613c:	fd043503          	ld	a0,-48(s0)
    80006140:	fffff097          	auipc	ra,0xfffff
    80006144:	508080e7          	jalr	1288(ra) # 80005648 <fdalloc>
    80006148:	fca42223          	sw	a0,-60(s0)
    8000614c:	08054c63          	bltz	a0,800061e4 <sys_pipe+0xea>
    80006150:	fc843503          	ld	a0,-56(s0)
    80006154:	fffff097          	auipc	ra,0xfffff
    80006158:	4f4080e7          	jalr	1268(ra) # 80005648 <fdalloc>
    8000615c:	fca42023          	sw	a0,-64(s0)
    80006160:	06054863          	bltz	a0,800061d0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006164:	4691                	li	a3,4
    80006166:	fc440613          	addi	a2,s0,-60
    8000616a:	fd843583          	ld	a1,-40(s0)
    8000616e:	68a8                	ld	a0,80(s1)
    80006170:	ffffb097          	auipc	ra,0xffffb
    80006174:	74e080e7          	jalr	1870(ra) # 800018be <copyout>
    80006178:	02054063          	bltz	a0,80006198 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000617c:	4691                	li	a3,4
    8000617e:	fc040613          	addi	a2,s0,-64
    80006182:	fd843583          	ld	a1,-40(s0)
    80006186:	0591                	addi	a1,a1,4
    80006188:	68a8                	ld	a0,80(s1)
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	734080e7          	jalr	1844(ra) # 800018be <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006192:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006194:	06055563          	bgez	a0,800061fe <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006198:	fc442783          	lw	a5,-60(s0)
    8000619c:	07e9                	addi	a5,a5,26
    8000619e:	078e                	slli	a5,a5,0x3
    800061a0:	97a6                	add	a5,a5,s1
    800061a2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800061a6:	fc042503          	lw	a0,-64(s0)
    800061aa:	0569                	addi	a0,a0,26
    800061ac:	050e                	slli	a0,a0,0x3
    800061ae:	9526                	add	a0,a0,s1
    800061b0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800061b4:	fd043503          	ld	a0,-48(s0)
    800061b8:	fffff097          	auipc	ra,0xfffff
    800061bc:	9aa080e7          	jalr	-1622(ra) # 80004b62 <fileclose>
    fileclose(wf);
    800061c0:	fc843503          	ld	a0,-56(s0)
    800061c4:	fffff097          	auipc	ra,0xfffff
    800061c8:	99e080e7          	jalr	-1634(ra) # 80004b62 <fileclose>
    return -1;
    800061cc:	57fd                	li	a5,-1
    800061ce:	a805                	j	800061fe <sys_pipe+0x104>
    if(fd0 >= 0)
    800061d0:	fc442783          	lw	a5,-60(s0)
    800061d4:	0007c863          	bltz	a5,800061e4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800061d8:	01a78513          	addi	a0,a5,26
    800061dc:	050e                	slli	a0,a0,0x3
    800061de:	9526                	add	a0,a0,s1
    800061e0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800061e4:	fd043503          	ld	a0,-48(s0)
    800061e8:	fffff097          	auipc	ra,0xfffff
    800061ec:	97a080e7          	jalr	-1670(ra) # 80004b62 <fileclose>
    fileclose(wf);
    800061f0:	fc843503          	ld	a0,-56(s0)
    800061f4:	fffff097          	auipc	ra,0xfffff
    800061f8:	96e080e7          	jalr	-1682(ra) # 80004b62 <fileclose>
    return -1;
    800061fc:	57fd                	li	a5,-1
}
    800061fe:	853e                	mv	a0,a5
    80006200:	70e2                	ld	ra,56(sp)
    80006202:	7442                	ld	s0,48(sp)
    80006204:	74a2                	ld	s1,40(sp)
    80006206:	6121                	addi	sp,sp,64
    80006208:	8082                	ret
    8000620a:	0000                	unimp
    8000620c:	0000                	unimp
	...

0000000080006210 <kernelvec>:
    80006210:	7111                	addi	sp,sp,-256
    80006212:	e006                	sd	ra,0(sp)
    80006214:	e40a                	sd	sp,8(sp)
    80006216:	e80e                	sd	gp,16(sp)
    80006218:	ec12                	sd	tp,24(sp)
    8000621a:	f016                	sd	t0,32(sp)
    8000621c:	f41a                	sd	t1,40(sp)
    8000621e:	f81e                	sd	t2,48(sp)
    80006220:	fc22                	sd	s0,56(sp)
    80006222:	e0a6                	sd	s1,64(sp)
    80006224:	e4aa                	sd	a0,72(sp)
    80006226:	e8ae                	sd	a1,80(sp)
    80006228:	ecb2                	sd	a2,88(sp)
    8000622a:	f0b6                	sd	a3,96(sp)
    8000622c:	f4ba                	sd	a4,104(sp)
    8000622e:	f8be                	sd	a5,112(sp)
    80006230:	fcc2                	sd	a6,120(sp)
    80006232:	e146                	sd	a7,128(sp)
    80006234:	e54a                	sd	s2,136(sp)
    80006236:	e94e                	sd	s3,144(sp)
    80006238:	ed52                	sd	s4,152(sp)
    8000623a:	f156                	sd	s5,160(sp)
    8000623c:	f55a                	sd	s6,168(sp)
    8000623e:	f95e                	sd	s7,176(sp)
    80006240:	fd62                	sd	s8,184(sp)
    80006242:	e1e6                	sd	s9,192(sp)
    80006244:	e5ea                	sd	s10,200(sp)
    80006246:	e9ee                	sd	s11,208(sp)
    80006248:	edf2                	sd	t3,216(sp)
    8000624a:	f1f6                	sd	t4,224(sp)
    8000624c:	f5fa                	sd	t5,232(sp)
    8000624e:	f9fe                	sd	t6,240(sp)
    80006250:	c69fc0ef          	jal	ra,80002eb8 <kerneltrap>
    80006254:	6082                	ld	ra,0(sp)
    80006256:	6122                	ld	sp,8(sp)
    80006258:	61c2                	ld	gp,16(sp)
    8000625a:	7282                	ld	t0,32(sp)
    8000625c:	7322                	ld	t1,40(sp)
    8000625e:	73c2                	ld	t2,48(sp)
    80006260:	7462                	ld	s0,56(sp)
    80006262:	6486                	ld	s1,64(sp)
    80006264:	6526                	ld	a0,72(sp)
    80006266:	65c6                	ld	a1,80(sp)
    80006268:	6666                	ld	a2,88(sp)
    8000626a:	7686                	ld	a3,96(sp)
    8000626c:	7726                	ld	a4,104(sp)
    8000626e:	77c6                	ld	a5,112(sp)
    80006270:	7866                	ld	a6,120(sp)
    80006272:	688a                	ld	a7,128(sp)
    80006274:	692a                	ld	s2,136(sp)
    80006276:	69ca                	ld	s3,144(sp)
    80006278:	6a6a                	ld	s4,152(sp)
    8000627a:	7a8a                	ld	s5,160(sp)
    8000627c:	7b2a                	ld	s6,168(sp)
    8000627e:	7bca                	ld	s7,176(sp)
    80006280:	7c6a                	ld	s8,184(sp)
    80006282:	6c8e                	ld	s9,192(sp)
    80006284:	6d2e                	ld	s10,200(sp)
    80006286:	6dce                	ld	s11,208(sp)
    80006288:	6e6e                	ld	t3,216(sp)
    8000628a:	7e8e                	ld	t4,224(sp)
    8000628c:	7f2e                	ld	t5,232(sp)
    8000628e:	7fce                	ld	t6,240(sp)
    80006290:	6111                	addi	sp,sp,256
    80006292:	10200073          	sret
    80006296:	00000013          	nop
    8000629a:	00000013          	nop
    8000629e:	0001                	nop

00000000800062a0 <timervec>:
    800062a0:	34051573          	csrrw	a0,mscratch,a0
    800062a4:	e10c                	sd	a1,0(a0)
    800062a6:	e510                	sd	a2,8(a0)
    800062a8:	e914                	sd	a3,16(a0)
    800062aa:	710c                	ld	a1,32(a0)
    800062ac:	7510                	ld	a2,40(a0)
    800062ae:	6194                	ld	a3,0(a1)
    800062b0:	96b2                	add	a3,a3,a2
    800062b2:	e194                	sd	a3,0(a1)
    800062b4:	4589                	li	a1,2
    800062b6:	14459073          	csrw	sip,a1
    800062ba:	6914                	ld	a3,16(a0)
    800062bc:	6510                	ld	a2,8(a0)
    800062be:	610c                	ld	a1,0(a0)
    800062c0:	34051573          	csrrw	a0,mscratch,a0
    800062c4:	30200073          	mret
	...

00000000800062ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062ca:	1141                	addi	sp,sp,-16
    800062cc:	e422                	sd	s0,8(sp)
    800062ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062d0:	0c0007b7          	lui	a5,0xc000
    800062d4:	4705                	li	a4,1
    800062d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062d8:	c3d8                	sw	a4,4(a5)
}
    800062da:	6422                	ld	s0,8(sp)
    800062dc:	0141                	addi	sp,sp,16
    800062de:	8082                	ret

00000000800062e0 <plicinithart>:

void
plicinithart(void)
{
    800062e0:	1141                	addi	sp,sp,-16
    800062e2:	e406                	sd	ra,8(sp)
    800062e4:	e022                	sd	s0,0(sp)
    800062e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062e8:	ffffc097          	auipc	ra,0xffffc
    800062ec:	ad8080e7          	jalr	-1320(ra) # 80001dc0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062f0:	0085171b          	slliw	a4,a0,0x8
    800062f4:	0c0027b7          	lui	a5,0xc002
    800062f8:	97ba                	add	a5,a5,a4
    800062fa:	40200713          	li	a4,1026
    800062fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006302:	00d5151b          	slliw	a0,a0,0xd
    80006306:	0c2017b7          	lui	a5,0xc201
    8000630a:	953e                	add	a0,a0,a5
    8000630c:	00052023          	sw	zero,0(a0)
}
    80006310:	60a2                	ld	ra,8(sp)
    80006312:	6402                	ld	s0,0(sp)
    80006314:	0141                	addi	sp,sp,16
    80006316:	8082                	ret

0000000080006318 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006318:	1141                	addi	sp,sp,-16
    8000631a:	e406                	sd	ra,8(sp)
    8000631c:	e022                	sd	s0,0(sp)
    8000631e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006320:	ffffc097          	auipc	ra,0xffffc
    80006324:	aa0080e7          	jalr	-1376(ra) # 80001dc0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006328:	00d5179b          	slliw	a5,a0,0xd
    8000632c:	0c201537          	lui	a0,0xc201
    80006330:	953e                	add	a0,a0,a5
  return irq;
}
    80006332:	4148                	lw	a0,4(a0)
    80006334:	60a2                	ld	ra,8(sp)
    80006336:	6402                	ld	s0,0(sp)
    80006338:	0141                	addi	sp,sp,16
    8000633a:	8082                	ret

000000008000633c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000633c:	1101                	addi	sp,sp,-32
    8000633e:	ec06                	sd	ra,24(sp)
    80006340:	e822                	sd	s0,16(sp)
    80006342:	e426                	sd	s1,8(sp)
    80006344:	1000                	addi	s0,sp,32
    80006346:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006348:	ffffc097          	auipc	ra,0xffffc
    8000634c:	a78080e7          	jalr	-1416(ra) # 80001dc0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006350:	00d5151b          	slliw	a0,a0,0xd
    80006354:	0c2017b7          	lui	a5,0xc201
    80006358:	97aa                	add	a5,a5,a0
    8000635a:	c3c4                	sw	s1,4(a5)
}
    8000635c:	60e2                	ld	ra,24(sp)
    8000635e:	6442                	ld	s0,16(sp)
    80006360:	64a2                	ld	s1,8(sp)
    80006362:	6105                	addi	sp,sp,32
    80006364:	8082                	ret

0000000080006366 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006366:	1141                	addi	sp,sp,-16
    80006368:	e406                	sd	ra,8(sp)
    8000636a:	e022                	sd	s0,0(sp)
    8000636c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000636e:	479d                	li	a5,7
    80006370:	04a7cc63          	blt	a5,a0,800063c8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80006374:	0001d797          	auipc	a5,0x1d
    80006378:	c8c78793          	addi	a5,a5,-884 # 80023000 <disk>
    8000637c:	00a78733          	add	a4,a5,a0
    80006380:	6789                	lui	a5,0x2
    80006382:	97ba                	add	a5,a5,a4
    80006384:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006388:	eba1                	bnez	a5,800063d8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    8000638a:	00451713          	slli	a4,a0,0x4
    8000638e:	0001f797          	auipc	a5,0x1f
    80006392:	c727b783          	ld	a5,-910(a5) # 80025000 <disk+0x2000>
    80006396:	97ba                	add	a5,a5,a4
    80006398:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000639c:	0001d797          	auipc	a5,0x1d
    800063a0:	c6478793          	addi	a5,a5,-924 # 80023000 <disk>
    800063a4:	97aa                	add	a5,a5,a0
    800063a6:	6509                	lui	a0,0x2
    800063a8:	953e                	add	a0,a0,a5
    800063aa:	4785                	li	a5,1
    800063ac:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800063b0:	0001f517          	auipc	a0,0x1f
    800063b4:	c6850513          	addi	a0,a0,-920 # 80025018 <disk+0x2018>
    800063b8:	ffffc097          	auipc	ra,0xffffc
    800063bc:	552080e7          	jalr	1362(ra) # 8000290a <wakeup>
}
    800063c0:	60a2                	ld	ra,8(sp)
    800063c2:	6402                	ld	s0,0(sp)
    800063c4:	0141                	addi	sp,sp,16
    800063c6:	8082                	ret
    panic("virtio_disk_intr 1");
    800063c8:	00002517          	auipc	a0,0x2
    800063cc:	62050513          	addi	a0,a0,1568 # 800089e8 <sysnames+0x330>
    800063d0:	ffffa097          	auipc	ra,0xffffa
    800063d4:	178080e7          	jalr	376(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    800063d8:	00002517          	auipc	a0,0x2
    800063dc:	62850513          	addi	a0,a0,1576 # 80008a00 <sysnames+0x348>
    800063e0:	ffffa097          	auipc	ra,0xffffa
    800063e4:	168080e7          	jalr	360(ra) # 80000548 <panic>

00000000800063e8 <virtio_disk_init>:
{
    800063e8:	1101                	addi	sp,sp,-32
    800063ea:	ec06                	sd	ra,24(sp)
    800063ec:	e822                	sd	s0,16(sp)
    800063ee:	e426                	sd	s1,8(sp)
    800063f0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063f2:	00002597          	auipc	a1,0x2
    800063f6:	62658593          	addi	a1,a1,1574 # 80008a18 <sysnames+0x360>
    800063fa:	0001f517          	auipc	a0,0x1f
    800063fe:	cae50513          	addi	a0,a0,-850 # 800250a8 <disk+0x20a8>
    80006402:	ffffa097          	auipc	ra,0xffffa
    80006406:	7c8080e7          	jalr	1992(ra) # 80000bca <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000640a:	100017b7          	lui	a5,0x10001
    8000640e:	4398                	lw	a4,0(a5)
    80006410:	2701                	sext.w	a4,a4
    80006412:	747277b7          	lui	a5,0x74727
    80006416:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000641a:	0ef71163          	bne	a4,a5,800064fc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000641e:	100017b7          	lui	a5,0x10001
    80006422:	43dc                	lw	a5,4(a5)
    80006424:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006426:	4705                	li	a4,1
    80006428:	0ce79a63          	bne	a5,a4,800064fc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000642c:	100017b7          	lui	a5,0x10001
    80006430:	479c                	lw	a5,8(a5)
    80006432:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006434:	4709                	li	a4,2
    80006436:	0ce79363          	bne	a5,a4,800064fc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000643a:	100017b7          	lui	a5,0x10001
    8000643e:	47d8                	lw	a4,12(a5)
    80006440:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006442:	554d47b7          	lui	a5,0x554d4
    80006446:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000644a:	0af71963          	bne	a4,a5,800064fc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000644e:	100017b7          	lui	a5,0x10001
    80006452:	4705                	li	a4,1
    80006454:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006456:	470d                	li	a4,3
    80006458:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000645a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000645c:	c7ffe737          	lui	a4,0xc7ffe
    80006460:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80006464:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006466:	2701                	sext.w	a4,a4
    80006468:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000646a:	472d                	li	a4,11
    8000646c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000646e:	473d                	li	a4,15
    80006470:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006472:	6705                	lui	a4,0x1
    80006474:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006476:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000647a:	5bdc                	lw	a5,52(a5)
    8000647c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000647e:	c7d9                	beqz	a5,8000650c <virtio_disk_init+0x124>
  if(max < NUM)
    80006480:	471d                	li	a4,7
    80006482:	08f77d63          	bgeu	a4,a5,8000651c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006486:	100014b7          	lui	s1,0x10001
    8000648a:	47a1                	li	a5,8
    8000648c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000648e:	6609                	lui	a2,0x2
    80006490:	4581                	li	a1,0
    80006492:	0001d517          	auipc	a0,0x1d
    80006496:	b6e50513          	addi	a0,a0,-1170 # 80023000 <disk>
    8000649a:	ffffb097          	auipc	ra,0xffffb
    8000649e:	8bc080e7          	jalr	-1860(ra) # 80000d56 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800064a2:	0001d717          	auipc	a4,0x1d
    800064a6:	b5e70713          	addi	a4,a4,-1186 # 80023000 <disk>
    800064aa:	00c75793          	srli	a5,a4,0xc
    800064ae:	2781                	sext.w	a5,a5
    800064b0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    800064b2:	0001f797          	auipc	a5,0x1f
    800064b6:	b4e78793          	addi	a5,a5,-1202 # 80025000 <disk+0x2000>
    800064ba:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    800064bc:	0001d717          	auipc	a4,0x1d
    800064c0:	bc470713          	addi	a4,a4,-1084 # 80023080 <disk+0x80>
    800064c4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800064c6:	0001e717          	auipc	a4,0x1e
    800064ca:	b3a70713          	addi	a4,a4,-1222 # 80024000 <disk+0x1000>
    800064ce:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800064d0:	4705                	li	a4,1
    800064d2:	00e78c23          	sb	a4,24(a5)
    800064d6:	00e78ca3          	sb	a4,25(a5)
    800064da:	00e78d23          	sb	a4,26(a5)
    800064de:	00e78da3          	sb	a4,27(a5)
    800064e2:	00e78e23          	sb	a4,28(a5)
    800064e6:	00e78ea3          	sb	a4,29(a5)
    800064ea:	00e78f23          	sb	a4,30(a5)
    800064ee:	00e78fa3          	sb	a4,31(a5)
}
    800064f2:	60e2                	ld	ra,24(sp)
    800064f4:	6442                	ld	s0,16(sp)
    800064f6:	64a2                	ld	s1,8(sp)
    800064f8:	6105                	addi	sp,sp,32
    800064fa:	8082                	ret
    panic("could not find virtio disk");
    800064fc:	00002517          	auipc	a0,0x2
    80006500:	52c50513          	addi	a0,a0,1324 # 80008a28 <sysnames+0x370>
    80006504:	ffffa097          	auipc	ra,0xffffa
    80006508:	044080e7          	jalr	68(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000650c:	00002517          	auipc	a0,0x2
    80006510:	53c50513          	addi	a0,a0,1340 # 80008a48 <sysnames+0x390>
    80006514:	ffffa097          	auipc	ra,0xffffa
    80006518:	034080e7          	jalr	52(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000651c:	00002517          	auipc	a0,0x2
    80006520:	54c50513          	addi	a0,a0,1356 # 80008a68 <sysnames+0x3b0>
    80006524:	ffffa097          	auipc	ra,0xffffa
    80006528:	024080e7          	jalr	36(ra) # 80000548 <panic>

000000008000652c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000652c:	7119                	addi	sp,sp,-128
    8000652e:	fc86                	sd	ra,120(sp)
    80006530:	f8a2                	sd	s0,112(sp)
    80006532:	f4a6                	sd	s1,104(sp)
    80006534:	f0ca                	sd	s2,96(sp)
    80006536:	ecce                	sd	s3,88(sp)
    80006538:	e8d2                	sd	s4,80(sp)
    8000653a:	e4d6                	sd	s5,72(sp)
    8000653c:	e0da                	sd	s6,64(sp)
    8000653e:	fc5e                	sd	s7,56(sp)
    80006540:	f862                	sd	s8,48(sp)
    80006542:	f466                	sd	s9,40(sp)
    80006544:	f06a                	sd	s10,32(sp)
    80006546:	0100                	addi	s0,sp,128
    80006548:	892a                	mv	s2,a0
    8000654a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000654c:	00c52c83          	lw	s9,12(a0)
    80006550:	001c9c9b          	slliw	s9,s9,0x1
    80006554:	1c82                	slli	s9,s9,0x20
    80006556:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000655a:	0001f517          	auipc	a0,0x1f
    8000655e:	b4e50513          	addi	a0,a0,-1202 # 800250a8 <disk+0x20a8>
    80006562:	ffffa097          	auipc	ra,0xffffa
    80006566:	6f8080e7          	jalr	1784(ra) # 80000c5a <acquire>
  for(int i = 0; i < 3; i++){
    8000656a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000656c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000656e:	0001db97          	auipc	s7,0x1d
    80006572:	a92b8b93          	addi	s7,s7,-1390 # 80023000 <disk>
    80006576:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006578:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000657a:	8a4e                	mv	s4,s3
    8000657c:	a051                	j	80006600 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000657e:	00fb86b3          	add	a3,s7,a5
    80006582:	96da                	add	a3,a3,s6
    80006584:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006588:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000658a:	0207c563          	bltz	a5,800065b4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000658e:	2485                	addiw	s1,s1,1
    80006590:	0711                	addi	a4,a4,4
    80006592:	23548d63          	beq	s1,s5,800067cc <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006596:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006598:	0001f697          	auipc	a3,0x1f
    8000659c:	a8068693          	addi	a3,a3,-1408 # 80025018 <disk+0x2018>
    800065a0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800065a2:	0006c583          	lbu	a1,0(a3)
    800065a6:	fde1                	bnez	a1,8000657e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800065a8:	2785                	addiw	a5,a5,1
    800065aa:	0685                	addi	a3,a3,1
    800065ac:	ff879be3          	bne	a5,s8,800065a2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800065b0:	57fd                	li	a5,-1
    800065b2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800065b4:	02905a63          	blez	s1,800065e8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065b8:	f9042503          	lw	a0,-112(s0)
    800065bc:	00000097          	auipc	ra,0x0
    800065c0:	daa080e7          	jalr	-598(ra) # 80006366 <free_desc>
      for(int j = 0; j < i; j++)
    800065c4:	4785                	li	a5,1
    800065c6:	0297d163          	bge	a5,s1,800065e8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065ca:	f9442503          	lw	a0,-108(s0)
    800065ce:	00000097          	auipc	ra,0x0
    800065d2:	d98080e7          	jalr	-616(ra) # 80006366 <free_desc>
      for(int j = 0; j < i; j++)
    800065d6:	4789                	li	a5,2
    800065d8:	0097d863          	bge	a5,s1,800065e8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065dc:	f9842503          	lw	a0,-104(s0)
    800065e0:	00000097          	auipc	ra,0x0
    800065e4:	d86080e7          	jalr	-634(ra) # 80006366 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065e8:	0001f597          	auipc	a1,0x1f
    800065ec:	ac058593          	addi	a1,a1,-1344 # 800250a8 <disk+0x20a8>
    800065f0:	0001f517          	auipc	a0,0x1f
    800065f4:	a2850513          	addi	a0,a0,-1496 # 80025018 <disk+0x2018>
    800065f8:	ffffc097          	auipc	ra,0xffffc
    800065fc:	18c080e7          	jalr	396(ra) # 80002784 <sleep>
  for(int i = 0; i < 3; i++){
    80006600:	f9040713          	addi	a4,s0,-112
    80006604:	84ce                	mv	s1,s3
    80006606:	bf41                	j	80006596 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006608:	4785                	li	a5,1
    8000660a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000660e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006612:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006616:	f9042983          	lw	s3,-112(s0)
    8000661a:	00499493          	slli	s1,s3,0x4
    8000661e:	0001fa17          	auipc	s4,0x1f
    80006622:	9e2a0a13          	addi	s4,s4,-1566 # 80025000 <disk+0x2000>
    80006626:	000a3a83          	ld	s5,0(s4)
    8000662a:	9aa6                	add	s5,s5,s1
    8000662c:	f8040513          	addi	a0,s0,-128
    80006630:	ffffb097          	auipc	ra,0xffffb
    80006634:	b1e080e7          	jalr	-1250(ra) # 8000114e <kvmpa>
    80006638:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000663c:	000a3783          	ld	a5,0(s4)
    80006640:	97a6                	add	a5,a5,s1
    80006642:	4741                	li	a4,16
    80006644:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006646:	000a3783          	ld	a5,0(s4)
    8000664a:	97a6                	add	a5,a5,s1
    8000664c:	4705                	li	a4,1
    8000664e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006652:	f9442703          	lw	a4,-108(s0)
    80006656:	000a3783          	ld	a5,0(s4)
    8000665a:	97a6                	add	a5,a5,s1
    8000665c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006660:	0712                	slli	a4,a4,0x4
    80006662:	000a3783          	ld	a5,0(s4)
    80006666:	97ba                	add	a5,a5,a4
    80006668:	05890693          	addi	a3,s2,88
    8000666c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000666e:	000a3783          	ld	a5,0(s4)
    80006672:	97ba                	add	a5,a5,a4
    80006674:	40000693          	li	a3,1024
    80006678:	c794                	sw	a3,8(a5)
  if(write)
    8000667a:	100d0a63          	beqz	s10,8000678e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000667e:	0001f797          	auipc	a5,0x1f
    80006682:	9827b783          	ld	a5,-1662(a5) # 80025000 <disk+0x2000>
    80006686:	97ba                	add	a5,a5,a4
    80006688:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000668c:	0001d517          	auipc	a0,0x1d
    80006690:	97450513          	addi	a0,a0,-1676 # 80023000 <disk>
    80006694:	0001f797          	auipc	a5,0x1f
    80006698:	96c78793          	addi	a5,a5,-1684 # 80025000 <disk+0x2000>
    8000669c:	6394                	ld	a3,0(a5)
    8000669e:	96ba                	add	a3,a3,a4
    800066a0:	00c6d603          	lhu	a2,12(a3)
    800066a4:	00166613          	ori	a2,a2,1
    800066a8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800066ac:	f9842683          	lw	a3,-104(s0)
    800066b0:	6390                	ld	a2,0(a5)
    800066b2:	9732                	add	a4,a4,a2
    800066b4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800066b8:	20098613          	addi	a2,s3,512
    800066bc:	0612                	slli	a2,a2,0x4
    800066be:	962a                	add	a2,a2,a0
    800066c0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066c4:	00469713          	slli	a4,a3,0x4
    800066c8:	6394                	ld	a3,0(a5)
    800066ca:	96ba                	add	a3,a3,a4
    800066cc:	6589                	lui	a1,0x2
    800066ce:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800066d2:	94ae                	add	s1,s1,a1
    800066d4:	94aa                	add	s1,s1,a0
    800066d6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800066d8:	6394                	ld	a3,0(a5)
    800066da:	96ba                	add	a3,a3,a4
    800066dc:	4585                	li	a1,1
    800066de:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066e0:	6394                	ld	a3,0(a5)
    800066e2:	96ba                	add	a3,a3,a4
    800066e4:	4509                	li	a0,2
    800066e6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800066ea:	6394                	ld	a3,0(a5)
    800066ec:	9736                	add	a4,a4,a3
    800066ee:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066f2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800066f6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800066fa:	6794                	ld	a3,8(a5)
    800066fc:	0026d703          	lhu	a4,2(a3)
    80006700:	8b1d                	andi	a4,a4,7
    80006702:	2709                	addiw	a4,a4,2
    80006704:	0706                	slli	a4,a4,0x1
    80006706:	9736                	add	a4,a4,a3
    80006708:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000670c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006710:	6798                	ld	a4,8(a5)
    80006712:	00275783          	lhu	a5,2(a4)
    80006716:	2785                	addiw	a5,a5,1
    80006718:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000671c:	100017b7          	lui	a5,0x10001
    80006720:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006724:	00492703          	lw	a4,4(s2)
    80006728:	4785                	li	a5,1
    8000672a:	02f71163          	bne	a4,a5,8000674c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000672e:	0001f997          	auipc	s3,0x1f
    80006732:	97a98993          	addi	s3,s3,-1670 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006736:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006738:	85ce                	mv	a1,s3
    8000673a:	854a                	mv	a0,s2
    8000673c:	ffffc097          	auipc	ra,0xffffc
    80006740:	048080e7          	jalr	72(ra) # 80002784 <sleep>
  while(b->disk == 1) {
    80006744:	00492783          	lw	a5,4(s2)
    80006748:	fe9788e3          	beq	a5,s1,80006738 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000674c:	f9042483          	lw	s1,-112(s0)
    80006750:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006754:	00479713          	slli	a4,a5,0x4
    80006758:	0001d797          	auipc	a5,0x1d
    8000675c:	8a878793          	addi	a5,a5,-1880 # 80023000 <disk>
    80006760:	97ba                	add	a5,a5,a4
    80006762:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006766:	0001f917          	auipc	s2,0x1f
    8000676a:	89a90913          	addi	s2,s2,-1894 # 80025000 <disk+0x2000>
    free_desc(i);
    8000676e:	8526                	mv	a0,s1
    80006770:	00000097          	auipc	ra,0x0
    80006774:	bf6080e7          	jalr	-1034(ra) # 80006366 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006778:	0492                	slli	s1,s1,0x4
    8000677a:	00093783          	ld	a5,0(s2)
    8000677e:	94be                	add	s1,s1,a5
    80006780:	00c4d783          	lhu	a5,12(s1)
    80006784:	8b85                	andi	a5,a5,1
    80006786:	cf89                	beqz	a5,800067a0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006788:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000678c:	b7cd                	j	8000676e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000678e:	0001f797          	auipc	a5,0x1f
    80006792:	8727b783          	ld	a5,-1934(a5) # 80025000 <disk+0x2000>
    80006796:	97ba                	add	a5,a5,a4
    80006798:	4689                	li	a3,2
    8000679a:	00d79623          	sh	a3,12(a5)
    8000679e:	b5fd                	j	8000668c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800067a0:	0001f517          	auipc	a0,0x1f
    800067a4:	90850513          	addi	a0,a0,-1784 # 800250a8 <disk+0x20a8>
    800067a8:	ffffa097          	auipc	ra,0xffffa
    800067ac:	566080e7          	jalr	1382(ra) # 80000d0e <release>
}
    800067b0:	70e6                	ld	ra,120(sp)
    800067b2:	7446                	ld	s0,112(sp)
    800067b4:	74a6                	ld	s1,104(sp)
    800067b6:	7906                	ld	s2,96(sp)
    800067b8:	69e6                	ld	s3,88(sp)
    800067ba:	6a46                	ld	s4,80(sp)
    800067bc:	6aa6                	ld	s5,72(sp)
    800067be:	6b06                	ld	s6,64(sp)
    800067c0:	7be2                	ld	s7,56(sp)
    800067c2:	7c42                	ld	s8,48(sp)
    800067c4:	7ca2                	ld	s9,40(sp)
    800067c6:	7d02                	ld	s10,32(sp)
    800067c8:	6109                	addi	sp,sp,128
    800067ca:	8082                	ret
  if(write)
    800067cc:	e20d1ee3          	bnez	s10,80006608 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800067d0:	f8042023          	sw	zero,-128(s0)
    800067d4:	bd2d                	j	8000660e <virtio_disk_rw+0xe2>

00000000800067d6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067d6:	1101                	addi	sp,sp,-32
    800067d8:	ec06                	sd	ra,24(sp)
    800067da:	e822                	sd	s0,16(sp)
    800067dc:	e426                	sd	s1,8(sp)
    800067de:	e04a                	sd	s2,0(sp)
    800067e0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067e2:	0001f517          	auipc	a0,0x1f
    800067e6:	8c650513          	addi	a0,a0,-1850 # 800250a8 <disk+0x20a8>
    800067ea:	ffffa097          	auipc	ra,0xffffa
    800067ee:	470080e7          	jalr	1136(ra) # 80000c5a <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800067f2:	0001f717          	auipc	a4,0x1f
    800067f6:	80e70713          	addi	a4,a4,-2034 # 80025000 <disk+0x2000>
    800067fa:	02075783          	lhu	a5,32(a4)
    800067fe:	6b18                	ld	a4,16(a4)
    80006800:	00275683          	lhu	a3,2(a4)
    80006804:	8ebd                	xor	a3,a3,a5
    80006806:	8a9d                	andi	a3,a3,7
    80006808:	cab9                	beqz	a3,8000685e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000680a:	0001c917          	auipc	s2,0x1c
    8000680e:	7f690913          	addi	s2,s2,2038 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006812:	0001e497          	auipc	s1,0x1e
    80006816:	7ee48493          	addi	s1,s1,2030 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000681a:	078e                	slli	a5,a5,0x3
    8000681c:	97ba                	add	a5,a5,a4
    8000681e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006820:	20078713          	addi	a4,a5,512
    80006824:	0712                	slli	a4,a4,0x4
    80006826:	974a                	add	a4,a4,s2
    80006828:	03074703          	lbu	a4,48(a4)
    8000682c:	ef21                	bnez	a4,80006884 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000682e:	20078793          	addi	a5,a5,512
    80006832:	0792                	slli	a5,a5,0x4
    80006834:	97ca                	add	a5,a5,s2
    80006836:	7798                	ld	a4,40(a5)
    80006838:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000683c:	7788                	ld	a0,40(a5)
    8000683e:	ffffc097          	auipc	ra,0xffffc
    80006842:	0cc080e7          	jalr	204(ra) # 8000290a <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006846:	0204d783          	lhu	a5,32(s1)
    8000684a:	2785                	addiw	a5,a5,1
    8000684c:	8b9d                	andi	a5,a5,7
    8000684e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006852:	6898                	ld	a4,16(s1)
    80006854:	00275683          	lhu	a3,2(a4)
    80006858:	8a9d                	andi	a3,a3,7
    8000685a:	fcf690e3          	bne	a3,a5,8000681a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000685e:	10001737          	lui	a4,0x10001
    80006862:	533c                	lw	a5,96(a4)
    80006864:	8b8d                	andi	a5,a5,3
    80006866:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006868:	0001f517          	auipc	a0,0x1f
    8000686c:	84050513          	addi	a0,a0,-1984 # 800250a8 <disk+0x20a8>
    80006870:	ffffa097          	auipc	ra,0xffffa
    80006874:	49e080e7          	jalr	1182(ra) # 80000d0e <release>
}
    80006878:	60e2                	ld	ra,24(sp)
    8000687a:	6442                	ld	s0,16(sp)
    8000687c:	64a2                	ld	s1,8(sp)
    8000687e:	6902                	ld	s2,0(sp)
    80006880:	6105                	addi	sp,sp,32
    80006882:	8082                	ret
      panic("virtio_disk_intr status");
    80006884:	00002517          	auipc	a0,0x2
    80006888:	20450513          	addi	a0,a0,516 # 80008a88 <sysnames+0x3d0>
    8000688c:	ffffa097          	auipc	ra,0xffffa
    80006890:	cbc080e7          	jalr	-836(ra) # 80000548 <panic>

0000000080006894 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    80006894:	7179                	addi	sp,sp,-48
    80006896:	f406                	sd	ra,40(sp)
    80006898:	f022                	sd	s0,32(sp)
    8000689a:	ec26                	sd	s1,24(sp)
    8000689c:	e84a                	sd	s2,16(sp)
    8000689e:	e44e                	sd	s3,8(sp)
    800068a0:	e052                	sd	s4,0(sp)
    800068a2:	1800                	addi	s0,sp,48
    800068a4:	892a                	mv	s2,a0
    800068a6:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    800068a8:	00002a17          	auipc	s4,0x2
    800068ac:	780a0a13          	addi	s4,s4,1920 # 80009028 <stats>
    800068b0:	000a2683          	lw	a3,0(s4)
    800068b4:	00002617          	auipc	a2,0x2
    800068b8:	1ec60613          	addi	a2,a2,492 # 80008aa0 <sysnames+0x3e8>
    800068bc:	00000097          	auipc	ra,0x0
    800068c0:	2c2080e7          	jalr	706(ra) # 80006b7e <snprintf>
    800068c4:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    800068c6:	004a2683          	lw	a3,4(s4)
    800068ca:	00002617          	auipc	a2,0x2
    800068ce:	1e660613          	addi	a2,a2,486 # 80008ab0 <sysnames+0x3f8>
    800068d2:	85ce                	mv	a1,s3
    800068d4:	954a                	add	a0,a0,s2
    800068d6:	00000097          	auipc	ra,0x0
    800068da:	2a8080e7          	jalr	680(ra) # 80006b7e <snprintf>
  return n;
}
    800068de:	9d25                	addw	a0,a0,s1
    800068e0:	70a2                	ld	ra,40(sp)
    800068e2:	7402                	ld	s0,32(sp)
    800068e4:	64e2                	ld	s1,24(sp)
    800068e6:	6942                	ld	s2,16(sp)
    800068e8:	69a2                	ld	s3,8(sp)
    800068ea:	6a02                	ld	s4,0(sp)
    800068ec:	6145                	addi	sp,sp,48
    800068ee:	8082                	ret

00000000800068f0 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800068f0:	7179                	addi	sp,sp,-48
    800068f2:	f406                	sd	ra,40(sp)
    800068f4:	f022                	sd	s0,32(sp)
    800068f6:	ec26                	sd	s1,24(sp)
    800068f8:	e84a                	sd	s2,16(sp)
    800068fa:	e44e                	sd	s3,8(sp)
    800068fc:	1800                	addi	s0,sp,48
    800068fe:	89ae                	mv	s3,a1
    80006900:	84b2                	mv	s1,a2
    80006902:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006904:	ffffb097          	auipc	ra,0xffffb
    80006908:	4e8080e7          	jalr	1256(ra) # 80001dec <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    8000690c:	653c                	ld	a5,72(a0)
    8000690e:	02f4ff63          	bgeu	s1,a5,8000694c <copyin_new+0x5c>
    80006912:	01248733          	add	a4,s1,s2
    80006916:	02f77d63          	bgeu	a4,a5,80006950 <copyin_new+0x60>
    8000691a:	02976d63          	bltu	a4,s1,80006954 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    8000691e:	0009061b          	sext.w	a2,s2
    80006922:	85a6                	mv	a1,s1
    80006924:	854e                	mv	a0,s3
    80006926:	ffffa097          	auipc	ra,0xffffa
    8000692a:	490080e7          	jalr	1168(ra) # 80000db6 <memmove>
  stats.ncopyin++;   // XXX lock
    8000692e:	00002717          	auipc	a4,0x2
    80006932:	6fa70713          	addi	a4,a4,1786 # 80009028 <stats>
    80006936:	431c                	lw	a5,0(a4)
    80006938:	2785                	addiw	a5,a5,1
    8000693a:	c31c                	sw	a5,0(a4)
  return 0;
    8000693c:	4501                	li	a0,0
}
    8000693e:	70a2                	ld	ra,40(sp)
    80006940:	7402                	ld	s0,32(sp)
    80006942:	64e2                	ld	s1,24(sp)
    80006944:	6942                	ld	s2,16(sp)
    80006946:	69a2                	ld	s3,8(sp)
    80006948:	6145                	addi	sp,sp,48
    8000694a:	8082                	ret
    return -1;
    8000694c:	557d                	li	a0,-1
    8000694e:	bfc5                	j	8000693e <copyin_new+0x4e>
    80006950:	557d                	li	a0,-1
    80006952:	b7f5                	j	8000693e <copyin_new+0x4e>
    80006954:	557d                	li	a0,-1
    80006956:	b7e5                	j	8000693e <copyin_new+0x4e>

0000000080006958 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006958:	7179                	addi	sp,sp,-48
    8000695a:	f406                	sd	ra,40(sp)
    8000695c:	f022                	sd	s0,32(sp)
    8000695e:	ec26                	sd	s1,24(sp)
    80006960:	e84a                	sd	s2,16(sp)
    80006962:	e44e                	sd	s3,8(sp)
    80006964:	1800                	addi	s0,sp,48
    80006966:	89ae                	mv	s3,a1
    80006968:	8932                	mv	s2,a2
    8000696a:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    8000696c:	ffffb097          	auipc	ra,0xffffb
    80006970:	480080e7          	jalr	1152(ra) # 80001dec <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006974:	00002717          	auipc	a4,0x2
    80006978:	6b470713          	addi	a4,a4,1716 # 80009028 <stats>
    8000697c:	435c                	lw	a5,4(a4)
    8000697e:	2785                	addiw	a5,a5,1
    80006980:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006982:	cc85                	beqz	s1,800069ba <copyinstr_new+0x62>
    80006984:	00990833          	add	a6,s2,s1
    80006988:	87ca                	mv	a5,s2
    8000698a:	6538                	ld	a4,72(a0)
    8000698c:	00e7ff63          	bgeu	a5,a4,800069aa <copyinstr_new+0x52>
    dst[i] = s[i];
    80006990:	0007c683          	lbu	a3,0(a5)
    80006994:	41278733          	sub	a4,a5,s2
    80006998:	974e                	add	a4,a4,s3
    8000699a:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    8000699e:	c285                	beqz	a3,800069be <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    800069a0:	0785                	addi	a5,a5,1
    800069a2:	ff0794e3          	bne	a5,a6,8000698a <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    800069a6:	557d                	li	a0,-1
    800069a8:	a011                	j	800069ac <copyinstr_new+0x54>
    800069aa:	557d                	li	a0,-1
}
    800069ac:	70a2                	ld	ra,40(sp)
    800069ae:	7402                	ld	s0,32(sp)
    800069b0:	64e2                	ld	s1,24(sp)
    800069b2:	6942                	ld	s2,16(sp)
    800069b4:	69a2                	ld	s3,8(sp)
    800069b6:	6145                	addi	sp,sp,48
    800069b8:	8082                	ret
  return -1;
    800069ba:	557d                	li	a0,-1
    800069bc:	bfc5                	j	800069ac <copyinstr_new+0x54>
      return 0;
    800069be:	4501                	li	a0,0
    800069c0:	b7f5                	j	800069ac <copyinstr_new+0x54>

00000000800069c2 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    800069c2:	1141                	addi	sp,sp,-16
    800069c4:	e422                	sd	s0,8(sp)
    800069c6:	0800                	addi	s0,sp,16
  return -1;
}
    800069c8:	557d                	li	a0,-1
    800069ca:	6422                	ld	s0,8(sp)
    800069cc:	0141                	addi	sp,sp,16
    800069ce:	8082                	ret

00000000800069d0 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800069d0:	7179                	addi	sp,sp,-48
    800069d2:	f406                	sd	ra,40(sp)
    800069d4:	f022                	sd	s0,32(sp)
    800069d6:	ec26                	sd	s1,24(sp)
    800069d8:	e84a                	sd	s2,16(sp)
    800069da:	e44e                	sd	s3,8(sp)
    800069dc:	e052                	sd	s4,0(sp)
    800069de:	1800                	addi	s0,sp,48
    800069e0:	892a                	mv	s2,a0
    800069e2:	89ae                	mv	s3,a1
    800069e4:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800069e6:	0001f517          	auipc	a0,0x1f
    800069ea:	61a50513          	addi	a0,a0,1562 # 80026000 <stats>
    800069ee:	ffffa097          	auipc	ra,0xffffa
    800069f2:	26c080e7          	jalr	620(ra) # 80000c5a <acquire>

  if(stats.sz == 0) {
    800069f6:	00020797          	auipc	a5,0x20
    800069fa:	6227a783          	lw	a5,1570(a5) # 80027018 <stats+0x1018>
    800069fe:	cbb5                	beqz	a5,80006a72 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006a00:	00020797          	auipc	a5,0x20
    80006a04:	60078793          	addi	a5,a5,1536 # 80027000 <stats+0x1000>
    80006a08:	4fd8                	lw	a4,28(a5)
    80006a0a:	4f9c                	lw	a5,24(a5)
    80006a0c:	9f99                	subw	a5,a5,a4
    80006a0e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006a12:	06d05e63          	blez	a3,80006a8e <statsread+0xbe>
    if(m > n)
    80006a16:	8a3e                	mv	s4,a5
    80006a18:	00d4d363          	bge	s1,a3,80006a1e <statsread+0x4e>
    80006a1c:	8a26                	mv	s4,s1
    80006a1e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006a22:	86a6                	mv	a3,s1
    80006a24:	0001f617          	auipc	a2,0x1f
    80006a28:	5f460613          	addi	a2,a2,1524 # 80026018 <stats+0x18>
    80006a2c:	963a                	add	a2,a2,a4
    80006a2e:	85ce                	mv	a1,s3
    80006a30:	854a                	mv	a0,s2
    80006a32:	ffffc097          	auipc	ra,0xffffc
    80006a36:	fb4080e7          	jalr	-76(ra) # 800029e6 <either_copyout>
    80006a3a:	57fd                	li	a5,-1
    80006a3c:	00f50a63          	beq	a0,a5,80006a50 <statsread+0x80>
      stats.off += m;
    80006a40:	00020717          	auipc	a4,0x20
    80006a44:	5c070713          	addi	a4,a4,1472 # 80027000 <stats+0x1000>
    80006a48:	4f5c                	lw	a5,28(a4)
    80006a4a:	014787bb          	addw	a5,a5,s4
    80006a4e:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006a50:	0001f517          	auipc	a0,0x1f
    80006a54:	5b050513          	addi	a0,a0,1456 # 80026000 <stats>
    80006a58:	ffffa097          	auipc	ra,0xffffa
    80006a5c:	2b6080e7          	jalr	694(ra) # 80000d0e <release>
  return m;
}
    80006a60:	8526                	mv	a0,s1
    80006a62:	70a2                	ld	ra,40(sp)
    80006a64:	7402                	ld	s0,32(sp)
    80006a66:	64e2                	ld	s1,24(sp)
    80006a68:	6942                	ld	s2,16(sp)
    80006a6a:	69a2                	ld	s3,8(sp)
    80006a6c:	6a02                	ld	s4,0(sp)
    80006a6e:	6145                	addi	sp,sp,48
    80006a70:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    80006a72:	6585                	lui	a1,0x1
    80006a74:	0001f517          	auipc	a0,0x1f
    80006a78:	5a450513          	addi	a0,a0,1444 # 80026018 <stats+0x18>
    80006a7c:	00000097          	auipc	ra,0x0
    80006a80:	e18080e7          	jalr	-488(ra) # 80006894 <statscopyin>
    80006a84:	00020797          	auipc	a5,0x20
    80006a88:	58a7aa23          	sw	a0,1428(a5) # 80027018 <stats+0x1018>
    80006a8c:	bf95                	j	80006a00 <statsread+0x30>
    stats.sz = 0;
    80006a8e:	00020797          	auipc	a5,0x20
    80006a92:	57278793          	addi	a5,a5,1394 # 80027000 <stats+0x1000>
    80006a96:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    80006a9a:	0007ae23          	sw	zero,28(a5)
    m = -1;
    80006a9e:	54fd                	li	s1,-1
    80006aa0:	bf45                	j	80006a50 <statsread+0x80>

0000000080006aa2 <statsinit>:

void
statsinit(void)
{
    80006aa2:	1141                	addi	sp,sp,-16
    80006aa4:	e406                	sd	ra,8(sp)
    80006aa6:	e022                	sd	s0,0(sp)
    80006aa8:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    80006aaa:	00002597          	auipc	a1,0x2
    80006aae:	01658593          	addi	a1,a1,22 # 80008ac0 <sysnames+0x408>
    80006ab2:	0001f517          	auipc	a0,0x1f
    80006ab6:	54e50513          	addi	a0,a0,1358 # 80026000 <stats>
    80006aba:	ffffa097          	auipc	ra,0xffffa
    80006abe:	110080e7          	jalr	272(ra) # 80000bca <initlock>

  devsw[STATS].read = statsread;
    80006ac2:	0001b797          	auipc	a5,0x1b
    80006ac6:	2ee78793          	addi	a5,a5,750 # 80021db0 <devsw>
    80006aca:	00000717          	auipc	a4,0x0
    80006ace:	f0670713          	addi	a4,a4,-250 # 800069d0 <statsread>
    80006ad2:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006ad4:	00000717          	auipc	a4,0x0
    80006ad8:	eee70713          	addi	a4,a4,-274 # 800069c2 <statswrite>
    80006adc:	f798                	sd	a4,40(a5)
}
    80006ade:	60a2                	ld	ra,8(sp)
    80006ae0:	6402                	ld	s0,0(sp)
    80006ae2:	0141                	addi	sp,sp,16
    80006ae4:	8082                	ret

0000000080006ae6 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006ae6:	1101                	addi	sp,sp,-32
    80006ae8:	ec22                	sd	s0,24(sp)
    80006aea:	1000                	addi	s0,sp,32
    80006aec:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    80006aee:	c299                	beqz	a3,80006af4 <sprintint+0xe>
    80006af0:	0805c163          	bltz	a1,80006b72 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006af4:	2581                	sext.w	a1,a1
    80006af6:	4301                	li	t1,0

  i = 0;
    80006af8:	fe040713          	addi	a4,s0,-32
    80006afc:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    80006afe:	2601                	sext.w	a2,a2
    80006b00:	00002697          	auipc	a3,0x2
    80006b04:	fc868693          	addi	a3,a3,-56 # 80008ac8 <digits>
    80006b08:	88aa                	mv	a7,a0
    80006b0a:	2505                	addiw	a0,a0,1
    80006b0c:	02c5f7bb          	remuw	a5,a1,a2
    80006b10:	1782                	slli	a5,a5,0x20
    80006b12:	9381                	srli	a5,a5,0x20
    80006b14:	97b6                	add	a5,a5,a3
    80006b16:	0007c783          	lbu	a5,0(a5)
    80006b1a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    80006b1e:	0005879b          	sext.w	a5,a1
    80006b22:	02c5d5bb          	divuw	a1,a1,a2
    80006b26:	0705                	addi	a4,a4,1
    80006b28:	fec7f0e3          	bgeu	a5,a2,80006b08 <sprintint+0x22>

  if(sign)
    80006b2c:	00030b63          	beqz	t1,80006b42 <sprintint+0x5c>
    buf[i++] = '-';
    80006b30:	ff040793          	addi	a5,s0,-16
    80006b34:	97aa                	add	a5,a5,a0
    80006b36:	02d00713          	li	a4,45
    80006b3a:	fee78823          	sb	a4,-16(a5)
    80006b3e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006b42:	02a05c63          	blez	a0,80006b7a <sprintint+0x94>
    80006b46:	fe040793          	addi	a5,s0,-32
    80006b4a:	00a78733          	add	a4,a5,a0
    80006b4e:	87c2                	mv	a5,a6
    80006b50:	0805                	addi	a6,a6,1
    80006b52:	fff5061b          	addiw	a2,a0,-1
    80006b56:	1602                	slli	a2,a2,0x20
    80006b58:	9201                	srli	a2,a2,0x20
    80006b5a:	9642                	add	a2,a2,a6
  *s = c;
    80006b5c:	fff74683          	lbu	a3,-1(a4)
    80006b60:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006b64:	177d                	addi	a4,a4,-1
    80006b66:	0785                	addi	a5,a5,1
    80006b68:	fec79ae3          	bne	a5,a2,80006b5c <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006b6c:	6462                	ld	s0,24(sp)
    80006b6e:	6105                	addi	sp,sp,32
    80006b70:	8082                	ret
    x = -xx;
    80006b72:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006b76:	4305                	li	t1,1
    x = -xx;
    80006b78:	b741                	j	80006af8 <sprintint+0x12>
  while(--i >= 0)
    80006b7a:	4501                	li	a0,0
    80006b7c:	bfc5                	j	80006b6c <sprintint+0x86>

0000000080006b7e <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006b7e:	7171                	addi	sp,sp,-176
    80006b80:	fc86                	sd	ra,120(sp)
    80006b82:	f8a2                	sd	s0,112(sp)
    80006b84:	f4a6                	sd	s1,104(sp)
    80006b86:	f0ca                	sd	s2,96(sp)
    80006b88:	ecce                	sd	s3,88(sp)
    80006b8a:	e8d2                	sd	s4,80(sp)
    80006b8c:	e4d6                	sd	s5,72(sp)
    80006b8e:	e0da                	sd	s6,64(sp)
    80006b90:	fc5e                	sd	s7,56(sp)
    80006b92:	f862                	sd	s8,48(sp)
    80006b94:	f466                	sd	s9,40(sp)
    80006b96:	f06a                	sd	s10,32(sp)
    80006b98:	ec6e                	sd	s11,24(sp)
    80006b9a:	0100                	addi	s0,sp,128
    80006b9c:	e414                	sd	a3,8(s0)
    80006b9e:	e818                	sd	a4,16(s0)
    80006ba0:	ec1c                	sd	a5,24(s0)
    80006ba2:	03043023          	sd	a6,32(s0)
    80006ba6:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    80006baa:	ca0d                	beqz	a2,80006bdc <snprintf+0x5e>
    80006bac:	8baa                	mv	s7,a0
    80006bae:	89ae                	mv	s3,a1
    80006bb0:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006bb2:	00840793          	addi	a5,s0,8
    80006bb6:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    80006bba:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006bbc:	4901                	li	s2,0
    80006bbe:	02b05763          	blez	a1,80006bec <snprintf+0x6e>
    if(c != '%'){
    80006bc2:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006bc6:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    80006bca:	02800d93          	li	s11,40
  *s = c;
    80006bce:	02500d13          	li	s10,37
    switch(c){
    80006bd2:	07800c93          	li	s9,120
    80006bd6:	06400c13          	li	s8,100
    80006bda:	a01d                	j	80006c00 <snprintf+0x82>
    panic("null fmt");
    80006bdc:	00001517          	auipc	a0,0x1
    80006be0:	44c50513          	addi	a0,a0,1100 # 80008028 <etext+0x28>
    80006be4:	ffffa097          	auipc	ra,0xffffa
    80006be8:	964080e7          	jalr	-1692(ra) # 80000548 <panic>
  int off = 0;
    80006bec:	4481                	li	s1,0
    80006bee:	a86d                	j	80006ca8 <snprintf+0x12a>
  *s = c;
    80006bf0:	009b8733          	add	a4,s7,s1
    80006bf4:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006bf8:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006bfa:	2905                	addiw	s2,s2,1
    80006bfc:	0b34d663          	bge	s1,s3,80006ca8 <snprintf+0x12a>
    80006c00:	012a07b3          	add	a5,s4,s2
    80006c04:	0007c783          	lbu	a5,0(a5)
    80006c08:	0007871b          	sext.w	a4,a5
    80006c0c:	cfd1                	beqz	a5,80006ca8 <snprintf+0x12a>
    if(c != '%'){
    80006c0e:	ff5711e3          	bne	a4,s5,80006bf0 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006c12:	2905                	addiw	s2,s2,1
    80006c14:	012a07b3          	add	a5,s4,s2
    80006c18:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    80006c1c:	c7d1                	beqz	a5,80006ca8 <snprintf+0x12a>
    switch(c){
    80006c1e:	05678c63          	beq	a5,s6,80006c76 <snprintf+0xf8>
    80006c22:	02fb6763          	bltu	s6,a5,80006c50 <snprintf+0xd2>
    80006c26:	0b578763          	beq	a5,s5,80006cd4 <snprintf+0x156>
    80006c2a:	0b879b63          	bne	a5,s8,80006ce0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    80006c2e:	f8843783          	ld	a5,-120(s0)
    80006c32:	00878713          	addi	a4,a5,8
    80006c36:	f8e43423          	sd	a4,-120(s0)
    80006c3a:	4685                	li	a3,1
    80006c3c:	4629                	li	a2,10
    80006c3e:	438c                	lw	a1,0(a5)
    80006c40:	009b8533          	add	a0,s7,s1
    80006c44:	00000097          	auipc	ra,0x0
    80006c48:	ea2080e7          	jalr	-350(ra) # 80006ae6 <sprintint>
    80006c4c:	9ca9                	addw	s1,s1,a0
      break;
    80006c4e:	b775                	j	80006bfa <snprintf+0x7c>
    switch(c){
    80006c50:	09979863          	bne	a5,s9,80006ce0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006c54:	f8843783          	ld	a5,-120(s0)
    80006c58:	00878713          	addi	a4,a5,8
    80006c5c:	f8e43423          	sd	a4,-120(s0)
    80006c60:	4685                	li	a3,1
    80006c62:	4641                	li	a2,16
    80006c64:	438c                	lw	a1,0(a5)
    80006c66:	009b8533          	add	a0,s7,s1
    80006c6a:	00000097          	auipc	ra,0x0
    80006c6e:	e7c080e7          	jalr	-388(ra) # 80006ae6 <sprintint>
    80006c72:	9ca9                	addw	s1,s1,a0
      break;
    80006c74:	b759                	j	80006bfa <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006c76:	f8843783          	ld	a5,-120(s0)
    80006c7a:	00878713          	addi	a4,a5,8
    80006c7e:	f8e43423          	sd	a4,-120(s0)
    80006c82:	639c                	ld	a5,0(a5)
    80006c84:	c3b1                	beqz	a5,80006cc8 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006c86:	0007c703          	lbu	a4,0(a5)
    80006c8a:	db25                	beqz	a4,80006bfa <snprintf+0x7c>
    80006c8c:	0134de63          	bge	s1,s3,80006ca8 <snprintf+0x12a>
    80006c90:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006c94:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006c98:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006c9a:	0785                	addi	a5,a5,1
    80006c9c:	0007c703          	lbu	a4,0(a5)
    80006ca0:	df29                	beqz	a4,80006bfa <snprintf+0x7c>
    80006ca2:	0685                	addi	a3,a3,1
    80006ca4:	fe9998e3          	bne	s3,s1,80006c94 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006ca8:	8526                	mv	a0,s1
    80006caa:	70e6                	ld	ra,120(sp)
    80006cac:	7446                	ld	s0,112(sp)
    80006cae:	74a6                	ld	s1,104(sp)
    80006cb0:	7906                	ld	s2,96(sp)
    80006cb2:	69e6                	ld	s3,88(sp)
    80006cb4:	6a46                	ld	s4,80(sp)
    80006cb6:	6aa6                	ld	s5,72(sp)
    80006cb8:	6b06                	ld	s6,64(sp)
    80006cba:	7be2                	ld	s7,56(sp)
    80006cbc:	7c42                	ld	s8,48(sp)
    80006cbe:	7ca2                	ld	s9,40(sp)
    80006cc0:	7d02                	ld	s10,32(sp)
    80006cc2:	6de2                	ld	s11,24(sp)
    80006cc4:	614d                	addi	sp,sp,176
    80006cc6:	8082                	ret
        s = "(null)";
    80006cc8:	00001797          	auipc	a5,0x1
    80006ccc:	35878793          	addi	a5,a5,856 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006cd0:	876e                	mv	a4,s11
    80006cd2:	bf6d                	j	80006c8c <snprintf+0x10e>
  *s = c;
    80006cd4:	009b87b3          	add	a5,s7,s1
    80006cd8:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006cdc:	2485                	addiw	s1,s1,1
      break;
    80006cde:	bf31                	j	80006bfa <snprintf+0x7c>
  *s = c;
    80006ce0:	009b8733          	add	a4,s7,s1
    80006ce4:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006ce8:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006cec:	975e                	add	a4,a4,s7
    80006cee:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006cf2:	2489                	addiw	s1,s1,2
      break;
    80006cf4:	b719                	j	80006bfa <snprintf+0x7c>
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
