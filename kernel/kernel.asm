
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b8013103          	ld	sp,-1152(sp) # 80008b80 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000060:	40478793          	addi	a5,a5,1028 # 80006460 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd67df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	ec078793          	addi	a5,a5,-320 # 80000f66 <main>
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
    80000110:	bac080e7          	jalr	-1108(ra) # 80000cb8 <acquire>
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
    8000012a:	9b4080e7          	jalr	-1612(ra) # 80002ada <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00001097          	auipc	ra,0x1
    8000013a:	808080e7          	jalr	-2040(ra) # 8000093e <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	c1e080e7          	jalr	-994(ra) # 80000d6c <release>

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
    800001a2:	b1a080e7          	jalr	-1254(ra) # 80000cb8 <acquire>
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
    800001d2:	c74080e7          	jalr	-908(ra) # 80001e42 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	644080e7          	jalr	1604(ra) # 80002822 <sleep>
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
    8000021a:	00003097          	auipc	ra,0x3
    8000021e:	86a080e7          	jalr	-1942(ra) # 80002a84 <either_copyout>
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
    8000023a:	b36080e7          	jalr	-1226(ra) # 80000d6c <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	b20080e7          	jalr	-1248(ra) # 80000d6c <release>
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
    8000029a:	5c2080e7          	jalr	1474(ra) # 80000858 <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	5b0080e7          	jalr	1456(ra) # 80000858 <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5a4080e7          	jalr	1444(ra) # 80000858 <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	59a080e7          	jalr	1434(ra) # 80000858 <uartputc_sync>
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
    800002e2:	9da080e7          	jalr	-1574(ra) # 80000cb8 <acquire>

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
    800002fc:	00003097          	auipc	ra,0x3
    80000300:	834080e7          	jalr	-1996(ra) # 80002b30 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a60080e7          	jalr	-1440(ra) # 80000d6c <release>
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
    80000454:	558080e7          	jalr	1368(ra) # 800029a8 <wakeup>
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
    80000476:	7b6080e7          	jalr	1974(ra) # 80000c28 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	38e080e7          	jalr	910(ra) # 80000808 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00022797          	auipc	a5,0x22
    80000486:	12e78793          	addi	a5,a5,302 # 800225b0 <devsw>
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
    800004c8:	b8c60613          	addi	a2,a2,-1140 # 80008050 <digits>
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

0000000080000548 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000552:	00011497          	auipc	s1,0x11
    80000556:	38648493          	addi	s1,s1,902 # 800118d8 <pr>
    8000055a:	00008597          	auipc	a1,0x8
    8000055e:	abe58593          	addi	a1,a1,-1346 # 80008018 <etext+0x18>
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	6c4080e7          	jalr	1732(ra) # 80000c28 <initlock>
  pr.locking = 1;
    8000056c:	4785                	li	a5,1
    8000056e:	cc9c                	sw	a5,24(s1)
}
    80000570:	60e2                	ld	ra,24(sp)
    80000572:	6442                	ld	s0,16(sp)
    80000574:	64a2                	ld	s1,8(sp)
    80000576:	6105                	addi	sp,sp,32
    80000578:	8082                	ret

000000008000057a <backtrace>:

void backtrace(void)
{
    8000057a:	7179                	addi	sp,sp,-48
    8000057c:	f406                	sd	ra,40(sp)
    8000057e:	f022                	sd	s0,32(sp)
    80000580:	ec26                	sd	s1,24(sp)
    80000582:	e84a                	sd	s2,16(sp)
    80000584:	e44e                	sd	s3,8(sp)
    80000586:	1800                	addi	s0,sp,48
  printf("backtrace:\n");
    80000588:	00008517          	auipc	a0,0x8
    8000058c:	a9850513          	addi	a0,a0,-1384 # 80008020 <etext+0x20>
    80000590:	00000097          	auipc	ra,0x0
    80000594:	092080e7          	jalr	146(ra) # 80000622 <printf>

static inline uint64
r_fp()
{
  uint64 x;
  asm volatile("mv %0, s0" : "=r" (x) );
    80000598:	84a2                	mv	s1,s0
  // 1. retrieve the current function call's stack frame pointer
  uint64 curr_fp = r_fp();
  uint64 page_bottom = PGROUNDDOWN(curr_fp);
    8000059a:	797d                	lui	s2,0xfffff
    8000059c:	0124f933          	and	s2,s1,s2
  while (page_bottom < curr_fp) {
    800005a0:	02997163          	bgeu	s2,s1,800005c2 <backtrace+0x48>
    // 2. retrieve the return address and prev call stack frame pointer
    uint64 ret = *(pte_t *)(curr_fp - 0x8);
    uint64 prev_fp = *(pte_t *)(curr_fp - 0x10);
    // 3. print the return address
    printf("%p\n", ret);
    800005a4:	00008997          	auipc	s3,0x8
    800005a8:	cac98993          	addi	s3,s3,-852 # 80008250 <digits+0x200>
    uint64 ret = *(pte_t *)(curr_fp - 0x8);
    800005ac:	ff84b583          	ld	a1,-8(s1)
    uint64 prev_fp = *(pte_t *)(curr_fp - 0x10);
    800005b0:	ff04b483          	ld	s1,-16(s1)
    printf("%p\n", ret);
    800005b4:	854e                	mv	a0,s3
    800005b6:	00000097          	auipc	ra,0x0
    800005ba:	06c080e7          	jalr	108(ra) # 80000622 <printf>
  while (page_bottom < curr_fp) {
    800005be:	fe9967e3          	bltu	s2,s1,800005ac <backtrace+0x32>
    // 4. jump to prev stack frame
    curr_fp = prev_fp;
  }
}
    800005c2:	70a2                	ld	ra,40(sp)
    800005c4:	7402                	ld	s0,32(sp)
    800005c6:	64e2                	ld	s1,24(sp)
    800005c8:	6942                	ld	s2,16(sp)
    800005ca:	69a2                	ld	s3,8(sp)
    800005cc:	6145                	addi	sp,sp,48
    800005ce:	8082                	ret

00000000800005d0 <panic>:
{
    800005d0:	1101                	addi	sp,sp,-32
    800005d2:	ec06                	sd	ra,24(sp)
    800005d4:	e822                	sd	s0,16(sp)
    800005d6:	e426                	sd	s1,8(sp)
    800005d8:	1000                	addi	s0,sp,32
    800005da:	84aa                	mv	s1,a0
  pr.locking = 0;
    800005dc:	00011797          	auipc	a5,0x11
    800005e0:	3007aa23          	sw	zero,788(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    800005e4:	00008517          	auipc	a0,0x8
    800005e8:	a4c50513          	addi	a0,a0,-1460 # 80008030 <etext+0x30>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	036080e7          	jalr	54(ra) # 80000622 <printf>
  printf(s);
    800005f4:	8526                	mv	a0,s1
    800005f6:	00000097          	auipc	ra,0x0
    800005fa:	02c080e7          	jalr	44(ra) # 80000622 <printf>
  printf("\n");
    800005fe:	00008517          	auipc	a0,0x8
    80000602:	ada50513          	addi	a0,a0,-1318 # 800080d8 <digits+0x88>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	01c080e7          	jalr	28(ra) # 80000622 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000060e:	4785                	li	a5,1
    80000610:	00009717          	auipc	a4,0x9
    80000614:	9ef72823          	sw	a5,-1552(a4) # 80009000 <panicked>
  backtrace();
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f62080e7          	jalr	-158(ra) # 8000057a <backtrace>
  for(;;)
    80000620:	a001                	j	80000620 <panic+0x50>

0000000080000622 <printf>:
{
    80000622:	7131                	addi	sp,sp,-192
    80000624:	fc86                	sd	ra,120(sp)
    80000626:	f8a2                	sd	s0,112(sp)
    80000628:	f4a6                	sd	s1,104(sp)
    8000062a:	f0ca                	sd	s2,96(sp)
    8000062c:	ecce                	sd	s3,88(sp)
    8000062e:	e8d2                	sd	s4,80(sp)
    80000630:	e4d6                	sd	s5,72(sp)
    80000632:	e0da                	sd	s6,64(sp)
    80000634:	fc5e                	sd	s7,56(sp)
    80000636:	f862                	sd	s8,48(sp)
    80000638:	f466                	sd	s9,40(sp)
    8000063a:	f06a                	sd	s10,32(sp)
    8000063c:	ec6e                	sd	s11,24(sp)
    8000063e:	0100                	addi	s0,sp,128
    80000640:	8a2a                	mv	s4,a0
    80000642:	e40c                	sd	a1,8(s0)
    80000644:	e810                	sd	a2,16(s0)
    80000646:	ec14                	sd	a3,24(s0)
    80000648:	f018                	sd	a4,32(s0)
    8000064a:	f41c                	sd	a5,40(s0)
    8000064c:	03043823          	sd	a6,48(s0)
    80000650:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    80000654:	00011d97          	auipc	s11,0x11
    80000658:	29cdad83          	lw	s11,668(s11) # 800118f0 <pr+0x18>
  if(locking)
    8000065c:	020d9b63          	bnez	s11,80000692 <printf+0x70>
  if (fmt == 0)
    80000660:	040a0263          	beqz	s4,800006a4 <printf+0x82>
  va_start(ap, fmt);
    80000664:	00840793          	addi	a5,s0,8
    80000668:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000066c:	000a4503          	lbu	a0,0(s4)
    80000670:	16050263          	beqz	a0,800007d4 <printf+0x1b2>
    80000674:	4481                	li	s1,0
    if(c != '%'){
    80000676:	02500a93          	li	s5,37
    switch(c){
    8000067a:	07000b13          	li	s6,112
  consputc('x');
    8000067e:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000680:	00008b97          	auipc	s7,0x8
    80000684:	9d0b8b93          	addi	s7,s7,-1584 # 80008050 <digits>
    switch(c){
    80000688:	07300c93          	li	s9,115
    8000068c:	06400c13          	li	s8,100
    80000690:	a82d                	j	800006ca <printf+0xa8>
    acquire(&pr.lock);
    80000692:	00011517          	auipc	a0,0x11
    80000696:	24650513          	addi	a0,a0,582 # 800118d8 <pr>
    8000069a:	00000097          	auipc	ra,0x0
    8000069e:	61e080e7          	jalr	1566(ra) # 80000cb8 <acquire>
    800006a2:	bf7d                	j	80000660 <printf+0x3e>
    panic("null fmt");
    800006a4:	00008517          	auipc	a0,0x8
    800006a8:	99c50513          	addi	a0,a0,-1636 # 80008040 <etext+0x40>
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	f24080e7          	jalr	-220(ra) # 800005d0 <panic>
      consputc(c);
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bd2080e7          	jalr	-1070(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006bc:	2485                	addiw	s1,s1,1
    800006be:	009a07b3          	add	a5,s4,s1
    800006c2:	0007c503          	lbu	a0,0(a5)
    800006c6:	10050763          	beqz	a0,800007d4 <printf+0x1b2>
    if(c != '%'){
    800006ca:	ff5515e3          	bne	a0,s5,800006b4 <printf+0x92>
    c = fmt[++i] & 0xff;
    800006ce:	2485                	addiw	s1,s1,1
    800006d0:	009a07b3          	add	a5,s4,s1
    800006d4:	0007c783          	lbu	a5,0(a5)
    800006d8:	0007891b          	sext.w	s2,a5
    if(c == 0)
    800006dc:	cfe5                	beqz	a5,800007d4 <printf+0x1b2>
    switch(c){
    800006de:	05678a63          	beq	a5,s6,80000732 <printf+0x110>
    800006e2:	02fb7663          	bgeu	s6,a5,8000070e <printf+0xec>
    800006e6:	09978963          	beq	a5,s9,80000778 <printf+0x156>
    800006ea:	07800713          	li	a4,120
    800006ee:	0ce79863          	bne	a5,a4,800007be <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    800006f2:	f8843783          	ld	a5,-120(s0)
    800006f6:	00878713          	addi	a4,a5,8
    800006fa:	f8e43423          	sd	a4,-120(s0)
    800006fe:	4605                	li	a2,1
    80000700:	85ea                	mv	a1,s10
    80000702:	4388                	lw	a0,0(a5)
    80000704:	00000097          	auipc	ra,0x0
    80000708:	da2080e7          	jalr	-606(ra) # 800004a6 <printint>
      break;
    8000070c:	bf45                	j	800006bc <printf+0x9a>
    switch(c){
    8000070e:	0b578263          	beq	a5,s5,800007b2 <printf+0x190>
    80000712:	0b879663          	bne	a5,s8,800007be <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000716:	f8843783          	ld	a5,-120(s0)
    8000071a:	00878713          	addi	a4,a5,8
    8000071e:	f8e43423          	sd	a4,-120(s0)
    80000722:	4605                	li	a2,1
    80000724:	45a9                	li	a1,10
    80000726:	4388                	lw	a0,0(a5)
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	d7e080e7          	jalr	-642(ra) # 800004a6 <printint>
      break;
    80000730:	b771                	j	800006bc <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000732:	f8843783          	ld	a5,-120(s0)
    80000736:	00878713          	addi	a4,a5,8
    8000073a:	f8e43423          	sd	a4,-120(s0)
    8000073e:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000742:	03000513          	li	a0,48
    80000746:	00000097          	auipc	ra,0x0
    8000074a:	b40080e7          	jalr	-1216(ra) # 80000286 <consputc>
  consputc('x');
    8000074e:	07800513          	li	a0,120
    80000752:	00000097          	auipc	ra,0x0
    80000756:	b34080e7          	jalr	-1228(ra) # 80000286 <consputc>
    8000075a:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000075c:	03c9d793          	srli	a5,s3,0x3c
    80000760:	97de                	add	a5,a5,s7
    80000762:	0007c503          	lbu	a0,0(a5)
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	b20080e7          	jalr	-1248(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000076e:	0992                	slli	s3,s3,0x4
    80000770:	397d                	addiw	s2,s2,-1
    80000772:	fe0915e3          	bnez	s2,8000075c <printf+0x13a>
    80000776:	b799                	j	800006bc <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    80000778:	f8843783          	ld	a5,-120(s0)
    8000077c:	00878713          	addi	a4,a5,8
    80000780:	f8e43423          	sd	a4,-120(s0)
    80000784:	0007b903          	ld	s2,0(a5)
    80000788:	00090e63          	beqz	s2,800007a4 <printf+0x182>
      for(; *s; s++)
    8000078c:	00094503          	lbu	a0,0(s2) # fffffffffffff000 <end+0xffffffff7ffd6fe0>
    80000790:	d515                	beqz	a0,800006bc <printf+0x9a>
        consputc(*s);
    80000792:	00000097          	auipc	ra,0x0
    80000796:	af4080e7          	jalr	-1292(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000079a:	0905                	addi	s2,s2,1
    8000079c:	00094503          	lbu	a0,0(s2)
    800007a0:	f96d                	bnez	a0,80000792 <printf+0x170>
    800007a2:	bf29                	j	800006bc <printf+0x9a>
        s = "(null)";
    800007a4:	00008917          	auipc	s2,0x8
    800007a8:	89490913          	addi	s2,s2,-1900 # 80008038 <etext+0x38>
      for(; *s; s++)
    800007ac:	02800513          	li	a0,40
    800007b0:	b7cd                	j	80000792 <printf+0x170>
      consputc('%');
    800007b2:	8556                	mv	a0,s5
    800007b4:	00000097          	auipc	ra,0x0
    800007b8:	ad2080e7          	jalr	-1326(ra) # 80000286 <consputc>
      break;
    800007bc:	b701                	j	800006bc <printf+0x9a>
      consputc('%');
    800007be:	8556                	mv	a0,s5
    800007c0:	00000097          	auipc	ra,0x0
    800007c4:	ac6080e7          	jalr	-1338(ra) # 80000286 <consputc>
      consputc(c);
    800007c8:	854a                	mv	a0,s2
    800007ca:	00000097          	auipc	ra,0x0
    800007ce:	abc080e7          	jalr	-1348(ra) # 80000286 <consputc>
      break;
    800007d2:	b5ed                	j	800006bc <printf+0x9a>
  if(locking)
    800007d4:	020d9163          	bnez	s11,800007f6 <printf+0x1d4>
}
    800007d8:	70e6                	ld	ra,120(sp)
    800007da:	7446                	ld	s0,112(sp)
    800007dc:	74a6                	ld	s1,104(sp)
    800007de:	7906                	ld	s2,96(sp)
    800007e0:	69e6                	ld	s3,88(sp)
    800007e2:	6a46                	ld	s4,80(sp)
    800007e4:	6aa6                	ld	s5,72(sp)
    800007e6:	6b06                	ld	s6,64(sp)
    800007e8:	7be2                	ld	s7,56(sp)
    800007ea:	7c42                	ld	s8,48(sp)
    800007ec:	7ca2                	ld	s9,40(sp)
    800007ee:	7d02                	ld	s10,32(sp)
    800007f0:	6de2                	ld	s11,24(sp)
    800007f2:	6129                	addi	sp,sp,192
    800007f4:	8082                	ret
    release(&pr.lock);
    800007f6:	00011517          	auipc	a0,0x11
    800007fa:	0e250513          	addi	a0,a0,226 # 800118d8 <pr>
    800007fe:	00000097          	auipc	ra,0x0
    80000802:	56e080e7          	jalr	1390(ra) # 80000d6c <release>
}
    80000806:	bfc9                	j	800007d8 <printf+0x1b6>

0000000080000808 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000808:	1141                	addi	sp,sp,-16
    8000080a:	e406                	sd	ra,8(sp)
    8000080c:	e022                	sd	s0,0(sp)
    8000080e:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000810:	100007b7          	lui	a5,0x10000
    80000814:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000818:	f8000713          	li	a4,-128
    8000081c:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000820:	470d                	li	a4,3
    80000822:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000826:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000082a:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000082e:	469d                	li	a3,7
    80000830:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000834:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000838:	00008597          	auipc	a1,0x8
    8000083c:	83058593          	addi	a1,a1,-2000 # 80008068 <digits+0x18>
    80000840:	00011517          	auipc	a0,0x11
    80000844:	0b850513          	addi	a0,a0,184 # 800118f8 <uart_tx_lock>
    80000848:	00000097          	auipc	ra,0x0
    8000084c:	3e0080e7          	jalr	992(ra) # 80000c28 <initlock>
}
    80000850:	60a2                	ld	ra,8(sp)
    80000852:	6402                	ld	s0,0(sp)
    80000854:	0141                	addi	sp,sp,16
    80000856:	8082                	ret

0000000080000858 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000858:	1101                	addi	sp,sp,-32
    8000085a:	ec06                	sd	ra,24(sp)
    8000085c:	e822                	sd	s0,16(sp)
    8000085e:	e426                	sd	s1,8(sp)
    80000860:	1000                	addi	s0,sp,32
    80000862:	84aa                	mv	s1,a0
  push_off();
    80000864:	00000097          	auipc	ra,0x0
    80000868:	408080e7          	jalr	1032(ra) # 80000c6c <push_off>

  if(panicked){
    8000086c:	00008797          	auipc	a5,0x8
    80000870:	7947a783          	lw	a5,1940(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000874:	10000737          	lui	a4,0x10000
  if(panicked){
    80000878:	c391                	beqz	a5,8000087c <uartputc_sync+0x24>
    for(;;)
    8000087a:	a001                	j	8000087a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000087c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000880:	0ff7f793          	andi	a5,a5,255
    80000884:	0207f793          	andi	a5,a5,32
    80000888:	dbf5                	beqz	a5,8000087c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000088a:	0ff4f793          	andi	a5,s1,255
    8000088e:	10000737          	lui	a4,0x10000
    80000892:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000896:	00000097          	auipc	ra,0x0
    8000089a:	476080e7          	jalr	1142(ra) # 80000d0c <pop_off>
}
    8000089e:	60e2                	ld	ra,24(sp)
    800008a0:	6442                	ld	s0,16(sp)
    800008a2:	64a2                	ld	s1,8(sp)
    800008a4:	6105                	addi	sp,sp,32
    800008a6:	8082                	ret

00000000800008a8 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008a8:	00008797          	auipc	a5,0x8
    800008ac:	75c7a783          	lw	a5,1884(a5) # 80009004 <uart_tx_r>
    800008b0:	00008717          	auipc	a4,0x8
    800008b4:	75872703          	lw	a4,1880(a4) # 80009008 <uart_tx_w>
    800008b8:	08f70263          	beq	a4,a5,8000093c <uartstart+0x94>
{
    800008bc:	7139                	addi	sp,sp,-64
    800008be:	fc06                	sd	ra,56(sp)
    800008c0:	f822                	sd	s0,48(sp)
    800008c2:	f426                	sd	s1,40(sp)
    800008c4:	f04a                	sd	s2,32(sp)
    800008c6:	ec4e                	sd	s3,24(sp)
    800008c8:	e852                	sd	s4,16(sp)
    800008ca:	e456                	sd	s5,8(sp)
    800008cc:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008ce:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008d2:	00011a17          	auipc	s4,0x11
    800008d6:	026a0a13          	addi	s4,s4,38 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008da:	00008497          	auipc	s1,0x8
    800008de:	72a48493          	addi	s1,s1,1834 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008e2:	00008997          	auipc	s3,0x8
    800008e6:	72698993          	addi	s3,s3,1830 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008ea:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008ee:	0ff77713          	andi	a4,a4,255
    800008f2:	02077713          	andi	a4,a4,32
    800008f6:	cb15                	beqz	a4,8000092a <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008f8:	00fa0733          	add	a4,s4,a5
    800008fc:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000900:	2785                	addiw	a5,a5,1
    80000902:	41f7d71b          	sraiw	a4,a5,0x1f
    80000906:	01b7571b          	srliw	a4,a4,0x1b
    8000090a:	9fb9                	addw	a5,a5,a4
    8000090c:	8bfd                	andi	a5,a5,31
    8000090e:	9f99                	subw	a5,a5,a4
    80000910:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000912:	8526                	mv	a0,s1
    80000914:	00002097          	auipc	ra,0x2
    80000918:	094080e7          	jalr	148(ra) # 800029a8 <wakeup>
    
    WriteReg(THR, c);
    8000091c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000920:	409c                	lw	a5,0(s1)
    80000922:	0009a703          	lw	a4,0(s3)
    80000926:	fcf712e3          	bne	a4,a5,800008ea <uartstart+0x42>
  }
}
    8000092a:	70e2                	ld	ra,56(sp)
    8000092c:	7442                	ld	s0,48(sp)
    8000092e:	74a2                	ld	s1,40(sp)
    80000930:	7902                	ld	s2,32(sp)
    80000932:	69e2                	ld	s3,24(sp)
    80000934:	6a42                	ld	s4,16(sp)
    80000936:	6aa2                	ld	s5,8(sp)
    80000938:	6121                	addi	sp,sp,64
    8000093a:	8082                	ret
    8000093c:	8082                	ret

000000008000093e <uartputc>:
{
    8000093e:	7179                	addi	sp,sp,-48
    80000940:	f406                	sd	ra,40(sp)
    80000942:	f022                	sd	s0,32(sp)
    80000944:	ec26                	sd	s1,24(sp)
    80000946:	e84a                	sd	s2,16(sp)
    80000948:	e44e                	sd	s3,8(sp)
    8000094a:	e052                	sd	s4,0(sp)
    8000094c:	1800                	addi	s0,sp,48
    8000094e:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    80000950:	00011517          	auipc	a0,0x11
    80000954:	fa850513          	addi	a0,a0,-88 # 800118f8 <uart_tx_lock>
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	360080e7          	jalr	864(ra) # 80000cb8 <acquire>
  if(panicked){
    80000960:	00008797          	auipc	a5,0x8
    80000964:	6a07a783          	lw	a5,1696(a5) # 80009000 <panicked>
    80000968:	c391                	beqz	a5,8000096c <uartputc+0x2e>
    for(;;)
    8000096a:	a001                	j	8000096a <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000096c:	00008717          	auipc	a4,0x8
    80000970:	69c72703          	lw	a4,1692(a4) # 80009008 <uart_tx_w>
    80000974:	0017079b          	addiw	a5,a4,1
    80000978:	41f7d69b          	sraiw	a3,a5,0x1f
    8000097c:	01b6d69b          	srliw	a3,a3,0x1b
    80000980:	9fb5                	addw	a5,a5,a3
    80000982:	8bfd                	andi	a5,a5,31
    80000984:	9f95                	subw	a5,a5,a3
    80000986:	00008697          	auipc	a3,0x8
    8000098a:	67e6a683          	lw	a3,1662(a3) # 80009004 <uart_tx_r>
    8000098e:	04f69263          	bne	a3,a5,800009d2 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000992:	00011a17          	auipc	s4,0x11
    80000996:	f66a0a13          	addi	s4,s4,-154 # 800118f8 <uart_tx_lock>
    8000099a:	00008497          	auipc	s1,0x8
    8000099e:	66a48493          	addi	s1,s1,1642 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009a2:	00008917          	auipc	s2,0x8
    800009a6:	66690913          	addi	s2,s2,1638 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009aa:	85d2                	mv	a1,s4
    800009ac:	8526                	mv	a0,s1
    800009ae:	00002097          	auipc	ra,0x2
    800009b2:	e74080e7          	jalr	-396(ra) # 80002822 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009b6:	00092703          	lw	a4,0(s2)
    800009ba:	0017079b          	addiw	a5,a4,1
    800009be:	41f7d69b          	sraiw	a3,a5,0x1f
    800009c2:	01b6d69b          	srliw	a3,a3,0x1b
    800009c6:	9fb5                	addw	a5,a5,a3
    800009c8:	8bfd                	andi	a5,a5,31
    800009ca:	9f95                	subw	a5,a5,a3
    800009cc:	4094                	lw	a3,0(s1)
    800009ce:	fcf68ee3          	beq	a3,a5,800009aa <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009d2:	00011497          	auipc	s1,0x11
    800009d6:	f2648493          	addi	s1,s1,-218 # 800118f8 <uart_tx_lock>
    800009da:	9726                	add	a4,a4,s1
    800009dc:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009e0:	00008717          	auipc	a4,0x8
    800009e4:	62f72423          	sw	a5,1576(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	ec0080e7          	jalr	-320(ra) # 800008a8 <uartstart>
      release(&uart_tx_lock);
    800009f0:	8526                	mv	a0,s1
    800009f2:	00000097          	auipc	ra,0x0
    800009f6:	37a080e7          	jalr	890(ra) # 80000d6c <release>
}
    800009fa:	70a2                	ld	ra,40(sp)
    800009fc:	7402                	ld	s0,32(sp)
    800009fe:	64e2                	ld	s1,24(sp)
    80000a00:	6942                	ld	s2,16(sp)
    80000a02:	69a2                	ld	s3,8(sp)
    80000a04:	6a02                	ld	s4,0(sp)
    80000a06:	6145                	addi	sp,sp,48
    80000a08:	8082                	ret

0000000080000a0a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000a0a:	1141                	addi	sp,sp,-16
    80000a0c:	e422                	sd	s0,8(sp)
    80000a0e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a10:	100007b7          	lui	a5,0x10000
    80000a14:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a18:	8b85                	andi	a5,a5,1
    80000a1a:	cb91                	beqz	a5,80000a2e <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a1c:	100007b7          	lui	a5,0x10000
    80000a20:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a24:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a28:	6422                	ld	s0,8(sp)
    80000a2a:	0141                	addi	sp,sp,16
    80000a2c:	8082                	ret
    return -1;
    80000a2e:	557d                	li	a0,-1
    80000a30:	bfe5                	j	80000a28 <uartgetc+0x1e>

0000000080000a32 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a32:	1101                	addi	sp,sp,-32
    80000a34:	ec06                	sd	ra,24(sp)
    80000a36:	e822                	sd	s0,16(sp)
    80000a38:	e426                	sd	s1,8(sp)
    80000a3a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a3c:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	fcc080e7          	jalr	-52(ra) # 80000a0a <uartgetc>
    if(c == -1)
    80000a46:	00950763          	beq	a0,s1,80000a54 <uartintr+0x22>
      break;
    consoleintr(c);
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	87e080e7          	jalr	-1922(ra) # 800002c8 <consoleintr>
  while(1){
    80000a52:	b7f5                	j	80000a3e <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a54:	00011497          	auipc	s1,0x11
    80000a58:	ea448493          	addi	s1,s1,-348 # 800118f8 <uart_tx_lock>
    80000a5c:	8526                	mv	a0,s1
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	25a080e7          	jalr	602(ra) # 80000cb8 <acquire>
  uartstart();
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	e42080e7          	jalr	-446(ra) # 800008a8 <uartstart>
  release(&uart_tx_lock);
    80000a6e:	8526                	mv	a0,s1
    80000a70:	00000097          	auipc	ra,0x0
    80000a74:	2fc080e7          	jalr	764(ra) # 80000d6c <release>
}
    80000a78:	60e2                	ld	ra,24(sp)
    80000a7a:	6442                	ld	s0,16(sp)
    80000a7c:	64a2                	ld	s1,8(sp)
    80000a7e:	6105                	addi	sp,sp,32
    80000a80:	8082                	ret

0000000080000a82 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a82:	1101                	addi	sp,sp,-32
    80000a84:	ec06                	sd	ra,24(sp)
    80000a86:	e822                	sd	s0,16(sp)
    80000a88:	e426                	sd	s1,8(sp)
    80000a8a:	e04a                	sd	s2,0(sp)
    80000a8c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a8e:	03451793          	slli	a5,a0,0x34
    80000a92:	ebb9                	bnez	a5,80000ae8 <kfree+0x66>
    80000a94:	84aa                	mv	s1,a0
    80000a96:	00027797          	auipc	a5,0x27
    80000a9a:	58a78793          	addi	a5,a5,1418 # 80028020 <end>
    80000a9e:	04f56563          	bltu	a0,a5,80000ae8 <kfree+0x66>
    80000aa2:	47c5                	li	a5,17
    80000aa4:	07ee                	slli	a5,a5,0x1b
    80000aa6:	04f57163          	bgeu	a0,a5,80000ae8 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000aaa:	6605                	lui	a2,0x1
    80000aac:	4585                	li	a1,1
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	306080e7          	jalr	774(ra) # 80000db4 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000ab6:	00011917          	auipc	s2,0x11
    80000aba:	e7a90913          	addi	s2,s2,-390 # 80011930 <kmem>
    80000abe:	854a                	mv	a0,s2
    80000ac0:	00000097          	auipc	ra,0x0
    80000ac4:	1f8080e7          	jalr	504(ra) # 80000cb8 <acquire>
  r->next = kmem.freelist;
    80000ac8:	01893783          	ld	a5,24(s2)
    80000acc:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ace:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000ad2:	854a                	mv	a0,s2
    80000ad4:	00000097          	auipc	ra,0x0
    80000ad8:	298080e7          	jalr	664(ra) # 80000d6c <release>
}
    80000adc:	60e2                	ld	ra,24(sp)
    80000ade:	6442                	ld	s0,16(sp)
    80000ae0:	64a2                	ld	s1,8(sp)
    80000ae2:	6902                	ld	s2,0(sp)
    80000ae4:	6105                	addi	sp,sp,32
    80000ae6:	8082                	ret
    panic("kfree");
    80000ae8:	00007517          	auipc	a0,0x7
    80000aec:	58850513          	addi	a0,a0,1416 # 80008070 <digits+0x20>
    80000af0:	00000097          	auipc	ra,0x0
    80000af4:	ae0080e7          	jalr	-1312(ra) # 800005d0 <panic>

0000000080000af8 <freerange>:
{
    80000af8:	7179                	addi	sp,sp,-48
    80000afa:	f406                	sd	ra,40(sp)
    80000afc:	f022                	sd	s0,32(sp)
    80000afe:	ec26                	sd	s1,24(sp)
    80000b00:	e84a                	sd	s2,16(sp)
    80000b02:	e44e                	sd	s3,8(sp)
    80000b04:	e052                	sd	s4,0(sp)
    80000b06:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b08:	6785                	lui	a5,0x1
    80000b0a:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b0e:	94aa                	add	s1,s1,a0
    80000b10:	757d                	lui	a0,0xfffff
    80000b12:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b14:	94be                	add	s1,s1,a5
    80000b16:	0095ee63          	bltu	a1,s1,80000b32 <freerange+0x3a>
    80000b1a:	892e                	mv	s2,a1
    kfree(p);
    80000b1c:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b1e:	6985                	lui	s3,0x1
    kfree(p);
    80000b20:	01448533          	add	a0,s1,s4
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	f5e080e7          	jalr	-162(ra) # 80000a82 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b2c:	94ce                	add	s1,s1,s3
    80000b2e:	fe9979e3          	bgeu	s2,s1,80000b20 <freerange+0x28>
}
    80000b32:	70a2                	ld	ra,40(sp)
    80000b34:	7402                	ld	s0,32(sp)
    80000b36:	64e2                	ld	s1,24(sp)
    80000b38:	6942                	ld	s2,16(sp)
    80000b3a:	69a2                	ld	s3,8(sp)
    80000b3c:	6a02                	ld	s4,0(sp)
    80000b3e:	6145                	addi	sp,sp,48
    80000b40:	8082                	ret

0000000080000b42 <kinit>:
{
    80000b42:	1141                	addi	sp,sp,-16
    80000b44:	e406                	sd	ra,8(sp)
    80000b46:	e022                	sd	s0,0(sp)
    80000b48:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b4a:	00007597          	auipc	a1,0x7
    80000b4e:	52e58593          	addi	a1,a1,1326 # 80008078 <digits+0x28>
    80000b52:	00011517          	auipc	a0,0x11
    80000b56:	dde50513          	addi	a0,a0,-546 # 80011930 <kmem>
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	0ce080e7          	jalr	206(ra) # 80000c28 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b62:	45c5                	li	a1,17
    80000b64:	05ee                	slli	a1,a1,0x1b
    80000b66:	00027517          	auipc	a0,0x27
    80000b6a:	4ba50513          	addi	a0,a0,1210 # 80028020 <end>
    80000b6e:	00000097          	auipc	ra,0x0
    80000b72:	f8a080e7          	jalr	-118(ra) # 80000af8 <freerange>
}
    80000b76:	60a2                	ld	ra,8(sp)
    80000b78:	6402                	ld	s0,0(sp)
    80000b7a:	0141                	addi	sp,sp,16
    80000b7c:	8082                	ret

0000000080000b7e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b7e:	1101                	addi	sp,sp,-32
    80000b80:	ec06                	sd	ra,24(sp)
    80000b82:	e822                	sd	s0,16(sp)
    80000b84:	e426                	sd	s1,8(sp)
    80000b86:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b88:	00011497          	auipc	s1,0x11
    80000b8c:	da848493          	addi	s1,s1,-600 # 80011930 <kmem>
    80000b90:	8526                	mv	a0,s1
    80000b92:	00000097          	auipc	ra,0x0
    80000b96:	126080e7          	jalr	294(ra) # 80000cb8 <acquire>
  r = kmem.freelist;
    80000b9a:	6c84                	ld	s1,24(s1)
  if(r)
    80000b9c:	c885                	beqz	s1,80000bcc <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b9e:	609c                	ld	a5,0(s1)
    80000ba0:	00011517          	auipc	a0,0x11
    80000ba4:	d9050513          	addi	a0,a0,-624 # 80011930 <kmem>
    80000ba8:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000baa:	00000097          	auipc	ra,0x0
    80000bae:	1c2080e7          	jalr	450(ra) # 80000d6c <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bb2:	6605                	lui	a2,0x1
    80000bb4:	4595                	li	a1,5
    80000bb6:	8526                	mv	a0,s1
    80000bb8:	00000097          	auipc	ra,0x0
    80000bbc:	1fc080e7          	jalr	508(ra) # 80000db4 <memset>
  return (void*)r;
}
    80000bc0:	8526                	mv	a0,s1
    80000bc2:	60e2                	ld	ra,24(sp)
    80000bc4:	6442                	ld	s0,16(sp)
    80000bc6:	64a2                	ld	s1,8(sp)
    80000bc8:	6105                	addi	sp,sp,32
    80000bca:	8082                	ret
  release(&kmem.lock);
    80000bcc:	00011517          	auipc	a0,0x11
    80000bd0:	d6450513          	addi	a0,a0,-668 # 80011930 <kmem>
    80000bd4:	00000097          	auipc	ra,0x0
    80000bd8:	198080e7          	jalr	408(ra) # 80000d6c <release>
  if(r)
    80000bdc:	b7d5                	j	80000bc0 <kalloc+0x42>

0000000080000bde <kfreemem>:

// Return the number of bytes of free memory
// should be multiple of PGSIZE
uint64
kfreemem(void) {
    80000bde:	1101                	addi	sp,sp,-32
    80000be0:	ec06                	sd	ra,24(sp)
    80000be2:	e822                	sd	s0,16(sp)
    80000be4:	e426                	sd	s1,8(sp)
    80000be6:	1000                	addi	s0,sp,32
  struct run *r;
  uint64 free = 0;
  acquire(&kmem.lock);
    80000be8:	00011497          	auipc	s1,0x11
    80000bec:	d4848493          	addi	s1,s1,-696 # 80011930 <kmem>
    80000bf0:	8526                	mv	a0,s1
    80000bf2:	00000097          	auipc	ra,0x0
    80000bf6:	0c6080e7          	jalr	198(ra) # 80000cb8 <acquire>
  r = kmem.freelist;
    80000bfa:	6c9c                	ld	a5,24(s1)
  while (r) {
    80000bfc:	c785                	beqz	a5,80000c24 <kfreemem+0x46>
  uint64 free = 0;
    80000bfe:	4481                	li	s1,0
    free += PGSIZE;
    80000c00:	6705                	lui	a4,0x1
    80000c02:	94ba                	add	s1,s1,a4
    r = r->next;
    80000c04:	639c                	ld	a5,0(a5)
  while (r) {
    80000c06:	fff5                	bnez	a5,80000c02 <kfreemem+0x24>
  }
  release(&kmem.lock);
    80000c08:	00011517          	auipc	a0,0x11
    80000c0c:	d2850513          	addi	a0,a0,-728 # 80011930 <kmem>
    80000c10:	00000097          	auipc	ra,0x0
    80000c14:	15c080e7          	jalr	348(ra) # 80000d6c <release>
  return free;
}
    80000c18:	8526                	mv	a0,s1
    80000c1a:	60e2                	ld	ra,24(sp)
    80000c1c:	6442                	ld	s0,16(sp)
    80000c1e:	64a2                	ld	s1,8(sp)
    80000c20:	6105                	addi	sp,sp,32
    80000c22:	8082                	ret
  uint64 free = 0;
    80000c24:	4481                	li	s1,0
    80000c26:	b7cd                	j	80000c08 <kfreemem+0x2a>

0000000080000c28 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c28:	1141                	addi	sp,sp,-16
    80000c2a:	e422                	sd	s0,8(sp)
    80000c2c:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c2e:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c30:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c34:	00053823          	sd	zero,16(a0)
}
    80000c38:	6422                	ld	s0,8(sp)
    80000c3a:	0141                	addi	sp,sp,16
    80000c3c:	8082                	ret

0000000080000c3e <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c3e:	411c                	lw	a5,0(a0)
    80000c40:	e399                	bnez	a5,80000c46 <holding+0x8>
    80000c42:	4501                	li	a0,0
  return r;
}
    80000c44:	8082                	ret
{
    80000c46:	1101                	addi	sp,sp,-32
    80000c48:	ec06                	sd	ra,24(sp)
    80000c4a:	e822                	sd	s0,16(sp)
    80000c4c:	e426                	sd	s1,8(sp)
    80000c4e:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c50:	6904                	ld	s1,16(a0)
    80000c52:	00001097          	auipc	ra,0x1
    80000c56:	1d4080e7          	jalr	468(ra) # 80001e26 <mycpu>
    80000c5a:	40a48533          	sub	a0,s1,a0
    80000c5e:	00153513          	seqz	a0,a0
}
    80000c62:	60e2                	ld	ra,24(sp)
    80000c64:	6442                	ld	s0,16(sp)
    80000c66:	64a2                	ld	s1,8(sp)
    80000c68:	6105                	addi	sp,sp,32
    80000c6a:	8082                	ret

0000000080000c6c <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c6c:	1101                	addi	sp,sp,-32
    80000c6e:	ec06                	sd	ra,24(sp)
    80000c70:	e822                	sd	s0,16(sp)
    80000c72:	e426                	sd	s1,8(sp)
    80000c74:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c76:	100024f3          	csrr	s1,sstatus
    80000c7a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c7e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c80:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c84:	00001097          	auipc	ra,0x1
    80000c88:	1a2080e7          	jalr	418(ra) # 80001e26 <mycpu>
    80000c8c:	5d3c                	lw	a5,120(a0)
    80000c8e:	cf89                	beqz	a5,80000ca8 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c90:	00001097          	auipc	ra,0x1
    80000c94:	196080e7          	jalr	406(ra) # 80001e26 <mycpu>
    80000c98:	5d3c                	lw	a5,120(a0)
    80000c9a:	2785                	addiw	a5,a5,1
    80000c9c:	dd3c                	sw	a5,120(a0)
}
    80000c9e:	60e2                	ld	ra,24(sp)
    80000ca0:	6442                	ld	s0,16(sp)
    80000ca2:	64a2                	ld	s1,8(sp)
    80000ca4:	6105                	addi	sp,sp,32
    80000ca6:	8082                	ret
    mycpu()->intena = old;
    80000ca8:	00001097          	auipc	ra,0x1
    80000cac:	17e080e7          	jalr	382(ra) # 80001e26 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cb0:	8085                	srli	s1,s1,0x1
    80000cb2:	8885                	andi	s1,s1,1
    80000cb4:	dd64                	sw	s1,124(a0)
    80000cb6:	bfe9                	j	80000c90 <push_off+0x24>

0000000080000cb8 <acquire>:
{
    80000cb8:	1101                	addi	sp,sp,-32
    80000cba:	ec06                	sd	ra,24(sp)
    80000cbc:	e822                	sd	s0,16(sp)
    80000cbe:	e426                	sd	s1,8(sp)
    80000cc0:	1000                	addi	s0,sp,32
    80000cc2:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	fa8080e7          	jalr	-88(ra) # 80000c6c <push_off>
  if(holding(lk))
    80000ccc:	8526                	mv	a0,s1
    80000cce:	00000097          	auipc	ra,0x0
    80000cd2:	f70080e7          	jalr	-144(ra) # 80000c3e <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cd6:	4705                	li	a4,1
  if(holding(lk))
    80000cd8:	e115                	bnez	a0,80000cfc <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cda:	87ba                	mv	a5,a4
    80000cdc:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000ce0:	2781                	sext.w	a5,a5
    80000ce2:	ffe5                	bnez	a5,80000cda <acquire+0x22>
  __sync_synchronize();
    80000ce4:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000ce8:	00001097          	auipc	ra,0x1
    80000cec:	13e080e7          	jalr	318(ra) # 80001e26 <mycpu>
    80000cf0:	e888                	sd	a0,16(s1)
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("acquire");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	38450513          	addi	a0,a0,900 # 80008080 <digits+0x30>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	8cc080e7          	jalr	-1844(ra) # 800005d0 <panic>

0000000080000d0c <pop_off>:

void
pop_off(void)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e406                	sd	ra,8(sp)
    80000d10:	e022                	sd	s0,0(sp)
    80000d12:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d14:	00001097          	auipc	ra,0x1
    80000d18:	112080e7          	jalr	274(ra) # 80001e26 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d1c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d20:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d22:	e78d                	bnez	a5,80000d4c <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d24:	5d3c                	lw	a5,120(a0)
    80000d26:	02f05b63          	blez	a5,80000d5c <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d2a:	37fd                	addiw	a5,a5,-1
    80000d2c:	0007871b          	sext.w	a4,a5
    80000d30:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d32:	eb09                	bnez	a4,80000d44 <pop_off+0x38>
    80000d34:	5d7c                	lw	a5,124(a0)
    80000d36:	c799                	beqz	a5,80000d44 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d38:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d3c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d40:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d44:	60a2                	ld	ra,8(sp)
    80000d46:	6402                	ld	s0,0(sp)
    80000d48:	0141                	addi	sp,sp,16
    80000d4a:	8082                	ret
    panic("pop_off - interruptible");
    80000d4c:	00007517          	auipc	a0,0x7
    80000d50:	33c50513          	addi	a0,a0,828 # 80008088 <digits+0x38>
    80000d54:	00000097          	auipc	ra,0x0
    80000d58:	87c080e7          	jalr	-1924(ra) # 800005d0 <panic>
    panic("pop_off");
    80000d5c:	00007517          	auipc	a0,0x7
    80000d60:	34450513          	addi	a0,a0,836 # 800080a0 <digits+0x50>
    80000d64:	00000097          	auipc	ra,0x0
    80000d68:	86c080e7          	jalr	-1940(ra) # 800005d0 <panic>

0000000080000d6c <release>:
{
    80000d6c:	1101                	addi	sp,sp,-32
    80000d6e:	ec06                	sd	ra,24(sp)
    80000d70:	e822                	sd	s0,16(sp)
    80000d72:	e426                	sd	s1,8(sp)
    80000d74:	1000                	addi	s0,sp,32
    80000d76:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d78:	00000097          	auipc	ra,0x0
    80000d7c:	ec6080e7          	jalr	-314(ra) # 80000c3e <holding>
    80000d80:	c115                	beqz	a0,80000da4 <release+0x38>
  lk->cpu = 0;
    80000d82:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d86:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d8a:	0f50000f          	fence	iorw,ow
    80000d8e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f7a080e7          	jalr	-134(ra) # 80000d0c <pop_off>
}
    80000d9a:	60e2                	ld	ra,24(sp)
    80000d9c:	6442                	ld	s0,16(sp)
    80000d9e:	64a2                	ld	s1,8(sp)
    80000da0:	6105                	addi	sp,sp,32
    80000da2:	8082                	ret
    panic("release");
    80000da4:	00007517          	auipc	a0,0x7
    80000da8:	30450513          	addi	a0,a0,772 # 800080a8 <digits+0x58>
    80000dac:	00000097          	auipc	ra,0x0
    80000db0:	824080e7          	jalr	-2012(ra) # 800005d0 <panic>

0000000080000db4 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000db4:	1141                	addi	sp,sp,-16
    80000db6:	e422                	sd	s0,8(sp)
    80000db8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000dba:	ce09                	beqz	a2,80000dd4 <memset+0x20>
    80000dbc:	87aa                	mv	a5,a0
    80000dbe:	fff6071b          	addiw	a4,a2,-1
    80000dc2:	1702                	slli	a4,a4,0x20
    80000dc4:	9301                	srli	a4,a4,0x20
    80000dc6:	0705                	addi	a4,a4,1
    80000dc8:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000dca:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dce:	0785                	addi	a5,a5,1
    80000dd0:	fee79de3          	bne	a5,a4,80000dca <memset+0x16>
  }
  return dst;
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret

0000000080000dda <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000dda:	1141                	addi	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000de0:	ca05                	beqz	a2,80000e10 <memcmp+0x36>
    80000de2:	fff6069b          	addiw	a3,a2,-1
    80000de6:	1682                	slli	a3,a3,0x20
    80000de8:	9281                	srli	a3,a3,0x20
    80000dea:	0685                	addi	a3,a3,1
    80000dec:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000dee:	00054783          	lbu	a5,0(a0)
    80000df2:	0005c703          	lbu	a4,0(a1)
    80000df6:	00e79863          	bne	a5,a4,80000e06 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dfa:	0505                	addi	a0,a0,1
    80000dfc:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000dfe:	fed518e3          	bne	a0,a3,80000dee <memcmp+0x14>
  }

  return 0;
    80000e02:	4501                	li	a0,0
    80000e04:	a019                	j	80000e0a <memcmp+0x30>
      return *s1 - *s2;
    80000e06:	40e7853b          	subw	a0,a5,a4
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret
  return 0;
    80000e10:	4501                	li	a0,0
    80000e12:	bfe5                	j	80000e0a <memcmp+0x30>

0000000080000e14 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e14:	1141                	addi	sp,sp,-16
    80000e16:	e422                	sd	s0,8(sp)
    80000e18:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e1a:	00a5f963          	bgeu	a1,a0,80000e2c <memmove+0x18>
    80000e1e:	02061713          	slli	a4,a2,0x20
    80000e22:	9301                	srli	a4,a4,0x20
    80000e24:	00e587b3          	add	a5,a1,a4
    80000e28:	02f56563          	bltu	a0,a5,80000e52 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e2c:	fff6069b          	addiw	a3,a2,-1
    80000e30:	ce11                	beqz	a2,80000e4c <memmove+0x38>
    80000e32:	1682                	slli	a3,a3,0x20
    80000e34:	9281                	srli	a3,a3,0x20
    80000e36:	0685                	addi	a3,a3,1
    80000e38:	96ae                	add	a3,a3,a1
    80000e3a:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000e3c:	0585                	addi	a1,a1,1
    80000e3e:	0785                	addi	a5,a5,1
    80000e40:	fff5c703          	lbu	a4,-1(a1)
    80000e44:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000e48:	fed59ae3          	bne	a1,a3,80000e3c <memmove+0x28>

  return dst;
}
    80000e4c:	6422                	ld	s0,8(sp)
    80000e4e:	0141                	addi	sp,sp,16
    80000e50:	8082                	ret
    d += n;
    80000e52:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e54:	fff6069b          	addiw	a3,a2,-1
    80000e58:	da75                	beqz	a2,80000e4c <memmove+0x38>
    80000e5a:	02069613          	slli	a2,a3,0x20
    80000e5e:	9201                	srli	a2,a2,0x20
    80000e60:	fff64613          	not	a2,a2
    80000e64:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e66:	17fd                	addi	a5,a5,-1
    80000e68:	177d                	addi	a4,a4,-1
    80000e6a:	0007c683          	lbu	a3,0(a5)
    80000e6e:	00d70023          	sb	a3,0(a4) # 1000 <_entry-0x7ffff000>
    while(n-- > 0)
    80000e72:	fec79ae3          	bne	a5,a2,80000e66 <memmove+0x52>
    80000e76:	bfd9                	j	80000e4c <memmove+0x38>

0000000080000e78 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e80:	00000097          	auipc	ra,0x0
    80000e84:	f94080e7          	jalr	-108(ra) # 80000e14 <memmove>
}
    80000e88:	60a2                	ld	ra,8(sp)
    80000e8a:	6402                	ld	s0,0(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret

0000000080000e90 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e90:	1141                	addi	sp,sp,-16
    80000e92:	e422                	sd	s0,8(sp)
    80000e94:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e96:	ce11                	beqz	a2,80000eb2 <strncmp+0x22>
    80000e98:	00054783          	lbu	a5,0(a0)
    80000e9c:	cf89                	beqz	a5,80000eb6 <strncmp+0x26>
    80000e9e:	0005c703          	lbu	a4,0(a1)
    80000ea2:	00f71a63          	bne	a4,a5,80000eb6 <strncmp+0x26>
    n--, p++, q++;
    80000ea6:	367d                	addiw	a2,a2,-1
    80000ea8:	0505                	addi	a0,a0,1
    80000eaa:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000eac:	f675                	bnez	a2,80000e98 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000eae:	4501                	li	a0,0
    80000eb0:	a809                	j	80000ec2 <strncmp+0x32>
    80000eb2:	4501                	li	a0,0
    80000eb4:	a039                	j	80000ec2 <strncmp+0x32>
  if(n == 0)
    80000eb6:	ca09                	beqz	a2,80000ec8 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000eb8:	00054503          	lbu	a0,0(a0)
    80000ebc:	0005c783          	lbu	a5,0(a1)
    80000ec0:	9d1d                	subw	a0,a0,a5
}
    80000ec2:	6422                	ld	s0,8(sp)
    80000ec4:	0141                	addi	sp,sp,16
    80000ec6:	8082                	ret
    return 0;
    80000ec8:	4501                	li	a0,0
    80000eca:	bfe5                	j	80000ec2 <strncmp+0x32>

0000000080000ecc <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ecc:	1141                	addi	sp,sp,-16
    80000ece:	e422                	sd	s0,8(sp)
    80000ed0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ed2:	872a                	mv	a4,a0
    80000ed4:	8832                	mv	a6,a2
    80000ed6:	367d                	addiw	a2,a2,-1
    80000ed8:	01005963          	blez	a6,80000eea <strncpy+0x1e>
    80000edc:	0705                	addi	a4,a4,1
    80000ede:	0005c783          	lbu	a5,0(a1)
    80000ee2:	fef70fa3          	sb	a5,-1(a4)
    80000ee6:	0585                	addi	a1,a1,1
    80000ee8:	f7f5                	bnez	a5,80000ed4 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000eea:	00c05d63          	blez	a2,80000f04 <strncpy+0x38>
    80000eee:	86ba                	mv	a3,a4
    *s++ = 0;
    80000ef0:	0685                	addi	a3,a3,1
    80000ef2:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000ef6:	fff6c793          	not	a5,a3
    80000efa:	9fb9                	addw	a5,a5,a4
    80000efc:	010787bb          	addw	a5,a5,a6
    80000f00:	fef048e3          	bgtz	a5,80000ef0 <strncpy+0x24>
  return os;
}
    80000f04:	6422                	ld	s0,8(sp)
    80000f06:	0141                	addi	sp,sp,16
    80000f08:	8082                	ret

0000000080000f0a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f0a:	1141                	addi	sp,sp,-16
    80000f0c:	e422                	sd	s0,8(sp)
    80000f0e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f10:	02c05363          	blez	a2,80000f36 <safestrcpy+0x2c>
    80000f14:	fff6069b          	addiw	a3,a2,-1
    80000f18:	1682                	slli	a3,a3,0x20
    80000f1a:	9281                	srli	a3,a3,0x20
    80000f1c:	96ae                	add	a3,a3,a1
    80000f1e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f20:	00d58963          	beq	a1,a3,80000f32 <safestrcpy+0x28>
    80000f24:	0585                	addi	a1,a1,1
    80000f26:	0785                	addi	a5,a5,1
    80000f28:	fff5c703          	lbu	a4,-1(a1)
    80000f2c:	fee78fa3          	sb	a4,-1(a5)
    80000f30:	fb65                	bnez	a4,80000f20 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f32:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f36:	6422                	ld	s0,8(sp)
    80000f38:	0141                	addi	sp,sp,16
    80000f3a:	8082                	ret

0000000080000f3c <strlen>:

int
strlen(const char *s)
{
    80000f3c:	1141                	addi	sp,sp,-16
    80000f3e:	e422                	sd	s0,8(sp)
    80000f40:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f42:	00054783          	lbu	a5,0(a0)
    80000f46:	cf91                	beqz	a5,80000f62 <strlen+0x26>
    80000f48:	0505                	addi	a0,a0,1
    80000f4a:	87aa                	mv	a5,a0
    80000f4c:	4685                	li	a3,1
    80000f4e:	9e89                	subw	a3,a3,a0
    80000f50:	00f6853b          	addw	a0,a3,a5
    80000f54:	0785                	addi	a5,a5,1
    80000f56:	fff7c703          	lbu	a4,-1(a5)
    80000f5a:	fb7d                	bnez	a4,80000f50 <strlen+0x14>
    ;
  return n;
}
    80000f5c:	6422                	ld	s0,8(sp)
    80000f5e:	0141                	addi	sp,sp,16
    80000f60:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f62:	4501                	li	a0,0
    80000f64:	bfe5                	j	80000f5c <strlen+0x20>

0000000080000f66 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f66:	1141                	addi	sp,sp,-16
    80000f68:	e406                	sd	ra,8(sp)
    80000f6a:	e022                	sd	s0,0(sp)
    80000f6c:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f6e:	00001097          	auipc	ra,0x1
    80000f72:	ea8080e7          	jalr	-344(ra) # 80001e16 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f76:	00008717          	auipc	a4,0x8
    80000f7a:	09670713          	addi	a4,a4,150 # 8000900c <started>
  if(cpuid() == 0){
    80000f7e:	c139                	beqz	a0,80000fc4 <main+0x5e>
    while(started == 0)
    80000f80:	431c                	lw	a5,0(a4)
    80000f82:	2781                	sext.w	a5,a5
    80000f84:	dff5                	beqz	a5,80000f80 <main+0x1a>
      ;
    __sync_synchronize();
    80000f86:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f8a:	00001097          	auipc	ra,0x1
    80000f8e:	e8c080e7          	jalr	-372(ra) # 80001e16 <cpuid>
    80000f92:	85aa                	mv	a1,a0
    80000f94:	00007517          	auipc	a0,0x7
    80000f98:	13450513          	addi	a0,a0,308 # 800080c8 <digits+0x78>
    80000f9c:	fffff097          	auipc	ra,0xfffff
    80000fa0:	686080e7          	jalr	1670(ra) # 80000622 <printf>
    kvminithart();    // turn on paging
    80000fa4:	00000097          	auipc	ra,0x0
    80000fa8:	0f4080e7          	jalr	244(ra) # 80001098 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	d18080e7          	jalr	-744(ra) # 80002cc4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	4ec080e7          	jalr	1260(ra) # 800064a0 <plicinithart>
  }

  scheduler();        
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	576080e7          	jalr	1398(ra) # 80002532 <scheduler>
    consoleinit();
    80000fc4:	fffff097          	auipc	ra,0xfffff
    80000fc8:	496080e7          	jalr	1174(ra) # 8000045a <consoleinit>
    printfinit();
    80000fcc:	fffff097          	auipc	ra,0xfffff
    80000fd0:	57c080e7          	jalr	1404(ra) # 80000548 <printfinit>
    printf("\n");
    80000fd4:	00007517          	auipc	a0,0x7
    80000fd8:	10450513          	addi	a0,a0,260 # 800080d8 <digits+0x88>
    80000fdc:	fffff097          	auipc	ra,0xfffff
    80000fe0:	646080e7          	jalr	1606(ra) # 80000622 <printf>
    printf("xv6 kernel is booting\n");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0cc50513          	addi	a0,a0,204 # 800080b0 <digits+0x60>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	636080e7          	jalr	1590(ra) # 80000622 <printf>
    printf("\n");
    80000ff4:	00007517          	auipc	a0,0x7
    80000ff8:	0e450513          	addi	a0,a0,228 # 800080d8 <digits+0x88>
    80000ffc:	fffff097          	auipc	ra,0xfffff
    80001000:	626080e7          	jalr	1574(ra) # 80000622 <printf>
    kinit();         // physical page allocator
    80001004:	00000097          	auipc	ra,0x0
    80001008:	b3e080e7          	jalr	-1218(ra) # 80000b42 <kinit>
    kvminit();       // create kernel page table
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	334080e7          	jalr	820(ra) # 80001340 <kvminit>
    kvminithart();   // turn on paging
    80001014:	00000097          	auipc	ra,0x0
    80001018:	084080e7          	jalr	132(ra) # 80001098 <kvminithart>
    procinit();      // process table
    8000101c:	00001097          	auipc	ra,0x1
    80001020:	d2a080e7          	jalr	-726(ra) # 80001d46 <procinit>
    trapinit();      // trap vectors
    80001024:	00002097          	auipc	ra,0x2
    80001028:	c78080e7          	jalr	-904(ra) # 80002c9c <trapinit>
    trapinithart();  // install kernel trap vector
    8000102c:	00002097          	auipc	ra,0x2
    80001030:	c98080e7          	jalr	-872(ra) # 80002cc4 <trapinithart>
    plicinit();      // set up interrupt controller
    80001034:	00005097          	auipc	ra,0x5
    80001038:	456080e7          	jalr	1110(ra) # 8000648a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000103c:	00005097          	auipc	ra,0x5
    80001040:	464080e7          	jalr	1124(ra) # 800064a0 <plicinithart>
    binit();         // buffer cache
    80001044:	00002097          	auipc	ra,0x2
    80001048:	5ba080e7          	jalr	1466(ra) # 800035fe <binit>
    iinit();         // inode cache
    8000104c:	00003097          	auipc	ra,0x3
    80001050:	c4a080e7          	jalr	-950(ra) # 80003c96 <iinit>
    fileinit();      // file table
    80001054:	00004097          	auipc	ra,0x4
    80001058:	be4080e7          	jalr	-1052(ra) # 80004c38 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000105c:	00005097          	auipc	ra,0x5
    80001060:	54c080e7          	jalr	1356(ra) # 800065a8 <virtio_disk_init>
    userinit();      // first user process
    80001064:	00001097          	auipc	ra,0x1
    80001068:	198080e7          	jalr	408(ra) # 800021fc <userinit>
    __sync_synchronize();
    8000106c:	0ff0000f          	fence
    started = 1;
    80001070:	4785                	li	a5,1
    80001072:	00008717          	auipc	a4,0x8
    80001076:	f8f72d23          	sw	a5,-102(a4) # 8000900c <started>
    8000107a:	b789                	j	80000fbc <main+0x56>

000000008000107c <ukvminithard>:
  // the highest virtual address in the kernel.
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
}

// refresh the TLB to refer the page as virtual memory mapping table
void ukvminithard(pagetable_t page) {
    8000107c:	1141                	addi	sp,sp,-16
    8000107e:	e422                	sd	s0,8(sp)
    80001080:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(page));
    80001082:	8131                	srli	a0,a0,0xc
    80001084:	57fd                	li	a5,-1
    80001086:	17fe                	slli	a5,a5,0x3f
    80001088:	8d5d                	or	a0,a0,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000108a:	18051073          	csrw	satp,a0
  asm volatile("sfence.vma zero, zero");
    8000108e:	12000073          	sfence.vma
  sfence_vma();
}
    80001092:	6422                	ld	s0,8(sp)
    80001094:	0141                	addi	sp,sp,16
    80001096:	8082                	ret

0000000080001098 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001098:	1141                	addi	sp,sp,-16
    8000109a:	e422                	sd	s0,8(sp)
    8000109c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000109e:	00008797          	auipc	a5,0x8
    800010a2:	f727b783          	ld	a5,-142(a5) # 80009010 <kernel_pagetable>
    800010a6:	83b1                	srli	a5,a5,0xc
    800010a8:	577d                	li	a4,-1
    800010aa:	177e                	slli	a4,a4,0x3f
    800010ac:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010ae:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010b2:	12000073          	sfence.vma
  sfence_vma();
}
    800010b6:	6422                	ld	s0,8(sp)
    800010b8:	0141                	addi	sp,sp,16
    800010ba:	8082                	ret

00000000800010bc <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010bc:	7139                	addi	sp,sp,-64
    800010be:	fc06                	sd	ra,56(sp)
    800010c0:	f822                	sd	s0,48(sp)
    800010c2:	f426                	sd	s1,40(sp)
    800010c4:	f04a                	sd	s2,32(sp)
    800010c6:	ec4e                	sd	s3,24(sp)
    800010c8:	e852                	sd	s4,16(sp)
    800010ca:	e456                	sd	s5,8(sp)
    800010cc:	e05a                	sd	s6,0(sp)
    800010ce:	0080                	addi	s0,sp,64
    800010d0:	84aa                	mv	s1,a0
    800010d2:	89ae                	mv	s3,a1
    800010d4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010d6:	57fd                	li	a5,-1
    800010d8:	83e9                	srli	a5,a5,0x1a
    800010da:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010dc:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010de:	04b7f263          	bgeu	a5,a1,80001122 <walk+0x66>
    panic("walk");
    800010e2:	00007517          	auipc	a0,0x7
    800010e6:	ffe50513          	addi	a0,a0,-2 # 800080e0 <digits+0x90>
    800010ea:	fffff097          	auipc	ra,0xfffff
    800010ee:	4e6080e7          	jalr	1254(ra) # 800005d0 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010f2:	060a8663          	beqz	s5,8000115e <walk+0xa2>
    800010f6:	00000097          	auipc	ra,0x0
    800010fa:	a88080e7          	jalr	-1400(ra) # 80000b7e <kalloc>
    800010fe:	84aa                	mv	s1,a0
    80001100:	c529                	beqz	a0,8000114a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001102:	6605                	lui	a2,0x1
    80001104:	4581                	li	a1,0
    80001106:	00000097          	auipc	ra,0x0
    8000110a:	cae080e7          	jalr	-850(ra) # 80000db4 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000110e:	00c4d793          	srli	a5,s1,0xc
    80001112:	07aa                	slli	a5,a5,0xa
    80001114:	0017e793          	ori	a5,a5,1
    80001118:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000111c:	3a5d                	addiw	s4,s4,-9
    8000111e:	036a0063          	beq	s4,s6,8000113e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001122:	0149d933          	srl	s2,s3,s4
    80001126:	1ff97913          	andi	s2,s2,511
    8000112a:	090e                	slli	s2,s2,0x3
    8000112c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000112e:	00093483          	ld	s1,0(s2)
    80001132:	0014f793          	andi	a5,s1,1
    80001136:	dfd5                	beqz	a5,800010f2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001138:	80a9                	srli	s1,s1,0xa
    8000113a:	04b2                	slli	s1,s1,0xc
    8000113c:	b7c5                	j	8000111c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000113e:	00c9d513          	srli	a0,s3,0xc
    80001142:	1ff57513          	andi	a0,a0,511
    80001146:	050e                	slli	a0,a0,0x3
    80001148:	9526                	add	a0,a0,s1
}
    8000114a:	70e2                	ld	ra,56(sp)
    8000114c:	7442                	ld	s0,48(sp)
    8000114e:	74a2                	ld	s1,40(sp)
    80001150:	7902                	ld	s2,32(sp)
    80001152:	69e2                	ld	s3,24(sp)
    80001154:	6a42                	ld	s4,16(sp)
    80001156:	6aa2                	ld	s5,8(sp)
    80001158:	6b02                	ld	s6,0(sp)
    8000115a:	6121                	addi	sp,sp,64
    8000115c:	8082                	ret
        return 0;
    8000115e:	4501                	li	a0,0
    80001160:	b7ed                	j	8000114a <walk+0x8e>

0000000080001162 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001162:	57fd                	li	a5,-1
    80001164:	83e9                	srli	a5,a5,0x1a
    80001166:	00b7f463          	bgeu	a5,a1,8000116e <walkaddr+0xc>
    return 0;
    8000116a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000116c:	8082                	ret
{
    8000116e:	1141                	addi	sp,sp,-16
    80001170:	e406                	sd	ra,8(sp)
    80001172:	e022                	sd	s0,0(sp)
    80001174:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001176:	4601                	li	a2,0
    80001178:	00000097          	auipc	ra,0x0
    8000117c:	f44080e7          	jalr	-188(ra) # 800010bc <walk>
  if(pte == 0)
    80001180:	c105                	beqz	a0,800011a0 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001182:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001184:	0117f693          	andi	a3,a5,17
    80001188:	4745                	li	a4,17
    return 0;
    8000118a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000118c:	00e68663          	beq	a3,a4,80001198 <walkaddr+0x36>
}
    80001190:	60a2                	ld	ra,8(sp)
    80001192:	6402                	ld	s0,0(sp)
    80001194:	0141                	addi	sp,sp,16
    80001196:	8082                	ret
  pa = PTE2PA(*pte);
    80001198:	00a7d513          	srli	a0,a5,0xa
    8000119c:	0532                	slli	a0,a0,0xc
  return pa;
    8000119e:	bfcd                	j	80001190 <walkaddr+0x2e>
    return 0;
    800011a0:	4501                	li	a0,0
    800011a2:	b7fd                	j	80001190 <walkaddr+0x2e>

00000000800011a4 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800011a4:	1101                	addi	sp,sp,-32
    800011a6:	ec06                	sd	ra,24(sp)
    800011a8:	e822                	sd	s0,16(sp)
    800011aa:	e426                	sd	s1,8(sp)
    800011ac:	1000                	addi	s0,sp,32
    800011ae:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800011b0:	1552                	slli	a0,a0,0x34
    800011b2:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800011b6:	4601                	li	a2,0
    800011b8:	00008517          	auipc	a0,0x8
    800011bc:	e5853503          	ld	a0,-424(a0) # 80009010 <kernel_pagetable>
    800011c0:	00000097          	auipc	ra,0x0
    800011c4:	efc080e7          	jalr	-260(ra) # 800010bc <walk>
  if(pte == 0)
    800011c8:	cd09                	beqz	a0,800011e2 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800011ca:	6108                	ld	a0,0(a0)
    800011cc:	00157793          	andi	a5,a0,1
    800011d0:	c38d                	beqz	a5,800011f2 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800011d2:	8129                	srli	a0,a0,0xa
    800011d4:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800011d6:	9526                	add	a0,a0,s1
    800011d8:	60e2                	ld	ra,24(sp)
    800011da:	6442                	ld	s0,16(sp)
    800011dc:	64a2                	ld	s1,8(sp)
    800011de:	6105                	addi	sp,sp,32
    800011e0:	8082                	ret
    panic("kvmpa");
    800011e2:	00007517          	auipc	a0,0x7
    800011e6:	f0650513          	addi	a0,a0,-250 # 800080e8 <digits+0x98>
    800011ea:	fffff097          	auipc	ra,0xfffff
    800011ee:	3e6080e7          	jalr	998(ra) # 800005d0 <panic>
    panic("kvmpa");
    800011f2:	00007517          	auipc	a0,0x7
    800011f6:	ef650513          	addi	a0,a0,-266 # 800080e8 <digits+0x98>
    800011fa:	fffff097          	auipc	ra,0xfffff
    800011fe:	3d6080e7          	jalr	982(ra) # 800005d0 <panic>

0000000080001202 <umappages>:

// Same as mappages without panic on remapping
int umappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm) {
    80001202:	715d                	addi	sp,sp,-80
    80001204:	e486                	sd	ra,72(sp)
    80001206:	e0a2                	sd	s0,64(sp)
    80001208:	fc26                	sd	s1,56(sp)
    8000120a:	f84a                	sd	s2,48(sp)
    8000120c:	f44e                	sd	s3,40(sp)
    8000120e:	f052                	sd	s4,32(sp)
    80001210:	ec56                	sd	s5,24(sp)
    80001212:	e85a                	sd	s6,16(sp)
    80001214:	e45e                	sd	s7,8(sp)
    80001216:	0880                	addi	s0,sp,80
    80001218:	8aaa                	mv	s5,a0
    8000121a:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000121c:	777d                	lui	a4,0xfffff
    8000121e:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001222:	167d                	addi	a2,a2,-1
    80001224:	00b609b3          	add	s3,a2,a1
    80001228:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000122c:	893e                	mv	s2,a5
    8000122e:	40f68a33          	sub	s4,a3,a5
    if((pte = walk(pagetable, a, 1)) == 0)
      return -1;
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001232:	6b85                	lui	s7,0x1
    80001234:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001238:	4605                	li	a2,1
    8000123a:	85ca                	mv	a1,s2
    8000123c:	8556                	mv	a0,s5
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	e7e080e7          	jalr	-386(ra) # 800010bc <walk>
    80001246:	cd01                	beqz	a0,8000125e <umappages+0x5c>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001248:	80b1                	srli	s1,s1,0xc
    8000124a:	04aa                	slli	s1,s1,0xa
    8000124c:	0164e4b3          	or	s1,s1,s6
    80001250:	0014e493          	ori	s1,s1,1
    80001254:	e104                	sd	s1,0(a0)
    if(a == last)
    80001256:	03390063          	beq	s2,s3,80001276 <umappages+0x74>
    a += PGSIZE;
    8000125a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000125c:	bfe1                	j	80001234 <umappages+0x32>
      return -1;
    8000125e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001260:	60a6                	ld	ra,72(sp)
    80001262:	6406                	ld	s0,64(sp)
    80001264:	74e2                	ld	s1,56(sp)
    80001266:	7942                	ld	s2,48(sp)
    80001268:	79a2                	ld	s3,40(sp)
    8000126a:	7a02                	ld	s4,32(sp)
    8000126c:	6ae2                	ld	s5,24(sp)
    8000126e:	6b42                	ld	s6,16(sp)
    80001270:	6ba2                	ld	s7,8(sp)
    80001272:	6161                	addi	sp,sp,80
    80001274:	8082                	ret
  return 0;
    80001276:	4501                	li	a0,0
    80001278:	b7e5                	j	80001260 <umappages+0x5e>

000000008000127a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000127a:	715d                	addi	sp,sp,-80
    8000127c:	e486                	sd	ra,72(sp)
    8000127e:	e0a2                	sd	s0,64(sp)
    80001280:	fc26                	sd	s1,56(sp)
    80001282:	f84a                	sd	s2,48(sp)
    80001284:	f44e                	sd	s3,40(sp)
    80001286:	f052                	sd	s4,32(sp)
    80001288:	ec56                	sd	s5,24(sp)
    8000128a:	e85a                	sd	s6,16(sp)
    8000128c:	e45e                	sd	s7,8(sp)
    8000128e:	0880                	addi	s0,sp,80
    80001290:	8aaa                	mv	s5,a0
    80001292:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001294:	777d                	lui	a4,0xfffff
    80001296:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000129a:	167d                	addi	a2,a2,-1
    8000129c:	00b609b3          	add	s3,a2,a1
    800012a0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800012a4:	893e                	mv	s2,a5
    800012a6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800012aa:	6b85                	lui	s7,0x1
    800012ac:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012b0:	4605                	li	a2,1
    800012b2:	85ca                	mv	a1,s2
    800012b4:	8556                	mv	a0,s5
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	e06080e7          	jalr	-506(ra) # 800010bc <walk>
    800012be:	c51d                	beqz	a0,800012ec <mappages+0x72>
    if(*pte & PTE_V)
    800012c0:	611c                	ld	a5,0(a0)
    800012c2:	8b85                	andi	a5,a5,1
    800012c4:	ef81                	bnez	a5,800012dc <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800012c6:	80b1                	srli	s1,s1,0xc
    800012c8:	04aa                	slli	s1,s1,0xa
    800012ca:	0164e4b3          	or	s1,s1,s6
    800012ce:	0014e493          	ori	s1,s1,1
    800012d2:	e104                	sd	s1,0(a0)
    if(a == last)
    800012d4:	03390863          	beq	s2,s3,80001304 <mappages+0x8a>
    a += PGSIZE;
    800012d8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800012da:	bfc9                	j	800012ac <mappages+0x32>
      panic("remap");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e1450513          	addi	a0,a0,-492 # 800080f0 <digits+0xa0>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	2ec080e7          	jalr	748(ra) # 800005d0 <panic>
      return -1;
    800012ec:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012ee:	60a6                	ld	ra,72(sp)
    800012f0:	6406                	ld	s0,64(sp)
    800012f2:	74e2                	ld	s1,56(sp)
    800012f4:	7942                	ld	s2,48(sp)
    800012f6:	79a2                	ld	s3,40(sp)
    800012f8:	7a02                	ld	s4,32(sp)
    800012fa:	6ae2                	ld	s5,24(sp)
    800012fc:	6b42                	ld	s6,16(sp)
    800012fe:	6ba2                	ld	s7,8(sp)
    80001300:	6161                	addi	sp,sp,80
    80001302:	8082                	ret
  return 0;
    80001304:	4501                	li	a0,0
    80001306:	b7e5                	j	800012ee <mappages+0x74>

0000000080001308 <kvmmap>:
{
    80001308:	1141                	addi	sp,sp,-16
    8000130a:	e406                	sd	ra,8(sp)
    8000130c:	e022                	sd	s0,0(sp)
    8000130e:	0800                	addi	s0,sp,16
    80001310:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001312:	86ae                	mv	a3,a1
    80001314:	85aa                	mv	a1,a0
    80001316:	00008517          	auipc	a0,0x8
    8000131a:	cfa53503          	ld	a0,-774(a0) # 80009010 <kernel_pagetable>
    8000131e:	00000097          	auipc	ra,0x0
    80001322:	f5c080e7          	jalr	-164(ra) # 8000127a <mappages>
    80001326:	e509                	bnez	a0,80001330 <kvmmap+0x28>
}
    80001328:	60a2                	ld	ra,8(sp)
    8000132a:	6402                	ld	s0,0(sp)
    8000132c:	0141                	addi	sp,sp,16
    8000132e:	8082                	ret
    panic("kvmmap");
    80001330:	00007517          	auipc	a0,0x7
    80001334:	dc850513          	addi	a0,a0,-568 # 800080f8 <digits+0xa8>
    80001338:	fffff097          	auipc	ra,0xfffff
    8000133c:	298080e7          	jalr	664(ra) # 800005d0 <panic>

0000000080001340 <kvminit>:
{
    80001340:	1101                	addi	sp,sp,-32
    80001342:	ec06                	sd	ra,24(sp)
    80001344:	e822                	sd	s0,16(sp)
    80001346:	e426                	sd	s1,8(sp)
    80001348:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	834080e7          	jalr	-1996(ra) # 80000b7e <kalloc>
    80001352:	00008797          	auipc	a5,0x8
    80001356:	caa7bf23          	sd	a0,-834(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	a56080e7          	jalr	-1450(ra) # 80000db4 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001366:	4699                	li	a3,6
    80001368:	6605                	lui	a2,0x1
    8000136a:	100005b7          	lui	a1,0x10000
    8000136e:	10000537          	lui	a0,0x10000
    80001372:	00000097          	auipc	ra,0x0
    80001376:	f96080e7          	jalr	-106(ra) # 80001308 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000137a:	4699                	li	a3,6
    8000137c:	6605                	lui	a2,0x1
    8000137e:	100015b7          	lui	a1,0x10001
    80001382:	10001537          	lui	a0,0x10001
    80001386:	00000097          	auipc	ra,0x0
    8000138a:	f82080e7          	jalr	-126(ra) # 80001308 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000138e:	4699                	li	a3,6
    80001390:	6641                	lui	a2,0x10
    80001392:	020005b7          	lui	a1,0x2000
    80001396:	02000537          	lui	a0,0x2000
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	f6e080e7          	jalr	-146(ra) # 80001308 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800013a2:	4699                	li	a3,6
    800013a4:	00400637          	lui	a2,0x400
    800013a8:	0c0005b7          	lui	a1,0xc000
    800013ac:	0c000537          	lui	a0,0xc000
    800013b0:	00000097          	auipc	ra,0x0
    800013b4:	f58080e7          	jalr	-168(ra) # 80001308 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800013b8:	00007497          	auipc	s1,0x7
    800013bc:	c4848493          	addi	s1,s1,-952 # 80008000 <etext>
    800013c0:	46a9                	li	a3,10
    800013c2:	80007617          	auipc	a2,0x80007
    800013c6:	c3e60613          	addi	a2,a2,-962 # 8000 <_entry-0x7fff8000>
    800013ca:	4585                	li	a1,1
    800013cc:	05fe                	slli	a1,a1,0x1f
    800013ce:	852e                	mv	a0,a1
    800013d0:	00000097          	auipc	ra,0x0
    800013d4:	f38080e7          	jalr	-200(ra) # 80001308 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800013d8:	4699                	li	a3,6
    800013da:	4645                	li	a2,17
    800013dc:	066e                	slli	a2,a2,0x1b
    800013de:	8e05                	sub	a2,a2,s1
    800013e0:	85a6                	mv	a1,s1
    800013e2:	8526                	mv	a0,s1
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	f24080e7          	jalr	-220(ra) # 80001308 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013ec:	46a9                	li	a3,10
    800013ee:	6605                	lui	a2,0x1
    800013f0:	00006597          	auipc	a1,0x6
    800013f4:	c1058593          	addi	a1,a1,-1008 # 80007000 <_trampoline>
    800013f8:	04000537          	lui	a0,0x4000
    800013fc:	157d                	addi	a0,a0,-1
    800013fe:	0532                	slli	a0,a0,0xc
    80001400:	00000097          	auipc	ra,0x0
    80001404:	f08080e7          	jalr	-248(ra) # 80001308 <kvmmap>
}
    80001408:	60e2                	ld	ra,24(sp)
    8000140a:	6442                	ld	s0,16(sp)
    8000140c:	64a2                	ld	s1,8(sp)
    8000140e:	6105                	addi	sp,sp,32
    80001410:	8082                	ret

0000000080001412 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001412:	715d                	addi	sp,sp,-80
    80001414:	e486                	sd	ra,72(sp)
    80001416:	e0a2                	sd	s0,64(sp)
    80001418:	fc26                	sd	s1,56(sp)
    8000141a:	f84a                	sd	s2,48(sp)
    8000141c:	f44e                	sd	s3,40(sp)
    8000141e:	f052                	sd	s4,32(sp)
    80001420:	ec56                	sd	s5,24(sp)
    80001422:	e85a                	sd	s6,16(sp)
    80001424:	e45e                	sd	s7,8(sp)
    80001426:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001428:	03459793          	slli	a5,a1,0x34
    8000142c:	e795                	bnez	a5,80001458 <uvmunmap+0x46>
    8000142e:	8a2a                	mv	s4,a0
    80001430:	892e                	mv	s2,a1
    80001432:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001434:	0632                	slli	a2,a2,0xc
    80001436:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000143a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000143c:	6b05                	lui	s6,0x1
    8000143e:	0735e863          	bltu	a1,s3,800014ae <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001442:	60a6                	ld	ra,72(sp)
    80001444:	6406                	ld	s0,64(sp)
    80001446:	74e2                	ld	s1,56(sp)
    80001448:	7942                	ld	s2,48(sp)
    8000144a:	79a2                	ld	s3,40(sp)
    8000144c:	7a02                	ld	s4,32(sp)
    8000144e:	6ae2                	ld	s5,24(sp)
    80001450:	6b42                	ld	s6,16(sp)
    80001452:	6ba2                	ld	s7,8(sp)
    80001454:	6161                	addi	sp,sp,80
    80001456:	8082                	ret
    panic("uvmunmap: not aligned");
    80001458:	00007517          	auipc	a0,0x7
    8000145c:	ca850513          	addi	a0,a0,-856 # 80008100 <digits+0xb0>
    80001460:	fffff097          	auipc	ra,0xfffff
    80001464:	170080e7          	jalr	368(ra) # 800005d0 <panic>
      panic("uvmunmap: walk");
    80001468:	00007517          	auipc	a0,0x7
    8000146c:	cb050513          	addi	a0,a0,-848 # 80008118 <digits+0xc8>
    80001470:	fffff097          	auipc	ra,0xfffff
    80001474:	160080e7          	jalr	352(ra) # 800005d0 <panic>
      panic("uvmunmap: not mapped");
    80001478:	00007517          	auipc	a0,0x7
    8000147c:	cb050513          	addi	a0,a0,-848 # 80008128 <digits+0xd8>
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	150080e7          	jalr	336(ra) # 800005d0 <panic>
      panic("uvmunmap: not a leaf");
    80001488:	00007517          	auipc	a0,0x7
    8000148c:	cb850513          	addi	a0,a0,-840 # 80008140 <digits+0xf0>
    80001490:	fffff097          	auipc	ra,0xfffff
    80001494:	140080e7          	jalr	320(ra) # 800005d0 <panic>
      uint64 pa = PTE2PA(*pte);
    80001498:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000149a:	0532                	slli	a0,a0,0xc
    8000149c:	fffff097          	auipc	ra,0xfffff
    800014a0:	5e6080e7          	jalr	1510(ra) # 80000a82 <kfree>
    *pte = 0;
    800014a4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014a8:	995a                	add	s2,s2,s6
    800014aa:	f9397ce3          	bgeu	s2,s3,80001442 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800014ae:	4601                	li	a2,0
    800014b0:	85ca                	mv	a1,s2
    800014b2:	8552                	mv	a0,s4
    800014b4:	00000097          	auipc	ra,0x0
    800014b8:	c08080e7          	jalr	-1016(ra) # 800010bc <walk>
    800014bc:	84aa                	mv	s1,a0
    800014be:	d54d                	beqz	a0,80001468 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014c0:	6108                	ld	a0,0(a0)
    800014c2:	00157793          	andi	a5,a0,1
    800014c6:	dbcd                	beqz	a5,80001478 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014c8:	3ff57793          	andi	a5,a0,1023
    800014cc:	fb778ee3          	beq	a5,s7,80001488 <uvmunmap+0x76>
    if(do_free){
    800014d0:	fc0a8ae3          	beqz	s5,800014a4 <uvmunmap+0x92>
    800014d4:	b7d1                	j	80001498 <uvmunmap+0x86>

00000000800014d6 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014d6:	1101                	addi	sp,sp,-32
    800014d8:	ec06                	sd	ra,24(sp)
    800014da:	e822                	sd	s0,16(sp)
    800014dc:	e426                	sd	s1,8(sp)
    800014de:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014e0:	fffff097          	auipc	ra,0xfffff
    800014e4:	69e080e7          	jalr	1694(ra) # 80000b7e <kalloc>
    800014e8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014ea:	c519                	beqz	a0,800014f8 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014ec:	6605                	lui	a2,0x1
    800014ee:	4581                	li	a1,0
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	8c4080e7          	jalr	-1852(ra) # 80000db4 <memset>
  return pagetable;
}
    800014f8:	8526                	mv	a0,s1
    800014fa:	60e2                	ld	ra,24(sp)
    800014fc:	6442                	ld	s0,16(sp)
    800014fe:	64a2                	ld	s1,8(sp)
    80001500:	6105                	addi	sp,sp,32
    80001502:	8082                	ret

0000000080001504 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001504:	7179                	addi	sp,sp,-48
    80001506:	f406                	sd	ra,40(sp)
    80001508:	f022                	sd	s0,32(sp)
    8000150a:	ec26                	sd	s1,24(sp)
    8000150c:	e84a                	sd	s2,16(sp)
    8000150e:	e44e                	sd	s3,8(sp)
    80001510:	e052                	sd	s4,0(sp)
    80001512:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001514:	6785                	lui	a5,0x1
    80001516:	04f67863          	bgeu	a2,a5,80001566 <uvminit+0x62>
    8000151a:	8a2a                	mv	s4,a0
    8000151c:	89ae                	mv	s3,a1
    8000151e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001520:	fffff097          	auipc	ra,0xfffff
    80001524:	65e080e7          	jalr	1630(ra) # 80000b7e <kalloc>
    80001528:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000152a:	6605                	lui	a2,0x1
    8000152c:	4581                	li	a1,0
    8000152e:	00000097          	auipc	ra,0x0
    80001532:	886080e7          	jalr	-1914(ra) # 80000db4 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001536:	4779                	li	a4,30
    80001538:	86ca                	mv	a3,s2
    8000153a:	6605                	lui	a2,0x1
    8000153c:	4581                	li	a1,0
    8000153e:	8552                	mv	a0,s4
    80001540:	00000097          	auipc	ra,0x0
    80001544:	d3a080e7          	jalr	-710(ra) # 8000127a <mappages>
  memmove(mem, src, sz);
    80001548:	8626                	mv	a2,s1
    8000154a:	85ce                	mv	a1,s3
    8000154c:	854a                	mv	a0,s2
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	8c6080e7          	jalr	-1850(ra) # 80000e14 <memmove>
}
    80001556:	70a2                	ld	ra,40(sp)
    80001558:	7402                	ld	s0,32(sp)
    8000155a:	64e2                	ld	s1,24(sp)
    8000155c:	6942                	ld	s2,16(sp)
    8000155e:	69a2                	ld	s3,8(sp)
    80001560:	6a02                	ld	s4,0(sp)
    80001562:	6145                	addi	sp,sp,48
    80001564:	8082                	ret
    panic("inituvm: more than a page");
    80001566:	00007517          	auipc	a0,0x7
    8000156a:	bf250513          	addi	a0,a0,-1038 # 80008158 <digits+0x108>
    8000156e:	fffff097          	auipc	ra,0xfffff
    80001572:	062080e7          	jalr	98(ra) # 800005d0 <panic>

0000000080001576 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001576:	1101                	addi	sp,sp,-32
    80001578:	ec06                	sd	ra,24(sp)
    8000157a:	e822                	sd	s0,16(sp)
    8000157c:	e426                	sd	s1,8(sp)
    8000157e:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001580:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001582:	00b67d63          	bgeu	a2,a1,8000159c <uvmdealloc+0x26>
    80001586:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001588:	6785                	lui	a5,0x1
    8000158a:	17fd                	addi	a5,a5,-1
    8000158c:	00f60733          	add	a4,a2,a5
    80001590:	767d                	lui	a2,0xfffff
    80001592:	8f71                	and	a4,a4,a2
    80001594:	97ae                	add	a5,a5,a1
    80001596:	8ff1                	and	a5,a5,a2
    80001598:	00f76863          	bltu	a4,a5,800015a8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000159c:	8526                	mv	a0,s1
    8000159e:	60e2                	ld	ra,24(sp)
    800015a0:	6442                	ld	s0,16(sp)
    800015a2:	64a2                	ld	s1,8(sp)
    800015a4:	6105                	addi	sp,sp,32
    800015a6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015a8:	8f99                	sub	a5,a5,a4
    800015aa:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015ac:	4685                	li	a3,1
    800015ae:	0007861b          	sext.w	a2,a5
    800015b2:	85ba                	mv	a1,a4
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	e5e080e7          	jalr	-418(ra) # 80001412 <uvmunmap>
    800015bc:	b7c5                	j	8000159c <uvmdealloc+0x26>

00000000800015be <uvmalloc>:
  if(newsz < oldsz)
    800015be:	0ab66163          	bltu	a2,a1,80001660 <uvmalloc+0xa2>
{
    800015c2:	7139                	addi	sp,sp,-64
    800015c4:	fc06                	sd	ra,56(sp)
    800015c6:	f822                	sd	s0,48(sp)
    800015c8:	f426                	sd	s1,40(sp)
    800015ca:	f04a                	sd	s2,32(sp)
    800015cc:	ec4e                	sd	s3,24(sp)
    800015ce:	e852                	sd	s4,16(sp)
    800015d0:	e456                	sd	s5,8(sp)
    800015d2:	0080                	addi	s0,sp,64
    800015d4:	8aaa                	mv	s5,a0
    800015d6:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015d8:	6985                	lui	s3,0x1
    800015da:	19fd                	addi	s3,s3,-1
    800015dc:	95ce                	add	a1,a1,s3
    800015de:	79fd                	lui	s3,0xfffff
    800015e0:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015e4:	08c9f063          	bgeu	s3,a2,80001664 <uvmalloc+0xa6>
    800015e8:	894e                	mv	s2,s3
    mem = kalloc();
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	594080e7          	jalr	1428(ra) # 80000b7e <kalloc>
    800015f2:	84aa                	mv	s1,a0
    if(mem == 0){
    800015f4:	c51d                	beqz	a0,80001622 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800015f6:	6605                	lui	a2,0x1
    800015f8:	4581                	li	a1,0
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	7ba080e7          	jalr	1978(ra) # 80000db4 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001602:	4779                	li	a4,30
    80001604:	86a6                	mv	a3,s1
    80001606:	6605                	lui	a2,0x1
    80001608:	85ca                	mv	a1,s2
    8000160a:	8556                	mv	a0,s5
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	c6e080e7          	jalr	-914(ra) # 8000127a <mappages>
    80001614:	e905                	bnez	a0,80001644 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001616:	6785                	lui	a5,0x1
    80001618:	993e                	add	s2,s2,a5
    8000161a:	fd4968e3          	bltu	s2,s4,800015ea <uvmalloc+0x2c>
  return newsz;
    8000161e:	8552                	mv	a0,s4
    80001620:	a809                	j	80001632 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001622:	864e                	mv	a2,s3
    80001624:	85ca                	mv	a1,s2
    80001626:	8556                	mv	a0,s5
    80001628:	00000097          	auipc	ra,0x0
    8000162c:	f4e080e7          	jalr	-178(ra) # 80001576 <uvmdealloc>
      return 0;
    80001630:	4501                	li	a0,0
}
    80001632:	70e2                	ld	ra,56(sp)
    80001634:	7442                	ld	s0,48(sp)
    80001636:	74a2                	ld	s1,40(sp)
    80001638:	7902                	ld	s2,32(sp)
    8000163a:	69e2                	ld	s3,24(sp)
    8000163c:	6a42                	ld	s4,16(sp)
    8000163e:	6aa2                	ld	s5,8(sp)
    80001640:	6121                	addi	sp,sp,64
    80001642:	8082                	ret
      kfree(mem);
    80001644:	8526                	mv	a0,s1
    80001646:	fffff097          	auipc	ra,0xfffff
    8000164a:	43c080e7          	jalr	1084(ra) # 80000a82 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000164e:	864e                	mv	a2,s3
    80001650:	85ca                	mv	a1,s2
    80001652:	8556                	mv	a0,s5
    80001654:	00000097          	auipc	ra,0x0
    80001658:	f22080e7          	jalr	-222(ra) # 80001576 <uvmdealloc>
      return 0;
    8000165c:	4501                	li	a0,0
    8000165e:	bfd1                	j	80001632 <uvmalloc+0x74>
    return oldsz;
    80001660:	852e                	mv	a0,a1
}
    80001662:	8082                	ret
  return newsz;
    80001664:	8532                	mv	a0,a2
    80001666:	b7f1                	j	80001632 <uvmalloc+0x74>

0000000080001668 <ufreewalk>:

// Recursively free page-table pages similar to freewalk
// not need to already free leaf node
void
ufreewalk(pagetable_t pagetable)
{
    80001668:	7139                	addi	sp,sp,-64
    8000166a:	fc06                	sd	ra,56(sp)
    8000166c:	f822                	sd	s0,48(sp)
    8000166e:	f426                	sd	s1,40(sp)
    80001670:	f04a                	sd	s2,32(sp)
    80001672:	ec4e                	sd	s3,24(sp)
    80001674:	e852                	sd	s4,16(sp)
    80001676:	e456                	sd	s5,8(sp)
    80001678:	0080                	addi	s0,sp,64
    8000167a:	8aaa                	mv	s5,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000167c:	84aa                	mv	s1,a0
    8000167e:	6985                	lui	s3,0x1
    80001680:	99aa                	add	s3,s3,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001682:	4a05                	li	s4,1
    80001684:	a821                	j	8000169c <ufreewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001686:	8129                	srli	a0,a0,0xa
      ufreewalk((pagetable_t)child);
    80001688:	0532                	slli	a0,a0,0xc
    8000168a:	00000097          	auipc	ra,0x0
    8000168e:	fde080e7          	jalr	-34(ra) # 80001668 <ufreewalk>
      pagetable[i] = 0;
    }
    pagetable[i] = 0;
    80001692:	00093023          	sd	zero,0(s2)
  for(int i = 0; i < 512; i++){
    80001696:	04a1                	addi	s1,s1,8
    80001698:	01348963          	beq	s1,s3,800016aa <ufreewalk+0x42>
    pte_t pte = pagetable[i];
    8000169c:	8926                	mv	s2,s1
    8000169e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016a0:	00f57793          	andi	a5,a0,15
    800016a4:	ff4797e3          	bne	a5,s4,80001692 <ufreewalk+0x2a>
    800016a8:	bff9                	j	80001686 <ufreewalk+0x1e>
  }
  kfree((void*)pagetable);
    800016aa:	8556                	mv	a0,s5
    800016ac:	fffff097          	auipc	ra,0xfffff
    800016b0:	3d6080e7          	jalr	982(ra) # 80000a82 <kfree>
}
    800016b4:	70e2                	ld	ra,56(sp)
    800016b6:	7442                	ld	s0,48(sp)
    800016b8:	74a2                	ld	s1,40(sp)
    800016ba:	7902                	ld	s2,32(sp)
    800016bc:	69e2                	ld	s3,24(sp)
    800016be:	6a42                	ld	s4,16(sp)
    800016c0:	6aa2                	ld	s5,8(sp)
    800016c2:	6121                	addi	sp,sp,64
    800016c4:	8082                	ret

00000000800016c6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800016c6:	7179                	addi	sp,sp,-48
    800016c8:	f406                	sd	ra,40(sp)
    800016ca:	f022                	sd	s0,32(sp)
    800016cc:	ec26                	sd	s1,24(sp)
    800016ce:	e84a                	sd	s2,16(sp)
    800016d0:	e44e                	sd	s3,8(sp)
    800016d2:	e052                	sd	s4,0(sp)
    800016d4:	1800                	addi	s0,sp,48
    800016d6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800016d8:	84aa                	mv	s1,a0
    800016da:	6905                	lui	s2,0x1
    800016dc:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016de:	4985                	li	s3,1
    800016e0:	a821                	j	800016f8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800016e2:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800016e4:	0532                	slli	a0,a0,0xc
    800016e6:	00000097          	auipc	ra,0x0
    800016ea:	fe0080e7          	jalr	-32(ra) # 800016c6 <freewalk>
      pagetable[i] = 0;
    800016ee:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016f2:	04a1                	addi	s1,s1,8
    800016f4:	03248163          	beq	s1,s2,80001716 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800016f8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016fa:	00f57793          	andi	a5,a0,15
    800016fe:	ff3782e3          	beq	a5,s3,800016e2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001702:	8905                	andi	a0,a0,1
    80001704:	d57d                	beqz	a0,800016f2 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001706:	00007517          	auipc	a0,0x7
    8000170a:	a7250513          	addi	a0,a0,-1422 # 80008178 <digits+0x128>
    8000170e:	fffff097          	auipc	ra,0xfffff
    80001712:	ec2080e7          	jalr	-318(ra) # 800005d0 <panic>
    }
  }
  kfree((void*)pagetable);
    80001716:	8552                	mv	a0,s4
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	36a080e7          	jalr	874(ra) # 80000a82 <kfree>
}
    80001720:	70a2                	ld	ra,40(sp)
    80001722:	7402                	ld	s0,32(sp)
    80001724:	64e2                	ld	s1,24(sp)
    80001726:	6942                	ld	s2,16(sp)
    80001728:	69a2                	ld	s3,8(sp)
    8000172a:	6a02                	ld	s4,0(sp)
    8000172c:	6145                	addi	sp,sp,48
    8000172e:	8082                	ret

0000000080001730 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001730:	1101                	addi	sp,sp,-32
    80001732:	ec06                	sd	ra,24(sp)
    80001734:	e822                	sd	s0,16(sp)
    80001736:	e426                	sd	s1,8(sp)
    80001738:	1000                	addi	s0,sp,32
    8000173a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000173c:	e999                	bnez	a1,80001752 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000173e:	8526                	mv	a0,s1
    80001740:	00000097          	auipc	ra,0x0
    80001744:	f86080e7          	jalr	-122(ra) # 800016c6 <freewalk>
}
    80001748:	60e2                	ld	ra,24(sp)
    8000174a:	6442                	ld	s0,16(sp)
    8000174c:	64a2                	ld	s1,8(sp)
    8000174e:	6105                	addi	sp,sp,32
    80001750:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001752:	6605                	lui	a2,0x1
    80001754:	167d                	addi	a2,a2,-1
    80001756:	962e                	add	a2,a2,a1
    80001758:	4685                	li	a3,1
    8000175a:	8231                	srli	a2,a2,0xc
    8000175c:	4581                	li	a1,0
    8000175e:	00000097          	auipc	ra,0x0
    80001762:	cb4080e7          	jalr	-844(ra) # 80001412 <uvmunmap>
    80001766:	bfe1                	j	8000173e <uvmfree+0xe>

0000000080001768 <pagecopy>:

// copying from old page to new page from
// begin in old page to new in old page
// and mask off PTE_U bit
int
pagecopy(pagetable_t oldpage, pagetable_t newpage, uint64 begin, uint64 end) {
    80001768:	7179                	addi	sp,sp,-48
    8000176a:	f406                	sd	ra,40(sp)
    8000176c:	f022                	sd	s0,32(sp)
    8000176e:	ec26                	sd	s1,24(sp)
    80001770:	e84a                	sd	s2,16(sp)
    80001772:	e44e                	sd	s3,8(sp)
    80001774:	e052                	sd	s4,0(sp)
    80001776:	1800                	addi	s0,sp,48
    80001778:	8a2a                	mv	s4,a0
    8000177a:	89ae                	mv	s3,a1
    8000177c:	8936                	mv	s2,a3
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  begin = PGROUNDUP(begin);
    8000177e:	6485                	lui	s1,0x1
    80001780:	14fd                	addi	s1,s1,-1
    80001782:	9626                	add	a2,a2,s1
    80001784:	74fd                	lui	s1,0xfffff
    80001786:	8cf1                	and	s1,s1,a2

  for (i = begin; i < end; i += PGSIZE) {
    80001788:	08d4f263          	bgeu	s1,a3,8000180c <pagecopy+0xa4>
    if ((pte = walk(oldpage, i, 0)) == 0)
    8000178c:	4601                	li	a2,0
    8000178e:	85a6                	mv	a1,s1
    80001790:	8552                	mv	a0,s4
    80001792:	00000097          	auipc	ra,0x0
    80001796:	92a080e7          	jalr	-1750(ra) # 800010bc <walk>
    8000179a:	c51d                	beqz	a0,800017c8 <pagecopy+0x60>
      panic("pagecopy walk oldpage nullptr");
    if ((*pte & PTE_V) == 0)
    8000179c:	6118                	ld	a4,0(a0)
    8000179e:	00177793          	andi	a5,a4,1
    800017a2:	cb9d                	beqz	a5,800017d8 <pagecopy+0x70>
      panic("pagecopy oldpage pte not valid");
    pa = PTE2PA(*pte);
    800017a4:	00a75693          	srli	a3,a4,0xa
    flags = PTE_FLAGS(*pte) & (~PTE_U);
    if (umappages(newpage, i, PGSIZE, pa, flags) != 0) {
    800017a8:	3ef77713          	andi	a4,a4,1007
    800017ac:	06b2                	slli	a3,a3,0xc
    800017ae:	6605                	lui	a2,0x1
    800017b0:	85a6                	mv	a1,s1
    800017b2:	854e                	mv	a0,s3
    800017b4:	00000097          	auipc	ra,0x0
    800017b8:	a4e080e7          	jalr	-1458(ra) # 80001202 <umappages>
    800017bc:	e515                	bnez	a0,800017e8 <pagecopy+0x80>
  for (i = begin; i < end; i += PGSIZE) {
    800017be:	6785                	lui	a5,0x1
    800017c0:	94be                	add	s1,s1,a5
    800017c2:	fd24e5e3          	bltu	s1,s2,8000178c <pagecopy+0x24>
    800017c6:	a81d                	j	800017fc <pagecopy+0x94>
      panic("pagecopy walk oldpage nullptr");
    800017c8:	00007517          	auipc	a0,0x7
    800017cc:	9c050513          	addi	a0,a0,-1600 # 80008188 <digits+0x138>
    800017d0:	fffff097          	auipc	ra,0xfffff
    800017d4:	e00080e7          	jalr	-512(ra) # 800005d0 <panic>
      panic("pagecopy oldpage pte not valid");
    800017d8:	00007517          	auipc	a0,0x7
    800017dc:	9d050513          	addi	a0,a0,-1584 # 800081a8 <digits+0x158>
    800017e0:	fffff097          	auipc	ra,0xfffff
    800017e4:	df0080e7          	jalr	-528(ra) # 800005d0 <panic>
    }
  }
  return 0;

err:
  uvmunmap(newpage, 0, i / PGSIZE, 1);
    800017e8:	4685                	li	a3,1
    800017ea:	00c4d613          	srli	a2,s1,0xc
    800017ee:	4581                	li	a1,0
    800017f0:	854e                	mv	a0,s3
    800017f2:	00000097          	auipc	ra,0x0
    800017f6:	c20080e7          	jalr	-992(ra) # 80001412 <uvmunmap>
  return -1;
    800017fa:	557d                	li	a0,-1
}
    800017fc:	70a2                	ld	ra,40(sp)
    800017fe:	7402                	ld	s0,32(sp)
    80001800:	64e2                	ld	s1,24(sp)
    80001802:	6942                	ld	s2,16(sp)
    80001804:	69a2                	ld	s3,8(sp)
    80001806:	6a02                	ld	s4,0(sp)
    80001808:	6145                	addi	sp,sp,48
    8000180a:	8082                	ret
  return 0;
    8000180c:	4501                	li	a0,0
    8000180e:	b7fd                	j	800017fc <pagecopy+0x94>

0000000080001810 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001810:	c679                	beqz	a2,800018de <uvmcopy+0xce>
{
    80001812:	715d                	addi	sp,sp,-80
    80001814:	e486                	sd	ra,72(sp)
    80001816:	e0a2                	sd	s0,64(sp)
    80001818:	fc26                	sd	s1,56(sp)
    8000181a:	f84a                	sd	s2,48(sp)
    8000181c:	f44e                	sd	s3,40(sp)
    8000181e:	f052                	sd	s4,32(sp)
    80001820:	ec56                	sd	s5,24(sp)
    80001822:	e85a                	sd	s6,16(sp)
    80001824:	e45e                	sd	s7,8(sp)
    80001826:	0880                	addi	s0,sp,80
    80001828:	8b2a                	mv	s6,a0
    8000182a:	8aae                	mv	s5,a1
    8000182c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000182e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001830:	4601                	li	a2,0
    80001832:	85ce                	mv	a1,s3
    80001834:	855a                	mv	a0,s6
    80001836:	00000097          	auipc	ra,0x0
    8000183a:	886080e7          	jalr	-1914(ra) # 800010bc <walk>
    8000183e:	c531                	beqz	a0,8000188a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001840:	6118                	ld	a4,0(a0)
    80001842:	00177793          	andi	a5,a4,1
    80001846:	cbb1                	beqz	a5,8000189a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001848:	00a75593          	srli	a1,a4,0xa
    8000184c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001850:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001854:	fffff097          	auipc	ra,0xfffff
    80001858:	32a080e7          	jalr	810(ra) # 80000b7e <kalloc>
    8000185c:	892a                	mv	s2,a0
    8000185e:	c939                	beqz	a0,800018b4 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001860:	6605                	lui	a2,0x1
    80001862:	85de                	mv	a1,s7
    80001864:	fffff097          	auipc	ra,0xfffff
    80001868:	5b0080e7          	jalr	1456(ra) # 80000e14 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000186c:	8726                	mv	a4,s1
    8000186e:	86ca                	mv	a3,s2
    80001870:	6605                	lui	a2,0x1
    80001872:	85ce                	mv	a1,s3
    80001874:	8556                	mv	a0,s5
    80001876:	00000097          	auipc	ra,0x0
    8000187a:	a04080e7          	jalr	-1532(ra) # 8000127a <mappages>
    8000187e:	e515                	bnez	a0,800018aa <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001880:	6785                	lui	a5,0x1
    80001882:	99be                	add	s3,s3,a5
    80001884:	fb49e6e3          	bltu	s3,s4,80001830 <uvmcopy+0x20>
    80001888:	a081                	j	800018c8 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000188a:	00007517          	auipc	a0,0x7
    8000188e:	93e50513          	addi	a0,a0,-1730 # 800081c8 <digits+0x178>
    80001892:	fffff097          	auipc	ra,0xfffff
    80001896:	d3e080e7          	jalr	-706(ra) # 800005d0 <panic>
      panic("uvmcopy: page not present");
    8000189a:	00007517          	auipc	a0,0x7
    8000189e:	94e50513          	addi	a0,a0,-1714 # 800081e8 <digits+0x198>
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	d2e080e7          	jalr	-722(ra) # 800005d0 <panic>
      kfree(mem);
    800018aa:	854a                	mv	a0,s2
    800018ac:	fffff097          	auipc	ra,0xfffff
    800018b0:	1d6080e7          	jalr	470(ra) # 80000a82 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800018b4:	4685                	li	a3,1
    800018b6:	00c9d613          	srli	a2,s3,0xc
    800018ba:	4581                	li	a1,0
    800018bc:	8556                	mv	a0,s5
    800018be:	00000097          	auipc	ra,0x0
    800018c2:	b54080e7          	jalr	-1196(ra) # 80001412 <uvmunmap>
  return -1;
    800018c6:	557d                	li	a0,-1
}
    800018c8:	60a6                	ld	ra,72(sp)
    800018ca:	6406                	ld	s0,64(sp)
    800018cc:	74e2                	ld	s1,56(sp)
    800018ce:	7942                	ld	s2,48(sp)
    800018d0:	79a2                	ld	s3,40(sp)
    800018d2:	7a02                	ld	s4,32(sp)
    800018d4:	6ae2                	ld	s5,24(sp)
    800018d6:	6b42                	ld	s6,16(sp)
    800018d8:	6ba2                	ld	s7,8(sp)
    800018da:	6161                	addi	sp,sp,80
    800018dc:	8082                	ret
  return 0;
    800018de:	4501                	li	a0,0
}
    800018e0:	8082                	ret

00000000800018e2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800018e2:	1141                	addi	sp,sp,-16
    800018e4:	e406                	sd	ra,8(sp)
    800018e6:	e022                	sd	s0,0(sp)
    800018e8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800018ea:	4601                	li	a2,0
    800018ec:	fffff097          	auipc	ra,0xfffff
    800018f0:	7d0080e7          	jalr	2000(ra) # 800010bc <walk>
  if(pte == 0)
    800018f4:	c901                	beqz	a0,80001904 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800018f6:	611c                	ld	a5,0(a0)
    800018f8:	9bbd                	andi	a5,a5,-17
    800018fa:	e11c                	sd	a5,0(a0)
}
    800018fc:	60a2                	ld	ra,8(sp)
    800018fe:	6402                	ld	s0,0(sp)
    80001900:	0141                	addi	sp,sp,16
    80001902:	8082                	ret
    panic("uvmclear");
    80001904:	00007517          	auipc	a0,0x7
    80001908:	90450513          	addi	a0,a0,-1788 # 80008208 <digits+0x1b8>
    8000190c:	fffff097          	auipc	ra,0xfffff
    80001910:	cc4080e7          	jalr	-828(ra) # 800005d0 <panic>

0000000080001914 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001914:	c6bd                	beqz	a3,80001982 <copyout+0x6e>
{
    80001916:	715d                	addi	sp,sp,-80
    80001918:	e486                	sd	ra,72(sp)
    8000191a:	e0a2                	sd	s0,64(sp)
    8000191c:	fc26                	sd	s1,56(sp)
    8000191e:	f84a                	sd	s2,48(sp)
    80001920:	f44e                	sd	s3,40(sp)
    80001922:	f052                	sd	s4,32(sp)
    80001924:	ec56                	sd	s5,24(sp)
    80001926:	e85a                	sd	s6,16(sp)
    80001928:	e45e                	sd	s7,8(sp)
    8000192a:	e062                	sd	s8,0(sp)
    8000192c:	0880                	addi	s0,sp,80
    8000192e:	8b2a                	mv	s6,a0
    80001930:	8c2e                	mv	s8,a1
    80001932:	8a32                	mv	s4,a2
    80001934:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001936:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001938:	6a85                	lui	s5,0x1
    8000193a:	a015                	j	8000195e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000193c:	9562                	add	a0,a0,s8
    8000193e:	0004861b          	sext.w	a2,s1
    80001942:	85d2                	mv	a1,s4
    80001944:	41250533          	sub	a0,a0,s2
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	4cc080e7          	jalr	1228(ra) # 80000e14 <memmove>

    len -= n;
    80001950:	409989b3          	sub	s3,s3,s1
    src += n;
    80001954:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001956:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000195a:	02098263          	beqz	s3,8000197e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000195e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001962:	85ca                	mv	a1,s2
    80001964:	855a                	mv	a0,s6
    80001966:	fffff097          	auipc	ra,0xfffff
    8000196a:	7fc080e7          	jalr	2044(ra) # 80001162 <walkaddr>
    if(pa0 == 0)
    8000196e:	cd01                	beqz	a0,80001986 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001970:	418904b3          	sub	s1,s2,s8
    80001974:	94d6                	add	s1,s1,s5
    if(n > len)
    80001976:	fc99f3e3          	bgeu	s3,s1,8000193c <copyout+0x28>
    8000197a:	84ce                	mv	s1,s3
    8000197c:	b7c1                	j	8000193c <copyout+0x28>
  }
  return 0;
    8000197e:	4501                	li	a0,0
    80001980:	a021                	j	80001988 <copyout+0x74>
    80001982:	4501                	li	a0,0
}
    80001984:	8082                	ret
      return -1;
    80001986:	557d                	li	a0,-1
}
    80001988:	60a6                	ld	ra,72(sp)
    8000198a:	6406                	ld	s0,64(sp)
    8000198c:	74e2                	ld	s1,56(sp)
    8000198e:	7942                	ld	s2,48(sp)
    80001990:	79a2                	ld	s3,40(sp)
    80001992:	7a02                	ld	s4,32(sp)
    80001994:	6ae2                	ld	s5,24(sp)
    80001996:	6b42                	ld	s6,16(sp)
    80001998:	6ba2                	ld	s7,8(sp)
    8000199a:	6c02                	ld	s8,0(sp)
    8000199c:	6161                	addi	sp,sp,80
    8000199e:	8082                	ret

00000000800019a0 <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800019a0:	1141                	addi	sp,sp,-16
    800019a2:	e406                	sd	ra,8(sp)
    800019a4:	e022                	sd	s0,0(sp)
    800019a6:	0800                	addi	s0,sp,16
  return copyin_new(pagetable, dst, srcva, len);
    800019a8:	00005097          	auipc	ra,0x5
    800019ac:	418080e7          	jalr	1048(ra) # 80006dc0 <copyin_new>
}
    800019b0:	60a2                	ld	ra,8(sp)
    800019b2:	6402                	ld	s0,0(sp)
    800019b4:	0141                	addi	sp,sp,16
    800019b6:	8082                	ret

00000000800019b8 <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800019b8:	1141                	addi	sp,sp,-16
    800019ba:	e406                	sd	ra,8(sp)
    800019bc:	e022                	sd	s0,0(sp)
    800019be:	0800                	addi	s0,sp,16
  return copyinstr_new(pagetable, dst, srcva, max);
    800019c0:	00005097          	auipc	ra,0x5
    800019c4:	468080e7          	jalr	1128(ra) # 80006e28 <copyinstr_new>
}
    800019c8:	60a2                	ld	ra,8(sp)
    800019ca:	6402                	ld	s0,0(sp)
    800019cc:	0141                	addi	sp,sp,16
    800019ce:	8082                	ret

00000000800019d0 <vmprint_helper>:

// Recursive helper
void vmprint_helper(pagetable_t pagetable, int depth) {
    800019d0:	715d                	addi	sp,sp,-80
    800019d2:	e486                	sd	ra,72(sp)
    800019d4:	e0a2                	sd	s0,64(sp)
    800019d6:	fc26                	sd	s1,56(sp)
    800019d8:	f84a                	sd	s2,48(sp)
    800019da:	f44e                	sd	s3,40(sp)
    800019dc:	f052                	sd	s4,32(sp)
    800019de:	ec56                	sd	s5,24(sp)
    800019e0:	e85a                	sd	s6,16(sp)
    800019e2:	e45e                	sd	s7,8(sp)
    800019e4:	e062                	sd	s8,0(sp)
    800019e6:	0880                	addi	s0,sp,80
      "",
      "..",
      ".. ..",
      ".. .. .."
  };
  if (depth <= 0 || depth >= 4) {
    800019e8:	fff5871b          	addiw	a4,a1,-1
    800019ec:	4789                	li	a5,2
    800019ee:	02e7e463          	bltu	a5,a4,80001a16 <vmprint_helper+0x46>
    800019f2:	89aa                	mv	s3,a0
    800019f4:	4901                	li	s2,0
  }
  // there are 2^9 = 512 PTES in a page table.
  for (int i = 0; i < 512; i++) {
    pte_t pte = pagetable[i];
    if (pte & PTE_V) {
      printf("%s%d: pte %p pa %p\n", indent[depth], i, pte, PTE2PA(pte));
    800019f6:	00359793          	slli	a5,a1,0x3
    800019fa:	00007b17          	auipc	s6,0x7
    800019fe:	8c6b0b13          	addi	s6,s6,-1850 # 800082c0 <indent.1832>
    80001a02:	9b3e                	add	s6,s6,a5
    80001a04:	00007b97          	auipc	s7,0x7
    80001a08:	83cb8b93          	addi	s7,s7,-1988 # 80008240 <digits+0x1f0>
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
        // points to a lower-level page table
        uint64 child = PTE2PA(pte);
        vmprint_helper((pagetable_t)child, depth+1);
    80001a0c:	00158c1b          	addiw	s8,a1,1
  for (int i = 0; i < 512; i++) {
    80001a10:	20000a93          	li	s5,512
    80001a14:	a01d                	j	80001a3a <vmprint_helper+0x6a>
    panic("vmprint_helper: depth not in {1, 2, 3}");
    80001a16:	00007517          	auipc	a0,0x7
    80001a1a:	80250513          	addi	a0,a0,-2046 # 80008218 <digits+0x1c8>
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	bb2080e7          	jalr	-1102(ra) # 800005d0 <panic>
        vmprint_helper((pagetable_t)child, depth+1);
    80001a26:	85e2                	mv	a1,s8
    80001a28:	8552                	mv	a0,s4
    80001a2a:	00000097          	auipc	ra,0x0
    80001a2e:	fa6080e7          	jalr	-90(ra) # 800019d0 <vmprint_helper>
  for (int i = 0; i < 512; i++) {
    80001a32:	2905                	addiw	s2,s2,1
    80001a34:	09a1                	addi	s3,s3,8
    80001a36:	03590763          	beq	s2,s5,80001a64 <vmprint_helper+0x94>
    pte_t pte = pagetable[i];
    80001a3a:	0009b483          	ld	s1,0(s3) # 1000 <_entry-0x7ffff000>
    if (pte & PTE_V) {
    80001a3e:	0014f793          	andi	a5,s1,1
    80001a42:	dbe5                	beqz	a5,80001a32 <vmprint_helper+0x62>
      printf("%s%d: pte %p pa %p\n", indent[depth], i, pte, PTE2PA(pte));
    80001a44:	00a4da13          	srli	s4,s1,0xa
    80001a48:	0a32                	slli	s4,s4,0xc
    80001a4a:	8752                	mv	a4,s4
    80001a4c:	86a6                	mv	a3,s1
    80001a4e:	864a                	mv	a2,s2
    80001a50:	000b3583          	ld	a1,0(s6)
    80001a54:	855e                	mv	a0,s7
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	bcc080e7          	jalr	-1076(ra) # 80000622 <printf>
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    80001a5e:	88b9                	andi	s1,s1,14
    80001a60:	f8e9                	bnez	s1,80001a32 <vmprint_helper+0x62>
    80001a62:	b7d1                	j	80001a26 <vmprint_helper+0x56>
      }
    }
  }
}
    80001a64:	60a6                	ld	ra,72(sp)
    80001a66:	6406                	ld	s0,64(sp)
    80001a68:	74e2                	ld	s1,56(sp)
    80001a6a:	7942                	ld	s2,48(sp)
    80001a6c:	79a2                	ld	s3,40(sp)
    80001a6e:	7a02                	ld	s4,32(sp)
    80001a70:	6ae2                	ld	s5,24(sp)
    80001a72:	6b42                	ld	s6,16(sp)
    80001a74:	6ba2                	ld	s7,8(sp)
    80001a76:	6c02                	ld	s8,0(sp)
    80001a78:	6161                	addi	sp,sp,80
    80001a7a:	8082                	ret

0000000080001a7c <vmprint>:

// Utility func to print the valid
// PTEs within a page table recursively
void vmprint(pagetable_t pagetable) {
    80001a7c:	1101                	addi	sp,sp,-32
    80001a7e:	ec06                	sd	ra,24(sp)
    80001a80:	e822                	sd	s0,16(sp)
    80001a82:	e426                	sd	s1,8(sp)
    80001a84:	1000                	addi	s0,sp,32
    80001a86:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    80001a88:	85aa                	mv	a1,a0
    80001a8a:	00006517          	auipc	a0,0x6
    80001a8e:	7ce50513          	addi	a0,a0,1998 # 80008258 <digits+0x208>
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	b90080e7          	jalr	-1136(ra) # 80000622 <printf>
  vmprint_helper(pagetable, 1);
    80001a9a:	4585                	li	a1,1
    80001a9c:	8526                	mv	a0,s1
    80001a9e:	00000097          	auipc	ra,0x0
    80001aa2:	f32080e7          	jalr	-206(ra) # 800019d0 <vmprint_helper>
}
    80001aa6:	60e2                	ld	ra,24(sp)
    80001aa8:	6442                	ld	s0,16(sp)
    80001aaa:	64a2                	ld	s1,8(sp)
    80001aac:	6105                	addi	sp,sp,32
    80001aae:	8082                	ret

0000000080001ab0 <ukvmmap>:

// add a mapping to the per-process kernel page table.
void
ukvmmap(pagetable_t kpagetable, uint64 va, uint64 pa, uint64 sz, int perm)
{
    80001ab0:	1141                	addi	sp,sp,-16
    80001ab2:	e406                	sd	ra,8(sp)
    80001ab4:	e022                	sd	s0,0(sp)
    80001ab6:	0800                	addi	s0,sp,16
    80001ab8:	87b6                	mv	a5,a3
  if(mappages(kpagetable, va, sz, pa, perm) != 0)
    80001aba:	86b2                	mv	a3,a2
    80001abc:	863e                	mv	a2,a5
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	7bc080e7          	jalr	1980(ra) # 8000127a <mappages>
    80001ac6:	e509                	bnez	a0,80001ad0 <ukvmmap+0x20>
    panic("ukvmmap");
}
    80001ac8:	60a2                	ld	ra,8(sp)
    80001aca:	6402                	ld	s0,0(sp)
    80001acc:	0141                	addi	sp,sp,16
    80001ace:	8082                	ret
    panic("ukvmmap");
    80001ad0:	00006517          	auipc	a0,0x6
    80001ad4:	79850513          	addi	a0,a0,1944 # 80008268 <digits+0x218>
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	af8080e7          	jalr	-1288(ra) # 800005d0 <panic>

0000000080001ae0 <ukvminit>:
 * create a direct-map page table for the per-process kernel page table.
 * return nullptr when kalloc fails
 */
pagetable_t
ukvminit()
{
    80001ae0:	1101                	addi	sp,sp,-32
    80001ae2:	ec06                	sd	ra,24(sp)
    80001ae4:	e822                	sd	s0,16(sp)
    80001ae6:	e426                	sd	s1,8(sp)
    80001ae8:	e04a                	sd	s2,0(sp)
    80001aea:	1000                	addi	s0,sp,32
  pagetable_t kpagetable = (pagetable_t) kalloc();
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	092080e7          	jalr	146(ra) # 80000b7e <kalloc>
    80001af4:	84aa                	mv	s1,a0
  if (kpagetable == 0) {
    80001af6:	c161                	beqz	a0,80001bb6 <ukvminit+0xd6>
    return kpagetable;
  }

  memset(kpagetable, 0, PGSIZE);
    80001af8:	6605                	lui	a2,0x1
    80001afa:	4581                	li	a1,0
    80001afc:	fffff097          	auipc	ra,0xfffff
    80001b00:	2b8080e7          	jalr	696(ra) # 80000db4 <memset>

  // uart registers
  ukvmmap(kpagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001b04:	4719                	li	a4,6
    80001b06:	6685                	lui	a3,0x1
    80001b08:	10000637          	lui	a2,0x10000
    80001b0c:	100005b7          	lui	a1,0x10000
    80001b10:	8526                	mv	a0,s1
    80001b12:	00000097          	auipc	ra,0x0
    80001b16:	f9e080e7          	jalr	-98(ra) # 80001ab0 <ukvmmap>

  // virtio mmio disk interface
  ukvmmap(kpagetable, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001b1a:	4719                	li	a4,6
    80001b1c:	6685                	lui	a3,0x1
    80001b1e:	10001637          	lui	a2,0x10001
    80001b22:	100015b7          	lui	a1,0x10001
    80001b26:	8526                	mv	a0,s1
    80001b28:	00000097          	auipc	ra,0x0
    80001b2c:	f88080e7          	jalr	-120(ra) # 80001ab0 <ukvmmap>

  // CLINT
  ukvmmap(kpagetable, CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001b30:	4719                	li	a4,6
    80001b32:	66c1                	lui	a3,0x10
    80001b34:	02000637          	lui	a2,0x2000
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	00000097          	auipc	ra,0x0
    80001b42:	f72080e7          	jalr	-142(ra) # 80001ab0 <ukvmmap>

  // PLIC
  ukvmmap(kpagetable, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001b46:	4719                	li	a4,6
    80001b48:	004006b7          	lui	a3,0x400
    80001b4c:	0c000637          	lui	a2,0xc000
    80001b50:	0c0005b7          	lui	a1,0xc000
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	f5a080e7          	jalr	-166(ra) # 80001ab0 <ukvmmap>

  // map kernel text executable and read-only.
  ukvmmap(kpagetable, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001b5e:	00006917          	auipc	s2,0x6
    80001b62:	4a290913          	addi	s2,s2,1186 # 80008000 <etext>
    80001b66:	4729                	li	a4,10
    80001b68:	80006697          	auipc	a3,0x80006
    80001b6c:	49868693          	addi	a3,a3,1176 # 8000 <_entry-0x7fff8000>
    80001b70:	4605                	li	a2,1
    80001b72:	067e                	slli	a2,a2,0x1f
    80001b74:	85b2                	mv	a1,a2
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	f38080e7          	jalr	-200(ra) # 80001ab0 <ukvmmap>

  // map kernel data and the physical RAM we'll make use of.
  ukvmmap(kpagetable, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001b80:	4719                	li	a4,6
    80001b82:	46c5                	li	a3,17
    80001b84:	06ee                	slli	a3,a3,0x1b
    80001b86:	412686b3          	sub	a3,a3,s2
    80001b8a:	864a                	mv	a2,s2
    80001b8c:	85ca                	mv	a1,s2
    80001b8e:	8526                	mv	a0,s1
    80001b90:	00000097          	auipc	ra,0x0
    80001b94:	f20080e7          	jalr	-224(ra) # 80001ab0 <ukvmmap>

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  ukvmmap(kpagetable, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001b98:	4729                	li	a4,10
    80001b9a:	6685                	lui	a3,0x1
    80001b9c:	00005617          	auipc	a2,0x5
    80001ba0:	46460613          	addi	a2,a2,1124 # 80007000 <_trampoline>
    80001ba4:	040005b7          	lui	a1,0x4000
    80001ba8:	15fd                	addi	a1,a1,-1
    80001baa:	05b2                	slli	a1,a1,0xc
    80001bac:	8526                	mv	a0,s1
    80001bae:	00000097          	auipc	ra,0x0
    80001bb2:	f02080e7          	jalr	-254(ra) # 80001ab0 <ukvmmap>

  return kpagetable;
}
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	60e2                	ld	ra,24(sp)
    80001bba:	6442                	ld	s0,16(sp)
    80001bbc:	64a2                	ld	s1,8(sp)
    80001bbe:	6902                	ld	s2,0(sp)
    80001bc0:	6105                	addi	sp,sp,32
    80001bc2:	8082                	ret

0000000080001bc4 <ukvmunmap>:
// Unmap the leaf node mapping
// of the per-process kernel page table
// so that we could call freewalk on that
void
ukvmunmap(pagetable_t pagetable, uint64 va, uint64 npages)
{
    80001bc4:	7139                	addi	sp,sp,-64
    80001bc6:	fc06                	sd	ra,56(sp)
    80001bc8:	f822                	sd	s0,48(sp)
    80001bca:	f426                	sd	s1,40(sp)
    80001bcc:	f04a                	sd	s2,32(sp)
    80001bce:	ec4e                	sd	s3,24(sp)
    80001bd0:	e852                	sd	s4,16(sp)
    80001bd2:	e456                	sd	s5,8(sp)
    80001bd4:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001bd6:	03459793          	slli	a5,a1,0x34
    80001bda:	e39d                	bnez	a5,80001c00 <ukvmunmap+0x3c>
    80001bdc:	89aa                	mv	s3,a0
    80001bde:	84ae                	mv	s1,a1
    panic("ukvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001be0:	00c61913          	slli	s2,a2,0xc
    80001be4:	992e                	add	s2,s2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      goto clean;
    if((*pte & PTE_V) == 0)
      goto clean;
    if(PTE_FLAGS(*pte) == PTE_V)
    80001be6:	4a85                	li	s5,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001be8:	6a05                	lui	s4,0x1
    80001bea:	0325e863          	bltu	a1,s2,80001c1a <ukvmunmap+0x56>
      panic("ukvmunmap: not a leaf");

    clean:
      *pte = 0;
  }
}
    80001bee:	70e2                	ld	ra,56(sp)
    80001bf0:	7442                	ld	s0,48(sp)
    80001bf2:	74a2                	ld	s1,40(sp)
    80001bf4:	7902                	ld	s2,32(sp)
    80001bf6:	69e2                	ld	s3,24(sp)
    80001bf8:	6a42                	ld	s4,16(sp)
    80001bfa:	6aa2                	ld	s5,8(sp)
    80001bfc:	6121                	addi	sp,sp,64
    80001bfe:	8082                	ret
    panic("ukvmunmap: not aligned");
    80001c00:	00006517          	auipc	a0,0x6
    80001c04:	67050513          	addi	a0,a0,1648 # 80008270 <digits+0x220>
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	9c8080e7          	jalr	-1592(ra) # 800005d0 <panic>
      *pte = 0;
    80001c10:	00053023          	sd	zero,0(a0)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001c14:	94d2                	add	s1,s1,s4
    80001c16:	fd24fce3          	bgeu	s1,s2,80001bee <ukvmunmap+0x2a>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001c1a:	4601                	li	a2,0
    80001c1c:	85a6                	mv	a1,s1
    80001c1e:	854e                	mv	a0,s3
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	49c080e7          	jalr	1180(ra) # 800010bc <walk>
    80001c28:	d565                	beqz	a0,80001c10 <ukvmunmap+0x4c>
    if((*pte & PTE_V) == 0)
    80001c2a:	611c                	ld	a5,0(a0)
    80001c2c:	0017f713          	andi	a4,a5,1
    80001c30:	d365                	beqz	a4,80001c10 <ukvmunmap+0x4c>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001c32:	3ff7f793          	andi	a5,a5,1023
    80001c36:	fd579de3          	bne	a5,s5,80001c10 <ukvmunmap+0x4c>
      panic("ukvmunmap: not a leaf");
    80001c3a:	00006517          	auipc	a0,0x6
    80001c3e:	64e50513          	addi	a0,a0,1614 # 80008288 <digits+0x238>
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	98e080e7          	jalr	-1650(ra) # 800005d0 <panic>

0000000080001c4a <freeprockvm>:

// helper function to first free all leaf mapping
// of a per-process kernel table but do not free the physical address
// and then remove all 3-levels indirection and the physical address
// for this kernel page itself
void freeprockvm(struct proc* p) {
    80001c4a:	1101                	addi	sp,sp,-32
    80001c4c:	ec06                	sd	ra,24(sp)
    80001c4e:	e822                	sd	s0,16(sp)
    80001c50:	e426                	sd	s1,8(sp)
    80001c52:	1000                	addi	s0,sp,32
  pagetable_t kpagetable = p->kpagetable;
    80001c54:	17853483          	ld	s1,376(a0)
  // reverse order of allocation
  ukvmunmap(kpagetable, p->kstack, PGSIZE/PGSIZE);
    80001c58:	4605                	li	a2,1
    80001c5a:	612c                	ld	a1,64(a0)
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	00000097          	auipc	ra,0x0
    80001c62:	f66080e7          	jalr	-154(ra) # 80001bc4 <ukvmunmap>
  ukvmunmap(kpagetable, TRAMPOLINE, PGSIZE/PGSIZE);
    80001c66:	4605                	li	a2,1
    80001c68:	040005b7          	lui	a1,0x4000
    80001c6c:	15fd                	addi	a1,a1,-1
    80001c6e:	05b2                	slli	a1,a1,0xc
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	f52080e7          	jalr	-174(ra) # 80001bc4 <ukvmunmap>
  ukvmunmap(kpagetable, (uint64)etext, (PHYSTOP-(uint64)etext)/PGSIZE);
    80001c7a:	00006597          	auipc	a1,0x6
    80001c7e:	38658593          	addi	a1,a1,902 # 80008000 <etext>
    80001c82:	4645                	li	a2,17
    80001c84:	066e                	slli	a2,a2,0x1b
    80001c86:	8e0d                	sub	a2,a2,a1
    80001c88:	8231                	srli	a2,a2,0xc
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	f38080e7          	jalr	-200(ra) # 80001bc4 <ukvmunmap>
  ukvmunmap(kpagetable, KERNBASE, ((uint64)etext-KERNBASE)/PGSIZE);
    80001c94:	80006617          	auipc	a2,0x80006
    80001c98:	36c60613          	addi	a2,a2,876 # 8000 <_entry-0x7fff8000>
    80001c9c:	8231                	srli	a2,a2,0xc
    80001c9e:	4585                	li	a1,1
    80001ca0:	05fe                	slli	a1,a1,0x1f
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	f20080e7          	jalr	-224(ra) # 80001bc4 <ukvmunmap>
  ukvmunmap(kpagetable, PLIC, 0x400000/PGSIZE);
    80001cac:	40000613          	li	a2,1024
    80001cb0:	0c0005b7          	lui	a1,0xc000
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	f0e080e7          	jalr	-242(ra) # 80001bc4 <ukvmunmap>
  ukvmunmap(kpagetable, CLINT, 0x10000/PGSIZE);
    80001cbe:	4641                	li	a2,16
    80001cc0:	020005b7          	lui	a1,0x2000
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	efe080e7          	jalr	-258(ra) # 80001bc4 <ukvmunmap>
  ukvmunmap(kpagetable, VIRTIO0, PGSIZE/PGSIZE);
    80001cce:	4605                	li	a2,1
    80001cd0:	100015b7          	lui	a1,0x10001
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	eee080e7          	jalr	-274(ra) # 80001bc4 <ukvmunmap>
  ukvmunmap(kpagetable, UART0, PGSIZE/PGSIZE);
    80001cde:	4605                	li	a2,1
    80001ce0:	100005b7          	lui	a1,0x10000
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	00000097          	auipc	ra,0x0
    80001cea:	ede080e7          	jalr	-290(ra) # 80001bc4 <ukvmunmap>
  ufreewalk(kpagetable);
    80001cee:	8526                	mv	a0,s1
    80001cf0:	00000097          	auipc	ra,0x0
    80001cf4:	978080e7          	jalr	-1672(ra) # 80001668 <ufreewalk>
}
    80001cf8:	60e2                	ld	ra,24(sp)
    80001cfa:	6442                	ld	s0,16(sp)
    80001cfc:	64a2                	ld	s1,8(sp)
    80001cfe:	6105                	addi	sp,sp,32
    80001d00:	8082                	ret

0000000080001d02 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001d02:	1101                	addi	sp,sp,-32
    80001d04:	ec06                	sd	ra,24(sp)
    80001d06:	e822                	sd	s0,16(sp)
    80001d08:	e426                	sd	s1,8(sp)
    80001d0a:	1000                	addi	s0,sp,32
    80001d0c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	f30080e7          	jalr	-208(ra) # 80000c3e <holding>
    80001d16:	c909                	beqz	a0,80001d28 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001d18:	749c                	ld	a5,40(s1)
    80001d1a:	00978f63          	beq	a5,s1,80001d38 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001d1e:	60e2                	ld	ra,24(sp)
    80001d20:	6442                	ld	s0,16(sp)
    80001d22:	64a2                	ld	s1,8(sp)
    80001d24:	6105                	addi	sp,sp,32
    80001d26:	8082                	ret
    panic("wakeup1");
    80001d28:	00006517          	auipc	a0,0x6
    80001d2c:	5b850513          	addi	a0,a0,1464 # 800082e0 <indent.1832+0x20>
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	8a0080e7          	jalr	-1888(ra) # 800005d0 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001d38:	4c98                	lw	a4,24(s1)
    80001d3a:	4785                	li	a5,1
    80001d3c:	fef711e3          	bne	a4,a5,80001d1e <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001d40:	4789                	li	a5,2
    80001d42:	cc9c                	sw	a5,24(s1)
}
    80001d44:	bfe9                	j	80001d1e <wakeup1+0x1c>

0000000080001d46 <procinit>:
{
    80001d46:	715d                	addi	sp,sp,-80
    80001d48:	e486                	sd	ra,72(sp)
    80001d4a:	e0a2                	sd	s0,64(sp)
    80001d4c:	fc26                	sd	s1,56(sp)
    80001d4e:	f84a                	sd	s2,48(sp)
    80001d50:	f44e                	sd	s3,40(sp)
    80001d52:	f052                	sd	s4,32(sp)
    80001d54:	ec56                	sd	s5,24(sp)
    80001d56:	e85a                	sd	s6,16(sp)
    80001d58:	e45e                	sd	s7,8(sp)
    80001d5a:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001d5c:	00006597          	auipc	a1,0x6
    80001d60:	58c58593          	addi	a1,a1,1420 # 800082e8 <indent.1832+0x28>
    80001d64:	00010517          	auipc	a0,0x10
    80001d68:	bec50513          	addi	a0,a0,-1044 # 80011950 <pid_lock>
    80001d6c:	fffff097          	auipc	ra,0xfffff
    80001d70:	ebc080e7          	jalr	-324(ra) # 80000c28 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d74:	00010917          	auipc	s2,0x10
    80001d78:	ff490913          	addi	s2,s2,-12 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001d7c:	00006b97          	auipc	s7,0x6
    80001d80:	574b8b93          	addi	s7,s7,1396 # 800082f0 <indent.1832+0x30>
      uint64 va = KSTACK((int) (p - proc));
    80001d84:	8b4a                	mv	s6,s2
    80001d86:	00006a97          	auipc	s5,0x6
    80001d8a:	27aa8a93          	addi	s5,s5,634 # 80008000 <etext>
    80001d8e:	040009b7          	lui	s3,0x4000
    80001d92:	19fd                	addi	s3,s3,-1
    80001d94:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d96:	00016a17          	auipc	s4,0x16
    80001d9a:	5d2a0a13          	addi	s4,s4,1490 # 80018368 <tickslock>
      initlock(&p->lock, "proc");
    80001d9e:	85de                	mv	a1,s7
    80001da0:	854a                	mv	a0,s2
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	e86080e7          	jalr	-378(ra) # 80000c28 <initlock>
      char *pa = kalloc();
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	dd4080e7          	jalr	-556(ra) # 80000b7e <kalloc>
    80001db2:	85aa                	mv	a1,a0
      if(pa == 0)
    80001db4:	c929                	beqz	a0,80001e06 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001db6:	416904b3          	sub	s1,s2,s6
    80001dba:	848d                	srai	s1,s1,0x3
    80001dbc:	000ab783          	ld	a5,0(s5)
    80001dc0:	02f484b3          	mul	s1,s1,a5
    80001dc4:	2485                	addiw	s1,s1,1
    80001dc6:	00d4949b          	slliw	s1,s1,0xd
    80001dca:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001dce:	4699                	li	a3,6
    80001dd0:	6605                	lui	a2,0x1
    80001dd2:	8526                	mv	a0,s1
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	534080e7          	jalr	1332(ra) # 80001308 <kvmmap>
      p->kstack = va;
    80001ddc:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de0:	19890913          	addi	s2,s2,408
    80001de4:	fb491de3          	bne	s2,s4,80001d9e <procinit+0x58>
  kvminithart();
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	2b0080e7          	jalr	688(ra) # 80001098 <kvminithart>
}
    80001df0:	60a6                	ld	ra,72(sp)
    80001df2:	6406                	ld	s0,64(sp)
    80001df4:	74e2                	ld	s1,56(sp)
    80001df6:	7942                	ld	s2,48(sp)
    80001df8:	79a2                	ld	s3,40(sp)
    80001dfa:	7a02                	ld	s4,32(sp)
    80001dfc:	6ae2                	ld	s5,24(sp)
    80001dfe:	6b42                	ld	s6,16(sp)
    80001e00:	6ba2                	ld	s7,8(sp)
    80001e02:	6161                	addi	sp,sp,80
    80001e04:	8082                	ret
        panic("kalloc");
    80001e06:	00006517          	auipc	a0,0x6
    80001e0a:	4f250513          	addi	a0,a0,1266 # 800082f8 <indent.1832+0x38>
    80001e0e:	ffffe097          	auipc	ra,0xffffe
    80001e12:	7c2080e7          	jalr	1986(ra) # 800005d0 <panic>

0000000080001e16 <cpuid>:
{
    80001e16:	1141                	addi	sp,sp,-16
    80001e18:	e422                	sd	s0,8(sp)
    80001e1a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e1c:	8512                	mv	a0,tp
}
    80001e1e:	2501                	sext.w	a0,a0
    80001e20:	6422                	ld	s0,8(sp)
    80001e22:	0141                	addi	sp,sp,16
    80001e24:	8082                	ret

0000000080001e26 <mycpu>:
mycpu(void) {
    80001e26:	1141                	addi	sp,sp,-16
    80001e28:	e422                	sd	s0,8(sp)
    80001e2a:	0800                	addi	s0,sp,16
    80001e2c:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001e2e:	2781                	sext.w	a5,a5
    80001e30:	079e                	slli	a5,a5,0x7
}
    80001e32:	00010517          	auipc	a0,0x10
    80001e36:	b3650513          	addi	a0,a0,-1226 # 80011968 <cpus>
    80001e3a:	953e                	add	a0,a0,a5
    80001e3c:	6422                	ld	s0,8(sp)
    80001e3e:	0141                	addi	sp,sp,16
    80001e40:	8082                	ret

0000000080001e42 <myproc>:
myproc(void) {
    80001e42:	1101                	addi	sp,sp,-32
    80001e44:	ec06                	sd	ra,24(sp)
    80001e46:	e822                	sd	s0,16(sp)
    80001e48:	e426                	sd	s1,8(sp)
    80001e4a:	1000                	addi	s0,sp,32
  push_off();
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	e20080e7          	jalr	-480(ra) # 80000c6c <push_off>
    80001e54:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001e56:	2781                	sext.w	a5,a5
    80001e58:	079e                	slli	a5,a5,0x7
    80001e5a:	00010717          	auipc	a4,0x10
    80001e5e:	af670713          	addi	a4,a4,-1290 # 80011950 <pid_lock>
    80001e62:	97ba                	add	a5,a5,a4
    80001e64:	6f84                	ld	s1,24(a5)
  pop_off();
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	ea6080e7          	jalr	-346(ra) # 80000d0c <pop_off>
}
    80001e6e:	8526                	mv	a0,s1
    80001e70:	60e2                	ld	ra,24(sp)
    80001e72:	6442                	ld	s0,16(sp)
    80001e74:	64a2                	ld	s1,8(sp)
    80001e76:	6105                	addi	sp,sp,32
    80001e78:	8082                	ret

0000000080001e7a <forkret>:
{
    80001e7a:	1141                	addi	sp,sp,-16
    80001e7c:	e406                	sd	ra,8(sp)
    80001e7e:	e022                	sd	s0,0(sp)
    80001e80:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	fc0080e7          	jalr	-64(ra) # 80001e42 <myproc>
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	ee2080e7          	jalr	-286(ra) # 80000d6c <release>
  if (first) {
    80001e92:	00007797          	auipc	a5,0x7
    80001e96:	c9e7a783          	lw	a5,-866(a5) # 80008b30 <first.1735>
    80001e9a:	eb89                	bnez	a5,80001eac <forkret+0x32>
  usertrapret();
    80001e9c:	00001097          	auipc	ra,0x1
    80001ea0:	e40080e7          	jalr	-448(ra) # 80002cdc <usertrapret>
}
    80001ea4:	60a2                	ld	ra,8(sp)
    80001ea6:	6402                	ld	s0,0(sp)
    80001ea8:	0141                	addi	sp,sp,16
    80001eaa:	8082                	ret
    first = 0;
    80001eac:	00007797          	auipc	a5,0x7
    80001eb0:	c807a223          	sw	zero,-892(a5) # 80008b30 <first.1735>
    fsinit(ROOTDEV);
    80001eb4:	4505                	li	a0,1
    80001eb6:	00002097          	auipc	ra,0x2
    80001eba:	d60080e7          	jalr	-672(ra) # 80003c16 <fsinit>
    80001ebe:	bff9                	j	80001e9c <forkret+0x22>

0000000080001ec0 <allocpid>:
allocpid() {
    80001ec0:	1101                	addi	sp,sp,-32
    80001ec2:	ec06                	sd	ra,24(sp)
    80001ec4:	e822                	sd	s0,16(sp)
    80001ec6:	e426                	sd	s1,8(sp)
    80001ec8:	e04a                	sd	s2,0(sp)
    80001eca:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ecc:	00010917          	auipc	s2,0x10
    80001ed0:	a8490913          	addi	s2,s2,-1404 # 80011950 <pid_lock>
    80001ed4:	854a                	mv	a0,s2
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	de2080e7          	jalr	-542(ra) # 80000cb8 <acquire>
  pid = nextpid;
    80001ede:	00007797          	auipc	a5,0x7
    80001ee2:	c5678793          	addi	a5,a5,-938 # 80008b34 <nextpid>
    80001ee6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ee8:	0014871b          	addiw	a4,s1,1
    80001eec:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001eee:	854a                	mv	a0,s2
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	e7c080e7          	jalr	-388(ra) # 80000d6c <release>
}
    80001ef8:	8526                	mv	a0,s1
    80001efa:	60e2                	ld	ra,24(sp)
    80001efc:	6442                	ld	s0,16(sp)
    80001efe:	64a2                	ld	s1,8(sp)
    80001f00:	6902                	ld	s2,0(sp)
    80001f02:	6105                	addi	sp,sp,32
    80001f04:	8082                	ret

0000000080001f06 <proc_pagetable>:
{
    80001f06:	1101                	addi	sp,sp,-32
    80001f08:	ec06                	sd	ra,24(sp)
    80001f0a:	e822                	sd	s0,16(sp)
    80001f0c:	e426                	sd	s1,8(sp)
    80001f0e:	e04a                	sd	s2,0(sp)
    80001f10:	1000                	addi	s0,sp,32
    80001f12:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	5c2080e7          	jalr	1474(ra) # 800014d6 <uvmcreate>
    80001f1c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001f1e:	c121                	beqz	a0,80001f5e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f20:	4729                	li	a4,10
    80001f22:	00005697          	auipc	a3,0x5
    80001f26:	0de68693          	addi	a3,a3,222 # 80007000 <_trampoline>
    80001f2a:	6605                	lui	a2,0x1
    80001f2c:	040005b7          	lui	a1,0x4000
    80001f30:	15fd                	addi	a1,a1,-1
    80001f32:	05b2                	slli	a1,a1,0xc
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	346080e7          	jalr	838(ra) # 8000127a <mappages>
    80001f3c:	02054863          	bltz	a0,80001f6c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f40:	4719                	li	a4,6
    80001f42:	05893683          	ld	a3,88(s2)
    80001f46:	6605                	lui	a2,0x1
    80001f48:	020005b7          	lui	a1,0x2000
    80001f4c:	15fd                	addi	a1,a1,-1
    80001f4e:	05b6                	slli	a1,a1,0xd
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	328080e7          	jalr	808(ra) # 8000127a <mappages>
    80001f5a:	02054163          	bltz	a0,80001f7c <proc_pagetable+0x76>
}
    80001f5e:	8526                	mv	a0,s1
    80001f60:	60e2                	ld	ra,24(sp)
    80001f62:	6442                	ld	s0,16(sp)
    80001f64:	64a2                	ld	s1,8(sp)
    80001f66:	6902                	ld	s2,0(sp)
    80001f68:	6105                	addi	sp,sp,32
    80001f6a:	8082                	ret
    uvmfree(pagetable, 0);
    80001f6c:	4581                	li	a1,0
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	7c0080e7          	jalr	1984(ra) # 80001730 <uvmfree>
    return 0;
    80001f78:	4481                	li	s1,0
    80001f7a:	b7d5                	j	80001f5e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f7c:	4681                	li	a3,0
    80001f7e:	4605                	li	a2,1
    80001f80:	040005b7          	lui	a1,0x4000
    80001f84:	15fd                	addi	a1,a1,-1
    80001f86:	05b2                	slli	a1,a1,0xc
    80001f88:	8526                	mv	a0,s1
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	488080e7          	jalr	1160(ra) # 80001412 <uvmunmap>
    uvmfree(pagetable, 0);
    80001f92:	4581                	li	a1,0
    80001f94:	8526                	mv	a0,s1
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	79a080e7          	jalr	1946(ra) # 80001730 <uvmfree>
    return 0;
    80001f9e:	4481                	li	s1,0
    80001fa0:	bf7d                	j	80001f5e <proc_pagetable+0x58>

0000000080001fa2 <proc_freepagetable>:
{
    80001fa2:	1101                	addi	sp,sp,-32
    80001fa4:	ec06                	sd	ra,24(sp)
    80001fa6:	e822                	sd	s0,16(sp)
    80001fa8:	e426                	sd	s1,8(sp)
    80001faa:	e04a                	sd	s2,0(sp)
    80001fac:	1000                	addi	s0,sp,32
    80001fae:	84aa                	mv	s1,a0
    80001fb0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001fb2:	4681                	li	a3,0
    80001fb4:	4605                	li	a2,1
    80001fb6:	040005b7          	lui	a1,0x4000
    80001fba:	15fd                	addi	a1,a1,-1
    80001fbc:	05b2                	slli	a1,a1,0xc
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	454080e7          	jalr	1108(ra) # 80001412 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001fc6:	4681                	li	a3,0
    80001fc8:	4605                	li	a2,1
    80001fca:	020005b7          	lui	a1,0x2000
    80001fce:	15fd                	addi	a1,a1,-1
    80001fd0:	05b6                	slli	a1,a1,0xd
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	43e080e7          	jalr	1086(ra) # 80001412 <uvmunmap>
  uvmfree(pagetable, sz);
    80001fdc:	85ca                	mv	a1,s2
    80001fde:	8526                	mv	a0,s1
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	750080e7          	jalr	1872(ra) # 80001730 <uvmfree>
}
    80001fe8:	60e2                	ld	ra,24(sp)
    80001fea:	6442                	ld	s0,16(sp)
    80001fec:	64a2                	ld	s1,8(sp)
    80001fee:	6902                	ld	s2,0(sp)
    80001ff0:	6105                	addi	sp,sp,32
    80001ff2:	8082                	ret

0000000080001ff4 <freeproc>:
{
    80001ff4:	1101                	addi	sp,sp,-32
    80001ff6:	ec06                	sd	ra,24(sp)
    80001ff8:	e822                	sd	s0,16(sp)
    80001ffa:	e426                	sd	s1,8(sp)
    80001ffc:	1000                	addi	s0,sp,32
    80001ffe:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002000:	6d28                	ld	a0,88(a0)
    80002002:	c509                	beqz	a0,8000200c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	a7e080e7          	jalr	-1410(ra) # 80000a82 <kfree>
  p->trapframe = 0;
    8000200c:	0404bc23          	sd	zero,88(s1) # fffffffffffff058 <end+0xffffffff7ffd7038>
  if(p->pagetable)
    80002010:	68a8                	ld	a0,80(s1)
    80002012:	c511                	beqz	a0,8000201e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002014:	64ac                	ld	a1,72(s1)
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	f8c080e7          	jalr	-116(ra) # 80001fa2 <proc_freepagetable>
  p->pagetable = 0;
    8000201e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80002022:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80002026:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    8000202a:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    8000202e:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80002032:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80002036:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    8000203a:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    8000203e:	0004ac23          	sw	zero,24(s1)
  p->alarm_handler = 0;
    80002042:	1804b423          	sd	zero,392(s1)
  p->alarm_period = 0;
    80002046:	1804a023          	sw	zero,384(s1)
  p->inalarm = 0;
    8000204a:	1804aa23          	sw	zero,404(s1)
  if (p->kpagetable) {
    8000204e:	1784b783          	ld	a5,376(s1)
    80002052:	cb81                	beqz	a5,80002062 <freeproc+0x6e>
    freeprockvm(p);
    80002054:	8526                	mv	a0,s1
    80002056:	00000097          	auipc	ra,0x0
    8000205a:	bf4080e7          	jalr	-1036(ra) # 80001c4a <freeprockvm>
    p->kpagetable = 0;
    8000205e:	1604bc23          	sd	zero,376(s1)
  if (p->kstack) {
    80002062:	60bc                	ld	a5,64(s1)
    80002064:	c399                	beqz	a5,8000206a <freeproc+0x76>
    p->kstack = 0;
    80002066:	0404b023          	sd	zero,64(s1)
  if (p->alarmframe)
    8000206a:	70a8                	ld	a0,96(s1)
    8000206c:	c509                	beqz	a0,80002076 <freeproc+0x82>
    kfree((void *)p->alarmframe);
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	a14080e7          	jalr	-1516(ra) # 80000a82 <kfree>
  p->alarmframe = 0;
    80002076:	0604b023          	sd	zero,96(s1)
}
    8000207a:	60e2                	ld	ra,24(sp)
    8000207c:	6442                	ld	s0,16(sp)
    8000207e:	64a2                	ld	s1,8(sp)
    80002080:	6105                	addi	sp,sp,32
    80002082:	8082                	ret

0000000080002084 <allocproc>:
{
    80002084:	7179                	addi	sp,sp,-48
    80002086:	f406                	sd	ra,40(sp)
    80002088:	f022                	sd	s0,32(sp)
    8000208a:	ec26                	sd	s1,24(sp)
    8000208c:	e84a                	sd	s2,16(sp)
    8000208e:	e44e                	sd	s3,8(sp)
    80002090:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80002092:	00010497          	auipc	s1,0x10
    80002096:	cd648493          	addi	s1,s1,-810 # 80011d68 <proc>
    8000209a:	00016917          	auipc	s2,0x16
    8000209e:	2ce90913          	addi	s2,s2,718 # 80018368 <tickslock>
    acquire(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	c14080e7          	jalr	-1004(ra) # 80000cb8 <acquire>
    if(p->state == UNUSED) {
    800020ac:	4c9c                	lw	a5,24(s1)
    800020ae:	cf81                	beqz	a5,800020c6 <allocproc+0x42>
      release(&p->lock);
    800020b0:	8526                	mv	a0,s1
    800020b2:	fffff097          	auipc	ra,0xfffff
    800020b6:	cba080e7          	jalr	-838(ra) # 80000d6c <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ba:	19848493          	addi	s1,s1,408
    800020be:	ff2492e3          	bne	s1,s2,800020a2 <allocproc+0x1e>
  return 0;
    800020c2:	4481                	li	s1,0
    800020c4:	a8f1                	j	800021a0 <allocproc+0x11c>
  p->pid = allocpid();
    800020c6:	00000097          	auipc	ra,0x0
    800020ca:	dfa080e7          	jalr	-518(ra) # 80001ec0 <allocpid>
    800020ce:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	aae080e7          	jalr	-1362(ra) # 80000b7e <kalloc>
    800020d8:	892a                	mv	s2,a0
    800020da:	eca8                	sd	a0,88(s1)
    800020dc:	c971                	beqz	a0,800021b0 <allocproc+0x12c>
  if((p->alarmframe = (struct trapframe *)kalloc()) == 0){
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	aa0080e7          	jalr	-1376(ra) # 80000b7e <kalloc>
    800020e6:	892a                	mv	s2,a0
    800020e8:	f0a8                	sd	a0,96(s1)
    800020ea:	c971                	beqz	a0,800021be <allocproc+0x13a>
  p->pagetable = proc_pagetable(p);
    800020ec:	8526                	mv	a0,s1
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	e18080e7          	jalr	-488(ra) # 80001f06 <proc_pagetable>
    800020f6:	892a                	mv	s2,a0
    800020f8:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    800020fa:	c969                	beqz	a0,800021cc <allocproc+0x148>
  p->kpagetable = ukvminit();
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	9e4080e7          	jalr	-1564(ra) # 80001ae0 <ukvminit>
    80002104:	892a                	mv	s2,a0
    80002106:	16a4bc23          	sd	a0,376(s1)
  if(p->kpagetable == 0) {
    8000210a:	cd69                	beqz	a0,800021e4 <allocproc+0x160>
  uint64 va = KSTACK((int) (p - proc));
    8000210c:	00010797          	auipc	a5,0x10
    80002110:	c5c78793          	addi	a5,a5,-932 # 80011d68 <proc>
    80002114:	40f487b3          	sub	a5,s1,a5
    80002118:	878d                	srai	a5,a5,0x3
    8000211a:	00006717          	auipc	a4,0x6
    8000211e:	ee673703          	ld	a4,-282(a4) # 80008000 <etext>
    80002122:	02e787b3          	mul	a5,a5,a4
    80002126:	2785                	addiw	a5,a5,1
    80002128:	00d7979b          	slliw	a5,a5,0xd
    8000212c:	04000937          	lui	s2,0x4000
    80002130:	197d                	addi	s2,s2,-1
    80002132:	0932                	slli	s2,s2,0xc
    80002134:	40f90933          	sub	s2,s2,a5
  pte_t pa = kvmpa(va);
    80002138:	854a                	mv	a0,s2
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	06a080e7          	jalr	106(ra) # 800011a4 <kvmpa>
    80002142:	89aa                	mv	s3,a0
  memset((void *)pa, 0, PGSIZE);
    80002144:	6605                	lui	a2,0x1
    80002146:	4581                	li	a1,0
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	c6c080e7          	jalr	-916(ra) # 80000db4 <memset>
  ukvmmap(p->kpagetable, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80002150:	4719                	li	a4,6
    80002152:	6685                	lui	a3,0x1
    80002154:	864e                	mv	a2,s3
    80002156:	85ca                	mv	a1,s2
    80002158:	1784b503          	ld	a0,376(s1)
    8000215c:	00000097          	auipc	ra,0x0
    80002160:	954080e7          	jalr	-1708(ra) # 80001ab0 <ukvmmap>
  p->kstack = va;
    80002164:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    80002168:	07000613          	li	a2,112
    8000216c:	4581                	li	a1,0
    8000216e:	06848513          	addi	a0,s1,104
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	c42080e7          	jalr	-958(ra) # 80000db4 <memset>
  p->context.ra = (uint64)forkret;
    8000217a:	00000797          	auipc	a5,0x0
    8000217e:	d0078793          	addi	a5,a5,-768 # 80001e7a <forkret>
    80002182:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002184:	60bc                	ld	a5,64(s1)
    80002186:	6705                	lui	a4,0x1
    80002188:	97ba                	add	a5,a5,a4
    8000218a:	f8bc                	sd	a5,112(s1)
  p->tracemask = 0;
    8000218c:	1604b823          	sd	zero,368(s1)
  p->alarm_period = 0;
    80002190:	1804a023          	sw	zero,384(s1)
  p->alarm_handler = 0;
    80002194:	1804b423          	sd	zero,392(s1)
  p->ticks_since_last_alarm = 0;
    80002198:	1804a823          	sw	zero,400(s1)
  p->inalarm = 0;
    8000219c:	1804aa23          	sw	zero,404(s1)
}
    800021a0:	8526                	mv	a0,s1
    800021a2:	70a2                	ld	ra,40(sp)
    800021a4:	7402                	ld	s0,32(sp)
    800021a6:	64e2                	ld	s1,24(sp)
    800021a8:	6942                	ld	s2,16(sp)
    800021aa:	69a2                	ld	s3,8(sp)
    800021ac:	6145                	addi	sp,sp,48
    800021ae:	8082                	ret
    release(&p->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	bba080e7          	jalr	-1094(ra) # 80000d6c <release>
    return 0;
    800021ba:	84ca                	mv	s1,s2
    800021bc:	b7d5                	j	800021a0 <allocproc+0x11c>
    release(&p->lock);
    800021be:	8526                	mv	a0,s1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	bac080e7          	jalr	-1108(ra) # 80000d6c <release>
    return 0;
    800021c8:	84ca                	mv	s1,s2
    800021ca:	bfd9                	j	800021a0 <allocproc+0x11c>
    freeproc(p);
    800021cc:	8526                	mv	a0,s1
    800021ce:	00000097          	auipc	ra,0x0
    800021d2:	e26080e7          	jalr	-474(ra) # 80001ff4 <freeproc>
    release(&p->lock);
    800021d6:	8526                	mv	a0,s1
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	b94080e7          	jalr	-1132(ra) # 80000d6c <release>
    return 0;
    800021e0:	84ca                	mv	s1,s2
    800021e2:	bf7d                	j	800021a0 <allocproc+0x11c>
    freeproc(p);
    800021e4:	8526                	mv	a0,s1
    800021e6:	00000097          	auipc	ra,0x0
    800021ea:	e0e080e7          	jalr	-498(ra) # 80001ff4 <freeproc>
    release(&p->lock);
    800021ee:	8526                	mv	a0,s1
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	b7c080e7          	jalr	-1156(ra) # 80000d6c <release>
    return 0;
    800021f8:	84ca                	mv	s1,s2
    800021fa:	b75d                	j	800021a0 <allocproc+0x11c>

00000000800021fc <userinit>:
{
    800021fc:	1101                	addi	sp,sp,-32
    800021fe:	ec06                	sd	ra,24(sp)
    80002200:	e822                	sd	s0,16(sp)
    80002202:	e426                	sd	s1,8(sp)
    80002204:	e04a                	sd	s2,0(sp)
    80002206:	1000                	addi	s0,sp,32
  p = allocproc();
    80002208:	00000097          	auipc	ra,0x0
    8000220c:	e7c080e7          	jalr	-388(ra) # 80002084 <allocproc>
    80002210:	84aa                	mv	s1,a0
  initproc = p;
    80002212:	00007797          	auipc	a5,0x7
    80002216:	e0a7b323          	sd	a0,-506(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000221a:	03400613          	li	a2,52
    8000221e:	00007597          	auipc	a1,0x7
    80002222:	92258593          	addi	a1,a1,-1758 # 80008b40 <initcode>
    80002226:	6928                	ld	a0,80(a0)
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	2dc080e7          	jalr	732(ra) # 80001504 <uvminit>
  p->sz = PGSIZE;
    80002230:	6905                	lui	s2,0x1
    80002232:	0524b423          	sd	s2,72(s1)
  pagecopy(p->pagetable, p->kpagetable, 0, p->sz);
    80002236:	6685                	lui	a3,0x1
    80002238:	4601                	li	a2,0
    8000223a:	1784b583          	ld	a1,376(s1)
    8000223e:	68a8                	ld	a0,80(s1)
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	528080e7          	jalr	1320(ra) # 80001768 <pagecopy>
  p->trapframe->epc = 0;      // user program counter
    80002248:	6cbc                	ld	a5,88(s1)
    8000224a:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000224e:	6cbc                	ld	a5,88(s1)
    80002250:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002254:	4641                	li	a2,16
    80002256:	00006597          	auipc	a1,0x6
    8000225a:	0aa58593          	addi	a1,a1,170 # 80008300 <indent.1832+0x40>
    8000225e:	16048513          	addi	a0,s1,352
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	ca8080e7          	jalr	-856(ra) # 80000f0a <safestrcpy>
  p->cwd = namei("/");
    8000226a:	00006517          	auipc	a0,0x6
    8000226e:	0a650513          	addi	a0,a0,166 # 80008310 <indent.1832+0x50>
    80002272:	00002097          	auipc	ra,0x2
    80002276:	3cc080e7          	jalr	972(ra) # 8000463e <namei>
    8000227a:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    8000227e:	4789                	li	a5,2
    80002280:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	ae8080e7          	jalr	-1304(ra) # 80000d6c <release>
}
    8000228c:	60e2                	ld	ra,24(sp)
    8000228e:	6442                	ld	s0,16(sp)
    80002290:	64a2                	ld	s1,8(sp)
    80002292:	6902                	ld	s2,0(sp)
    80002294:	6105                	addi	sp,sp,32
    80002296:	8082                	ret

0000000080002298 <growproc>:
{
    80002298:	7179                	addi	sp,sp,-48
    8000229a:	f406                	sd	ra,40(sp)
    8000229c:	f022                	sd	s0,32(sp)
    8000229e:	ec26                	sd	s1,24(sp)
    800022a0:	e84a                	sd	s2,16(sp)
    800022a2:	e44e                	sd	s3,8(sp)
    800022a4:	1800                	addi	s0,sp,48
    800022a6:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800022a8:	00000097          	auipc	ra,0x0
    800022ac:	b9a080e7          	jalr	-1126(ra) # 80001e42 <myproc>
    800022b0:	84aa                	mv	s1,a0
  sz = p->sz;
    800022b2:	652c                	ld	a1,72(a0)
    800022b4:	0005899b          	sext.w	s3,a1
  if(n > 0){
    800022b8:	07205663          	blez	s2,80002324 <growproc+0x8c>
    if (sz + n > PLIC || (sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800022bc:	0139093b          	addw	s2,s2,s3
    800022c0:	0009071b          	sext.w	a4,s2
    800022c4:	0c0007b7          	lui	a5,0xc000
    800022c8:	0ae7ec63          	bltu	a5,a4,80002380 <growproc+0xe8>
    800022cc:	02091613          	slli	a2,s2,0x20
    800022d0:	9201                	srli	a2,a2,0x20
    800022d2:	1582                	slli	a1,a1,0x20
    800022d4:	9181                	srli	a1,a1,0x20
    800022d6:	6928                	ld	a0,80(a0)
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	2e6080e7          	jalr	742(ra) # 800015be <uvmalloc>
    800022e0:	0005099b          	sext.w	s3,a0
    800022e4:	0a098063          	beqz	s3,80002384 <growproc+0xec>
    if (pagecopy(p->pagetable, p->kpagetable, p->sz, sz) != 0) {
    800022e8:	02051693          	slli	a3,a0,0x20
    800022ec:	9281                	srli	a3,a3,0x20
    800022ee:	64b0                	ld	a2,72(s1)
    800022f0:	1784b583          	ld	a1,376(s1)
    800022f4:	68a8                	ld	a0,80(s1)
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	472080e7          	jalr	1138(ra) # 80001768 <pagecopy>
    800022fe:	e549                	bnez	a0,80002388 <growproc+0xf0>
  ukvminithard(p->kpagetable);
    80002300:	1784b503          	ld	a0,376(s1)
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	d78080e7          	jalr	-648(ra) # 8000107c <ukvminithard>
  p->sz = sz;
    8000230c:	02099613          	slli	a2,s3,0x20
    80002310:	9201                	srli	a2,a2,0x20
    80002312:	e4b0                	sd	a2,72(s1)
  return 0;
    80002314:	4501                	li	a0,0
}
    80002316:	70a2                	ld	ra,40(sp)
    80002318:	7402                	ld	s0,32(sp)
    8000231a:	64e2                	ld	s1,24(sp)
    8000231c:	6942                	ld	s2,16(sp)
    8000231e:	69a2                	ld	s3,8(sp)
    80002320:	6145                	addi	sp,sp,48
    80002322:	8082                	ret
  } else if(n < 0){
    80002324:	fc095ee3          	bgez	s2,80002300 <growproc+0x68>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002328:	0139063b          	addw	a2,s2,s3
    8000232c:	557d                	li	a0,-1
    8000232e:	02055913          	srli	s2,a0,0x20
    80002332:	1602                	slli	a2,a2,0x20
    80002334:	9201                	srli	a2,a2,0x20
    80002336:	0125f5b3          	and	a1,a1,s2
    8000233a:	68a8                	ld	a0,80(s1)
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	23a080e7          	jalr	570(ra) # 80001576 <uvmdealloc>
    80002344:	0005099b          	sext.w	s3,a0
    if (sz != p->sz) {
    80002348:	64bc                	ld	a5,72(s1)
    8000234a:	01257533          	and	a0,a0,s2
    8000234e:	faa789e3          	beq	a5,a0,80002300 <growproc+0x68>
      uvmunmap(p->kpagetable, PGROUNDUP(sz), (PGROUNDUP(p->sz) - PGROUNDUP(sz)) / PGSIZE, 0);
    80002352:	6585                	lui	a1,0x1
    80002354:	35fd                	addiw	a1,a1,-1
    80002356:	00b985bb          	addw	a1,s3,a1
    8000235a:	777d                	lui	a4,0xfffff
    8000235c:	8df9                	and	a1,a1,a4
    8000235e:	1582                	slli	a1,a1,0x20
    80002360:	9181                	srli	a1,a1,0x20
    80002362:	6605                	lui	a2,0x1
    80002364:	167d                	addi	a2,a2,-1
    80002366:	963e                	add	a2,a2,a5
    80002368:	77fd                	lui	a5,0xfffff
    8000236a:	8e7d                	and	a2,a2,a5
    8000236c:	8e0d                	sub	a2,a2,a1
    8000236e:	4681                	li	a3,0
    80002370:	8231                	srli	a2,a2,0xc
    80002372:	1784b503          	ld	a0,376(s1)
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	09c080e7          	jalr	156(ra) # 80001412 <uvmunmap>
    8000237e:	b749                	j	80002300 <growproc+0x68>
      return -1;
    80002380:	557d                	li	a0,-1
    80002382:	bf51                	j	80002316 <growproc+0x7e>
    80002384:	557d                	li	a0,-1
    80002386:	bf41                	j	80002316 <growproc+0x7e>
      return -1;
    80002388:	557d                	li	a0,-1
    8000238a:	b771                	j	80002316 <growproc+0x7e>

000000008000238c <fork>:
{
    8000238c:	7179                	addi	sp,sp,-48
    8000238e:	f406                	sd	ra,40(sp)
    80002390:	f022                	sd	s0,32(sp)
    80002392:	ec26                	sd	s1,24(sp)
    80002394:	e84a                	sd	s2,16(sp)
    80002396:	e44e                	sd	s3,8(sp)
    80002398:	e052                	sd	s4,0(sp)
    8000239a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000239c:	00000097          	auipc	ra,0x0
    800023a0:	aa6080e7          	jalr	-1370(ra) # 80001e42 <myproc>
    800023a4:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800023a6:	00000097          	auipc	ra,0x0
    800023aa:	cde080e7          	jalr	-802(ra) # 80002084 <allocproc>
    800023ae:	10050d63          	beqz	a0,800024c8 <fork+0x13c>
    800023b2:	89aa                	mv	s3,a0
  np->tracemask = p->tracemask;
    800023b4:	17093783          	ld	a5,368(s2) # 1170 <_entry-0x7fffee90>
    800023b8:	16f53823          	sd	a5,368(a0)
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800023bc:	04893603          	ld	a2,72(s2)
    800023c0:	692c                	ld	a1,80(a0)
    800023c2:	05093503          	ld	a0,80(s2)
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	44a080e7          	jalr	1098(ra) # 80001810 <uvmcopy>
    800023ce:	06054263          	bltz	a0,80002432 <fork+0xa6>
  np->sz = p->sz;
    800023d2:	04893683          	ld	a3,72(s2)
    800023d6:	04d9b423          	sd	a3,72(s3) # 4000048 <_entry-0x7bffffb8>
  if (pagecopy(np->pagetable, np->kpagetable, 0, np->sz) != 0) {
    800023da:	4601                	li	a2,0
    800023dc:	1789b583          	ld	a1,376(s3)
    800023e0:	0509b503          	ld	a0,80(s3)
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	384080e7          	jalr	900(ra) # 80001768 <pagecopy>
    800023ec:	ed39                	bnez	a0,8000244a <fork+0xbe>
  np->parent = p;
    800023ee:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    800023f2:	05893683          	ld	a3,88(s2)
    800023f6:	87b6                	mv	a5,a3
    800023f8:	0589b703          	ld	a4,88(s3)
    800023fc:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    80002400:	0007b803          	ld	a6,0(a5) # fffffffffffff000 <end+0xffffffff7ffd6fe0>
    80002404:	6788                	ld	a0,8(a5)
    80002406:	6b8c                	ld	a1,16(a5)
    80002408:	6f90                	ld	a2,24(a5)
    8000240a:	01073023          	sd	a6,0(a4) # fffffffffffff000 <end+0xffffffff7ffd6fe0>
    8000240e:	e708                	sd	a0,8(a4)
    80002410:	eb0c                	sd	a1,16(a4)
    80002412:	ef10                	sd	a2,24(a4)
    80002414:	02078793          	addi	a5,a5,32
    80002418:	02070713          	addi	a4,a4,32
    8000241c:	fed792e3          	bne	a5,a3,80002400 <fork+0x74>
  np->trapframe->a0 = 0;
    80002420:	0589b783          	ld	a5,88(s3)
    80002424:	0607b823          	sd	zero,112(a5)
    80002428:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    8000242c:	15800a13          	li	s4,344
    80002430:	a099                	j	80002476 <fork+0xea>
    freeproc(np);
    80002432:	854e                	mv	a0,s3
    80002434:	00000097          	auipc	ra,0x0
    80002438:	bc0080e7          	jalr	-1088(ra) # 80001ff4 <freeproc>
    release(&np->lock);
    8000243c:	854e                	mv	a0,s3
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	92e080e7          	jalr	-1746(ra) # 80000d6c <release>
    return -1;
    80002446:	54fd                	li	s1,-1
    80002448:	a0bd                	j	800024b6 <fork+0x12a>
    freeproc(np);
    8000244a:	854e                	mv	a0,s3
    8000244c:	00000097          	auipc	ra,0x0
    80002450:	ba8080e7          	jalr	-1112(ra) # 80001ff4 <freeproc>
    release(&np->lock);
    80002454:	854e                	mv	a0,s3
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	916080e7          	jalr	-1770(ra) # 80000d6c <release>
    return -1;
    8000245e:	54fd                	li	s1,-1
    80002460:	a899                	j	800024b6 <fork+0x12a>
      np->ofile[i] = filedup(p->ofile[i]);
    80002462:	00003097          	auipc	ra,0x3
    80002466:	868080e7          	jalr	-1944(ra) # 80004cca <filedup>
    8000246a:	009987b3          	add	a5,s3,s1
    8000246e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002470:	04a1                	addi	s1,s1,8
    80002472:	01448763          	beq	s1,s4,80002480 <fork+0xf4>
    if(p->ofile[i])
    80002476:	009907b3          	add	a5,s2,s1
    8000247a:	6388                	ld	a0,0(a5)
    8000247c:	f17d                	bnez	a0,80002462 <fork+0xd6>
    8000247e:	bfcd                	j	80002470 <fork+0xe4>
  np->cwd = idup(p->cwd);
    80002480:	15893503          	ld	a0,344(s2)
    80002484:	00002097          	auipc	ra,0x2
    80002488:	9cc080e7          	jalr	-1588(ra) # 80003e50 <idup>
    8000248c:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002490:	4641                	li	a2,16
    80002492:	16090593          	addi	a1,s2,352
    80002496:	16098513          	addi	a0,s3,352
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	a70080e7          	jalr	-1424(ra) # 80000f0a <safestrcpy>
  pid = np->pid;
    800024a2:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    800024a6:	4789                	li	a5,2
    800024a8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800024ac:	854e                	mv	a0,s3
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	8be080e7          	jalr	-1858(ra) # 80000d6c <release>
}
    800024b6:	8526                	mv	a0,s1
    800024b8:	70a2                	ld	ra,40(sp)
    800024ba:	7402                	ld	s0,32(sp)
    800024bc:	64e2                	ld	s1,24(sp)
    800024be:	6942                	ld	s2,16(sp)
    800024c0:	69a2                	ld	s3,8(sp)
    800024c2:	6a02                	ld	s4,0(sp)
    800024c4:	6145                	addi	sp,sp,48
    800024c6:	8082                	ret
    return -1;
    800024c8:	54fd                	li	s1,-1
    800024ca:	b7f5                	j	800024b6 <fork+0x12a>

00000000800024cc <reparent>:
{
    800024cc:	7179                	addi	sp,sp,-48
    800024ce:	f406                	sd	ra,40(sp)
    800024d0:	f022                	sd	s0,32(sp)
    800024d2:	ec26                	sd	s1,24(sp)
    800024d4:	e84a                	sd	s2,16(sp)
    800024d6:	e44e                	sd	s3,8(sp)
    800024d8:	e052                	sd	s4,0(sp)
    800024da:	1800                	addi	s0,sp,48
    800024dc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024de:	00010497          	auipc	s1,0x10
    800024e2:	88a48493          	addi	s1,s1,-1910 # 80011d68 <proc>
      pp->parent = initproc;
    800024e6:	00007a17          	auipc	s4,0x7
    800024ea:	b32a0a13          	addi	s4,s4,-1230 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024ee:	00016997          	auipc	s3,0x16
    800024f2:	e7a98993          	addi	s3,s3,-390 # 80018368 <tickslock>
    800024f6:	a029                	j	80002500 <reparent+0x34>
    800024f8:	19848493          	addi	s1,s1,408
    800024fc:	03348363          	beq	s1,s3,80002522 <reparent+0x56>
    if(pp->parent == p){
    80002500:	709c                	ld	a5,32(s1)
    80002502:	ff279be3          	bne	a5,s2,800024f8 <reparent+0x2c>
      acquire(&pp->lock);
    80002506:	8526                	mv	a0,s1
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	7b0080e7          	jalr	1968(ra) # 80000cb8 <acquire>
      pp->parent = initproc;
    80002510:	000a3783          	ld	a5,0(s4)
    80002514:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002516:	8526                	mv	a0,s1
    80002518:	fffff097          	auipc	ra,0xfffff
    8000251c:	854080e7          	jalr	-1964(ra) # 80000d6c <release>
    80002520:	bfe1                	j	800024f8 <reparent+0x2c>
}
    80002522:	70a2                	ld	ra,40(sp)
    80002524:	7402                	ld	s0,32(sp)
    80002526:	64e2                	ld	s1,24(sp)
    80002528:	6942                	ld	s2,16(sp)
    8000252a:	69a2                	ld	s3,8(sp)
    8000252c:	6a02                	ld	s4,0(sp)
    8000252e:	6145                	addi	sp,sp,48
    80002530:	8082                	ret

0000000080002532 <scheduler>:
{
    80002532:	715d                	addi	sp,sp,-80
    80002534:	e486                	sd	ra,72(sp)
    80002536:	e0a2                	sd	s0,64(sp)
    80002538:	fc26                	sd	s1,56(sp)
    8000253a:	f84a                	sd	s2,48(sp)
    8000253c:	f44e                	sd	s3,40(sp)
    8000253e:	f052                	sd	s4,32(sp)
    80002540:	ec56                	sd	s5,24(sp)
    80002542:	e85a                	sd	s6,16(sp)
    80002544:	e45e                	sd	s7,8(sp)
    80002546:	e062                	sd	s8,0(sp)
    80002548:	0880                	addi	s0,sp,80
    8000254a:	8792                	mv	a5,tp
  int id = r_tp();
    8000254c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000254e:	00779b13          	slli	s6,a5,0x7
    80002552:	0000f717          	auipc	a4,0xf
    80002556:	3fe70713          	addi	a4,a4,1022 # 80011950 <pid_lock>
    8000255a:	975a                	add	a4,a4,s6
    8000255c:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002560:	0000f717          	auipc	a4,0xf
    80002564:	41070713          	addi	a4,a4,1040 # 80011970 <cpus+0x8>
    80002568:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    8000256a:	4c0d                	li	s8,3
        c->proc = p;
    8000256c:	079e                	slli	a5,a5,0x7
    8000256e:	0000fa17          	auipc	s4,0xf
    80002572:	3e2a0a13          	addi	s4,s4,994 # 80011950 <pid_lock>
    80002576:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002578:	00016997          	auipc	s3,0x16
    8000257c:	df098993          	addi	s3,s3,-528 # 80018368 <tickslock>
        found = 1;
    80002580:	4b85                	li	s7,1
    80002582:	a0ad                	j	800025ec <scheduler+0xba>
        p->state = RUNNING;
    80002584:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80002588:	009a3c23          	sd	s1,24(s4)
        ukvminithard(p->kpagetable);
    8000258c:	1784b503          	ld	a0,376(s1)
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	aec080e7          	jalr	-1300(ra) # 8000107c <ukvminithard>
        swtch(&c->context, &p->context);
    80002598:	06848593          	addi	a1,s1,104
    8000259c:	855a                	mv	a0,s6
    8000259e:	00000097          	auipc	ra,0x0
    800025a2:	694080e7          	jalr	1684(ra) # 80002c32 <swtch>
        kvminithart();
    800025a6:	fffff097          	auipc	ra,0xfffff
    800025aa:	af2080e7          	jalr	-1294(ra) # 80001098 <kvminithart>
        c->proc = 0;
    800025ae:	000a3c23          	sd	zero,24(s4)
        found = 1;
    800025b2:	8ade                	mv	s5,s7
      release(&p->lock);
    800025b4:	8526                	mv	a0,s1
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	7b6080e7          	jalr	1974(ra) # 80000d6c <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800025be:	19848493          	addi	s1,s1,408
    800025c2:	01348b63          	beq	s1,s3,800025d8 <scheduler+0xa6>
      acquire(&p->lock);
    800025c6:	8526                	mv	a0,s1
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	6f0080e7          	jalr	1776(ra) # 80000cb8 <acquire>
      if(p->state == RUNNABLE) {
    800025d0:	4c9c                	lw	a5,24(s1)
    800025d2:	ff2791e3          	bne	a5,s2,800025b4 <scheduler+0x82>
    800025d6:	b77d                	j	80002584 <scheduler+0x52>
    if(found == 0) {
    800025d8:	000a9a63          	bnez	s5,800025ec <scheduler+0xba>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025dc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025e0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025e4:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800025e8:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025ec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025f0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025f4:	10079073          	csrw	sstatus,a5
    int found = 0;
    800025f8:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    800025fa:	0000f497          	auipc	s1,0xf
    800025fe:	76e48493          	addi	s1,s1,1902 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002602:	4909                	li	s2,2
    80002604:	b7c9                	j	800025c6 <scheduler+0x94>

0000000080002606 <sched>:
{
    80002606:	7179                	addi	sp,sp,-48
    80002608:	f406                	sd	ra,40(sp)
    8000260a:	f022                	sd	s0,32(sp)
    8000260c:	ec26                	sd	s1,24(sp)
    8000260e:	e84a                	sd	s2,16(sp)
    80002610:	e44e                	sd	s3,8(sp)
    80002612:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002614:	00000097          	auipc	ra,0x0
    80002618:	82e080e7          	jalr	-2002(ra) # 80001e42 <myproc>
    8000261c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	620080e7          	jalr	1568(ra) # 80000c3e <holding>
    80002626:	c93d                	beqz	a0,8000269c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002628:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000262a:	2781                	sext.w	a5,a5
    8000262c:	079e                	slli	a5,a5,0x7
    8000262e:	0000f717          	auipc	a4,0xf
    80002632:	32270713          	addi	a4,a4,802 # 80011950 <pid_lock>
    80002636:	97ba                	add	a5,a5,a4
    80002638:	0907a703          	lw	a4,144(a5)
    8000263c:	4785                	li	a5,1
    8000263e:	06f71763          	bne	a4,a5,800026ac <sched+0xa6>
  if(p->state == RUNNING)
    80002642:	4c98                	lw	a4,24(s1)
    80002644:	478d                	li	a5,3
    80002646:	06f70b63          	beq	a4,a5,800026bc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000264a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000264e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002650:	efb5                	bnez	a5,800026cc <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002652:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002654:	0000f917          	auipc	s2,0xf
    80002658:	2fc90913          	addi	s2,s2,764 # 80011950 <pid_lock>
    8000265c:	2781                	sext.w	a5,a5
    8000265e:	079e                	slli	a5,a5,0x7
    80002660:	97ca                	add	a5,a5,s2
    80002662:	0947a983          	lw	s3,148(a5)
    80002666:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002668:	2781                	sext.w	a5,a5
    8000266a:	079e                	slli	a5,a5,0x7
    8000266c:	0000f597          	auipc	a1,0xf
    80002670:	30458593          	addi	a1,a1,772 # 80011970 <cpus+0x8>
    80002674:	95be                	add	a1,a1,a5
    80002676:	06848513          	addi	a0,s1,104
    8000267a:	00000097          	auipc	ra,0x0
    8000267e:	5b8080e7          	jalr	1464(ra) # 80002c32 <swtch>
    80002682:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002684:	2781                	sext.w	a5,a5
    80002686:	079e                	slli	a5,a5,0x7
    80002688:	97ca                	add	a5,a5,s2
    8000268a:	0937aa23          	sw	s3,148(a5)
}
    8000268e:	70a2                	ld	ra,40(sp)
    80002690:	7402                	ld	s0,32(sp)
    80002692:	64e2                	ld	s1,24(sp)
    80002694:	6942                	ld	s2,16(sp)
    80002696:	69a2                	ld	s3,8(sp)
    80002698:	6145                	addi	sp,sp,48
    8000269a:	8082                	ret
    panic("sched p->lock");
    8000269c:	00006517          	auipc	a0,0x6
    800026a0:	c7c50513          	addi	a0,a0,-900 # 80008318 <indent.1832+0x58>
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	f2c080e7          	jalr	-212(ra) # 800005d0 <panic>
    panic("sched locks");
    800026ac:	00006517          	auipc	a0,0x6
    800026b0:	c7c50513          	addi	a0,a0,-900 # 80008328 <indent.1832+0x68>
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	f1c080e7          	jalr	-228(ra) # 800005d0 <panic>
    panic("sched running");
    800026bc:	00006517          	auipc	a0,0x6
    800026c0:	c7c50513          	addi	a0,a0,-900 # 80008338 <indent.1832+0x78>
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	f0c080e7          	jalr	-244(ra) # 800005d0 <panic>
    panic("sched interruptible");
    800026cc:	00006517          	auipc	a0,0x6
    800026d0:	c7c50513          	addi	a0,a0,-900 # 80008348 <indent.1832+0x88>
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	efc080e7          	jalr	-260(ra) # 800005d0 <panic>

00000000800026dc <exit>:
{
    800026dc:	7179                	addi	sp,sp,-48
    800026de:	f406                	sd	ra,40(sp)
    800026e0:	f022                	sd	s0,32(sp)
    800026e2:	ec26                	sd	s1,24(sp)
    800026e4:	e84a                	sd	s2,16(sp)
    800026e6:	e44e                	sd	s3,8(sp)
    800026e8:	e052                	sd	s4,0(sp)
    800026ea:	1800                	addi	s0,sp,48
    800026ec:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026ee:	fffff097          	auipc	ra,0xfffff
    800026f2:	754080e7          	jalr	1876(ra) # 80001e42 <myproc>
    800026f6:	89aa                	mv	s3,a0
  if(p == initproc)
    800026f8:	00007797          	auipc	a5,0x7
    800026fc:	9207b783          	ld	a5,-1760(a5) # 80009018 <initproc>
    80002700:	0d850493          	addi	s1,a0,216
    80002704:	15850913          	addi	s2,a0,344
    80002708:	02a79363          	bne	a5,a0,8000272e <exit+0x52>
    panic("init exiting");
    8000270c:	00006517          	auipc	a0,0x6
    80002710:	c5450513          	addi	a0,a0,-940 # 80008360 <indent.1832+0xa0>
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	ebc080e7          	jalr	-324(ra) # 800005d0 <panic>
      fileclose(f);
    8000271c:	00002097          	auipc	ra,0x2
    80002720:	600080e7          	jalr	1536(ra) # 80004d1c <fileclose>
      p->ofile[fd] = 0;
    80002724:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002728:	04a1                	addi	s1,s1,8
    8000272a:	01248563          	beq	s1,s2,80002734 <exit+0x58>
    if(p->ofile[fd]){
    8000272e:	6088                	ld	a0,0(s1)
    80002730:	f575                	bnez	a0,8000271c <exit+0x40>
    80002732:	bfdd                	j	80002728 <exit+0x4c>
  begin_op();
    80002734:	00002097          	auipc	ra,0x2
    80002738:	116080e7          	jalr	278(ra) # 8000484a <begin_op>
  iput(p->cwd);
    8000273c:	1589b503          	ld	a0,344(s3)
    80002740:	00002097          	auipc	ra,0x2
    80002744:	908080e7          	jalr	-1784(ra) # 80004048 <iput>
  end_op();
    80002748:	00002097          	auipc	ra,0x2
    8000274c:	182080e7          	jalr	386(ra) # 800048ca <end_op>
  p->cwd = 0;
    80002750:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    80002754:	00007497          	auipc	s1,0x7
    80002758:	8c448493          	addi	s1,s1,-1852 # 80009018 <initproc>
    8000275c:	6088                	ld	a0,0(s1)
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	55a080e7          	jalr	1370(ra) # 80000cb8 <acquire>
  wakeup1(initproc);
    80002766:	6088                	ld	a0,0(s1)
    80002768:	fffff097          	auipc	ra,0xfffff
    8000276c:	59a080e7          	jalr	1434(ra) # 80001d02 <wakeup1>
  release(&initproc->lock);
    80002770:	6088                	ld	a0,0(s1)
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	5fa080e7          	jalr	1530(ra) # 80000d6c <release>
  acquire(&p->lock);
    8000277a:	854e                	mv	a0,s3
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	53c080e7          	jalr	1340(ra) # 80000cb8 <acquire>
  struct proc *original_parent = p->parent;
    80002784:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002788:	854e                	mv	a0,s3
    8000278a:	ffffe097          	auipc	ra,0xffffe
    8000278e:	5e2080e7          	jalr	1506(ra) # 80000d6c <release>
  acquire(&original_parent->lock);
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	524080e7          	jalr	1316(ra) # 80000cb8 <acquire>
  acquire(&p->lock);
    8000279c:	854e                	mv	a0,s3
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	51a080e7          	jalr	1306(ra) # 80000cb8 <acquire>
  reparent(p);
    800027a6:	854e                	mv	a0,s3
    800027a8:	00000097          	auipc	ra,0x0
    800027ac:	d24080e7          	jalr	-732(ra) # 800024cc <reparent>
  wakeup1(original_parent);
    800027b0:	8526                	mv	a0,s1
    800027b2:	fffff097          	auipc	ra,0xfffff
    800027b6:	550080e7          	jalr	1360(ra) # 80001d02 <wakeup1>
  p->xstate = status;
    800027ba:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800027be:	4791                	li	a5,4
    800027c0:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800027c4:	8526                	mv	a0,s1
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	5a6080e7          	jalr	1446(ra) # 80000d6c <release>
  sched();
    800027ce:	00000097          	auipc	ra,0x0
    800027d2:	e38080e7          	jalr	-456(ra) # 80002606 <sched>
  panic("zombie exit");
    800027d6:	00006517          	auipc	a0,0x6
    800027da:	b9a50513          	addi	a0,a0,-1126 # 80008370 <indent.1832+0xb0>
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	df2080e7          	jalr	-526(ra) # 800005d0 <panic>

00000000800027e6 <yield>:
{
    800027e6:	1101                	addi	sp,sp,-32
    800027e8:	ec06                	sd	ra,24(sp)
    800027ea:	e822                	sd	s0,16(sp)
    800027ec:	e426                	sd	s1,8(sp)
    800027ee:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800027f0:	fffff097          	auipc	ra,0xfffff
    800027f4:	652080e7          	jalr	1618(ra) # 80001e42 <myproc>
    800027f8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	4be080e7          	jalr	1214(ra) # 80000cb8 <acquire>
  p->state = RUNNABLE;
    80002802:	4789                	li	a5,2
    80002804:	cc9c                	sw	a5,24(s1)
  sched();
    80002806:	00000097          	auipc	ra,0x0
    8000280a:	e00080e7          	jalr	-512(ra) # 80002606 <sched>
  release(&p->lock);
    8000280e:	8526                	mv	a0,s1
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	55c080e7          	jalr	1372(ra) # 80000d6c <release>
}
    80002818:	60e2                	ld	ra,24(sp)
    8000281a:	6442                	ld	s0,16(sp)
    8000281c:	64a2                	ld	s1,8(sp)
    8000281e:	6105                	addi	sp,sp,32
    80002820:	8082                	ret

0000000080002822 <sleep>:
{
    80002822:	7179                	addi	sp,sp,-48
    80002824:	f406                	sd	ra,40(sp)
    80002826:	f022                	sd	s0,32(sp)
    80002828:	ec26                	sd	s1,24(sp)
    8000282a:	e84a                	sd	s2,16(sp)
    8000282c:	e44e                	sd	s3,8(sp)
    8000282e:	1800                	addi	s0,sp,48
    80002830:	89aa                	mv	s3,a0
    80002832:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002834:	fffff097          	auipc	ra,0xfffff
    80002838:	60e080e7          	jalr	1550(ra) # 80001e42 <myproc>
    8000283c:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000283e:	05250663          	beq	a0,s2,8000288a <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	476080e7          	jalr	1142(ra) # 80000cb8 <acquire>
    release(lk);
    8000284a:	854a                	mv	a0,s2
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	520080e7          	jalr	1312(ra) # 80000d6c <release>
  p->chan = chan;
    80002854:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002858:	4785                	li	a5,1
    8000285a:	cc9c                	sw	a5,24(s1)
  sched();
    8000285c:	00000097          	auipc	ra,0x0
    80002860:	daa080e7          	jalr	-598(ra) # 80002606 <sched>
  p->chan = 0;
    80002864:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002868:	8526                	mv	a0,s1
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	502080e7          	jalr	1282(ra) # 80000d6c <release>
    acquire(lk);
    80002872:	854a                	mv	a0,s2
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	444080e7          	jalr	1092(ra) # 80000cb8 <acquire>
}
    8000287c:	70a2                	ld	ra,40(sp)
    8000287e:	7402                	ld	s0,32(sp)
    80002880:	64e2                	ld	s1,24(sp)
    80002882:	6942                	ld	s2,16(sp)
    80002884:	69a2                	ld	s3,8(sp)
    80002886:	6145                	addi	sp,sp,48
    80002888:	8082                	ret
  p->chan = chan;
    8000288a:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000288e:	4785                	li	a5,1
    80002890:	cd1c                	sw	a5,24(a0)
  sched();
    80002892:	00000097          	auipc	ra,0x0
    80002896:	d74080e7          	jalr	-652(ra) # 80002606 <sched>
  p->chan = 0;
    8000289a:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000289e:	bff9                	j	8000287c <sleep+0x5a>

00000000800028a0 <wait>:
{
    800028a0:	715d                	addi	sp,sp,-80
    800028a2:	e486                	sd	ra,72(sp)
    800028a4:	e0a2                	sd	s0,64(sp)
    800028a6:	fc26                	sd	s1,56(sp)
    800028a8:	f84a                	sd	s2,48(sp)
    800028aa:	f44e                	sd	s3,40(sp)
    800028ac:	f052                	sd	s4,32(sp)
    800028ae:	ec56                	sd	s5,24(sp)
    800028b0:	e85a                	sd	s6,16(sp)
    800028b2:	e45e                	sd	s7,8(sp)
    800028b4:	e062                	sd	s8,0(sp)
    800028b6:	0880                	addi	s0,sp,80
    800028b8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800028ba:	fffff097          	auipc	ra,0xfffff
    800028be:	588080e7          	jalr	1416(ra) # 80001e42 <myproc>
    800028c2:	892a                	mv	s2,a0
  acquire(&p->lock);
    800028c4:	8c2a                	mv	s8,a0
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	3f2080e7          	jalr	1010(ra) # 80000cb8 <acquire>
    havekids = 0;
    800028ce:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800028d0:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800028d2:	00016997          	auipc	s3,0x16
    800028d6:	a9698993          	addi	s3,s3,-1386 # 80018368 <tickslock>
        havekids = 1;
    800028da:	4a85                	li	s5,1
    havekids = 0;
    800028dc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800028de:	0000f497          	auipc	s1,0xf
    800028e2:	48a48493          	addi	s1,s1,1162 # 80011d68 <proc>
    800028e6:	a08d                	j	80002948 <wait+0xa8>
          pid = np->pid;
    800028e8:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800028ec:	000b0e63          	beqz	s6,80002908 <wait+0x68>
    800028f0:	4691                	li	a3,4
    800028f2:	03448613          	addi	a2,s1,52
    800028f6:	85da                	mv	a1,s6
    800028f8:	05093503          	ld	a0,80(s2)
    800028fc:	fffff097          	auipc	ra,0xfffff
    80002900:	018080e7          	jalr	24(ra) # 80001914 <copyout>
    80002904:	02054263          	bltz	a0,80002928 <wait+0x88>
          freeproc(np);
    80002908:	8526                	mv	a0,s1
    8000290a:	fffff097          	auipc	ra,0xfffff
    8000290e:	6ea080e7          	jalr	1770(ra) # 80001ff4 <freeproc>
          release(&np->lock);
    80002912:	8526                	mv	a0,s1
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	458080e7          	jalr	1112(ra) # 80000d6c <release>
          release(&p->lock);
    8000291c:	854a                	mv	a0,s2
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	44e080e7          	jalr	1102(ra) # 80000d6c <release>
          return pid;
    80002926:	a8a9                	j	80002980 <wait+0xe0>
            release(&np->lock);
    80002928:	8526                	mv	a0,s1
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	442080e7          	jalr	1090(ra) # 80000d6c <release>
            release(&p->lock);
    80002932:	854a                	mv	a0,s2
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	438080e7          	jalr	1080(ra) # 80000d6c <release>
            return -1;
    8000293c:	59fd                	li	s3,-1
    8000293e:	a089                	j	80002980 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002940:	19848493          	addi	s1,s1,408
    80002944:	03348463          	beq	s1,s3,8000296c <wait+0xcc>
      if(np->parent == p){
    80002948:	709c                	ld	a5,32(s1)
    8000294a:	ff279be3          	bne	a5,s2,80002940 <wait+0xa0>
        acquire(&np->lock);
    8000294e:	8526                	mv	a0,s1
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	368080e7          	jalr	872(ra) # 80000cb8 <acquire>
        if(np->state == ZOMBIE){
    80002958:	4c9c                	lw	a5,24(s1)
    8000295a:	f94787e3          	beq	a5,s4,800028e8 <wait+0x48>
        release(&np->lock);
    8000295e:	8526                	mv	a0,s1
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	40c080e7          	jalr	1036(ra) # 80000d6c <release>
        havekids = 1;
    80002968:	8756                	mv	a4,s5
    8000296a:	bfd9                	j	80002940 <wait+0xa0>
    if(!havekids || p->killed){
    8000296c:	c701                	beqz	a4,80002974 <wait+0xd4>
    8000296e:	03092783          	lw	a5,48(s2)
    80002972:	c785                	beqz	a5,8000299a <wait+0xfa>
      release(&p->lock);
    80002974:	854a                	mv	a0,s2
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	3f6080e7          	jalr	1014(ra) # 80000d6c <release>
      return -1;
    8000297e:	59fd                	li	s3,-1
}
    80002980:	854e                	mv	a0,s3
    80002982:	60a6                	ld	ra,72(sp)
    80002984:	6406                	ld	s0,64(sp)
    80002986:	74e2                	ld	s1,56(sp)
    80002988:	7942                	ld	s2,48(sp)
    8000298a:	79a2                	ld	s3,40(sp)
    8000298c:	7a02                	ld	s4,32(sp)
    8000298e:	6ae2                	ld	s5,24(sp)
    80002990:	6b42                	ld	s6,16(sp)
    80002992:	6ba2                	ld	s7,8(sp)
    80002994:	6c02                	ld	s8,0(sp)
    80002996:	6161                	addi	sp,sp,80
    80002998:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000299a:	85e2                	mv	a1,s8
    8000299c:	854a                	mv	a0,s2
    8000299e:	00000097          	auipc	ra,0x0
    800029a2:	e84080e7          	jalr	-380(ra) # 80002822 <sleep>
    havekids = 0;
    800029a6:	bf1d                	j	800028dc <wait+0x3c>

00000000800029a8 <wakeup>:
{
    800029a8:	7139                	addi	sp,sp,-64
    800029aa:	fc06                	sd	ra,56(sp)
    800029ac:	f822                	sd	s0,48(sp)
    800029ae:	f426                	sd	s1,40(sp)
    800029b0:	f04a                	sd	s2,32(sp)
    800029b2:	ec4e                	sd	s3,24(sp)
    800029b4:	e852                	sd	s4,16(sp)
    800029b6:	e456                	sd	s5,8(sp)
    800029b8:	0080                	addi	s0,sp,64
    800029ba:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800029bc:	0000f497          	auipc	s1,0xf
    800029c0:	3ac48493          	addi	s1,s1,940 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800029c4:	4985                	li	s3,1
      p->state = RUNNABLE;
    800029c6:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800029c8:	00016917          	auipc	s2,0x16
    800029cc:	9a090913          	addi	s2,s2,-1632 # 80018368 <tickslock>
    800029d0:	a821                	j	800029e8 <wakeup+0x40>
      p->state = RUNNABLE;
    800029d2:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800029d6:	8526                	mv	a0,s1
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	394080e7          	jalr	916(ra) # 80000d6c <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800029e0:	19848493          	addi	s1,s1,408
    800029e4:	01248e63          	beq	s1,s2,80002a00 <wakeup+0x58>
    acquire(&p->lock);
    800029e8:	8526                	mv	a0,s1
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	2ce080e7          	jalr	718(ra) # 80000cb8 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800029f2:	4c9c                	lw	a5,24(s1)
    800029f4:	ff3791e3          	bne	a5,s3,800029d6 <wakeup+0x2e>
    800029f8:	749c                	ld	a5,40(s1)
    800029fa:	fd479ee3          	bne	a5,s4,800029d6 <wakeup+0x2e>
    800029fe:	bfd1                	j	800029d2 <wakeup+0x2a>
}
    80002a00:	70e2                	ld	ra,56(sp)
    80002a02:	7442                	ld	s0,48(sp)
    80002a04:	74a2                	ld	s1,40(sp)
    80002a06:	7902                	ld	s2,32(sp)
    80002a08:	69e2                	ld	s3,24(sp)
    80002a0a:	6a42                	ld	s4,16(sp)
    80002a0c:	6aa2                	ld	s5,8(sp)
    80002a0e:	6121                	addi	sp,sp,64
    80002a10:	8082                	ret

0000000080002a12 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002a12:	7179                	addi	sp,sp,-48
    80002a14:	f406                	sd	ra,40(sp)
    80002a16:	f022                	sd	s0,32(sp)
    80002a18:	ec26                	sd	s1,24(sp)
    80002a1a:	e84a                	sd	s2,16(sp)
    80002a1c:	e44e                	sd	s3,8(sp)
    80002a1e:	1800                	addi	s0,sp,48
    80002a20:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002a22:	0000f497          	auipc	s1,0xf
    80002a26:	34648493          	addi	s1,s1,838 # 80011d68 <proc>
    80002a2a:	00016997          	auipc	s3,0x16
    80002a2e:	93e98993          	addi	s3,s3,-1730 # 80018368 <tickslock>
    acquire(&p->lock);
    80002a32:	8526                	mv	a0,s1
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	284080e7          	jalr	644(ra) # 80000cb8 <acquire>
    if(p->pid == pid){
    80002a3c:	5c9c                	lw	a5,56(s1)
    80002a3e:	01278d63          	beq	a5,s2,80002a58 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a42:	8526                	mv	a0,s1
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	328080e7          	jalr	808(ra) # 80000d6c <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a4c:	19848493          	addi	s1,s1,408
    80002a50:	ff3491e3          	bne	s1,s3,80002a32 <kill+0x20>
  }
  return -1;
    80002a54:	557d                	li	a0,-1
    80002a56:	a829                	j	80002a70 <kill+0x5e>
      p->killed = 1;
    80002a58:	4785                	li	a5,1
    80002a5a:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002a5c:	4c98                	lw	a4,24(s1)
    80002a5e:	4785                	li	a5,1
    80002a60:	00f70f63          	beq	a4,a5,80002a7e <kill+0x6c>
      release(&p->lock);
    80002a64:	8526                	mv	a0,s1
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	306080e7          	jalr	774(ra) # 80000d6c <release>
      return 0;
    80002a6e:	4501                	li	a0,0
}
    80002a70:	70a2                	ld	ra,40(sp)
    80002a72:	7402                	ld	s0,32(sp)
    80002a74:	64e2                	ld	s1,24(sp)
    80002a76:	6942                	ld	s2,16(sp)
    80002a78:	69a2                	ld	s3,8(sp)
    80002a7a:	6145                	addi	sp,sp,48
    80002a7c:	8082                	ret
        p->state = RUNNABLE;
    80002a7e:	4789                	li	a5,2
    80002a80:	cc9c                	sw	a5,24(s1)
    80002a82:	b7cd                	j	80002a64 <kill+0x52>

0000000080002a84 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002a84:	7179                	addi	sp,sp,-48
    80002a86:	f406                	sd	ra,40(sp)
    80002a88:	f022                	sd	s0,32(sp)
    80002a8a:	ec26                	sd	s1,24(sp)
    80002a8c:	e84a                	sd	s2,16(sp)
    80002a8e:	e44e                	sd	s3,8(sp)
    80002a90:	e052                	sd	s4,0(sp)
    80002a92:	1800                	addi	s0,sp,48
    80002a94:	84aa                	mv	s1,a0
    80002a96:	892e                	mv	s2,a1
    80002a98:	89b2                	mv	s3,a2
    80002a9a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a9c:	fffff097          	auipc	ra,0xfffff
    80002aa0:	3a6080e7          	jalr	934(ra) # 80001e42 <myproc>
  if(user_dst){
    80002aa4:	c08d                	beqz	s1,80002ac6 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002aa6:	86d2                	mv	a3,s4
    80002aa8:	864e                	mv	a2,s3
    80002aaa:	85ca                	mv	a1,s2
    80002aac:	6928                	ld	a0,80(a0)
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	e66080e7          	jalr	-410(ra) # 80001914 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002ab6:	70a2                	ld	ra,40(sp)
    80002ab8:	7402                	ld	s0,32(sp)
    80002aba:	64e2                	ld	s1,24(sp)
    80002abc:	6942                	ld	s2,16(sp)
    80002abe:	69a2                	ld	s3,8(sp)
    80002ac0:	6a02                	ld	s4,0(sp)
    80002ac2:	6145                	addi	sp,sp,48
    80002ac4:	8082                	ret
    memmove((char *)dst, src, len);
    80002ac6:	000a061b          	sext.w	a2,s4
    80002aca:	85ce                	mv	a1,s3
    80002acc:	854a                	mv	a0,s2
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	346080e7          	jalr	838(ra) # 80000e14 <memmove>
    return 0;
    80002ad6:	8526                	mv	a0,s1
    80002ad8:	bff9                	j	80002ab6 <either_copyout+0x32>

0000000080002ada <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002ada:	7179                	addi	sp,sp,-48
    80002adc:	f406                	sd	ra,40(sp)
    80002ade:	f022                	sd	s0,32(sp)
    80002ae0:	ec26                	sd	s1,24(sp)
    80002ae2:	e84a                	sd	s2,16(sp)
    80002ae4:	e44e                	sd	s3,8(sp)
    80002ae6:	e052                	sd	s4,0(sp)
    80002ae8:	1800                	addi	s0,sp,48
    80002aea:	892a                	mv	s2,a0
    80002aec:	84ae                	mv	s1,a1
    80002aee:	89b2                	mv	s3,a2
    80002af0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	350080e7          	jalr	848(ra) # 80001e42 <myproc>
  if(user_src){
    80002afa:	c08d                	beqz	s1,80002b1c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002afc:	86d2                	mv	a3,s4
    80002afe:	864e                	mv	a2,s3
    80002b00:	85ca                	mv	a1,s2
    80002b02:	6928                	ld	a0,80(a0)
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	e9c080e7          	jalr	-356(ra) # 800019a0 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002b0c:	70a2                	ld	ra,40(sp)
    80002b0e:	7402                	ld	s0,32(sp)
    80002b10:	64e2                	ld	s1,24(sp)
    80002b12:	6942                	ld	s2,16(sp)
    80002b14:	69a2                	ld	s3,8(sp)
    80002b16:	6a02                	ld	s4,0(sp)
    80002b18:	6145                	addi	sp,sp,48
    80002b1a:	8082                	ret
    memmove(dst, (char*)src, len);
    80002b1c:	000a061b          	sext.w	a2,s4
    80002b20:	85ce                	mv	a1,s3
    80002b22:	854a                	mv	a0,s2
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	2f0080e7          	jalr	752(ra) # 80000e14 <memmove>
    return 0;
    80002b2c:	8526                	mv	a0,s1
    80002b2e:	bff9                	j	80002b0c <either_copyin+0x32>

0000000080002b30 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002b30:	715d                	addi	sp,sp,-80
    80002b32:	e486                	sd	ra,72(sp)
    80002b34:	e0a2                	sd	s0,64(sp)
    80002b36:	fc26                	sd	s1,56(sp)
    80002b38:	f84a                	sd	s2,48(sp)
    80002b3a:	f44e                	sd	s3,40(sp)
    80002b3c:	f052                	sd	s4,32(sp)
    80002b3e:	ec56                	sd	s5,24(sp)
    80002b40:	e85a                	sd	s6,16(sp)
    80002b42:	e45e                	sd	s7,8(sp)
    80002b44:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002b46:	00005517          	auipc	a0,0x5
    80002b4a:	59250513          	addi	a0,a0,1426 # 800080d8 <digits+0x88>
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	ad4080e7          	jalr	-1324(ra) # 80000622 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b56:	0000f497          	auipc	s1,0xf
    80002b5a:	37248493          	addi	s1,s1,882 # 80011ec8 <proc+0x160>
    80002b5e:	00016917          	auipc	s2,0x16
    80002b62:	96a90913          	addi	s2,s2,-1686 # 800184c8 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b66:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002b68:	00006997          	auipc	s3,0x6
    80002b6c:	81898993          	addi	s3,s3,-2024 # 80008380 <indent.1832+0xc0>
    printf("%d %s %s", p->pid, state, p->name);
    80002b70:	00006a97          	auipc	s5,0x6
    80002b74:	818a8a93          	addi	s5,s5,-2024 # 80008388 <indent.1832+0xc8>
    printf("\n");
    80002b78:	00005a17          	auipc	s4,0x5
    80002b7c:	560a0a13          	addi	s4,s4,1376 # 800080d8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b80:	00006b97          	auipc	s7,0x6
    80002b84:	840b8b93          	addi	s7,s7,-1984 # 800083c0 <states.1775>
    80002b88:	a00d                	j	80002baa <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002b8a:	ed86a583          	lw	a1,-296(a3)
    80002b8e:	8556                	mv	a0,s5
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	a92080e7          	jalr	-1390(ra) # 80000622 <printf>
    printf("\n");
    80002b98:	8552                	mv	a0,s4
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	a88080e7          	jalr	-1400(ra) # 80000622 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ba2:	19848493          	addi	s1,s1,408
    80002ba6:	03248163          	beq	s1,s2,80002bc8 <procdump+0x98>
    if(p->state == UNUSED)
    80002baa:	86a6                	mv	a3,s1
    80002bac:	eb84a783          	lw	a5,-328(s1)
    80002bb0:	dbed                	beqz	a5,80002ba2 <procdump+0x72>
      state = "???";
    80002bb2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bb4:	fcfb6be3          	bltu	s6,a5,80002b8a <procdump+0x5a>
    80002bb8:	1782                	slli	a5,a5,0x20
    80002bba:	9381                	srli	a5,a5,0x20
    80002bbc:	078e                	slli	a5,a5,0x3
    80002bbe:	97de                	add	a5,a5,s7
    80002bc0:	6390                	ld	a2,0(a5)
    80002bc2:	f661                	bnez	a2,80002b8a <procdump+0x5a>
      state = "???";
    80002bc4:	864e                	mv	a2,s3
    80002bc6:	b7d1                	j	80002b8a <procdump+0x5a>
  }
}
    80002bc8:	60a6                	ld	ra,72(sp)
    80002bca:	6406                	ld	s0,64(sp)
    80002bcc:	74e2                	ld	s1,56(sp)
    80002bce:	7942                	ld	s2,48(sp)
    80002bd0:	79a2                	ld	s3,40(sp)
    80002bd2:	7a02                	ld	s4,32(sp)
    80002bd4:	6ae2                	ld	s5,24(sp)
    80002bd6:	6b42                	ld	s6,16(sp)
    80002bd8:	6ba2                	ld	s7,8(sp)
    80002bda:	6161                	addi	sp,sp,80
    80002bdc:	8082                	ret

0000000080002bde <count_free_proc>:

// Count how many processes are not in the state of UNUSED
uint64
count_free_proc(void) {
    80002bde:	7179                	addi	sp,sp,-48
    80002be0:	f406                	sd	ra,40(sp)
    80002be2:	f022                	sd	s0,32(sp)
    80002be4:	ec26                	sd	s1,24(sp)
    80002be6:	e84a                	sd	s2,16(sp)
    80002be8:	e44e                	sd	s3,8(sp)
    80002bea:	1800                	addi	s0,sp,48
  struct proc *p;
  uint64 count = 0;
    80002bec:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002bee:	0000f497          	auipc	s1,0xf
    80002bf2:	17a48493          	addi	s1,s1,378 # 80011d68 <proc>
    80002bf6:	00015997          	auipc	s3,0x15
    80002bfa:	77298993          	addi	s3,s3,1906 # 80018368 <tickslock>
    acquire(&p->lock);
    80002bfe:	8526                	mv	a0,s1
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	0b8080e7          	jalr	184(ra) # 80000cb8 <acquire>
    if(p->state != UNUSED) {
    80002c08:	4c9c                	lw	a5,24(s1)
      count += 1;
    80002c0a:	00f037b3          	snez	a5,a5
    80002c0e:	993e                	add	s2,s2,a5
    }
    release(&p->lock);
    80002c10:	8526                	mv	a0,s1
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	15a080e7          	jalr	346(ra) # 80000d6c <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002c1a:	19848493          	addi	s1,s1,408
    80002c1e:	ff3490e3          	bne	s1,s3,80002bfe <count_free_proc+0x20>
  }
  return count;
}
    80002c22:	854a                	mv	a0,s2
    80002c24:	70a2                	ld	ra,40(sp)
    80002c26:	7402                	ld	s0,32(sp)
    80002c28:	64e2                	ld	s1,24(sp)
    80002c2a:	6942                	ld	s2,16(sp)
    80002c2c:	69a2                	ld	s3,8(sp)
    80002c2e:	6145                	addi	sp,sp,48
    80002c30:	8082                	ret

0000000080002c32 <swtch>:
    80002c32:	00153023          	sd	ra,0(a0)
    80002c36:	00253423          	sd	sp,8(a0)
    80002c3a:	e900                	sd	s0,16(a0)
    80002c3c:	ed04                	sd	s1,24(a0)
    80002c3e:	03253023          	sd	s2,32(a0)
    80002c42:	03353423          	sd	s3,40(a0)
    80002c46:	03453823          	sd	s4,48(a0)
    80002c4a:	03553c23          	sd	s5,56(a0)
    80002c4e:	05653023          	sd	s6,64(a0)
    80002c52:	05753423          	sd	s7,72(a0)
    80002c56:	05853823          	sd	s8,80(a0)
    80002c5a:	05953c23          	sd	s9,88(a0)
    80002c5e:	07a53023          	sd	s10,96(a0)
    80002c62:	07b53423          	sd	s11,104(a0)
    80002c66:	0005b083          	ld	ra,0(a1)
    80002c6a:	0085b103          	ld	sp,8(a1)
    80002c6e:	6980                	ld	s0,16(a1)
    80002c70:	6d84                	ld	s1,24(a1)
    80002c72:	0205b903          	ld	s2,32(a1)
    80002c76:	0285b983          	ld	s3,40(a1)
    80002c7a:	0305ba03          	ld	s4,48(a1)
    80002c7e:	0385ba83          	ld	s5,56(a1)
    80002c82:	0405bb03          	ld	s6,64(a1)
    80002c86:	0485bb83          	ld	s7,72(a1)
    80002c8a:	0505bc03          	ld	s8,80(a1)
    80002c8e:	0585bc83          	ld	s9,88(a1)
    80002c92:	0605bd03          	ld	s10,96(a1)
    80002c96:	0685bd83          	ld	s11,104(a1)
    80002c9a:	8082                	ret

0000000080002c9c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c9c:	1141                	addi	sp,sp,-16
    80002c9e:	e406                	sd	ra,8(sp)
    80002ca0:	e022                	sd	s0,0(sp)
    80002ca2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ca4:	00005597          	auipc	a1,0x5
    80002ca8:	74458593          	addi	a1,a1,1860 # 800083e8 <states.1775+0x28>
    80002cac:	00015517          	auipc	a0,0x15
    80002cb0:	6bc50513          	addi	a0,a0,1724 # 80018368 <tickslock>
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	f74080e7          	jalr	-140(ra) # 80000c28 <initlock>
}
    80002cbc:	60a2                	ld	ra,8(sp)
    80002cbe:	6402                	ld	s0,0(sp)
    80002cc0:	0141                	addi	sp,sp,16
    80002cc2:	8082                	ret

0000000080002cc4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002cc4:	1141                	addi	sp,sp,-16
    80002cc6:	e422                	sd	s0,8(sp)
    80002cc8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cca:	00003797          	auipc	a5,0x3
    80002cce:	70678793          	addi	a5,a5,1798 # 800063d0 <kernelvec>
    80002cd2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cd6:	6422                	ld	s0,8(sp)
    80002cd8:	0141                	addi	sp,sp,16
    80002cda:	8082                	ret

0000000080002cdc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002cdc:	1141                	addi	sp,sp,-16
    80002cde:	e406                	sd	ra,8(sp)
    80002ce0:	e022                	sd	s0,0(sp)
    80002ce2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	15e080e7          	jalr	350(ra) # 80001e42 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002cf0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cf2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002cf6:	00004617          	auipc	a2,0x4
    80002cfa:	30a60613          	addi	a2,a2,778 # 80007000 <_trampoline>
    80002cfe:	00004697          	auipc	a3,0x4
    80002d02:	30268693          	addi	a3,a3,770 # 80007000 <_trampoline>
    80002d06:	8e91                	sub	a3,a3,a2
    80002d08:	040007b7          	lui	a5,0x4000
    80002d0c:	17fd                	addi	a5,a5,-1
    80002d0e:	07b2                	slli	a5,a5,0xc
    80002d10:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d12:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d16:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d18:	180026f3          	csrr	a3,satp
    80002d1c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d1e:	6d38                	ld	a4,88(a0)
    80002d20:	6134                	ld	a3,64(a0)
    80002d22:	6585                	lui	a1,0x1
    80002d24:	96ae                	add	a3,a3,a1
    80002d26:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d28:	6d38                	ld	a4,88(a0)
    80002d2a:	00000697          	auipc	a3,0x0
    80002d2e:	13868693          	addi	a3,a3,312 # 80002e62 <usertrap>
    80002d32:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d34:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d36:	8692                	mv	a3,tp
    80002d38:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d3a:	100026f3          	csrr	a3,sstatus

  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d3e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d42:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d46:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d4a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d4c:	6f18                	ld	a4,24(a4)
    80002d4e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d52:	692c                	ld	a1,80(a0)
    80002d54:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d56:	00004717          	auipc	a4,0x4
    80002d5a:	33a70713          	addi	a4,a4,826 # 80007090 <userret>
    80002d5e:	8f11                	sub	a4,a4,a2
    80002d60:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d62:	577d                	li	a4,-1
    80002d64:	177e                	slli	a4,a4,0x3f
    80002d66:	8dd9                	or	a1,a1,a4
    80002d68:	02000537          	lui	a0,0x2000
    80002d6c:	157d                	addi	a0,a0,-1
    80002d6e:	0536                	slli	a0,a0,0xd
    80002d70:	9782                	jalr	a5
}
    80002d72:	60a2                	ld	ra,8(sp)
    80002d74:	6402                	ld	s0,0(sp)
    80002d76:	0141                	addi	sp,sp,16
    80002d78:	8082                	ret

0000000080002d7a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d7a:	1101                	addi	sp,sp,-32
    80002d7c:	ec06                	sd	ra,24(sp)
    80002d7e:	e822                	sd	s0,16(sp)
    80002d80:	e426                	sd	s1,8(sp)
    80002d82:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d84:	00015497          	auipc	s1,0x15
    80002d88:	5e448493          	addi	s1,s1,1508 # 80018368 <tickslock>
    80002d8c:	8526                	mv	a0,s1
    80002d8e:	ffffe097          	auipc	ra,0xffffe
    80002d92:	f2a080e7          	jalr	-214(ra) # 80000cb8 <acquire>
  ticks++;
    80002d96:	00006517          	auipc	a0,0x6
    80002d9a:	28a50513          	addi	a0,a0,650 # 80009020 <ticks>
    80002d9e:	411c                	lw	a5,0(a0)
    80002da0:	2785                	addiw	a5,a5,1
    80002da2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	c04080e7          	jalr	-1020(ra) # 800029a8 <wakeup>
  release(&tickslock);
    80002dac:	8526                	mv	a0,s1
    80002dae:	ffffe097          	auipc	ra,0xffffe
    80002db2:	fbe080e7          	jalr	-66(ra) # 80000d6c <release>
}
    80002db6:	60e2                	ld	ra,24(sp)
    80002db8:	6442                	ld	s0,16(sp)
    80002dba:	64a2                	ld	s1,8(sp)
    80002dbc:	6105                	addi	sp,sp,32
    80002dbe:	8082                	ret

0000000080002dc0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002dc0:	1101                	addi	sp,sp,-32
    80002dc2:	ec06                	sd	ra,24(sp)
    80002dc4:	e822                	sd	s0,16(sp)
    80002dc6:	e426                	sd	s1,8(sp)
    80002dc8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dca:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002dce:	00074d63          	bltz	a4,80002de8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002dd2:	57fd                	li	a5,-1
    80002dd4:	17fe                	slli	a5,a5,0x3f
    80002dd6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002dd8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002dda:	06f70363          	beq	a4,a5,80002e40 <devintr+0x80>
  }
}
    80002dde:	60e2                	ld	ra,24(sp)
    80002de0:	6442                	ld	s0,16(sp)
    80002de2:	64a2                	ld	s1,8(sp)
    80002de4:	6105                	addi	sp,sp,32
    80002de6:	8082                	ret
     (scause & 0xff) == 9){
    80002de8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002dec:	46a5                	li	a3,9
    80002dee:	fed792e3          	bne	a5,a3,80002dd2 <devintr+0x12>
    int irq = plic_claim();
    80002df2:	00003097          	auipc	ra,0x3
    80002df6:	6e6080e7          	jalr	1766(ra) # 800064d8 <plic_claim>
    80002dfa:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002dfc:	47a9                	li	a5,10
    80002dfe:	02f50763          	beq	a0,a5,80002e2c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e02:	4785                	li	a5,1
    80002e04:	02f50963          	beq	a0,a5,80002e36 <devintr+0x76>
    return 1;
    80002e08:	4505                	li	a0,1
    } else if(irq){
    80002e0a:	d8f1                	beqz	s1,80002dde <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e0c:	85a6                	mv	a1,s1
    80002e0e:	00005517          	auipc	a0,0x5
    80002e12:	5e250513          	addi	a0,a0,1506 # 800083f0 <states.1775+0x30>
    80002e16:	ffffe097          	auipc	ra,0xffffe
    80002e1a:	80c080e7          	jalr	-2036(ra) # 80000622 <printf>
      plic_complete(irq);
    80002e1e:	8526                	mv	a0,s1
    80002e20:	00003097          	auipc	ra,0x3
    80002e24:	6dc080e7          	jalr	1756(ra) # 800064fc <plic_complete>
    return 1;
    80002e28:	4505                	li	a0,1
    80002e2a:	bf55                	j	80002dde <devintr+0x1e>
      uartintr();
    80002e2c:	ffffe097          	auipc	ra,0xffffe
    80002e30:	c06080e7          	jalr	-1018(ra) # 80000a32 <uartintr>
    80002e34:	b7ed                	j	80002e1e <devintr+0x5e>
      virtio_disk_intr();
    80002e36:	00004097          	auipc	ra,0x4
    80002e3a:	b60080e7          	jalr	-1184(ra) # 80006996 <virtio_disk_intr>
    80002e3e:	b7c5                	j	80002e1e <devintr+0x5e>
    if(cpuid() == 0){
    80002e40:	fffff097          	auipc	ra,0xfffff
    80002e44:	fd6080e7          	jalr	-42(ra) # 80001e16 <cpuid>
    80002e48:	c901                	beqz	a0,80002e58 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e4a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e4e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e50:	14479073          	csrw	sip,a5
    return 2;
    80002e54:	4509                	li	a0,2
    80002e56:	b761                	j	80002dde <devintr+0x1e>
      clockintr();
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	f22080e7          	jalr	-222(ra) # 80002d7a <clockintr>
    80002e60:	b7ed                	j	80002e4a <devintr+0x8a>

0000000080002e62 <usertrap>:
{
    80002e62:	1101                	addi	sp,sp,-32
    80002e64:	ec06                	sd	ra,24(sp)
    80002e66:	e822                	sd	s0,16(sp)
    80002e68:	e426                	sd	s1,8(sp)
    80002e6a:	e04a                	sd	s2,0(sp)
    80002e6c:	1000                	addi	s0,sp,32
  int which_dev = devintr();
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	f52080e7          	jalr	-174(ra) # 80002dc0 <devintr>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e76:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e7a:	1007f793          	andi	a5,a5,256
    80002e7e:	e7ad                	bnez	a5,80002ee8 <usertrap+0x86>
    80002e80:	892a                	mv	s2,a0
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e82:	00003797          	auipc	a5,0x3
    80002e86:	54e78793          	addi	a5,a5,1358 # 800063d0 <kernelvec>
    80002e8a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e8e:	fffff097          	auipc	ra,0xfffff
    80002e92:	fb4080e7          	jalr	-76(ra) # 80001e42 <myproc>
    80002e96:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e98:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e9a:	14102773          	csrr	a4,sepc
    80002e9e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ea0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ea4:	47a1                	li	a5,8
    80002ea6:	04f71f63          	bne	a4,a5,80002f04 <usertrap+0xa2>
    if(p->killed)
    80002eaa:	591c                	lw	a5,48(a0)
    80002eac:	e7b1                	bnez	a5,80002ef8 <usertrap+0x96>
    p->trapframe->epc += 4;
    80002eae:	6cb8                	ld	a4,88(s1)
    80002eb0:	6f1c                	ld	a5,24(a4)
    80002eb2:	0791                	addi	a5,a5,4
    80002eb4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eb6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002eba:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ebe:	10079073          	csrw	sstatus,a5
    syscall();
    80002ec2:	00000097          	auipc	ra,0x0
    80002ec6:	330080e7          	jalr	816(ra) # 800031f2 <syscall>
  if(p->killed)
    80002eca:	589c                	lw	a5,48(s1)
    80002ecc:	ebbd                	bnez	a5,80002f42 <usertrap+0xe0>
  if(which_dev == 2) {
    80002ece:	4789                	li	a5,2
    80002ed0:	06f90f63          	beq	s2,a5,80002f4e <usertrap+0xec>
  usertrapret();
    80002ed4:	00000097          	auipc	ra,0x0
    80002ed8:	e08080e7          	jalr	-504(ra) # 80002cdc <usertrapret>
}
    80002edc:	60e2                	ld	ra,24(sp)
    80002ede:	6442                	ld	s0,16(sp)
    80002ee0:	64a2                	ld	s1,8(sp)
    80002ee2:	6902                	ld	s2,0(sp)
    80002ee4:	6105                	addi	sp,sp,32
    80002ee6:	8082                	ret
    panic("usertrap: not from user mode");
    80002ee8:	00005517          	auipc	a0,0x5
    80002eec:	52850513          	addi	a0,a0,1320 # 80008410 <states.1775+0x50>
    80002ef0:	ffffd097          	auipc	ra,0xffffd
    80002ef4:	6e0080e7          	jalr	1760(ra) # 800005d0 <panic>
      exit(-1);
    80002ef8:	557d                	li	a0,-1
    80002efa:	fffff097          	auipc	ra,0xfffff
    80002efe:	7e2080e7          	jalr	2018(ra) # 800026dc <exit>
    80002f02:	b775                	j	80002eae <usertrap+0x4c>
  } else if((which_dev = devintr()) != 0){
    80002f04:	00000097          	auipc	ra,0x0
    80002f08:	ebc080e7          	jalr	-324(ra) # 80002dc0 <devintr>
    80002f0c:	892a                	mv	s2,a0
    80002f0e:	fd55                	bnez	a0,80002eca <usertrap+0x68>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f10:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f14:	5c90                	lw	a2,56(s1)
    80002f16:	00005517          	auipc	a0,0x5
    80002f1a:	51a50513          	addi	a0,a0,1306 # 80008430 <states.1775+0x70>
    80002f1e:	ffffd097          	auipc	ra,0xffffd
    80002f22:	704080e7          	jalr	1796(ra) # 80000622 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f26:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f2a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f2e:	00005517          	auipc	a0,0x5
    80002f32:	53250513          	addi	a0,a0,1330 # 80008460 <states.1775+0xa0>
    80002f36:	ffffd097          	auipc	ra,0xffffd
    80002f3a:	6ec080e7          	jalr	1772(ra) # 80000622 <printf>
    p->killed = 1;
    80002f3e:	4785                	li	a5,1
    80002f40:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002f42:	557d                	li	a0,-1
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	798080e7          	jalr	1944(ra) # 800026dc <exit>
    80002f4c:	b749                	j	80002ece <usertrap+0x6c>
      p->ticks_since_last_alarm += 1;
    80002f4e:	1904a783          	lw	a5,400(s1)
    80002f52:	2785                	addiw	a5,a5,1
    80002f54:	0007871b          	sext.w	a4,a5
    80002f58:	18f4a823          	sw	a5,400(s1)
      if (p->inalarm == 0 && p->alarm_period != 0 && p->ticks_since_last_alarm == p->alarm_period) {
    80002f5c:	1944a783          	lw	a5,404(s1)
    80002f60:	e791                	bnez	a5,80002f6c <usertrap+0x10a>
    80002f62:	1804a783          	lw	a5,384(s1)
    80002f66:	c399                	beqz	a5,80002f6c <usertrap+0x10a>
    80002f68:	00f70763          	beq	a4,a5,80002f76 <usertrap+0x114>
      yield();
    80002f6c:	00000097          	auipc	ra,0x0
    80002f70:	87a080e7          	jalr	-1926(ra) # 800027e6 <yield>
    80002f74:	b785                	j	80002ed4 <usertrap+0x72>
        p->inalarm = 1;
    80002f76:	4785                	li	a5,1
    80002f78:	18f4aa23          	sw	a5,404(s1)
        *p->alarmframe = *p->trapframe;
    80002f7c:	6cb4                	ld	a3,88(s1)
    80002f7e:	87b6                	mv	a5,a3
    80002f80:	70b8                	ld	a4,96(s1)
    80002f82:	12068693          	addi	a3,a3,288
    80002f86:	0007b803          	ld	a6,0(a5)
    80002f8a:	6788                	ld	a0,8(a5)
    80002f8c:	6b8c                	ld	a1,16(a5)
    80002f8e:	6f90                	ld	a2,24(a5)
    80002f90:	01073023          	sd	a6,0(a4)
    80002f94:	e708                	sd	a0,8(a4)
    80002f96:	eb0c                	sd	a1,16(a4)
    80002f98:	ef10                	sd	a2,24(a4)
    80002f9a:	02078793          	addi	a5,a5,32
    80002f9e:	02070713          	addi	a4,a4,32
    80002fa2:	fed792e3          	bne	a5,a3,80002f86 <usertrap+0x124>
        p->trapframe->epc = (uint64)p->alarm_handler;
    80002fa6:	6cbc                	ld	a5,88(s1)
    80002fa8:	1884b703          	ld	a4,392(s1)
    80002fac:	ef98                	sd	a4,24(a5)
    80002fae:	bf7d                	j	80002f6c <usertrap+0x10a>

0000000080002fb0 <kerneltrap>:
{
    80002fb0:	7179                	addi	sp,sp,-48
    80002fb2:	f406                	sd	ra,40(sp)
    80002fb4:	f022                	sd	s0,32(sp)
    80002fb6:	ec26                	sd	s1,24(sp)
    80002fb8:	e84a                	sd	s2,16(sp)
    80002fba:	e44e                	sd	s3,8(sp)
    80002fbc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fbe:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fc2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fc6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fca:	1004f793          	andi	a5,s1,256
    80002fce:	cb85                	beqz	a5,80002ffe <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fd0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fd4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002fd6:	ef85                	bnez	a5,8000300e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002fd8:	00000097          	auipc	ra,0x0
    80002fdc:	de8080e7          	jalr	-536(ra) # 80002dc0 <devintr>
    80002fe0:	cd1d                	beqz	a0,8000301e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fe2:	4789                	li	a5,2
    80002fe4:	06f50a63          	beq	a0,a5,80003058 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fe8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fec:	10049073          	csrw	sstatus,s1
}
    80002ff0:	70a2                	ld	ra,40(sp)
    80002ff2:	7402                	ld	s0,32(sp)
    80002ff4:	64e2                	ld	s1,24(sp)
    80002ff6:	6942                	ld	s2,16(sp)
    80002ff8:	69a2                	ld	s3,8(sp)
    80002ffa:	6145                	addi	sp,sp,48
    80002ffc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ffe:	00005517          	auipc	a0,0x5
    80003002:	48250513          	addi	a0,a0,1154 # 80008480 <states.1775+0xc0>
    80003006:	ffffd097          	auipc	ra,0xffffd
    8000300a:	5ca080e7          	jalr	1482(ra) # 800005d0 <panic>
    panic("kerneltrap: interrupts enabled");
    8000300e:	00005517          	auipc	a0,0x5
    80003012:	49a50513          	addi	a0,a0,1178 # 800084a8 <states.1775+0xe8>
    80003016:	ffffd097          	auipc	ra,0xffffd
    8000301a:	5ba080e7          	jalr	1466(ra) # 800005d0 <panic>
    printf("scause %p\n", scause);
    8000301e:	85ce                	mv	a1,s3
    80003020:	00005517          	auipc	a0,0x5
    80003024:	4a850513          	addi	a0,a0,1192 # 800084c8 <states.1775+0x108>
    80003028:	ffffd097          	auipc	ra,0xffffd
    8000302c:	5fa080e7          	jalr	1530(ra) # 80000622 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003030:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003034:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003038:	00005517          	auipc	a0,0x5
    8000303c:	4a050513          	addi	a0,a0,1184 # 800084d8 <states.1775+0x118>
    80003040:	ffffd097          	auipc	ra,0xffffd
    80003044:	5e2080e7          	jalr	1506(ra) # 80000622 <printf>
    panic("kerneltrap");
    80003048:	00005517          	auipc	a0,0x5
    8000304c:	4a850513          	addi	a0,a0,1192 # 800084f0 <states.1775+0x130>
    80003050:	ffffd097          	auipc	ra,0xffffd
    80003054:	580080e7          	jalr	1408(ra) # 800005d0 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003058:	fffff097          	auipc	ra,0xfffff
    8000305c:	dea080e7          	jalr	-534(ra) # 80001e42 <myproc>
    80003060:	d541                	beqz	a0,80002fe8 <kerneltrap+0x38>
    80003062:	fffff097          	auipc	ra,0xfffff
    80003066:	de0080e7          	jalr	-544(ra) # 80001e42 <myproc>
    8000306a:	4d18                	lw	a4,24(a0)
    8000306c:	478d                	li	a5,3
    8000306e:	f6f71de3          	bne	a4,a5,80002fe8 <kerneltrap+0x38>
    yield();
    80003072:	fffff097          	auipc	ra,0xfffff
    80003076:	774080e7          	jalr	1908(ra) # 800027e6 <yield>
    8000307a:	b7bd                	j	80002fe8 <kerneltrap+0x38>

000000008000307c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000307c:	1101                	addi	sp,sp,-32
    8000307e:	ec06                	sd	ra,24(sp)
    80003080:	e822                	sd	s0,16(sp)
    80003082:	e426                	sd	s1,8(sp)
    80003084:	1000                	addi	s0,sp,32
    80003086:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003088:	fffff097          	auipc	ra,0xfffff
    8000308c:	dba080e7          	jalr	-582(ra) # 80001e42 <myproc>
  switch (n) {
    80003090:	4795                	li	a5,5
    80003092:	0497e163          	bltu	a5,s1,800030d4 <argraw+0x58>
    80003096:	048a                	slli	s1,s1,0x2
    80003098:	00005717          	auipc	a4,0x5
    8000309c:	57870713          	addi	a4,a4,1400 # 80008610 <states.1775+0x250>
    800030a0:	94ba                	add	s1,s1,a4
    800030a2:	409c                	lw	a5,0(s1)
    800030a4:	97ba                	add	a5,a5,a4
    800030a6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030a8:	6d3c                	ld	a5,88(a0)
    800030aa:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	64a2                	ld	s1,8(sp)
    800030b2:	6105                	addi	sp,sp,32
    800030b4:	8082                	ret
    return p->trapframe->a1;
    800030b6:	6d3c                	ld	a5,88(a0)
    800030b8:	7fa8                	ld	a0,120(a5)
    800030ba:	bfcd                	j	800030ac <argraw+0x30>
    return p->trapframe->a2;
    800030bc:	6d3c                	ld	a5,88(a0)
    800030be:	63c8                	ld	a0,128(a5)
    800030c0:	b7f5                	j	800030ac <argraw+0x30>
    return p->trapframe->a3;
    800030c2:	6d3c                	ld	a5,88(a0)
    800030c4:	67c8                	ld	a0,136(a5)
    800030c6:	b7dd                	j	800030ac <argraw+0x30>
    return p->trapframe->a4;
    800030c8:	6d3c                	ld	a5,88(a0)
    800030ca:	6bc8                	ld	a0,144(a5)
    800030cc:	b7c5                	j	800030ac <argraw+0x30>
    return p->trapframe->a5;
    800030ce:	6d3c                	ld	a5,88(a0)
    800030d0:	6fc8                	ld	a0,152(a5)
    800030d2:	bfe9                	j	800030ac <argraw+0x30>
  panic("argraw");
    800030d4:	00005517          	auipc	a0,0x5
    800030d8:	42c50513          	addi	a0,a0,1068 # 80008500 <states.1775+0x140>
    800030dc:	ffffd097          	auipc	ra,0xffffd
    800030e0:	4f4080e7          	jalr	1268(ra) # 800005d0 <panic>

00000000800030e4 <fetchaddr>:
{
    800030e4:	1101                	addi	sp,sp,-32
    800030e6:	ec06                	sd	ra,24(sp)
    800030e8:	e822                	sd	s0,16(sp)
    800030ea:	e426                	sd	s1,8(sp)
    800030ec:	e04a                	sd	s2,0(sp)
    800030ee:	1000                	addi	s0,sp,32
    800030f0:	84aa                	mv	s1,a0
    800030f2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030f4:	fffff097          	auipc	ra,0xfffff
    800030f8:	d4e080e7          	jalr	-690(ra) # 80001e42 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800030fc:	653c                	ld	a5,72(a0)
    800030fe:	02f4f863          	bgeu	s1,a5,8000312e <fetchaddr+0x4a>
    80003102:	00848713          	addi	a4,s1,8
    80003106:	02e7e663          	bltu	a5,a4,80003132 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000310a:	46a1                	li	a3,8
    8000310c:	8626                	mv	a2,s1
    8000310e:	85ca                	mv	a1,s2
    80003110:	6928                	ld	a0,80(a0)
    80003112:	fffff097          	auipc	ra,0xfffff
    80003116:	88e080e7          	jalr	-1906(ra) # 800019a0 <copyin>
    8000311a:	00a03533          	snez	a0,a0
    8000311e:	40a00533          	neg	a0,a0
}
    80003122:	60e2                	ld	ra,24(sp)
    80003124:	6442                	ld	s0,16(sp)
    80003126:	64a2                	ld	s1,8(sp)
    80003128:	6902                	ld	s2,0(sp)
    8000312a:	6105                	addi	sp,sp,32
    8000312c:	8082                	ret
    return -1;
    8000312e:	557d                	li	a0,-1
    80003130:	bfcd                	j	80003122 <fetchaddr+0x3e>
    80003132:	557d                	li	a0,-1
    80003134:	b7fd                	j	80003122 <fetchaddr+0x3e>

0000000080003136 <fetchstr>:
{
    80003136:	7179                	addi	sp,sp,-48
    80003138:	f406                	sd	ra,40(sp)
    8000313a:	f022                	sd	s0,32(sp)
    8000313c:	ec26                	sd	s1,24(sp)
    8000313e:	e84a                	sd	s2,16(sp)
    80003140:	e44e                	sd	s3,8(sp)
    80003142:	1800                	addi	s0,sp,48
    80003144:	892a                	mv	s2,a0
    80003146:	84ae                	mv	s1,a1
    80003148:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000314a:	fffff097          	auipc	ra,0xfffff
    8000314e:	cf8080e7          	jalr	-776(ra) # 80001e42 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003152:	86ce                	mv	a3,s3
    80003154:	864a                	mv	a2,s2
    80003156:	85a6                	mv	a1,s1
    80003158:	6928                	ld	a0,80(a0)
    8000315a:	fffff097          	auipc	ra,0xfffff
    8000315e:	85e080e7          	jalr	-1954(ra) # 800019b8 <copyinstr>
  if(err < 0)
    80003162:	00054763          	bltz	a0,80003170 <fetchstr+0x3a>
  return strlen(buf);
    80003166:	8526                	mv	a0,s1
    80003168:	ffffe097          	auipc	ra,0xffffe
    8000316c:	dd4080e7          	jalr	-556(ra) # 80000f3c <strlen>
}
    80003170:	70a2                	ld	ra,40(sp)
    80003172:	7402                	ld	s0,32(sp)
    80003174:	64e2                	ld	s1,24(sp)
    80003176:	6942                	ld	s2,16(sp)
    80003178:	69a2                	ld	s3,8(sp)
    8000317a:	6145                	addi	sp,sp,48
    8000317c:	8082                	ret

000000008000317e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000317e:	1101                	addi	sp,sp,-32
    80003180:	ec06                	sd	ra,24(sp)
    80003182:	e822                	sd	s0,16(sp)
    80003184:	e426                	sd	s1,8(sp)
    80003186:	1000                	addi	s0,sp,32
    80003188:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000318a:	00000097          	auipc	ra,0x0
    8000318e:	ef2080e7          	jalr	-270(ra) # 8000307c <argraw>
    80003192:	c088                	sw	a0,0(s1)
  return 0;
}
    80003194:	4501                	li	a0,0
    80003196:	60e2                	ld	ra,24(sp)
    80003198:	6442                	ld	s0,16(sp)
    8000319a:	64a2                	ld	s1,8(sp)
    8000319c:	6105                	addi	sp,sp,32
    8000319e:	8082                	ret

00000000800031a0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800031a0:	1101                	addi	sp,sp,-32
    800031a2:	ec06                	sd	ra,24(sp)
    800031a4:	e822                	sd	s0,16(sp)
    800031a6:	e426                	sd	s1,8(sp)
    800031a8:	1000                	addi	s0,sp,32
    800031aa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031ac:	00000097          	auipc	ra,0x0
    800031b0:	ed0080e7          	jalr	-304(ra) # 8000307c <argraw>
    800031b4:	e088                	sd	a0,0(s1)
  return 0;
}
    800031b6:	4501                	li	a0,0
    800031b8:	60e2                	ld	ra,24(sp)
    800031ba:	6442                	ld	s0,16(sp)
    800031bc:	64a2                	ld	s1,8(sp)
    800031be:	6105                	addi	sp,sp,32
    800031c0:	8082                	ret

00000000800031c2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031c2:	1101                	addi	sp,sp,-32
    800031c4:	ec06                	sd	ra,24(sp)
    800031c6:	e822                	sd	s0,16(sp)
    800031c8:	e426                	sd	s1,8(sp)
    800031ca:	e04a                	sd	s2,0(sp)
    800031cc:	1000                	addi	s0,sp,32
    800031ce:	84ae                	mv	s1,a1
    800031d0:	8932                	mv	s2,a2
  *ip = argraw(n);
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	eaa080e7          	jalr	-342(ra) # 8000307c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800031da:	864a                	mv	a2,s2
    800031dc:	85a6                	mv	a1,s1
    800031de:	00000097          	auipc	ra,0x0
    800031e2:	f58080e7          	jalr	-168(ra) # 80003136 <fetchstr>
}
    800031e6:	60e2                	ld	ra,24(sp)
    800031e8:	6442                	ld	s0,16(sp)
    800031ea:	64a2                	ld	s1,8(sp)
    800031ec:	6902                	ld	s2,0(sp)
    800031ee:	6105                	addi	sp,sp,32
    800031f0:	8082                	ret

00000000800031f2 <syscall>:
    "sigreturn",
};

void
syscall(void)
{
    800031f2:	7179                	addi	sp,sp,-48
    800031f4:	f406                	sd	ra,40(sp)
    800031f6:	f022                	sd	s0,32(sp)
    800031f8:	ec26                	sd	s1,24(sp)
    800031fa:	e84a                	sd	s2,16(sp)
    800031fc:	e44e                	sd	s3,8(sp)
    800031fe:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80003200:	fffff097          	auipc	ra,0xfffff
    80003204:	c42080e7          	jalr	-958(ra) # 80001e42 <myproc>
    80003208:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000320a:	05853903          	ld	s2,88(a0)
    8000320e:	0a893783          	ld	a5,168(s2)
    80003212:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003216:	37fd                	addiw	a5,a5,-1
    80003218:	4761                	li	a4,24
    8000321a:	04f76963          	bltu	a4,a5,8000326c <syscall+0x7a>
    8000321e:	00399713          	slli	a4,s3,0x3
    80003222:	00005797          	auipc	a5,0x5
    80003226:	40678793          	addi	a5,a5,1030 # 80008628 <syscalls>
    8000322a:	97ba                	add	a5,a5,a4
    8000322c:	639c                	ld	a5,0(a5)
    8000322e:	cf9d                	beqz	a5,8000326c <syscall+0x7a>
    p->trapframe->a0 = syscalls[num]();
    80003230:	9782                	jalr	a5
    80003232:	06a93823          	sd	a0,112(s2)
    if (p->tracemask & (1 << num)) {
    80003236:	4785                	li	a5,1
    80003238:	013797bb          	sllw	a5,a5,s3
    8000323c:	1704b703          	ld	a4,368(s1)
    80003240:	8ff9                	and	a5,a5,a4
    80003242:	c7a1                	beqz	a5,8000328a <syscall+0x98>
      // this process traces this sys call num
      printf("%d: syscall %s -> %d\n", p->pid, sysnames[num], p->trapframe->a0);
    80003244:	6cb8                	ld	a4,88(s1)
    80003246:	098e                	slli	s3,s3,0x3
    80003248:	00005797          	auipc	a5,0x5
    8000324c:	3e078793          	addi	a5,a5,992 # 80008628 <syscalls>
    80003250:	99be                	add	s3,s3,a5
    80003252:	7b34                	ld	a3,112(a4)
    80003254:	0d09b603          	ld	a2,208(s3)
    80003258:	5c8c                	lw	a1,56(s1)
    8000325a:	00005517          	auipc	a0,0x5
    8000325e:	2ae50513          	addi	a0,a0,686 # 80008508 <states.1775+0x148>
    80003262:	ffffd097          	auipc	ra,0xffffd
    80003266:	3c0080e7          	jalr	960(ra) # 80000622 <printf>
    8000326a:	a005                	j	8000328a <syscall+0x98>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000326c:	86ce                	mv	a3,s3
    8000326e:	16048613          	addi	a2,s1,352
    80003272:	5c8c                	lw	a1,56(s1)
    80003274:	00005517          	auipc	a0,0x5
    80003278:	2ac50513          	addi	a0,a0,684 # 80008520 <states.1775+0x160>
    8000327c:	ffffd097          	auipc	ra,0xffffd
    80003280:	3a6080e7          	jalr	934(ra) # 80000622 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003284:	6cbc                	ld	a5,88(s1)
    80003286:	577d                	li	a4,-1
    80003288:	fbb8                	sd	a4,112(a5)
  }
}
    8000328a:	70a2                	ld	ra,40(sp)
    8000328c:	7402                	ld	s0,32(sp)
    8000328e:	64e2                	ld	s1,24(sp)
    80003290:	6942                	ld	s2,16(sp)
    80003292:	69a2                	ld	s3,8(sp)
    80003294:	6145                	addi	sp,sp,48
    80003296:	8082                	ret

0000000080003298 <sys_exit>:
#include "sysinfo.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003298:	1101                	addi	sp,sp,-32
    8000329a:	ec06                	sd	ra,24(sp)
    8000329c:	e822                	sd	s0,16(sp)
    8000329e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800032a0:	fec40593          	addi	a1,s0,-20
    800032a4:	4501                	li	a0,0
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	ed8080e7          	jalr	-296(ra) # 8000317e <argint>
    return -1;
    800032ae:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032b0:	00054963          	bltz	a0,800032c2 <sys_exit+0x2a>
  exit(n);
    800032b4:	fec42503          	lw	a0,-20(s0)
    800032b8:	fffff097          	auipc	ra,0xfffff
    800032bc:	424080e7          	jalr	1060(ra) # 800026dc <exit>
  return 0;  // not reached
    800032c0:	4781                	li	a5,0
}
    800032c2:	853e                	mv	a0,a5
    800032c4:	60e2                	ld	ra,24(sp)
    800032c6:	6442                	ld	s0,16(sp)
    800032c8:	6105                	addi	sp,sp,32
    800032ca:	8082                	ret

00000000800032cc <sys_getpid>:

uint64
sys_getpid(void)
{
    800032cc:	1141                	addi	sp,sp,-16
    800032ce:	e406                	sd	ra,8(sp)
    800032d0:	e022                	sd	s0,0(sp)
    800032d2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032d4:	fffff097          	auipc	ra,0xfffff
    800032d8:	b6e080e7          	jalr	-1170(ra) # 80001e42 <myproc>
}
    800032dc:	5d08                	lw	a0,56(a0)
    800032de:	60a2                	ld	ra,8(sp)
    800032e0:	6402                	ld	s0,0(sp)
    800032e2:	0141                	addi	sp,sp,16
    800032e4:	8082                	ret

00000000800032e6 <sys_fork>:

uint64
sys_fork(void)
{
    800032e6:	1141                	addi	sp,sp,-16
    800032e8:	e406                	sd	ra,8(sp)
    800032ea:	e022                	sd	s0,0(sp)
    800032ec:	0800                	addi	s0,sp,16
  return fork();
    800032ee:	fffff097          	auipc	ra,0xfffff
    800032f2:	09e080e7          	jalr	158(ra) # 8000238c <fork>
}
    800032f6:	60a2                	ld	ra,8(sp)
    800032f8:	6402                	ld	s0,0(sp)
    800032fa:	0141                	addi	sp,sp,16
    800032fc:	8082                	ret

00000000800032fe <sys_wait>:

uint64
sys_wait(void)
{
    800032fe:	1101                	addi	sp,sp,-32
    80003300:	ec06                	sd	ra,24(sp)
    80003302:	e822                	sd	s0,16(sp)
    80003304:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003306:	fe840593          	addi	a1,s0,-24
    8000330a:	4501                	li	a0,0
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	e94080e7          	jalr	-364(ra) # 800031a0 <argaddr>
    80003314:	87aa                	mv	a5,a0
    return -1;
    80003316:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003318:	0007c863          	bltz	a5,80003328 <sys_wait+0x2a>
  return wait(p);
    8000331c:	fe843503          	ld	a0,-24(s0)
    80003320:	fffff097          	auipc	ra,0xfffff
    80003324:	580080e7          	jalr	1408(ra) # 800028a0 <wait>
}
    80003328:	60e2                	ld	ra,24(sp)
    8000332a:	6442                	ld	s0,16(sp)
    8000332c:	6105                	addi	sp,sp,32
    8000332e:	8082                	ret

0000000080003330 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003330:	7179                	addi	sp,sp,-48
    80003332:	f406                	sd	ra,40(sp)
    80003334:	f022                	sd	s0,32(sp)
    80003336:	ec26                	sd	s1,24(sp)
    80003338:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000333a:	fdc40593          	addi	a1,s0,-36
    8000333e:	4501                	li	a0,0
    80003340:	00000097          	auipc	ra,0x0
    80003344:	e3e080e7          	jalr	-450(ra) # 8000317e <argint>
    80003348:	87aa                	mv	a5,a0
    return -1;
    8000334a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000334c:	0207c063          	bltz	a5,8000336c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003350:	fffff097          	auipc	ra,0xfffff
    80003354:	af2080e7          	jalr	-1294(ra) # 80001e42 <myproc>
    80003358:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000335a:	fdc42503          	lw	a0,-36(s0)
    8000335e:	fffff097          	auipc	ra,0xfffff
    80003362:	f3a080e7          	jalr	-198(ra) # 80002298 <growproc>
    80003366:	00054863          	bltz	a0,80003376 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000336a:	8526                	mv	a0,s1
}
    8000336c:	70a2                	ld	ra,40(sp)
    8000336e:	7402                	ld	s0,32(sp)
    80003370:	64e2                	ld	s1,24(sp)
    80003372:	6145                	addi	sp,sp,48
    80003374:	8082                	ret
    return -1;
    80003376:	557d                	li	a0,-1
    80003378:	bfd5                	j	8000336c <sys_sbrk+0x3c>

000000008000337a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000337a:	7139                	addi	sp,sp,-64
    8000337c:	fc06                	sd	ra,56(sp)
    8000337e:	f822                	sd	s0,48(sp)
    80003380:	f426                	sd	s1,40(sp)
    80003382:	f04a                	sd	s2,32(sp)
    80003384:	ec4e                	sd	s3,24(sp)
    80003386:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003388:	fcc40593          	addi	a1,s0,-52
    8000338c:	4501                	li	a0,0
    8000338e:	00000097          	auipc	ra,0x0
    80003392:	df0080e7          	jalr	-528(ra) # 8000317e <argint>
    return -1;
    80003396:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003398:	06054963          	bltz	a0,8000340a <sys_sleep+0x90>
  acquire(&tickslock);
    8000339c:	00015517          	auipc	a0,0x15
    800033a0:	fcc50513          	addi	a0,a0,-52 # 80018368 <tickslock>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	914080e7          	jalr	-1772(ra) # 80000cb8 <acquire>
  ticks0 = ticks;
    800033ac:	00006917          	auipc	s2,0x6
    800033b0:	c7492903          	lw	s2,-908(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    800033b4:	fcc42783          	lw	a5,-52(s0)
    800033b8:	cf85                	beqz	a5,800033f0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033ba:	00015997          	auipc	s3,0x15
    800033be:	fae98993          	addi	s3,s3,-82 # 80018368 <tickslock>
    800033c2:	00006497          	auipc	s1,0x6
    800033c6:	c5e48493          	addi	s1,s1,-930 # 80009020 <ticks>
    if(myproc()->killed){
    800033ca:	fffff097          	auipc	ra,0xfffff
    800033ce:	a78080e7          	jalr	-1416(ra) # 80001e42 <myproc>
    800033d2:	591c                	lw	a5,48(a0)
    800033d4:	e3b9                	bnez	a5,8000341a <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    800033d6:	85ce                	mv	a1,s3
    800033d8:	8526                	mv	a0,s1
    800033da:	fffff097          	auipc	ra,0xfffff
    800033de:	448080e7          	jalr	1096(ra) # 80002822 <sleep>
  while(ticks - ticks0 < n){
    800033e2:	409c                	lw	a5,0(s1)
    800033e4:	412787bb          	subw	a5,a5,s2
    800033e8:	fcc42703          	lw	a4,-52(s0)
    800033ec:	fce7efe3          	bltu	a5,a4,800033ca <sys_sleep+0x50>
  }
  release(&tickslock);
    800033f0:	00015517          	auipc	a0,0x15
    800033f4:	f7850513          	addi	a0,a0,-136 # 80018368 <tickslock>
    800033f8:	ffffe097          	auipc	ra,0xffffe
    800033fc:	974080e7          	jalr	-1676(ra) # 80000d6c <release>
  backtrace();
    80003400:	ffffd097          	auipc	ra,0xffffd
    80003404:	17a080e7          	jalr	378(ra) # 8000057a <backtrace>
  return 0;
    80003408:	4781                	li	a5,0
}
    8000340a:	853e                	mv	a0,a5
    8000340c:	70e2                	ld	ra,56(sp)
    8000340e:	7442                	ld	s0,48(sp)
    80003410:	74a2                	ld	s1,40(sp)
    80003412:	7902                	ld	s2,32(sp)
    80003414:	69e2                	ld	s3,24(sp)
    80003416:	6121                	addi	sp,sp,64
    80003418:	8082                	ret
      release(&tickslock);
    8000341a:	00015517          	auipc	a0,0x15
    8000341e:	f4e50513          	addi	a0,a0,-178 # 80018368 <tickslock>
    80003422:	ffffe097          	auipc	ra,0xffffe
    80003426:	94a080e7          	jalr	-1718(ra) # 80000d6c <release>
      return -1;
    8000342a:	57fd                	li	a5,-1
    8000342c:	bff9                	j	8000340a <sys_sleep+0x90>

000000008000342e <sys_kill>:

uint64
sys_kill(void)
{
    8000342e:	1101                	addi	sp,sp,-32
    80003430:	ec06                	sd	ra,24(sp)
    80003432:	e822                	sd	s0,16(sp)
    80003434:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003436:	fec40593          	addi	a1,s0,-20
    8000343a:	4501                	li	a0,0
    8000343c:	00000097          	auipc	ra,0x0
    80003440:	d42080e7          	jalr	-702(ra) # 8000317e <argint>
    80003444:	87aa                	mv	a5,a0
    return -1;
    80003446:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003448:	0007c863          	bltz	a5,80003458 <sys_kill+0x2a>
  return kill(pid);
    8000344c:	fec42503          	lw	a0,-20(s0)
    80003450:	fffff097          	auipc	ra,0xfffff
    80003454:	5c2080e7          	jalr	1474(ra) # 80002a12 <kill>
}
    80003458:	60e2                	ld	ra,24(sp)
    8000345a:	6442                	ld	s0,16(sp)
    8000345c:	6105                	addi	sp,sp,32
    8000345e:	8082                	ret

0000000080003460 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003460:	1101                	addi	sp,sp,-32
    80003462:	ec06                	sd	ra,24(sp)
    80003464:	e822                	sd	s0,16(sp)
    80003466:	e426                	sd	s1,8(sp)
    80003468:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000346a:	00015517          	auipc	a0,0x15
    8000346e:	efe50513          	addi	a0,a0,-258 # 80018368 <tickslock>
    80003472:	ffffe097          	auipc	ra,0xffffe
    80003476:	846080e7          	jalr	-1978(ra) # 80000cb8 <acquire>
  xticks = ticks;
    8000347a:	00006497          	auipc	s1,0x6
    8000347e:	ba64a483          	lw	s1,-1114(s1) # 80009020 <ticks>
  release(&tickslock);
    80003482:	00015517          	auipc	a0,0x15
    80003486:	ee650513          	addi	a0,a0,-282 # 80018368 <tickslock>
    8000348a:	ffffe097          	auipc	ra,0xffffe
    8000348e:	8e2080e7          	jalr	-1822(ra) # 80000d6c <release>
  return xticks;
}
    80003492:	02049513          	slli	a0,s1,0x20
    80003496:	9101                	srli	a0,a0,0x20
    80003498:	60e2                	ld	ra,24(sp)
    8000349a:	6442                	ld	s0,16(sp)
    8000349c:	64a2                	ld	s1,8(sp)
    8000349e:	6105                	addi	sp,sp,32
    800034a0:	8082                	ret

00000000800034a2 <sys_trace>:

// click the sys call number in p->tracemask
// so as to tracing its calling afterwards
uint64
sys_trace(void) {
    800034a2:	1101                	addi	sp,sp,-32
    800034a4:	ec06                	sd	ra,24(sp)
    800034a6:	e822                	sd	s0,16(sp)
    800034a8:	1000                	addi	s0,sp,32
  int trace_sys_mask;
  if (argint(0, &trace_sys_mask) < 0)
    800034aa:	fec40593          	addi	a1,s0,-20
    800034ae:	4501                	li	a0,0
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	cce080e7          	jalr	-818(ra) # 8000317e <argint>
    return -1;
    800034b8:	57fd                	li	a5,-1
  if (argint(0, &trace_sys_mask) < 0)
    800034ba:	00054e63          	bltz	a0,800034d6 <sys_trace+0x34>
  myproc()->tracemask |= trace_sys_mask;
    800034be:	fffff097          	auipc	ra,0xfffff
    800034c2:	984080e7          	jalr	-1660(ra) # 80001e42 <myproc>
    800034c6:	fec42703          	lw	a4,-20(s0)
    800034ca:	17053783          	ld	a5,368(a0)
    800034ce:	8fd9                	or	a5,a5,a4
    800034d0:	16f53823          	sd	a5,368(a0)
  return 0;
    800034d4:	4781                	li	a5,0
}
    800034d6:	853e                	mv	a0,a5
    800034d8:	60e2                	ld	ra,24(sp)
    800034da:	6442                	ld	s0,16(sp)
    800034dc:	6105                	addi	sp,sp,32
    800034de:	8082                	ret

00000000800034e0 <sys_sysinfo>:

// collect system info
uint64
sys_sysinfo(void) {
    800034e0:	7139                	addi	sp,sp,-64
    800034e2:	fc06                	sd	ra,56(sp)
    800034e4:	f822                	sd	s0,48(sp)
    800034e6:	f426                	sd	s1,40(sp)
    800034e8:	0080                	addi	s0,sp,64
  struct proc *my_proc = myproc();
    800034ea:	fffff097          	auipc	ra,0xfffff
    800034ee:	958080e7          	jalr	-1704(ra) # 80001e42 <myproc>
    800034f2:	84aa                	mv	s1,a0
  uint64 p;
  if(argaddr(0, &p) < 0)
    800034f4:	fd840593          	addi	a1,s0,-40
    800034f8:	4501                	li	a0,0
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	ca6080e7          	jalr	-858(ra) # 800031a0 <argaddr>
    return -1;
    80003502:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80003504:	02054a63          	bltz	a0,80003538 <sys_sysinfo+0x58>
  // construct in kernel first
  struct sysinfo s;
  s.freemem = kfreemem();
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	6d6080e7          	jalr	1750(ra) # 80000bde <kfreemem>
    80003510:	fca43423          	sd	a0,-56(s0)
  s.nproc = count_free_proc();
    80003514:	fffff097          	auipc	ra,0xfffff
    80003518:	6ca080e7          	jalr	1738(ra) # 80002bde <count_free_proc>
    8000351c:	fca43823          	sd	a0,-48(s0)
  // copy to user space
  if(copyout(my_proc->pagetable, p, (char *)&s, sizeof(s)) < 0)
    80003520:	46c1                	li	a3,16
    80003522:	fc840613          	addi	a2,s0,-56
    80003526:	fd843583          	ld	a1,-40(s0)
    8000352a:	68a8                	ld	a0,80(s1)
    8000352c:	ffffe097          	auipc	ra,0xffffe
    80003530:	3e8080e7          	jalr	1000(ra) # 80001914 <copyout>
    80003534:	43f55793          	srai	a5,a0,0x3f
    return -1;
  return 0;
}
    80003538:	853e                	mv	a0,a5
    8000353a:	70e2                	ld	ra,56(sp)
    8000353c:	7442                	ld	s0,48(sp)
    8000353e:	74a2                	ld	s1,40(sp)
    80003540:	6121                	addi	sp,sp,64
    80003542:	8082                	ret

0000000080003544 <sys_sigalarm>:

// set an alarm to call the handler function
// every period ticks
uint64
sys_sigalarm(void) {
    80003544:	7179                	addi	sp,sp,-48
    80003546:	f406                	sd	ra,40(sp)
    80003548:	f022                	sd	s0,32(sp)
    8000354a:	ec26                	sd	s1,24(sp)
    8000354c:	1800                	addi	s0,sp,48
  struct proc *my_proc = myproc();
    8000354e:	fffff097          	auipc	ra,0xfffff
    80003552:	8f4080e7          	jalr	-1804(ra) # 80001e42 <myproc>
    80003556:	84aa                	mv	s1,a0
  int period;
  if (argint(0, &period) < 0)
    80003558:	fdc40593          	addi	a1,s0,-36
    8000355c:	4501                	li	a0,0
    8000355e:	00000097          	auipc	ra,0x0
    80003562:	c20080e7          	jalr	-992(ra) # 8000317e <argint>
    return -1;
    80003566:	57fd                	li	a5,-1
  if (argint(0, &period) < 0)
    80003568:	02054863          	bltz	a0,80003598 <sys_sigalarm+0x54>
  uint64 p;
  if(argaddr(1, &p) < 0)
    8000356c:	fd040593          	addi	a1,s0,-48
    80003570:	4505                	li	a0,1
    80003572:	00000097          	auipc	ra,0x0
    80003576:	c2e080e7          	jalr	-978(ra) # 800031a0 <argaddr>
    8000357a:	02054563          	bltz	a0,800035a4 <sys_sigalarm+0x60>
    return -1;
  my_proc->alarm_period = period;
    8000357e:	fdc42783          	lw	a5,-36(s0)
    80003582:	18f4a023          	sw	a5,384(s1)
  my_proc->alarm_handler = (void (*)()) p;
    80003586:	fd043783          	ld	a5,-48(s0)
    8000358a:	18f4b423          	sd	a5,392(s1)
  my_proc->ticks_since_last_alarm = 0;
    8000358e:	1804a823          	sw	zero,400(s1)
  my_proc->inalarm = 0;
    80003592:	1804aa23          	sw	zero,404(s1)
  return 0;
    80003596:	4781                	li	a5,0
}
    80003598:	853e                	mv	a0,a5
    8000359a:	70a2                	ld	ra,40(sp)
    8000359c:	7402                	ld	s0,32(sp)
    8000359e:	64e2                	ld	s1,24(sp)
    800035a0:	6145                	addi	sp,sp,48
    800035a2:	8082                	ret
    return -1;
    800035a4:	57fd                	li	a5,-1
    800035a6:	bfcd                	j	80003598 <sys_sigalarm+0x54>

00000000800035a8 <sys_sigreturn>:

uint64
sys_sigreturn(void) {
    800035a8:	1141                	addi	sp,sp,-16
    800035aa:	e406                	sd	ra,8(sp)
    800035ac:	e022                	sd	s0,0(sp)
    800035ae:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    800035b0:	fffff097          	auipc	ra,0xfffff
    800035b4:	892080e7          	jalr	-1902(ra) # 80001e42 <myproc>
  if (p->inalarm) {
    800035b8:	19452783          	lw	a5,404(a0)
    800035bc:	cf85                	beqz	a5,800035f4 <sys_sigreturn+0x4c>
    p->inalarm = 0;
    800035be:	18052a23          	sw	zero,404(a0)
    *p->trapframe = *p->alarmframe;
    800035c2:	7134                	ld	a3,96(a0)
    800035c4:	87b6                	mv	a5,a3
    800035c6:	6d38                	ld	a4,88(a0)
    800035c8:	12068693          	addi	a3,a3,288
    800035cc:	0007b883          	ld	a7,0(a5)
    800035d0:	0087b803          	ld	a6,8(a5)
    800035d4:	6b8c                	ld	a1,16(a5)
    800035d6:	6f90                	ld	a2,24(a5)
    800035d8:	01173023          	sd	a7,0(a4)
    800035dc:	01073423          	sd	a6,8(a4)
    800035e0:	eb0c                	sd	a1,16(a4)
    800035e2:	ef10                	sd	a2,24(a4)
    800035e4:	02078793          	addi	a5,a5,32
    800035e8:	02070713          	addi	a4,a4,32
    800035ec:	fed790e3          	bne	a5,a3,800035cc <sys_sigreturn+0x24>
    p->ticks_since_last_alarm = 0;
    800035f0:	18052823          	sw	zero,400(a0)
  }
  return 0;
}
    800035f4:	4501                	li	a0,0
    800035f6:	60a2                	ld	ra,8(sp)
    800035f8:	6402                	ld	s0,0(sp)
    800035fa:	0141                	addi	sp,sp,16
    800035fc:	8082                	ret

00000000800035fe <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800035fe:	7179                	addi	sp,sp,-48
    80003600:	f406                	sd	ra,40(sp)
    80003602:	f022                	sd	s0,32(sp)
    80003604:	ec26                	sd	s1,24(sp)
    80003606:	e84a                	sd	s2,16(sp)
    80003608:	e44e                	sd	s3,8(sp)
    8000360a:	e052                	sd	s4,0(sp)
    8000360c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000360e:	00005597          	auipc	a1,0x5
    80003612:	1ba58593          	addi	a1,a1,442 # 800087c8 <sysnames+0xd0>
    80003616:	00015517          	auipc	a0,0x15
    8000361a:	d6a50513          	addi	a0,a0,-662 # 80018380 <bcache>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	60a080e7          	jalr	1546(ra) # 80000c28 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003626:	0001d797          	auipc	a5,0x1d
    8000362a:	d5a78793          	addi	a5,a5,-678 # 80020380 <bcache+0x8000>
    8000362e:	0001d717          	auipc	a4,0x1d
    80003632:	fba70713          	addi	a4,a4,-70 # 800205e8 <bcache+0x8268>
    80003636:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000363a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000363e:	00015497          	auipc	s1,0x15
    80003642:	d5a48493          	addi	s1,s1,-678 # 80018398 <bcache+0x18>
    b->next = bcache.head.next;
    80003646:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003648:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000364a:	00005a17          	auipc	s4,0x5
    8000364e:	186a0a13          	addi	s4,s4,390 # 800087d0 <sysnames+0xd8>
    b->next = bcache.head.next;
    80003652:	2b893783          	ld	a5,696(s2)
    80003656:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003658:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000365c:	85d2                	mv	a1,s4
    8000365e:	01048513          	addi	a0,s1,16
    80003662:	00001097          	auipc	ra,0x1
    80003666:	4ac080e7          	jalr	1196(ra) # 80004b0e <initsleeplock>
    bcache.head.next->prev = b;
    8000366a:	2b893783          	ld	a5,696(s2)
    8000366e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003670:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003674:	45848493          	addi	s1,s1,1112
    80003678:	fd349de3          	bne	s1,s3,80003652 <binit+0x54>
  }
}
    8000367c:	70a2                	ld	ra,40(sp)
    8000367e:	7402                	ld	s0,32(sp)
    80003680:	64e2                	ld	s1,24(sp)
    80003682:	6942                	ld	s2,16(sp)
    80003684:	69a2                	ld	s3,8(sp)
    80003686:	6a02                	ld	s4,0(sp)
    80003688:	6145                	addi	sp,sp,48
    8000368a:	8082                	ret

000000008000368c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000368c:	7179                	addi	sp,sp,-48
    8000368e:	f406                	sd	ra,40(sp)
    80003690:	f022                	sd	s0,32(sp)
    80003692:	ec26                	sd	s1,24(sp)
    80003694:	e84a                	sd	s2,16(sp)
    80003696:	e44e                	sd	s3,8(sp)
    80003698:	1800                	addi	s0,sp,48
    8000369a:	89aa                	mv	s3,a0
    8000369c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000369e:	00015517          	auipc	a0,0x15
    800036a2:	ce250513          	addi	a0,a0,-798 # 80018380 <bcache>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	612080e7          	jalr	1554(ra) # 80000cb8 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036ae:	0001d497          	auipc	s1,0x1d
    800036b2:	f8a4b483          	ld	s1,-118(s1) # 80020638 <bcache+0x82b8>
    800036b6:	0001d797          	auipc	a5,0x1d
    800036ba:	f3278793          	addi	a5,a5,-206 # 800205e8 <bcache+0x8268>
    800036be:	02f48f63          	beq	s1,a5,800036fc <bread+0x70>
    800036c2:	873e                	mv	a4,a5
    800036c4:	a021                	j	800036cc <bread+0x40>
    800036c6:	68a4                	ld	s1,80(s1)
    800036c8:	02e48a63          	beq	s1,a4,800036fc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800036cc:	449c                	lw	a5,8(s1)
    800036ce:	ff379ce3          	bne	a5,s3,800036c6 <bread+0x3a>
    800036d2:	44dc                	lw	a5,12(s1)
    800036d4:	ff2799e3          	bne	a5,s2,800036c6 <bread+0x3a>
      b->refcnt++;
    800036d8:	40bc                	lw	a5,64(s1)
    800036da:	2785                	addiw	a5,a5,1
    800036dc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036de:	00015517          	auipc	a0,0x15
    800036e2:	ca250513          	addi	a0,a0,-862 # 80018380 <bcache>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	686080e7          	jalr	1670(ra) # 80000d6c <release>
      acquiresleep(&b->lock);
    800036ee:	01048513          	addi	a0,s1,16
    800036f2:	00001097          	auipc	ra,0x1
    800036f6:	456080e7          	jalr	1110(ra) # 80004b48 <acquiresleep>
      return b;
    800036fa:	a8b9                	j	80003758 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036fc:	0001d497          	auipc	s1,0x1d
    80003700:	f344b483          	ld	s1,-204(s1) # 80020630 <bcache+0x82b0>
    80003704:	0001d797          	auipc	a5,0x1d
    80003708:	ee478793          	addi	a5,a5,-284 # 800205e8 <bcache+0x8268>
    8000370c:	00f48863          	beq	s1,a5,8000371c <bread+0x90>
    80003710:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003712:	40bc                	lw	a5,64(s1)
    80003714:	cf81                	beqz	a5,8000372c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003716:	64a4                	ld	s1,72(s1)
    80003718:	fee49de3          	bne	s1,a4,80003712 <bread+0x86>
  panic("bget: no buffers");
    8000371c:	00005517          	auipc	a0,0x5
    80003720:	0bc50513          	addi	a0,a0,188 # 800087d8 <sysnames+0xe0>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	eac080e7          	jalr	-340(ra) # 800005d0 <panic>
      b->dev = dev;
    8000372c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003730:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003734:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003738:	4785                	li	a5,1
    8000373a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000373c:	00015517          	auipc	a0,0x15
    80003740:	c4450513          	addi	a0,a0,-956 # 80018380 <bcache>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	628080e7          	jalr	1576(ra) # 80000d6c <release>
      acquiresleep(&b->lock);
    8000374c:	01048513          	addi	a0,s1,16
    80003750:	00001097          	auipc	ra,0x1
    80003754:	3f8080e7          	jalr	1016(ra) # 80004b48 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003758:	409c                	lw	a5,0(s1)
    8000375a:	cb89                	beqz	a5,8000376c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000375c:	8526                	mv	a0,s1
    8000375e:	70a2                	ld	ra,40(sp)
    80003760:	7402                	ld	s0,32(sp)
    80003762:	64e2                	ld	s1,24(sp)
    80003764:	6942                	ld	s2,16(sp)
    80003766:	69a2                	ld	s3,8(sp)
    80003768:	6145                	addi	sp,sp,48
    8000376a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000376c:	4581                	li	a1,0
    8000376e:	8526                	mv	a0,s1
    80003770:	00003097          	auipc	ra,0x3
    80003774:	f7c080e7          	jalr	-132(ra) # 800066ec <virtio_disk_rw>
    b->valid = 1;
    80003778:	4785                	li	a5,1
    8000377a:	c09c                	sw	a5,0(s1)
  return b;
    8000377c:	b7c5                	j	8000375c <bread+0xd0>

000000008000377e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000377e:	1101                	addi	sp,sp,-32
    80003780:	ec06                	sd	ra,24(sp)
    80003782:	e822                	sd	s0,16(sp)
    80003784:	e426                	sd	s1,8(sp)
    80003786:	1000                	addi	s0,sp,32
    80003788:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000378a:	0541                	addi	a0,a0,16
    8000378c:	00001097          	auipc	ra,0x1
    80003790:	456080e7          	jalr	1110(ra) # 80004be2 <holdingsleep>
    80003794:	cd01                	beqz	a0,800037ac <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003796:	4585                	li	a1,1
    80003798:	8526                	mv	a0,s1
    8000379a:	00003097          	auipc	ra,0x3
    8000379e:	f52080e7          	jalr	-174(ra) # 800066ec <virtio_disk_rw>
}
    800037a2:	60e2                	ld	ra,24(sp)
    800037a4:	6442                	ld	s0,16(sp)
    800037a6:	64a2                	ld	s1,8(sp)
    800037a8:	6105                	addi	sp,sp,32
    800037aa:	8082                	ret
    panic("bwrite");
    800037ac:	00005517          	auipc	a0,0x5
    800037b0:	04450513          	addi	a0,a0,68 # 800087f0 <sysnames+0xf8>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	e1c080e7          	jalr	-484(ra) # 800005d0 <panic>

00000000800037bc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037bc:	1101                	addi	sp,sp,-32
    800037be:	ec06                	sd	ra,24(sp)
    800037c0:	e822                	sd	s0,16(sp)
    800037c2:	e426                	sd	s1,8(sp)
    800037c4:	e04a                	sd	s2,0(sp)
    800037c6:	1000                	addi	s0,sp,32
    800037c8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037ca:	01050913          	addi	s2,a0,16
    800037ce:	854a                	mv	a0,s2
    800037d0:	00001097          	auipc	ra,0x1
    800037d4:	412080e7          	jalr	1042(ra) # 80004be2 <holdingsleep>
    800037d8:	c92d                	beqz	a0,8000384a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800037da:	854a                	mv	a0,s2
    800037dc:	00001097          	auipc	ra,0x1
    800037e0:	3c2080e7          	jalr	962(ra) # 80004b9e <releasesleep>

  acquire(&bcache.lock);
    800037e4:	00015517          	auipc	a0,0x15
    800037e8:	b9c50513          	addi	a0,a0,-1124 # 80018380 <bcache>
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	4cc080e7          	jalr	1228(ra) # 80000cb8 <acquire>
  b->refcnt--;
    800037f4:	40bc                	lw	a5,64(s1)
    800037f6:	37fd                	addiw	a5,a5,-1
    800037f8:	0007871b          	sext.w	a4,a5
    800037fc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800037fe:	eb05                	bnez	a4,8000382e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003800:	68bc                	ld	a5,80(s1)
    80003802:	64b8                	ld	a4,72(s1)
    80003804:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003806:	64bc                	ld	a5,72(s1)
    80003808:	68b8                	ld	a4,80(s1)
    8000380a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000380c:	0001d797          	auipc	a5,0x1d
    80003810:	b7478793          	addi	a5,a5,-1164 # 80020380 <bcache+0x8000>
    80003814:	2b87b703          	ld	a4,696(a5)
    80003818:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000381a:	0001d717          	auipc	a4,0x1d
    8000381e:	dce70713          	addi	a4,a4,-562 # 800205e8 <bcache+0x8268>
    80003822:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003824:	2b87b703          	ld	a4,696(a5)
    80003828:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000382a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000382e:	00015517          	auipc	a0,0x15
    80003832:	b5250513          	addi	a0,a0,-1198 # 80018380 <bcache>
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	536080e7          	jalr	1334(ra) # 80000d6c <release>
}
    8000383e:	60e2                	ld	ra,24(sp)
    80003840:	6442                	ld	s0,16(sp)
    80003842:	64a2                	ld	s1,8(sp)
    80003844:	6902                	ld	s2,0(sp)
    80003846:	6105                	addi	sp,sp,32
    80003848:	8082                	ret
    panic("brelse");
    8000384a:	00005517          	auipc	a0,0x5
    8000384e:	fae50513          	addi	a0,a0,-82 # 800087f8 <sysnames+0x100>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	d7e080e7          	jalr	-642(ra) # 800005d0 <panic>

000000008000385a <bpin>:

void
bpin(struct buf *b) {
    8000385a:	1101                	addi	sp,sp,-32
    8000385c:	ec06                	sd	ra,24(sp)
    8000385e:	e822                	sd	s0,16(sp)
    80003860:	e426                	sd	s1,8(sp)
    80003862:	1000                	addi	s0,sp,32
    80003864:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003866:	00015517          	auipc	a0,0x15
    8000386a:	b1a50513          	addi	a0,a0,-1254 # 80018380 <bcache>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	44a080e7          	jalr	1098(ra) # 80000cb8 <acquire>
  b->refcnt++;
    80003876:	40bc                	lw	a5,64(s1)
    80003878:	2785                	addiw	a5,a5,1
    8000387a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000387c:	00015517          	auipc	a0,0x15
    80003880:	b0450513          	addi	a0,a0,-1276 # 80018380 <bcache>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	4e8080e7          	jalr	1256(ra) # 80000d6c <release>
}
    8000388c:	60e2                	ld	ra,24(sp)
    8000388e:	6442                	ld	s0,16(sp)
    80003890:	64a2                	ld	s1,8(sp)
    80003892:	6105                	addi	sp,sp,32
    80003894:	8082                	ret

0000000080003896 <bunpin>:

void
bunpin(struct buf *b) {
    80003896:	1101                	addi	sp,sp,-32
    80003898:	ec06                	sd	ra,24(sp)
    8000389a:	e822                	sd	s0,16(sp)
    8000389c:	e426                	sd	s1,8(sp)
    8000389e:	1000                	addi	s0,sp,32
    800038a0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038a2:	00015517          	auipc	a0,0x15
    800038a6:	ade50513          	addi	a0,a0,-1314 # 80018380 <bcache>
    800038aa:	ffffd097          	auipc	ra,0xffffd
    800038ae:	40e080e7          	jalr	1038(ra) # 80000cb8 <acquire>
  b->refcnt--;
    800038b2:	40bc                	lw	a5,64(s1)
    800038b4:	37fd                	addiw	a5,a5,-1
    800038b6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038b8:	00015517          	auipc	a0,0x15
    800038bc:	ac850513          	addi	a0,a0,-1336 # 80018380 <bcache>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	4ac080e7          	jalr	1196(ra) # 80000d6c <release>
}
    800038c8:	60e2                	ld	ra,24(sp)
    800038ca:	6442                	ld	s0,16(sp)
    800038cc:	64a2                	ld	s1,8(sp)
    800038ce:	6105                	addi	sp,sp,32
    800038d0:	8082                	ret

00000000800038d2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800038d2:	1101                	addi	sp,sp,-32
    800038d4:	ec06                	sd	ra,24(sp)
    800038d6:	e822                	sd	s0,16(sp)
    800038d8:	e426                	sd	s1,8(sp)
    800038da:	e04a                	sd	s2,0(sp)
    800038dc:	1000                	addi	s0,sp,32
    800038de:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800038e0:	00d5d59b          	srliw	a1,a1,0xd
    800038e4:	0001d797          	auipc	a5,0x1d
    800038e8:	1787a783          	lw	a5,376(a5) # 80020a5c <sb+0x1c>
    800038ec:	9dbd                	addw	a1,a1,a5
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	d9e080e7          	jalr	-610(ra) # 8000368c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800038f6:	0074f713          	andi	a4,s1,7
    800038fa:	4785                	li	a5,1
    800038fc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003900:	14ce                	slli	s1,s1,0x33
    80003902:	90d9                	srli	s1,s1,0x36
    80003904:	00950733          	add	a4,a0,s1
    80003908:	05874703          	lbu	a4,88(a4)
    8000390c:	00e7f6b3          	and	a3,a5,a4
    80003910:	c69d                	beqz	a3,8000393e <bfree+0x6c>
    80003912:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003914:	94aa                	add	s1,s1,a0
    80003916:	fff7c793          	not	a5,a5
    8000391a:	8ff9                	and	a5,a5,a4
    8000391c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003920:	00001097          	auipc	ra,0x1
    80003924:	100080e7          	jalr	256(ra) # 80004a20 <log_write>
  brelse(bp);
    80003928:	854a                	mv	a0,s2
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	e92080e7          	jalr	-366(ra) # 800037bc <brelse>
}
    80003932:	60e2                	ld	ra,24(sp)
    80003934:	6442                	ld	s0,16(sp)
    80003936:	64a2                	ld	s1,8(sp)
    80003938:	6902                	ld	s2,0(sp)
    8000393a:	6105                	addi	sp,sp,32
    8000393c:	8082                	ret
    panic("freeing free block");
    8000393e:	00005517          	auipc	a0,0x5
    80003942:	ec250513          	addi	a0,a0,-318 # 80008800 <sysnames+0x108>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	c8a080e7          	jalr	-886(ra) # 800005d0 <panic>

000000008000394e <balloc>:
{
    8000394e:	711d                	addi	sp,sp,-96
    80003950:	ec86                	sd	ra,88(sp)
    80003952:	e8a2                	sd	s0,80(sp)
    80003954:	e4a6                	sd	s1,72(sp)
    80003956:	e0ca                	sd	s2,64(sp)
    80003958:	fc4e                	sd	s3,56(sp)
    8000395a:	f852                	sd	s4,48(sp)
    8000395c:	f456                	sd	s5,40(sp)
    8000395e:	f05a                	sd	s6,32(sp)
    80003960:	ec5e                	sd	s7,24(sp)
    80003962:	e862                	sd	s8,16(sp)
    80003964:	e466                	sd	s9,8(sp)
    80003966:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003968:	0001d797          	auipc	a5,0x1d
    8000396c:	0dc7a783          	lw	a5,220(a5) # 80020a44 <sb+0x4>
    80003970:	cbd1                	beqz	a5,80003a04 <balloc+0xb6>
    80003972:	8baa                	mv	s7,a0
    80003974:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003976:	0001db17          	auipc	s6,0x1d
    8000397a:	0cab0b13          	addi	s6,s6,202 # 80020a40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000397e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003980:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003982:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003984:	6c89                	lui	s9,0x2
    80003986:	a831                	j	800039a2 <balloc+0x54>
    brelse(bp);
    80003988:	854a                	mv	a0,s2
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	e32080e7          	jalr	-462(ra) # 800037bc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003992:	015c87bb          	addw	a5,s9,s5
    80003996:	00078a9b          	sext.w	s5,a5
    8000399a:	004b2703          	lw	a4,4(s6)
    8000399e:	06eaf363          	bgeu	s5,a4,80003a04 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800039a2:	41fad79b          	sraiw	a5,s5,0x1f
    800039a6:	0137d79b          	srliw	a5,a5,0x13
    800039aa:	015787bb          	addw	a5,a5,s5
    800039ae:	40d7d79b          	sraiw	a5,a5,0xd
    800039b2:	01cb2583          	lw	a1,28(s6)
    800039b6:	9dbd                	addw	a1,a1,a5
    800039b8:	855e                	mv	a0,s7
    800039ba:	00000097          	auipc	ra,0x0
    800039be:	cd2080e7          	jalr	-814(ra) # 8000368c <bread>
    800039c2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039c4:	004b2503          	lw	a0,4(s6)
    800039c8:	000a849b          	sext.w	s1,s5
    800039cc:	8662                	mv	a2,s8
    800039ce:	faa4fde3          	bgeu	s1,a0,80003988 <balloc+0x3a>
      m = 1 << (bi % 8);
    800039d2:	41f6579b          	sraiw	a5,a2,0x1f
    800039d6:	01d7d69b          	srliw	a3,a5,0x1d
    800039da:	00c6873b          	addw	a4,a3,a2
    800039de:	00777793          	andi	a5,a4,7
    800039e2:	9f95                	subw	a5,a5,a3
    800039e4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800039e8:	4037571b          	sraiw	a4,a4,0x3
    800039ec:	00e906b3          	add	a3,s2,a4
    800039f0:	0586c683          	lbu	a3,88(a3)
    800039f4:	00d7f5b3          	and	a1,a5,a3
    800039f8:	cd91                	beqz	a1,80003a14 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039fa:	2605                	addiw	a2,a2,1
    800039fc:	2485                	addiw	s1,s1,1
    800039fe:	fd4618e3          	bne	a2,s4,800039ce <balloc+0x80>
    80003a02:	b759                	j	80003988 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003a04:	00005517          	auipc	a0,0x5
    80003a08:	e1450513          	addi	a0,a0,-492 # 80008818 <sysnames+0x120>
    80003a0c:	ffffd097          	auipc	ra,0xffffd
    80003a10:	bc4080e7          	jalr	-1084(ra) # 800005d0 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a14:	974a                	add	a4,a4,s2
    80003a16:	8fd5                	or	a5,a5,a3
    80003a18:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a1c:	854a                	mv	a0,s2
    80003a1e:	00001097          	auipc	ra,0x1
    80003a22:	002080e7          	jalr	2(ra) # 80004a20 <log_write>
        brelse(bp);
    80003a26:	854a                	mv	a0,s2
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	d94080e7          	jalr	-620(ra) # 800037bc <brelse>
  bp = bread(dev, bno);
    80003a30:	85a6                	mv	a1,s1
    80003a32:	855e                	mv	a0,s7
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	c58080e7          	jalr	-936(ra) # 8000368c <bread>
    80003a3c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a3e:	40000613          	li	a2,1024
    80003a42:	4581                	li	a1,0
    80003a44:	05850513          	addi	a0,a0,88
    80003a48:	ffffd097          	auipc	ra,0xffffd
    80003a4c:	36c080e7          	jalr	876(ra) # 80000db4 <memset>
  log_write(bp);
    80003a50:	854a                	mv	a0,s2
    80003a52:	00001097          	auipc	ra,0x1
    80003a56:	fce080e7          	jalr	-50(ra) # 80004a20 <log_write>
  brelse(bp);
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	d60080e7          	jalr	-672(ra) # 800037bc <brelse>
}
    80003a64:	8526                	mv	a0,s1
    80003a66:	60e6                	ld	ra,88(sp)
    80003a68:	6446                	ld	s0,80(sp)
    80003a6a:	64a6                	ld	s1,72(sp)
    80003a6c:	6906                	ld	s2,64(sp)
    80003a6e:	79e2                	ld	s3,56(sp)
    80003a70:	7a42                	ld	s4,48(sp)
    80003a72:	7aa2                	ld	s5,40(sp)
    80003a74:	7b02                	ld	s6,32(sp)
    80003a76:	6be2                	ld	s7,24(sp)
    80003a78:	6c42                	ld	s8,16(sp)
    80003a7a:	6ca2                	ld	s9,8(sp)
    80003a7c:	6125                	addi	sp,sp,96
    80003a7e:	8082                	ret

0000000080003a80 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a80:	7179                	addi	sp,sp,-48
    80003a82:	f406                	sd	ra,40(sp)
    80003a84:	f022                	sd	s0,32(sp)
    80003a86:	ec26                	sd	s1,24(sp)
    80003a88:	e84a                	sd	s2,16(sp)
    80003a8a:	e44e                	sd	s3,8(sp)
    80003a8c:	e052                	sd	s4,0(sp)
    80003a8e:	1800                	addi	s0,sp,48
    80003a90:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a92:	47ad                	li	a5,11
    80003a94:	04b7fe63          	bgeu	a5,a1,80003af0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003a98:	ff45849b          	addiw	s1,a1,-12
    80003a9c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003aa0:	0ff00793          	li	a5,255
    80003aa4:	0ae7e363          	bltu	a5,a4,80003b4a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003aa8:	08052583          	lw	a1,128(a0)
    80003aac:	c5ad                	beqz	a1,80003b16 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003aae:	00092503          	lw	a0,0(s2)
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	bda080e7          	jalr	-1062(ra) # 8000368c <bread>
    80003aba:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003abc:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ac0:	02049593          	slli	a1,s1,0x20
    80003ac4:	9181                	srli	a1,a1,0x20
    80003ac6:	058a                	slli	a1,a1,0x2
    80003ac8:	00b784b3          	add	s1,a5,a1
    80003acc:	0004a983          	lw	s3,0(s1)
    80003ad0:	04098d63          	beqz	s3,80003b2a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003ad4:	8552                	mv	a0,s4
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	ce6080e7          	jalr	-794(ra) # 800037bc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003ade:	854e                	mv	a0,s3
    80003ae0:	70a2                	ld	ra,40(sp)
    80003ae2:	7402                	ld	s0,32(sp)
    80003ae4:	64e2                	ld	s1,24(sp)
    80003ae6:	6942                	ld	s2,16(sp)
    80003ae8:	69a2                	ld	s3,8(sp)
    80003aea:	6a02                	ld	s4,0(sp)
    80003aec:	6145                	addi	sp,sp,48
    80003aee:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003af0:	02059493          	slli	s1,a1,0x20
    80003af4:	9081                	srli	s1,s1,0x20
    80003af6:	048a                	slli	s1,s1,0x2
    80003af8:	94aa                	add	s1,s1,a0
    80003afa:	0504a983          	lw	s3,80(s1)
    80003afe:	fe0990e3          	bnez	s3,80003ade <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003b02:	4108                	lw	a0,0(a0)
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	e4a080e7          	jalr	-438(ra) # 8000394e <balloc>
    80003b0c:	0005099b          	sext.w	s3,a0
    80003b10:	0534a823          	sw	s3,80(s1)
    80003b14:	b7e9                	j	80003ade <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003b16:	4108                	lw	a0,0(a0)
    80003b18:	00000097          	auipc	ra,0x0
    80003b1c:	e36080e7          	jalr	-458(ra) # 8000394e <balloc>
    80003b20:	0005059b          	sext.w	a1,a0
    80003b24:	08b92023          	sw	a1,128(s2)
    80003b28:	b759                	j	80003aae <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003b2a:	00092503          	lw	a0,0(s2)
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	e20080e7          	jalr	-480(ra) # 8000394e <balloc>
    80003b36:	0005099b          	sext.w	s3,a0
    80003b3a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003b3e:	8552                	mv	a0,s4
    80003b40:	00001097          	auipc	ra,0x1
    80003b44:	ee0080e7          	jalr	-288(ra) # 80004a20 <log_write>
    80003b48:	b771                	j	80003ad4 <bmap+0x54>
  panic("bmap: out of range");
    80003b4a:	00005517          	auipc	a0,0x5
    80003b4e:	ce650513          	addi	a0,a0,-794 # 80008830 <sysnames+0x138>
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	a7e080e7          	jalr	-1410(ra) # 800005d0 <panic>

0000000080003b5a <iget>:
{
    80003b5a:	7179                	addi	sp,sp,-48
    80003b5c:	f406                	sd	ra,40(sp)
    80003b5e:	f022                	sd	s0,32(sp)
    80003b60:	ec26                	sd	s1,24(sp)
    80003b62:	e84a                	sd	s2,16(sp)
    80003b64:	e44e                	sd	s3,8(sp)
    80003b66:	e052                	sd	s4,0(sp)
    80003b68:	1800                	addi	s0,sp,48
    80003b6a:	89aa                	mv	s3,a0
    80003b6c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003b6e:	0001d517          	auipc	a0,0x1d
    80003b72:	ef250513          	addi	a0,a0,-270 # 80020a60 <icache>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	142080e7          	jalr	322(ra) # 80000cb8 <acquire>
  empty = 0;
    80003b7e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003b80:	0001d497          	auipc	s1,0x1d
    80003b84:	ef848493          	addi	s1,s1,-264 # 80020a78 <icache+0x18>
    80003b88:	0001f697          	auipc	a3,0x1f
    80003b8c:	98068693          	addi	a3,a3,-1664 # 80022508 <log>
    80003b90:	a039                	j	80003b9e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b92:	02090b63          	beqz	s2,80003bc8 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003b96:	08848493          	addi	s1,s1,136
    80003b9a:	02d48a63          	beq	s1,a3,80003bce <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b9e:	449c                	lw	a5,8(s1)
    80003ba0:	fef059e3          	blez	a5,80003b92 <iget+0x38>
    80003ba4:	4098                	lw	a4,0(s1)
    80003ba6:	ff3716e3          	bne	a4,s3,80003b92 <iget+0x38>
    80003baa:	40d8                	lw	a4,4(s1)
    80003bac:	ff4713e3          	bne	a4,s4,80003b92 <iget+0x38>
      ip->ref++;
    80003bb0:	2785                	addiw	a5,a5,1
    80003bb2:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003bb4:	0001d517          	auipc	a0,0x1d
    80003bb8:	eac50513          	addi	a0,a0,-340 # 80020a60 <icache>
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	1b0080e7          	jalr	432(ra) # 80000d6c <release>
      return ip;
    80003bc4:	8926                	mv	s2,s1
    80003bc6:	a03d                	j	80003bf4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bc8:	f7f9                	bnez	a5,80003b96 <iget+0x3c>
    80003bca:	8926                	mv	s2,s1
    80003bcc:	b7e9                	j	80003b96 <iget+0x3c>
  if(empty == 0)
    80003bce:	02090c63          	beqz	s2,80003c06 <iget+0xac>
  ip->dev = dev;
    80003bd2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003bd6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003bda:	4785                	li	a5,1
    80003bdc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003be0:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003be4:	0001d517          	auipc	a0,0x1d
    80003be8:	e7c50513          	addi	a0,a0,-388 # 80020a60 <icache>
    80003bec:	ffffd097          	auipc	ra,0xffffd
    80003bf0:	180080e7          	jalr	384(ra) # 80000d6c <release>
}
    80003bf4:	854a                	mv	a0,s2
    80003bf6:	70a2                	ld	ra,40(sp)
    80003bf8:	7402                	ld	s0,32(sp)
    80003bfa:	64e2                	ld	s1,24(sp)
    80003bfc:	6942                	ld	s2,16(sp)
    80003bfe:	69a2                	ld	s3,8(sp)
    80003c00:	6a02                	ld	s4,0(sp)
    80003c02:	6145                	addi	sp,sp,48
    80003c04:	8082                	ret
    panic("iget: no inodes");
    80003c06:	00005517          	auipc	a0,0x5
    80003c0a:	c4250513          	addi	a0,a0,-958 # 80008848 <sysnames+0x150>
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	9c2080e7          	jalr	-1598(ra) # 800005d0 <panic>

0000000080003c16 <fsinit>:
fsinit(int dev) {
    80003c16:	7179                	addi	sp,sp,-48
    80003c18:	f406                	sd	ra,40(sp)
    80003c1a:	f022                	sd	s0,32(sp)
    80003c1c:	ec26                	sd	s1,24(sp)
    80003c1e:	e84a                	sd	s2,16(sp)
    80003c20:	e44e                	sd	s3,8(sp)
    80003c22:	1800                	addi	s0,sp,48
    80003c24:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c26:	4585                	li	a1,1
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	a64080e7          	jalr	-1436(ra) # 8000368c <bread>
    80003c30:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c32:	0001d997          	auipc	s3,0x1d
    80003c36:	e0e98993          	addi	s3,s3,-498 # 80020a40 <sb>
    80003c3a:	02000613          	li	a2,32
    80003c3e:	05850593          	addi	a1,a0,88
    80003c42:	854e                	mv	a0,s3
    80003c44:	ffffd097          	auipc	ra,0xffffd
    80003c48:	1d0080e7          	jalr	464(ra) # 80000e14 <memmove>
  brelse(bp);
    80003c4c:	8526                	mv	a0,s1
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	b6e080e7          	jalr	-1170(ra) # 800037bc <brelse>
  if(sb.magic != FSMAGIC)
    80003c56:	0009a703          	lw	a4,0(s3)
    80003c5a:	102037b7          	lui	a5,0x10203
    80003c5e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c62:	02f71263          	bne	a4,a5,80003c86 <fsinit+0x70>
  initlog(dev, &sb);
    80003c66:	0001d597          	auipc	a1,0x1d
    80003c6a:	dda58593          	addi	a1,a1,-550 # 80020a40 <sb>
    80003c6e:	854a                	mv	a0,s2
    80003c70:	00001097          	auipc	ra,0x1
    80003c74:	b38080e7          	jalr	-1224(ra) # 800047a8 <initlog>
}
    80003c78:	70a2                	ld	ra,40(sp)
    80003c7a:	7402                	ld	s0,32(sp)
    80003c7c:	64e2                	ld	s1,24(sp)
    80003c7e:	6942                	ld	s2,16(sp)
    80003c80:	69a2                	ld	s3,8(sp)
    80003c82:	6145                	addi	sp,sp,48
    80003c84:	8082                	ret
    panic("invalid file system");
    80003c86:	00005517          	auipc	a0,0x5
    80003c8a:	bd250513          	addi	a0,a0,-1070 # 80008858 <sysnames+0x160>
    80003c8e:	ffffd097          	auipc	ra,0xffffd
    80003c92:	942080e7          	jalr	-1726(ra) # 800005d0 <panic>

0000000080003c96 <iinit>:
{
    80003c96:	7179                	addi	sp,sp,-48
    80003c98:	f406                	sd	ra,40(sp)
    80003c9a:	f022                	sd	s0,32(sp)
    80003c9c:	ec26                	sd	s1,24(sp)
    80003c9e:	e84a                	sd	s2,16(sp)
    80003ca0:	e44e                	sd	s3,8(sp)
    80003ca2:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003ca4:	00005597          	auipc	a1,0x5
    80003ca8:	bcc58593          	addi	a1,a1,-1076 # 80008870 <sysnames+0x178>
    80003cac:	0001d517          	auipc	a0,0x1d
    80003cb0:	db450513          	addi	a0,a0,-588 # 80020a60 <icache>
    80003cb4:	ffffd097          	auipc	ra,0xffffd
    80003cb8:	f74080e7          	jalr	-140(ra) # 80000c28 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003cbc:	0001d497          	auipc	s1,0x1d
    80003cc0:	dcc48493          	addi	s1,s1,-564 # 80020a88 <icache+0x28>
    80003cc4:	0001f997          	auipc	s3,0x1f
    80003cc8:	85498993          	addi	s3,s3,-1964 # 80022518 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003ccc:	00005917          	auipc	s2,0x5
    80003cd0:	bac90913          	addi	s2,s2,-1108 # 80008878 <sysnames+0x180>
    80003cd4:	85ca                	mv	a1,s2
    80003cd6:	8526                	mv	a0,s1
    80003cd8:	00001097          	auipc	ra,0x1
    80003cdc:	e36080e7          	jalr	-458(ra) # 80004b0e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ce0:	08848493          	addi	s1,s1,136
    80003ce4:	ff3498e3          	bne	s1,s3,80003cd4 <iinit+0x3e>
}
    80003ce8:	70a2                	ld	ra,40(sp)
    80003cea:	7402                	ld	s0,32(sp)
    80003cec:	64e2                	ld	s1,24(sp)
    80003cee:	6942                	ld	s2,16(sp)
    80003cf0:	69a2                	ld	s3,8(sp)
    80003cf2:	6145                	addi	sp,sp,48
    80003cf4:	8082                	ret

0000000080003cf6 <ialloc>:
{
    80003cf6:	715d                	addi	sp,sp,-80
    80003cf8:	e486                	sd	ra,72(sp)
    80003cfa:	e0a2                	sd	s0,64(sp)
    80003cfc:	fc26                	sd	s1,56(sp)
    80003cfe:	f84a                	sd	s2,48(sp)
    80003d00:	f44e                	sd	s3,40(sp)
    80003d02:	f052                	sd	s4,32(sp)
    80003d04:	ec56                	sd	s5,24(sp)
    80003d06:	e85a                	sd	s6,16(sp)
    80003d08:	e45e                	sd	s7,8(sp)
    80003d0a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d0c:	0001d717          	auipc	a4,0x1d
    80003d10:	d4072703          	lw	a4,-704(a4) # 80020a4c <sb+0xc>
    80003d14:	4785                	li	a5,1
    80003d16:	04e7fa63          	bgeu	a5,a4,80003d6a <ialloc+0x74>
    80003d1a:	8aaa                	mv	s5,a0
    80003d1c:	8bae                	mv	s7,a1
    80003d1e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d20:	0001da17          	auipc	s4,0x1d
    80003d24:	d20a0a13          	addi	s4,s4,-736 # 80020a40 <sb>
    80003d28:	00048b1b          	sext.w	s6,s1
    80003d2c:	0044d593          	srli	a1,s1,0x4
    80003d30:	018a2783          	lw	a5,24(s4)
    80003d34:	9dbd                	addw	a1,a1,a5
    80003d36:	8556                	mv	a0,s5
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	954080e7          	jalr	-1708(ra) # 8000368c <bread>
    80003d40:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d42:	05850993          	addi	s3,a0,88
    80003d46:	00f4f793          	andi	a5,s1,15
    80003d4a:	079a                	slli	a5,a5,0x6
    80003d4c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d4e:	00099783          	lh	a5,0(s3)
    80003d52:	c785                	beqz	a5,80003d7a <ialloc+0x84>
    brelse(bp);
    80003d54:	00000097          	auipc	ra,0x0
    80003d58:	a68080e7          	jalr	-1432(ra) # 800037bc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d5c:	0485                	addi	s1,s1,1
    80003d5e:	00ca2703          	lw	a4,12(s4)
    80003d62:	0004879b          	sext.w	a5,s1
    80003d66:	fce7e1e3          	bltu	a5,a4,80003d28 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003d6a:	00005517          	auipc	a0,0x5
    80003d6e:	b1650513          	addi	a0,a0,-1258 # 80008880 <sysnames+0x188>
    80003d72:	ffffd097          	auipc	ra,0xffffd
    80003d76:	85e080e7          	jalr	-1954(ra) # 800005d0 <panic>
      memset(dip, 0, sizeof(*dip));
    80003d7a:	04000613          	li	a2,64
    80003d7e:	4581                	li	a1,0
    80003d80:	854e                	mv	a0,s3
    80003d82:	ffffd097          	auipc	ra,0xffffd
    80003d86:	032080e7          	jalr	50(ra) # 80000db4 <memset>
      dip->type = type;
    80003d8a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d8e:	854a                	mv	a0,s2
    80003d90:	00001097          	auipc	ra,0x1
    80003d94:	c90080e7          	jalr	-880(ra) # 80004a20 <log_write>
      brelse(bp);
    80003d98:	854a                	mv	a0,s2
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	a22080e7          	jalr	-1502(ra) # 800037bc <brelse>
      return iget(dev, inum);
    80003da2:	85da                	mv	a1,s6
    80003da4:	8556                	mv	a0,s5
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	db4080e7          	jalr	-588(ra) # 80003b5a <iget>
}
    80003dae:	60a6                	ld	ra,72(sp)
    80003db0:	6406                	ld	s0,64(sp)
    80003db2:	74e2                	ld	s1,56(sp)
    80003db4:	7942                	ld	s2,48(sp)
    80003db6:	79a2                	ld	s3,40(sp)
    80003db8:	7a02                	ld	s4,32(sp)
    80003dba:	6ae2                	ld	s5,24(sp)
    80003dbc:	6b42                	ld	s6,16(sp)
    80003dbe:	6ba2                	ld	s7,8(sp)
    80003dc0:	6161                	addi	sp,sp,80
    80003dc2:	8082                	ret

0000000080003dc4 <iupdate>:
{
    80003dc4:	1101                	addi	sp,sp,-32
    80003dc6:	ec06                	sd	ra,24(sp)
    80003dc8:	e822                	sd	s0,16(sp)
    80003dca:	e426                	sd	s1,8(sp)
    80003dcc:	e04a                	sd	s2,0(sp)
    80003dce:	1000                	addi	s0,sp,32
    80003dd0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003dd2:	415c                	lw	a5,4(a0)
    80003dd4:	0047d79b          	srliw	a5,a5,0x4
    80003dd8:	0001d597          	auipc	a1,0x1d
    80003ddc:	c805a583          	lw	a1,-896(a1) # 80020a58 <sb+0x18>
    80003de0:	9dbd                	addw	a1,a1,a5
    80003de2:	4108                	lw	a0,0(a0)
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	8a8080e7          	jalr	-1880(ra) # 8000368c <bread>
    80003dec:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003dee:	05850793          	addi	a5,a0,88
    80003df2:	40c8                	lw	a0,4(s1)
    80003df4:	893d                	andi	a0,a0,15
    80003df6:	051a                	slli	a0,a0,0x6
    80003df8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003dfa:	04449703          	lh	a4,68(s1)
    80003dfe:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e02:	04649703          	lh	a4,70(s1)
    80003e06:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e0a:	04849703          	lh	a4,72(s1)
    80003e0e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e12:	04a49703          	lh	a4,74(s1)
    80003e16:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e1a:	44f8                	lw	a4,76(s1)
    80003e1c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e1e:	03400613          	li	a2,52
    80003e22:	05048593          	addi	a1,s1,80
    80003e26:	0531                	addi	a0,a0,12
    80003e28:	ffffd097          	auipc	ra,0xffffd
    80003e2c:	fec080e7          	jalr	-20(ra) # 80000e14 <memmove>
  log_write(bp);
    80003e30:	854a                	mv	a0,s2
    80003e32:	00001097          	auipc	ra,0x1
    80003e36:	bee080e7          	jalr	-1042(ra) # 80004a20 <log_write>
  brelse(bp);
    80003e3a:	854a                	mv	a0,s2
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	980080e7          	jalr	-1664(ra) # 800037bc <brelse>
}
    80003e44:	60e2                	ld	ra,24(sp)
    80003e46:	6442                	ld	s0,16(sp)
    80003e48:	64a2                	ld	s1,8(sp)
    80003e4a:	6902                	ld	s2,0(sp)
    80003e4c:	6105                	addi	sp,sp,32
    80003e4e:	8082                	ret

0000000080003e50 <idup>:
{
    80003e50:	1101                	addi	sp,sp,-32
    80003e52:	ec06                	sd	ra,24(sp)
    80003e54:	e822                	sd	s0,16(sp)
    80003e56:	e426                	sd	s1,8(sp)
    80003e58:	1000                	addi	s0,sp,32
    80003e5a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003e5c:	0001d517          	auipc	a0,0x1d
    80003e60:	c0450513          	addi	a0,a0,-1020 # 80020a60 <icache>
    80003e64:	ffffd097          	auipc	ra,0xffffd
    80003e68:	e54080e7          	jalr	-428(ra) # 80000cb8 <acquire>
  ip->ref++;
    80003e6c:	449c                	lw	a5,8(s1)
    80003e6e:	2785                	addiw	a5,a5,1
    80003e70:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003e72:	0001d517          	auipc	a0,0x1d
    80003e76:	bee50513          	addi	a0,a0,-1042 # 80020a60 <icache>
    80003e7a:	ffffd097          	auipc	ra,0xffffd
    80003e7e:	ef2080e7          	jalr	-270(ra) # 80000d6c <release>
}
    80003e82:	8526                	mv	a0,s1
    80003e84:	60e2                	ld	ra,24(sp)
    80003e86:	6442                	ld	s0,16(sp)
    80003e88:	64a2                	ld	s1,8(sp)
    80003e8a:	6105                	addi	sp,sp,32
    80003e8c:	8082                	ret

0000000080003e8e <ilock>:
{
    80003e8e:	1101                	addi	sp,sp,-32
    80003e90:	ec06                	sd	ra,24(sp)
    80003e92:	e822                	sd	s0,16(sp)
    80003e94:	e426                	sd	s1,8(sp)
    80003e96:	e04a                	sd	s2,0(sp)
    80003e98:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e9a:	c115                	beqz	a0,80003ebe <ilock+0x30>
    80003e9c:	84aa                	mv	s1,a0
    80003e9e:	451c                	lw	a5,8(a0)
    80003ea0:	00f05f63          	blez	a5,80003ebe <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ea4:	0541                	addi	a0,a0,16
    80003ea6:	00001097          	auipc	ra,0x1
    80003eaa:	ca2080e7          	jalr	-862(ra) # 80004b48 <acquiresleep>
  if(ip->valid == 0){
    80003eae:	40bc                	lw	a5,64(s1)
    80003eb0:	cf99                	beqz	a5,80003ece <ilock+0x40>
}
    80003eb2:	60e2                	ld	ra,24(sp)
    80003eb4:	6442                	ld	s0,16(sp)
    80003eb6:	64a2                	ld	s1,8(sp)
    80003eb8:	6902                	ld	s2,0(sp)
    80003eba:	6105                	addi	sp,sp,32
    80003ebc:	8082                	ret
    panic("ilock");
    80003ebe:	00005517          	auipc	a0,0x5
    80003ec2:	9da50513          	addi	a0,a0,-1574 # 80008898 <sysnames+0x1a0>
    80003ec6:	ffffc097          	auipc	ra,0xffffc
    80003eca:	70a080e7          	jalr	1802(ra) # 800005d0 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ece:	40dc                	lw	a5,4(s1)
    80003ed0:	0047d79b          	srliw	a5,a5,0x4
    80003ed4:	0001d597          	auipc	a1,0x1d
    80003ed8:	b845a583          	lw	a1,-1148(a1) # 80020a58 <sb+0x18>
    80003edc:	9dbd                	addw	a1,a1,a5
    80003ede:	4088                	lw	a0,0(s1)
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	7ac080e7          	jalr	1964(ra) # 8000368c <bread>
    80003ee8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003eea:	05850593          	addi	a1,a0,88
    80003eee:	40dc                	lw	a5,4(s1)
    80003ef0:	8bbd                	andi	a5,a5,15
    80003ef2:	079a                	slli	a5,a5,0x6
    80003ef4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ef6:	00059783          	lh	a5,0(a1)
    80003efa:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003efe:	00259783          	lh	a5,2(a1)
    80003f02:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f06:	00459783          	lh	a5,4(a1)
    80003f0a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f0e:	00659783          	lh	a5,6(a1)
    80003f12:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f16:	459c                	lw	a5,8(a1)
    80003f18:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f1a:	03400613          	li	a2,52
    80003f1e:	05b1                	addi	a1,a1,12
    80003f20:	05048513          	addi	a0,s1,80
    80003f24:	ffffd097          	auipc	ra,0xffffd
    80003f28:	ef0080e7          	jalr	-272(ra) # 80000e14 <memmove>
    brelse(bp);
    80003f2c:	854a                	mv	a0,s2
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	88e080e7          	jalr	-1906(ra) # 800037bc <brelse>
    ip->valid = 1;
    80003f36:	4785                	li	a5,1
    80003f38:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f3a:	04449783          	lh	a5,68(s1)
    80003f3e:	fbb5                	bnez	a5,80003eb2 <ilock+0x24>
      panic("ilock: no type");
    80003f40:	00005517          	auipc	a0,0x5
    80003f44:	96050513          	addi	a0,a0,-1696 # 800088a0 <sysnames+0x1a8>
    80003f48:	ffffc097          	auipc	ra,0xffffc
    80003f4c:	688080e7          	jalr	1672(ra) # 800005d0 <panic>

0000000080003f50 <iunlock>:
{
    80003f50:	1101                	addi	sp,sp,-32
    80003f52:	ec06                	sd	ra,24(sp)
    80003f54:	e822                	sd	s0,16(sp)
    80003f56:	e426                	sd	s1,8(sp)
    80003f58:	e04a                	sd	s2,0(sp)
    80003f5a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f5c:	c905                	beqz	a0,80003f8c <iunlock+0x3c>
    80003f5e:	84aa                	mv	s1,a0
    80003f60:	01050913          	addi	s2,a0,16
    80003f64:	854a                	mv	a0,s2
    80003f66:	00001097          	auipc	ra,0x1
    80003f6a:	c7c080e7          	jalr	-900(ra) # 80004be2 <holdingsleep>
    80003f6e:	cd19                	beqz	a0,80003f8c <iunlock+0x3c>
    80003f70:	449c                	lw	a5,8(s1)
    80003f72:	00f05d63          	blez	a5,80003f8c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f76:	854a                	mv	a0,s2
    80003f78:	00001097          	auipc	ra,0x1
    80003f7c:	c26080e7          	jalr	-986(ra) # 80004b9e <releasesleep>
}
    80003f80:	60e2                	ld	ra,24(sp)
    80003f82:	6442                	ld	s0,16(sp)
    80003f84:	64a2                	ld	s1,8(sp)
    80003f86:	6902                	ld	s2,0(sp)
    80003f88:	6105                	addi	sp,sp,32
    80003f8a:	8082                	ret
    panic("iunlock");
    80003f8c:	00005517          	auipc	a0,0x5
    80003f90:	92450513          	addi	a0,a0,-1756 # 800088b0 <sysnames+0x1b8>
    80003f94:	ffffc097          	auipc	ra,0xffffc
    80003f98:	63c080e7          	jalr	1596(ra) # 800005d0 <panic>

0000000080003f9c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f9c:	7179                	addi	sp,sp,-48
    80003f9e:	f406                	sd	ra,40(sp)
    80003fa0:	f022                	sd	s0,32(sp)
    80003fa2:	ec26                	sd	s1,24(sp)
    80003fa4:	e84a                	sd	s2,16(sp)
    80003fa6:	e44e                	sd	s3,8(sp)
    80003fa8:	e052                	sd	s4,0(sp)
    80003faa:	1800                	addi	s0,sp,48
    80003fac:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003fae:	05050493          	addi	s1,a0,80
    80003fb2:	08050913          	addi	s2,a0,128
    80003fb6:	a021                	j	80003fbe <itrunc+0x22>
    80003fb8:	0491                	addi	s1,s1,4
    80003fba:	01248d63          	beq	s1,s2,80003fd4 <itrunc+0x38>
    if(ip->addrs[i]){
    80003fbe:	408c                	lw	a1,0(s1)
    80003fc0:	dde5                	beqz	a1,80003fb8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003fc2:	0009a503          	lw	a0,0(s3)
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	90c080e7          	jalr	-1780(ra) # 800038d2 <bfree>
      ip->addrs[i] = 0;
    80003fce:	0004a023          	sw	zero,0(s1)
    80003fd2:	b7dd                	j	80003fb8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003fd4:	0809a583          	lw	a1,128(s3)
    80003fd8:	e185                	bnez	a1,80003ff8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003fda:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003fde:	854e                	mv	a0,s3
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	de4080e7          	jalr	-540(ra) # 80003dc4 <iupdate>
}
    80003fe8:	70a2                	ld	ra,40(sp)
    80003fea:	7402                	ld	s0,32(sp)
    80003fec:	64e2                	ld	s1,24(sp)
    80003fee:	6942                	ld	s2,16(sp)
    80003ff0:	69a2                	ld	s3,8(sp)
    80003ff2:	6a02                	ld	s4,0(sp)
    80003ff4:	6145                	addi	sp,sp,48
    80003ff6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ff8:	0009a503          	lw	a0,0(s3)
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	690080e7          	jalr	1680(ra) # 8000368c <bread>
    80004004:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004006:	05850493          	addi	s1,a0,88
    8000400a:	45850913          	addi	s2,a0,1112
    8000400e:	a811                	j	80004022 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004010:	0009a503          	lw	a0,0(s3)
    80004014:	00000097          	auipc	ra,0x0
    80004018:	8be080e7          	jalr	-1858(ra) # 800038d2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000401c:	0491                	addi	s1,s1,4
    8000401e:	01248563          	beq	s1,s2,80004028 <itrunc+0x8c>
      if(a[j])
    80004022:	408c                	lw	a1,0(s1)
    80004024:	dde5                	beqz	a1,8000401c <itrunc+0x80>
    80004026:	b7ed                	j	80004010 <itrunc+0x74>
    brelse(bp);
    80004028:	8552                	mv	a0,s4
    8000402a:	fffff097          	auipc	ra,0xfffff
    8000402e:	792080e7          	jalr	1938(ra) # 800037bc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004032:	0809a583          	lw	a1,128(s3)
    80004036:	0009a503          	lw	a0,0(s3)
    8000403a:	00000097          	auipc	ra,0x0
    8000403e:	898080e7          	jalr	-1896(ra) # 800038d2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004042:	0809a023          	sw	zero,128(s3)
    80004046:	bf51                	j	80003fda <itrunc+0x3e>

0000000080004048 <iput>:
{
    80004048:	1101                	addi	sp,sp,-32
    8000404a:	ec06                	sd	ra,24(sp)
    8000404c:	e822                	sd	s0,16(sp)
    8000404e:	e426                	sd	s1,8(sp)
    80004050:	e04a                	sd	s2,0(sp)
    80004052:	1000                	addi	s0,sp,32
    80004054:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80004056:	0001d517          	auipc	a0,0x1d
    8000405a:	a0a50513          	addi	a0,a0,-1526 # 80020a60 <icache>
    8000405e:	ffffd097          	auipc	ra,0xffffd
    80004062:	c5a080e7          	jalr	-934(ra) # 80000cb8 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004066:	4498                	lw	a4,8(s1)
    80004068:	4785                	li	a5,1
    8000406a:	02f70363          	beq	a4,a5,80004090 <iput+0x48>
  ip->ref--;
    8000406e:	449c                	lw	a5,8(s1)
    80004070:	37fd                	addiw	a5,a5,-1
    80004072:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80004074:	0001d517          	auipc	a0,0x1d
    80004078:	9ec50513          	addi	a0,a0,-1556 # 80020a60 <icache>
    8000407c:	ffffd097          	auipc	ra,0xffffd
    80004080:	cf0080e7          	jalr	-784(ra) # 80000d6c <release>
}
    80004084:	60e2                	ld	ra,24(sp)
    80004086:	6442                	ld	s0,16(sp)
    80004088:	64a2                	ld	s1,8(sp)
    8000408a:	6902                	ld	s2,0(sp)
    8000408c:	6105                	addi	sp,sp,32
    8000408e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004090:	40bc                	lw	a5,64(s1)
    80004092:	dff1                	beqz	a5,8000406e <iput+0x26>
    80004094:	04a49783          	lh	a5,74(s1)
    80004098:	fbf9                	bnez	a5,8000406e <iput+0x26>
    acquiresleep(&ip->lock);
    8000409a:	01048913          	addi	s2,s1,16
    8000409e:	854a                	mv	a0,s2
    800040a0:	00001097          	auipc	ra,0x1
    800040a4:	aa8080e7          	jalr	-1368(ra) # 80004b48 <acquiresleep>
    release(&icache.lock);
    800040a8:	0001d517          	auipc	a0,0x1d
    800040ac:	9b850513          	addi	a0,a0,-1608 # 80020a60 <icache>
    800040b0:	ffffd097          	auipc	ra,0xffffd
    800040b4:	cbc080e7          	jalr	-836(ra) # 80000d6c <release>
    itrunc(ip);
    800040b8:	8526                	mv	a0,s1
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	ee2080e7          	jalr	-286(ra) # 80003f9c <itrunc>
    ip->type = 0;
    800040c2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800040c6:	8526                	mv	a0,s1
    800040c8:	00000097          	auipc	ra,0x0
    800040cc:	cfc080e7          	jalr	-772(ra) # 80003dc4 <iupdate>
    ip->valid = 0;
    800040d0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800040d4:	854a                	mv	a0,s2
    800040d6:	00001097          	auipc	ra,0x1
    800040da:	ac8080e7          	jalr	-1336(ra) # 80004b9e <releasesleep>
    acquire(&icache.lock);
    800040de:	0001d517          	auipc	a0,0x1d
    800040e2:	98250513          	addi	a0,a0,-1662 # 80020a60 <icache>
    800040e6:	ffffd097          	auipc	ra,0xffffd
    800040ea:	bd2080e7          	jalr	-1070(ra) # 80000cb8 <acquire>
    800040ee:	b741                	j	8000406e <iput+0x26>

00000000800040f0 <iunlockput>:
{
    800040f0:	1101                	addi	sp,sp,-32
    800040f2:	ec06                	sd	ra,24(sp)
    800040f4:	e822                	sd	s0,16(sp)
    800040f6:	e426                	sd	s1,8(sp)
    800040f8:	1000                	addi	s0,sp,32
    800040fa:	84aa                	mv	s1,a0
  iunlock(ip);
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	e54080e7          	jalr	-428(ra) # 80003f50 <iunlock>
  iput(ip);
    80004104:	8526                	mv	a0,s1
    80004106:	00000097          	auipc	ra,0x0
    8000410a:	f42080e7          	jalr	-190(ra) # 80004048 <iput>
}
    8000410e:	60e2                	ld	ra,24(sp)
    80004110:	6442                	ld	s0,16(sp)
    80004112:	64a2                	ld	s1,8(sp)
    80004114:	6105                	addi	sp,sp,32
    80004116:	8082                	ret

0000000080004118 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004118:	1141                	addi	sp,sp,-16
    8000411a:	e422                	sd	s0,8(sp)
    8000411c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000411e:	411c                	lw	a5,0(a0)
    80004120:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004122:	415c                	lw	a5,4(a0)
    80004124:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004126:	04451783          	lh	a5,68(a0)
    8000412a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000412e:	04a51783          	lh	a5,74(a0)
    80004132:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004136:	04c56783          	lwu	a5,76(a0)
    8000413a:	e99c                	sd	a5,16(a1)
}
    8000413c:	6422                	ld	s0,8(sp)
    8000413e:	0141                	addi	sp,sp,16
    80004140:	8082                	ret

0000000080004142 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004142:	457c                	lw	a5,76(a0)
    80004144:	0ed7e863          	bltu	a5,a3,80004234 <readi+0xf2>
{
    80004148:	7159                	addi	sp,sp,-112
    8000414a:	f486                	sd	ra,104(sp)
    8000414c:	f0a2                	sd	s0,96(sp)
    8000414e:	eca6                	sd	s1,88(sp)
    80004150:	e8ca                	sd	s2,80(sp)
    80004152:	e4ce                	sd	s3,72(sp)
    80004154:	e0d2                	sd	s4,64(sp)
    80004156:	fc56                	sd	s5,56(sp)
    80004158:	f85a                	sd	s6,48(sp)
    8000415a:	f45e                	sd	s7,40(sp)
    8000415c:	f062                	sd	s8,32(sp)
    8000415e:	ec66                	sd	s9,24(sp)
    80004160:	e86a                	sd	s10,16(sp)
    80004162:	e46e                	sd	s11,8(sp)
    80004164:	1880                	addi	s0,sp,112
    80004166:	8baa                	mv	s7,a0
    80004168:	8c2e                	mv	s8,a1
    8000416a:	8ab2                	mv	s5,a2
    8000416c:	84b6                	mv	s1,a3
    8000416e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004170:	9f35                	addw	a4,a4,a3
    return 0;
    80004172:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004174:	08d76f63          	bltu	a4,a3,80004212 <readi+0xd0>
  if(off + n > ip->size)
    80004178:	00e7f463          	bgeu	a5,a4,80004180 <readi+0x3e>
    n = ip->size - off;
    8000417c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004180:	0a0b0863          	beqz	s6,80004230 <readi+0xee>
    80004184:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004186:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000418a:	5cfd                	li	s9,-1
    8000418c:	a82d                	j	800041c6 <readi+0x84>
    8000418e:	020a1d93          	slli	s11,s4,0x20
    80004192:	020ddd93          	srli	s11,s11,0x20
    80004196:	05890613          	addi	a2,s2,88
    8000419a:	86ee                	mv	a3,s11
    8000419c:	963a                	add	a2,a2,a4
    8000419e:	85d6                	mv	a1,s5
    800041a0:	8562                	mv	a0,s8
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	8e2080e7          	jalr	-1822(ra) # 80002a84 <either_copyout>
    800041aa:	05950d63          	beq	a0,s9,80004204 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    800041ae:	854a                	mv	a0,s2
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	60c080e7          	jalr	1548(ra) # 800037bc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041b8:	013a09bb          	addw	s3,s4,s3
    800041bc:	009a04bb          	addw	s1,s4,s1
    800041c0:	9aee                	add	s5,s5,s11
    800041c2:	0569f663          	bgeu	s3,s6,8000420e <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800041c6:	000ba903          	lw	s2,0(s7)
    800041ca:	00a4d59b          	srliw	a1,s1,0xa
    800041ce:	855e                	mv	a0,s7
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	8b0080e7          	jalr	-1872(ra) # 80003a80 <bmap>
    800041d8:	0005059b          	sext.w	a1,a0
    800041dc:	854a                	mv	a0,s2
    800041de:	fffff097          	auipc	ra,0xfffff
    800041e2:	4ae080e7          	jalr	1198(ra) # 8000368c <bread>
    800041e6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041e8:	3ff4f713          	andi	a4,s1,1023
    800041ec:	40ed07bb          	subw	a5,s10,a4
    800041f0:	413b06bb          	subw	a3,s6,s3
    800041f4:	8a3e                	mv	s4,a5
    800041f6:	2781                	sext.w	a5,a5
    800041f8:	0006861b          	sext.w	a2,a3
    800041fc:	f8f679e3          	bgeu	a2,a5,8000418e <readi+0x4c>
    80004200:	8a36                	mv	s4,a3
    80004202:	b771                	j	8000418e <readi+0x4c>
      brelse(bp);
    80004204:	854a                	mv	a0,s2
    80004206:	fffff097          	auipc	ra,0xfffff
    8000420a:	5b6080e7          	jalr	1462(ra) # 800037bc <brelse>
  }
  return tot;
    8000420e:	0009851b          	sext.w	a0,s3
}
    80004212:	70a6                	ld	ra,104(sp)
    80004214:	7406                	ld	s0,96(sp)
    80004216:	64e6                	ld	s1,88(sp)
    80004218:	6946                	ld	s2,80(sp)
    8000421a:	69a6                	ld	s3,72(sp)
    8000421c:	6a06                	ld	s4,64(sp)
    8000421e:	7ae2                	ld	s5,56(sp)
    80004220:	7b42                	ld	s6,48(sp)
    80004222:	7ba2                	ld	s7,40(sp)
    80004224:	7c02                	ld	s8,32(sp)
    80004226:	6ce2                	ld	s9,24(sp)
    80004228:	6d42                	ld	s10,16(sp)
    8000422a:	6da2                	ld	s11,8(sp)
    8000422c:	6165                	addi	sp,sp,112
    8000422e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004230:	89da                	mv	s3,s6
    80004232:	bff1                	j	8000420e <readi+0xcc>
    return 0;
    80004234:	4501                	li	a0,0
}
    80004236:	8082                	ret

0000000080004238 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004238:	457c                	lw	a5,76(a0)
    8000423a:	10d7e663          	bltu	a5,a3,80004346 <writei+0x10e>
{
    8000423e:	7159                	addi	sp,sp,-112
    80004240:	f486                	sd	ra,104(sp)
    80004242:	f0a2                	sd	s0,96(sp)
    80004244:	eca6                	sd	s1,88(sp)
    80004246:	e8ca                	sd	s2,80(sp)
    80004248:	e4ce                	sd	s3,72(sp)
    8000424a:	e0d2                	sd	s4,64(sp)
    8000424c:	fc56                	sd	s5,56(sp)
    8000424e:	f85a                	sd	s6,48(sp)
    80004250:	f45e                	sd	s7,40(sp)
    80004252:	f062                	sd	s8,32(sp)
    80004254:	ec66                	sd	s9,24(sp)
    80004256:	e86a                	sd	s10,16(sp)
    80004258:	e46e                	sd	s11,8(sp)
    8000425a:	1880                	addi	s0,sp,112
    8000425c:	8baa                	mv	s7,a0
    8000425e:	8c2e                	mv	s8,a1
    80004260:	8ab2                	mv	s5,a2
    80004262:	8936                	mv	s2,a3
    80004264:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004266:	00e687bb          	addw	a5,a3,a4
    8000426a:	0ed7e063          	bltu	a5,a3,8000434a <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000426e:	00043737          	lui	a4,0x43
    80004272:	0cf76e63          	bltu	a4,a5,8000434e <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004276:	0a0b0763          	beqz	s6,80004324 <writei+0xec>
    8000427a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000427c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004280:	5cfd                	li	s9,-1
    80004282:	a091                	j	800042c6 <writei+0x8e>
    80004284:	02099d93          	slli	s11,s3,0x20
    80004288:	020ddd93          	srli	s11,s11,0x20
    8000428c:	05848513          	addi	a0,s1,88
    80004290:	86ee                	mv	a3,s11
    80004292:	8656                	mv	a2,s5
    80004294:	85e2                	mv	a1,s8
    80004296:	953a                	add	a0,a0,a4
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	842080e7          	jalr	-1982(ra) # 80002ada <either_copyin>
    800042a0:	07950263          	beq	a0,s9,80004304 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800042a4:	8526                	mv	a0,s1
    800042a6:	00000097          	auipc	ra,0x0
    800042aa:	77a080e7          	jalr	1914(ra) # 80004a20 <log_write>
    brelse(bp);
    800042ae:	8526                	mv	a0,s1
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	50c080e7          	jalr	1292(ra) # 800037bc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042b8:	01498a3b          	addw	s4,s3,s4
    800042bc:	0129893b          	addw	s2,s3,s2
    800042c0:	9aee                	add	s5,s5,s11
    800042c2:	056a7663          	bgeu	s4,s6,8000430e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042c6:	000ba483          	lw	s1,0(s7)
    800042ca:	00a9559b          	srliw	a1,s2,0xa
    800042ce:	855e                	mv	a0,s7
    800042d0:	fffff097          	auipc	ra,0xfffff
    800042d4:	7b0080e7          	jalr	1968(ra) # 80003a80 <bmap>
    800042d8:	0005059b          	sext.w	a1,a0
    800042dc:	8526                	mv	a0,s1
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	3ae080e7          	jalr	942(ra) # 8000368c <bread>
    800042e6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042e8:	3ff97713          	andi	a4,s2,1023
    800042ec:	40ed07bb          	subw	a5,s10,a4
    800042f0:	414b06bb          	subw	a3,s6,s4
    800042f4:	89be                	mv	s3,a5
    800042f6:	2781                	sext.w	a5,a5
    800042f8:	0006861b          	sext.w	a2,a3
    800042fc:	f8f674e3          	bgeu	a2,a5,80004284 <writei+0x4c>
    80004300:	89b6                	mv	s3,a3
    80004302:	b749                	j	80004284 <writei+0x4c>
      brelse(bp);
    80004304:	8526                	mv	a0,s1
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	4b6080e7          	jalr	1206(ra) # 800037bc <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    8000430e:	04cba783          	lw	a5,76(s7)
    80004312:	0127f463          	bgeu	a5,s2,8000431a <writei+0xe2>
      ip->size = off;
    80004316:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    8000431a:	855e                	mv	a0,s7
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	aa8080e7          	jalr	-1368(ra) # 80003dc4 <iupdate>
  }

  return n;
    80004324:	000b051b          	sext.w	a0,s6
}
    80004328:	70a6                	ld	ra,104(sp)
    8000432a:	7406                	ld	s0,96(sp)
    8000432c:	64e6                	ld	s1,88(sp)
    8000432e:	6946                	ld	s2,80(sp)
    80004330:	69a6                	ld	s3,72(sp)
    80004332:	6a06                	ld	s4,64(sp)
    80004334:	7ae2                	ld	s5,56(sp)
    80004336:	7b42                	ld	s6,48(sp)
    80004338:	7ba2                	ld	s7,40(sp)
    8000433a:	7c02                	ld	s8,32(sp)
    8000433c:	6ce2                	ld	s9,24(sp)
    8000433e:	6d42                	ld	s10,16(sp)
    80004340:	6da2                	ld	s11,8(sp)
    80004342:	6165                	addi	sp,sp,112
    80004344:	8082                	ret
    return -1;
    80004346:	557d                	li	a0,-1
}
    80004348:	8082                	ret
    return -1;
    8000434a:	557d                	li	a0,-1
    8000434c:	bff1                	j	80004328 <writei+0xf0>
    return -1;
    8000434e:	557d                	li	a0,-1
    80004350:	bfe1                	j	80004328 <writei+0xf0>

0000000080004352 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004352:	1141                	addi	sp,sp,-16
    80004354:	e406                	sd	ra,8(sp)
    80004356:	e022                	sd	s0,0(sp)
    80004358:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000435a:	4639                	li	a2,14
    8000435c:	ffffd097          	auipc	ra,0xffffd
    80004360:	b34080e7          	jalr	-1228(ra) # 80000e90 <strncmp>
}
    80004364:	60a2                	ld	ra,8(sp)
    80004366:	6402                	ld	s0,0(sp)
    80004368:	0141                	addi	sp,sp,16
    8000436a:	8082                	ret

000000008000436c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000436c:	7139                	addi	sp,sp,-64
    8000436e:	fc06                	sd	ra,56(sp)
    80004370:	f822                	sd	s0,48(sp)
    80004372:	f426                	sd	s1,40(sp)
    80004374:	f04a                	sd	s2,32(sp)
    80004376:	ec4e                	sd	s3,24(sp)
    80004378:	e852                	sd	s4,16(sp)
    8000437a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000437c:	04451703          	lh	a4,68(a0)
    80004380:	4785                	li	a5,1
    80004382:	00f71a63          	bne	a4,a5,80004396 <dirlookup+0x2a>
    80004386:	892a                	mv	s2,a0
    80004388:	89ae                	mv	s3,a1
    8000438a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000438c:	457c                	lw	a5,76(a0)
    8000438e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004390:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004392:	e79d                	bnez	a5,800043c0 <dirlookup+0x54>
    80004394:	a8a5                	j	8000440c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004396:	00004517          	auipc	a0,0x4
    8000439a:	52250513          	addi	a0,a0,1314 # 800088b8 <sysnames+0x1c0>
    8000439e:	ffffc097          	auipc	ra,0xffffc
    800043a2:	232080e7          	jalr	562(ra) # 800005d0 <panic>
      panic("dirlookup read");
    800043a6:	00004517          	auipc	a0,0x4
    800043aa:	52a50513          	addi	a0,a0,1322 # 800088d0 <sysnames+0x1d8>
    800043ae:	ffffc097          	auipc	ra,0xffffc
    800043b2:	222080e7          	jalr	546(ra) # 800005d0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043b6:	24c1                	addiw	s1,s1,16
    800043b8:	04c92783          	lw	a5,76(s2)
    800043bc:	04f4f763          	bgeu	s1,a5,8000440a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043c0:	4741                	li	a4,16
    800043c2:	86a6                	mv	a3,s1
    800043c4:	fc040613          	addi	a2,s0,-64
    800043c8:	4581                	li	a1,0
    800043ca:	854a                	mv	a0,s2
    800043cc:	00000097          	auipc	ra,0x0
    800043d0:	d76080e7          	jalr	-650(ra) # 80004142 <readi>
    800043d4:	47c1                	li	a5,16
    800043d6:	fcf518e3          	bne	a0,a5,800043a6 <dirlookup+0x3a>
    if(de.inum == 0)
    800043da:	fc045783          	lhu	a5,-64(s0)
    800043de:	dfe1                	beqz	a5,800043b6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800043e0:	fc240593          	addi	a1,s0,-62
    800043e4:	854e                	mv	a0,s3
    800043e6:	00000097          	auipc	ra,0x0
    800043ea:	f6c080e7          	jalr	-148(ra) # 80004352 <namecmp>
    800043ee:	f561                	bnez	a0,800043b6 <dirlookup+0x4a>
      if(poff)
    800043f0:	000a0463          	beqz	s4,800043f8 <dirlookup+0x8c>
        *poff = off;
    800043f4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043f8:	fc045583          	lhu	a1,-64(s0)
    800043fc:	00092503          	lw	a0,0(s2)
    80004400:	fffff097          	auipc	ra,0xfffff
    80004404:	75a080e7          	jalr	1882(ra) # 80003b5a <iget>
    80004408:	a011                	j	8000440c <dirlookup+0xa0>
  return 0;
    8000440a:	4501                	li	a0,0
}
    8000440c:	70e2                	ld	ra,56(sp)
    8000440e:	7442                	ld	s0,48(sp)
    80004410:	74a2                	ld	s1,40(sp)
    80004412:	7902                	ld	s2,32(sp)
    80004414:	69e2                	ld	s3,24(sp)
    80004416:	6a42                	ld	s4,16(sp)
    80004418:	6121                	addi	sp,sp,64
    8000441a:	8082                	ret

000000008000441c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000441c:	711d                	addi	sp,sp,-96
    8000441e:	ec86                	sd	ra,88(sp)
    80004420:	e8a2                	sd	s0,80(sp)
    80004422:	e4a6                	sd	s1,72(sp)
    80004424:	e0ca                	sd	s2,64(sp)
    80004426:	fc4e                	sd	s3,56(sp)
    80004428:	f852                	sd	s4,48(sp)
    8000442a:	f456                	sd	s5,40(sp)
    8000442c:	f05a                	sd	s6,32(sp)
    8000442e:	ec5e                	sd	s7,24(sp)
    80004430:	e862                	sd	s8,16(sp)
    80004432:	e466                	sd	s9,8(sp)
    80004434:	1080                	addi	s0,sp,96
    80004436:	84aa                	mv	s1,a0
    80004438:	8b2e                	mv	s6,a1
    8000443a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000443c:	00054703          	lbu	a4,0(a0)
    80004440:	02f00793          	li	a5,47
    80004444:	02f70363          	beq	a4,a5,8000446a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004448:	ffffe097          	auipc	ra,0xffffe
    8000444c:	9fa080e7          	jalr	-1542(ra) # 80001e42 <myproc>
    80004450:	15853503          	ld	a0,344(a0)
    80004454:	00000097          	auipc	ra,0x0
    80004458:	9fc080e7          	jalr	-1540(ra) # 80003e50 <idup>
    8000445c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000445e:	02f00913          	li	s2,47
  len = path - s;
    80004462:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004464:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004466:	4c05                	li	s8,1
    80004468:	a865                	j	80004520 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000446a:	4585                	li	a1,1
    8000446c:	4505                	li	a0,1
    8000446e:	fffff097          	auipc	ra,0xfffff
    80004472:	6ec080e7          	jalr	1772(ra) # 80003b5a <iget>
    80004476:	89aa                	mv	s3,a0
    80004478:	b7dd                	j	8000445e <namex+0x42>
      iunlockput(ip);
    8000447a:	854e                	mv	a0,s3
    8000447c:	00000097          	auipc	ra,0x0
    80004480:	c74080e7          	jalr	-908(ra) # 800040f0 <iunlockput>
      return 0;
    80004484:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004486:	854e                	mv	a0,s3
    80004488:	60e6                	ld	ra,88(sp)
    8000448a:	6446                	ld	s0,80(sp)
    8000448c:	64a6                	ld	s1,72(sp)
    8000448e:	6906                	ld	s2,64(sp)
    80004490:	79e2                	ld	s3,56(sp)
    80004492:	7a42                	ld	s4,48(sp)
    80004494:	7aa2                	ld	s5,40(sp)
    80004496:	7b02                	ld	s6,32(sp)
    80004498:	6be2                	ld	s7,24(sp)
    8000449a:	6c42                	ld	s8,16(sp)
    8000449c:	6ca2                	ld	s9,8(sp)
    8000449e:	6125                	addi	sp,sp,96
    800044a0:	8082                	ret
      iunlock(ip);
    800044a2:	854e                	mv	a0,s3
    800044a4:	00000097          	auipc	ra,0x0
    800044a8:	aac080e7          	jalr	-1364(ra) # 80003f50 <iunlock>
      return ip;
    800044ac:	bfe9                	j	80004486 <namex+0x6a>
      iunlockput(ip);
    800044ae:	854e                	mv	a0,s3
    800044b0:	00000097          	auipc	ra,0x0
    800044b4:	c40080e7          	jalr	-960(ra) # 800040f0 <iunlockput>
      return 0;
    800044b8:	89d2                	mv	s3,s4
    800044ba:	b7f1                	j	80004486 <namex+0x6a>
  len = path - s;
    800044bc:	40b48633          	sub	a2,s1,a1
    800044c0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800044c4:	094cd463          	bge	s9,s4,8000454c <namex+0x130>
    memmove(name, s, DIRSIZ);
    800044c8:	4639                	li	a2,14
    800044ca:	8556                	mv	a0,s5
    800044cc:	ffffd097          	auipc	ra,0xffffd
    800044d0:	948080e7          	jalr	-1720(ra) # 80000e14 <memmove>
  while(*path == '/')
    800044d4:	0004c783          	lbu	a5,0(s1)
    800044d8:	01279763          	bne	a5,s2,800044e6 <namex+0xca>
    path++;
    800044dc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044de:	0004c783          	lbu	a5,0(s1)
    800044e2:	ff278de3          	beq	a5,s2,800044dc <namex+0xc0>
    ilock(ip);
    800044e6:	854e                	mv	a0,s3
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	9a6080e7          	jalr	-1626(ra) # 80003e8e <ilock>
    if(ip->type != T_DIR){
    800044f0:	04499783          	lh	a5,68(s3)
    800044f4:	f98793e3          	bne	a5,s8,8000447a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800044f8:	000b0563          	beqz	s6,80004502 <namex+0xe6>
    800044fc:	0004c783          	lbu	a5,0(s1)
    80004500:	d3cd                	beqz	a5,800044a2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004502:	865e                	mv	a2,s7
    80004504:	85d6                	mv	a1,s5
    80004506:	854e                	mv	a0,s3
    80004508:	00000097          	auipc	ra,0x0
    8000450c:	e64080e7          	jalr	-412(ra) # 8000436c <dirlookup>
    80004510:	8a2a                	mv	s4,a0
    80004512:	dd51                	beqz	a0,800044ae <namex+0x92>
    iunlockput(ip);
    80004514:	854e                	mv	a0,s3
    80004516:	00000097          	auipc	ra,0x0
    8000451a:	bda080e7          	jalr	-1062(ra) # 800040f0 <iunlockput>
    ip = next;
    8000451e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004520:	0004c783          	lbu	a5,0(s1)
    80004524:	05279763          	bne	a5,s2,80004572 <namex+0x156>
    path++;
    80004528:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000452a:	0004c783          	lbu	a5,0(s1)
    8000452e:	ff278de3          	beq	a5,s2,80004528 <namex+0x10c>
  if(*path == 0)
    80004532:	c79d                	beqz	a5,80004560 <namex+0x144>
    path++;
    80004534:	85a6                	mv	a1,s1
  len = path - s;
    80004536:	8a5e                	mv	s4,s7
    80004538:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000453a:	01278963          	beq	a5,s2,8000454c <namex+0x130>
    8000453e:	dfbd                	beqz	a5,800044bc <namex+0xa0>
    path++;
    80004540:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004542:	0004c783          	lbu	a5,0(s1)
    80004546:	ff279ce3          	bne	a5,s2,8000453e <namex+0x122>
    8000454a:	bf8d                	j	800044bc <namex+0xa0>
    memmove(name, s, len);
    8000454c:	2601                	sext.w	a2,a2
    8000454e:	8556                	mv	a0,s5
    80004550:	ffffd097          	auipc	ra,0xffffd
    80004554:	8c4080e7          	jalr	-1852(ra) # 80000e14 <memmove>
    name[len] = 0;
    80004558:	9a56                	add	s4,s4,s5
    8000455a:	000a0023          	sb	zero,0(s4)
    8000455e:	bf9d                	j	800044d4 <namex+0xb8>
  if(nameiparent){
    80004560:	f20b03e3          	beqz	s6,80004486 <namex+0x6a>
    iput(ip);
    80004564:	854e                	mv	a0,s3
    80004566:	00000097          	auipc	ra,0x0
    8000456a:	ae2080e7          	jalr	-1310(ra) # 80004048 <iput>
    return 0;
    8000456e:	4981                	li	s3,0
    80004570:	bf19                	j	80004486 <namex+0x6a>
  if(*path == 0)
    80004572:	d7fd                	beqz	a5,80004560 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004574:	0004c783          	lbu	a5,0(s1)
    80004578:	85a6                	mv	a1,s1
    8000457a:	b7d1                	j	8000453e <namex+0x122>

000000008000457c <dirlink>:
{
    8000457c:	7139                	addi	sp,sp,-64
    8000457e:	fc06                	sd	ra,56(sp)
    80004580:	f822                	sd	s0,48(sp)
    80004582:	f426                	sd	s1,40(sp)
    80004584:	f04a                	sd	s2,32(sp)
    80004586:	ec4e                	sd	s3,24(sp)
    80004588:	e852                	sd	s4,16(sp)
    8000458a:	0080                	addi	s0,sp,64
    8000458c:	892a                	mv	s2,a0
    8000458e:	8a2e                	mv	s4,a1
    80004590:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004592:	4601                	li	a2,0
    80004594:	00000097          	auipc	ra,0x0
    80004598:	dd8080e7          	jalr	-552(ra) # 8000436c <dirlookup>
    8000459c:	e93d                	bnez	a0,80004612 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000459e:	04c92483          	lw	s1,76(s2)
    800045a2:	c49d                	beqz	s1,800045d0 <dirlink+0x54>
    800045a4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045a6:	4741                	li	a4,16
    800045a8:	86a6                	mv	a3,s1
    800045aa:	fc040613          	addi	a2,s0,-64
    800045ae:	4581                	li	a1,0
    800045b0:	854a                	mv	a0,s2
    800045b2:	00000097          	auipc	ra,0x0
    800045b6:	b90080e7          	jalr	-1136(ra) # 80004142 <readi>
    800045ba:	47c1                	li	a5,16
    800045bc:	06f51163          	bne	a0,a5,8000461e <dirlink+0xa2>
    if(de.inum == 0)
    800045c0:	fc045783          	lhu	a5,-64(s0)
    800045c4:	c791                	beqz	a5,800045d0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045c6:	24c1                	addiw	s1,s1,16
    800045c8:	04c92783          	lw	a5,76(s2)
    800045cc:	fcf4ede3          	bltu	s1,a5,800045a6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800045d0:	4639                	li	a2,14
    800045d2:	85d2                	mv	a1,s4
    800045d4:	fc240513          	addi	a0,s0,-62
    800045d8:	ffffd097          	auipc	ra,0xffffd
    800045dc:	8f4080e7          	jalr	-1804(ra) # 80000ecc <strncpy>
  de.inum = inum;
    800045e0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045e4:	4741                	li	a4,16
    800045e6:	86a6                	mv	a3,s1
    800045e8:	fc040613          	addi	a2,s0,-64
    800045ec:	4581                	li	a1,0
    800045ee:	854a                	mv	a0,s2
    800045f0:	00000097          	auipc	ra,0x0
    800045f4:	c48080e7          	jalr	-952(ra) # 80004238 <writei>
    800045f8:	872a                	mv	a4,a0
    800045fa:	47c1                	li	a5,16
  return 0;
    800045fc:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045fe:	02f71863          	bne	a4,a5,8000462e <dirlink+0xb2>
}
    80004602:	70e2                	ld	ra,56(sp)
    80004604:	7442                	ld	s0,48(sp)
    80004606:	74a2                	ld	s1,40(sp)
    80004608:	7902                	ld	s2,32(sp)
    8000460a:	69e2                	ld	s3,24(sp)
    8000460c:	6a42                	ld	s4,16(sp)
    8000460e:	6121                	addi	sp,sp,64
    80004610:	8082                	ret
    iput(ip);
    80004612:	00000097          	auipc	ra,0x0
    80004616:	a36080e7          	jalr	-1482(ra) # 80004048 <iput>
    return -1;
    8000461a:	557d                	li	a0,-1
    8000461c:	b7dd                	j	80004602 <dirlink+0x86>
      panic("dirlink read");
    8000461e:	00004517          	auipc	a0,0x4
    80004622:	2c250513          	addi	a0,a0,706 # 800088e0 <sysnames+0x1e8>
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	faa080e7          	jalr	-86(ra) # 800005d0 <panic>
    panic("dirlink");
    8000462e:	00004517          	auipc	a0,0x4
    80004632:	3c250513          	addi	a0,a0,962 # 800089f0 <sysnames+0x2f8>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	f9a080e7          	jalr	-102(ra) # 800005d0 <panic>

000000008000463e <namei>:

struct inode*
namei(char *path)
{
    8000463e:	1101                	addi	sp,sp,-32
    80004640:	ec06                	sd	ra,24(sp)
    80004642:	e822                	sd	s0,16(sp)
    80004644:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004646:	fe040613          	addi	a2,s0,-32
    8000464a:	4581                	li	a1,0
    8000464c:	00000097          	auipc	ra,0x0
    80004650:	dd0080e7          	jalr	-560(ra) # 8000441c <namex>
}
    80004654:	60e2                	ld	ra,24(sp)
    80004656:	6442                	ld	s0,16(sp)
    80004658:	6105                	addi	sp,sp,32
    8000465a:	8082                	ret

000000008000465c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000465c:	1141                	addi	sp,sp,-16
    8000465e:	e406                	sd	ra,8(sp)
    80004660:	e022                	sd	s0,0(sp)
    80004662:	0800                	addi	s0,sp,16
    80004664:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004666:	4585                	li	a1,1
    80004668:	00000097          	auipc	ra,0x0
    8000466c:	db4080e7          	jalr	-588(ra) # 8000441c <namex>
}
    80004670:	60a2                	ld	ra,8(sp)
    80004672:	6402                	ld	s0,0(sp)
    80004674:	0141                	addi	sp,sp,16
    80004676:	8082                	ret

0000000080004678 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004678:	1101                	addi	sp,sp,-32
    8000467a:	ec06                	sd	ra,24(sp)
    8000467c:	e822                	sd	s0,16(sp)
    8000467e:	e426                	sd	s1,8(sp)
    80004680:	e04a                	sd	s2,0(sp)
    80004682:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004684:	0001e917          	auipc	s2,0x1e
    80004688:	e8490913          	addi	s2,s2,-380 # 80022508 <log>
    8000468c:	01892583          	lw	a1,24(s2)
    80004690:	02892503          	lw	a0,40(s2)
    80004694:	fffff097          	auipc	ra,0xfffff
    80004698:	ff8080e7          	jalr	-8(ra) # 8000368c <bread>
    8000469c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000469e:	02c92683          	lw	a3,44(s2)
    800046a2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800046a4:	02d05763          	blez	a3,800046d2 <write_head+0x5a>
    800046a8:	0001e797          	auipc	a5,0x1e
    800046ac:	e9078793          	addi	a5,a5,-368 # 80022538 <log+0x30>
    800046b0:	05c50713          	addi	a4,a0,92
    800046b4:	36fd                	addiw	a3,a3,-1
    800046b6:	1682                	slli	a3,a3,0x20
    800046b8:	9281                	srli	a3,a3,0x20
    800046ba:	068a                	slli	a3,a3,0x2
    800046bc:	0001e617          	auipc	a2,0x1e
    800046c0:	e8060613          	addi	a2,a2,-384 # 8002253c <log+0x34>
    800046c4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800046c6:	4390                	lw	a2,0(a5)
    800046c8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046ca:	0791                	addi	a5,a5,4
    800046cc:	0711                	addi	a4,a4,4
    800046ce:	fed79ce3          	bne	a5,a3,800046c6 <write_head+0x4e>
  }
  bwrite(buf);
    800046d2:	8526                	mv	a0,s1
    800046d4:	fffff097          	auipc	ra,0xfffff
    800046d8:	0aa080e7          	jalr	170(ra) # 8000377e <bwrite>
  brelse(buf);
    800046dc:	8526                	mv	a0,s1
    800046de:	fffff097          	auipc	ra,0xfffff
    800046e2:	0de080e7          	jalr	222(ra) # 800037bc <brelse>
}
    800046e6:	60e2                	ld	ra,24(sp)
    800046e8:	6442                	ld	s0,16(sp)
    800046ea:	64a2                	ld	s1,8(sp)
    800046ec:	6902                	ld	s2,0(sp)
    800046ee:	6105                	addi	sp,sp,32
    800046f0:	8082                	ret

00000000800046f2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800046f2:	0001e797          	auipc	a5,0x1e
    800046f6:	e427a783          	lw	a5,-446(a5) # 80022534 <log+0x2c>
    800046fa:	0af05663          	blez	a5,800047a6 <install_trans+0xb4>
{
    800046fe:	7139                	addi	sp,sp,-64
    80004700:	fc06                	sd	ra,56(sp)
    80004702:	f822                	sd	s0,48(sp)
    80004704:	f426                	sd	s1,40(sp)
    80004706:	f04a                	sd	s2,32(sp)
    80004708:	ec4e                	sd	s3,24(sp)
    8000470a:	e852                	sd	s4,16(sp)
    8000470c:	e456                	sd	s5,8(sp)
    8000470e:	0080                	addi	s0,sp,64
    80004710:	0001ea97          	auipc	s5,0x1e
    80004714:	e28a8a93          	addi	s5,s5,-472 # 80022538 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004718:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000471a:	0001e997          	auipc	s3,0x1e
    8000471e:	dee98993          	addi	s3,s3,-530 # 80022508 <log>
    80004722:	0189a583          	lw	a1,24(s3)
    80004726:	014585bb          	addw	a1,a1,s4
    8000472a:	2585                	addiw	a1,a1,1
    8000472c:	0289a503          	lw	a0,40(s3)
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	f5c080e7          	jalr	-164(ra) # 8000368c <bread>
    80004738:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000473a:	000aa583          	lw	a1,0(s5)
    8000473e:	0289a503          	lw	a0,40(s3)
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	f4a080e7          	jalr	-182(ra) # 8000368c <bread>
    8000474a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000474c:	40000613          	li	a2,1024
    80004750:	05890593          	addi	a1,s2,88
    80004754:	05850513          	addi	a0,a0,88
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	6bc080e7          	jalr	1724(ra) # 80000e14 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004760:	8526                	mv	a0,s1
    80004762:	fffff097          	auipc	ra,0xfffff
    80004766:	01c080e7          	jalr	28(ra) # 8000377e <bwrite>
    bunpin(dbuf);
    8000476a:	8526                	mv	a0,s1
    8000476c:	fffff097          	auipc	ra,0xfffff
    80004770:	12a080e7          	jalr	298(ra) # 80003896 <bunpin>
    brelse(lbuf);
    80004774:	854a                	mv	a0,s2
    80004776:	fffff097          	auipc	ra,0xfffff
    8000477a:	046080e7          	jalr	70(ra) # 800037bc <brelse>
    brelse(dbuf);
    8000477e:	8526                	mv	a0,s1
    80004780:	fffff097          	auipc	ra,0xfffff
    80004784:	03c080e7          	jalr	60(ra) # 800037bc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004788:	2a05                	addiw	s4,s4,1
    8000478a:	0a91                	addi	s5,s5,4
    8000478c:	02c9a783          	lw	a5,44(s3)
    80004790:	f8fa49e3          	blt	s4,a5,80004722 <install_trans+0x30>
}
    80004794:	70e2                	ld	ra,56(sp)
    80004796:	7442                	ld	s0,48(sp)
    80004798:	74a2                	ld	s1,40(sp)
    8000479a:	7902                	ld	s2,32(sp)
    8000479c:	69e2                	ld	s3,24(sp)
    8000479e:	6a42                	ld	s4,16(sp)
    800047a0:	6aa2                	ld	s5,8(sp)
    800047a2:	6121                	addi	sp,sp,64
    800047a4:	8082                	ret
    800047a6:	8082                	ret

00000000800047a8 <initlog>:
{
    800047a8:	7179                	addi	sp,sp,-48
    800047aa:	f406                	sd	ra,40(sp)
    800047ac:	f022                	sd	s0,32(sp)
    800047ae:	ec26                	sd	s1,24(sp)
    800047b0:	e84a                	sd	s2,16(sp)
    800047b2:	e44e                	sd	s3,8(sp)
    800047b4:	1800                	addi	s0,sp,48
    800047b6:	892a                	mv	s2,a0
    800047b8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800047ba:	0001e497          	auipc	s1,0x1e
    800047be:	d4e48493          	addi	s1,s1,-690 # 80022508 <log>
    800047c2:	00004597          	auipc	a1,0x4
    800047c6:	12e58593          	addi	a1,a1,302 # 800088f0 <sysnames+0x1f8>
    800047ca:	8526                	mv	a0,s1
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	45c080e7          	jalr	1116(ra) # 80000c28 <initlock>
  log.start = sb->logstart;
    800047d4:	0149a583          	lw	a1,20(s3)
    800047d8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800047da:	0109a783          	lw	a5,16(s3)
    800047de:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800047e0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800047e4:	854a                	mv	a0,s2
    800047e6:	fffff097          	auipc	ra,0xfffff
    800047ea:	ea6080e7          	jalr	-346(ra) # 8000368c <bread>
  log.lh.n = lh->n;
    800047ee:	4d3c                	lw	a5,88(a0)
    800047f0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800047f2:	02f05563          	blez	a5,8000481c <initlog+0x74>
    800047f6:	05c50713          	addi	a4,a0,92
    800047fa:	0001e697          	auipc	a3,0x1e
    800047fe:	d3e68693          	addi	a3,a3,-706 # 80022538 <log+0x30>
    80004802:	37fd                	addiw	a5,a5,-1
    80004804:	1782                	slli	a5,a5,0x20
    80004806:	9381                	srli	a5,a5,0x20
    80004808:	078a                	slli	a5,a5,0x2
    8000480a:	06050613          	addi	a2,a0,96
    8000480e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004810:	4310                	lw	a2,0(a4)
    80004812:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004814:	0711                	addi	a4,a4,4
    80004816:	0691                	addi	a3,a3,4
    80004818:	fef71ce3          	bne	a4,a5,80004810 <initlog+0x68>
  brelse(buf);
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	fa0080e7          	jalr	-96(ra) # 800037bc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004824:	00000097          	auipc	ra,0x0
    80004828:	ece080e7          	jalr	-306(ra) # 800046f2 <install_trans>
  log.lh.n = 0;
    8000482c:	0001e797          	auipc	a5,0x1e
    80004830:	d007a423          	sw	zero,-760(a5) # 80022534 <log+0x2c>
  write_head(); // clear the log
    80004834:	00000097          	auipc	ra,0x0
    80004838:	e44080e7          	jalr	-444(ra) # 80004678 <write_head>
}
    8000483c:	70a2                	ld	ra,40(sp)
    8000483e:	7402                	ld	s0,32(sp)
    80004840:	64e2                	ld	s1,24(sp)
    80004842:	6942                	ld	s2,16(sp)
    80004844:	69a2                	ld	s3,8(sp)
    80004846:	6145                	addi	sp,sp,48
    80004848:	8082                	ret

000000008000484a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000484a:	1101                	addi	sp,sp,-32
    8000484c:	ec06                	sd	ra,24(sp)
    8000484e:	e822                	sd	s0,16(sp)
    80004850:	e426                	sd	s1,8(sp)
    80004852:	e04a                	sd	s2,0(sp)
    80004854:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004856:	0001e517          	auipc	a0,0x1e
    8000485a:	cb250513          	addi	a0,a0,-846 # 80022508 <log>
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	45a080e7          	jalr	1114(ra) # 80000cb8 <acquire>
  while(1){
    if(log.committing){
    80004866:	0001e497          	auipc	s1,0x1e
    8000486a:	ca248493          	addi	s1,s1,-862 # 80022508 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000486e:	4979                	li	s2,30
    80004870:	a039                	j	8000487e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004872:	85a6                	mv	a1,s1
    80004874:	8526                	mv	a0,s1
    80004876:	ffffe097          	auipc	ra,0xffffe
    8000487a:	fac080e7          	jalr	-84(ra) # 80002822 <sleep>
    if(log.committing){
    8000487e:	50dc                	lw	a5,36(s1)
    80004880:	fbed                	bnez	a5,80004872 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004882:	509c                	lw	a5,32(s1)
    80004884:	0017871b          	addiw	a4,a5,1
    80004888:	0007069b          	sext.w	a3,a4
    8000488c:	0027179b          	slliw	a5,a4,0x2
    80004890:	9fb9                	addw	a5,a5,a4
    80004892:	0017979b          	slliw	a5,a5,0x1
    80004896:	54d8                	lw	a4,44(s1)
    80004898:	9fb9                	addw	a5,a5,a4
    8000489a:	00f95963          	bge	s2,a5,800048ac <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000489e:	85a6                	mv	a1,s1
    800048a0:	8526                	mv	a0,s1
    800048a2:	ffffe097          	auipc	ra,0xffffe
    800048a6:	f80080e7          	jalr	-128(ra) # 80002822 <sleep>
    800048aa:	bfd1                	j	8000487e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800048ac:	0001e517          	auipc	a0,0x1e
    800048b0:	c5c50513          	addi	a0,a0,-932 # 80022508 <log>
    800048b4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	4b6080e7          	jalr	1206(ra) # 80000d6c <release>
      break;
    }
  }
}
    800048be:	60e2                	ld	ra,24(sp)
    800048c0:	6442                	ld	s0,16(sp)
    800048c2:	64a2                	ld	s1,8(sp)
    800048c4:	6902                	ld	s2,0(sp)
    800048c6:	6105                	addi	sp,sp,32
    800048c8:	8082                	ret

00000000800048ca <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800048ca:	7139                	addi	sp,sp,-64
    800048cc:	fc06                	sd	ra,56(sp)
    800048ce:	f822                	sd	s0,48(sp)
    800048d0:	f426                	sd	s1,40(sp)
    800048d2:	f04a                	sd	s2,32(sp)
    800048d4:	ec4e                	sd	s3,24(sp)
    800048d6:	e852                	sd	s4,16(sp)
    800048d8:	e456                	sd	s5,8(sp)
    800048da:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800048dc:	0001e497          	auipc	s1,0x1e
    800048e0:	c2c48493          	addi	s1,s1,-980 # 80022508 <log>
    800048e4:	8526                	mv	a0,s1
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	3d2080e7          	jalr	978(ra) # 80000cb8 <acquire>
  log.outstanding -= 1;
    800048ee:	509c                	lw	a5,32(s1)
    800048f0:	37fd                	addiw	a5,a5,-1
    800048f2:	0007891b          	sext.w	s2,a5
    800048f6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800048f8:	50dc                	lw	a5,36(s1)
    800048fa:	efb9                	bnez	a5,80004958 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800048fc:	06091663          	bnez	s2,80004968 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004900:	0001e497          	auipc	s1,0x1e
    80004904:	c0848493          	addi	s1,s1,-1016 # 80022508 <log>
    80004908:	4785                	li	a5,1
    8000490a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000490c:	8526                	mv	a0,s1
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	45e080e7          	jalr	1118(ra) # 80000d6c <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004916:	54dc                	lw	a5,44(s1)
    80004918:	06f04763          	bgtz	a5,80004986 <end_op+0xbc>
    acquire(&log.lock);
    8000491c:	0001e497          	auipc	s1,0x1e
    80004920:	bec48493          	addi	s1,s1,-1044 # 80022508 <log>
    80004924:	8526                	mv	a0,s1
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	392080e7          	jalr	914(ra) # 80000cb8 <acquire>
    log.committing = 0;
    8000492e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004932:	8526                	mv	a0,s1
    80004934:	ffffe097          	auipc	ra,0xffffe
    80004938:	074080e7          	jalr	116(ra) # 800029a8 <wakeup>
    release(&log.lock);
    8000493c:	8526                	mv	a0,s1
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	42e080e7          	jalr	1070(ra) # 80000d6c <release>
}
    80004946:	70e2                	ld	ra,56(sp)
    80004948:	7442                	ld	s0,48(sp)
    8000494a:	74a2                	ld	s1,40(sp)
    8000494c:	7902                	ld	s2,32(sp)
    8000494e:	69e2                	ld	s3,24(sp)
    80004950:	6a42                	ld	s4,16(sp)
    80004952:	6aa2                	ld	s5,8(sp)
    80004954:	6121                	addi	sp,sp,64
    80004956:	8082                	ret
    panic("log.committing");
    80004958:	00004517          	auipc	a0,0x4
    8000495c:	fa050513          	addi	a0,a0,-96 # 800088f8 <sysnames+0x200>
    80004960:	ffffc097          	auipc	ra,0xffffc
    80004964:	c70080e7          	jalr	-912(ra) # 800005d0 <panic>
    wakeup(&log);
    80004968:	0001e497          	auipc	s1,0x1e
    8000496c:	ba048493          	addi	s1,s1,-1120 # 80022508 <log>
    80004970:	8526                	mv	a0,s1
    80004972:	ffffe097          	auipc	ra,0xffffe
    80004976:	036080e7          	jalr	54(ra) # 800029a8 <wakeup>
  release(&log.lock);
    8000497a:	8526                	mv	a0,s1
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	3f0080e7          	jalr	1008(ra) # 80000d6c <release>
  if(do_commit){
    80004984:	b7c9                	j	80004946 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004986:	0001ea97          	auipc	s5,0x1e
    8000498a:	bb2a8a93          	addi	s5,s5,-1102 # 80022538 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000498e:	0001ea17          	auipc	s4,0x1e
    80004992:	b7aa0a13          	addi	s4,s4,-1158 # 80022508 <log>
    80004996:	018a2583          	lw	a1,24(s4)
    8000499a:	012585bb          	addw	a1,a1,s2
    8000499e:	2585                	addiw	a1,a1,1
    800049a0:	028a2503          	lw	a0,40(s4)
    800049a4:	fffff097          	auipc	ra,0xfffff
    800049a8:	ce8080e7          	jalr	-792(ra) # 8000368c <bread>
    800049ac:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800049ae:	000aa583          	lw	a1,0(s5)
    800049b2:	028a2503          	lw	a0,40(s4)
    800049b6:	fffff097          	auipc	ra,0xfffff
    800049ba:	cd6080e7          	jalr	-810(ra) # 8000368c <bread>
    800049be:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800049c0:	40000613          	li	a2,1024
    800049c4:	05850593          	addi	a1,a0,88
    800049c8:	05848513          	addi	a0,s1,88
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	448080e7          	jalr	1096(ra) # 80000e14 <memmove>
    bwrite(to);  // write the log
    800049d4:	8526                	mv	a0,s1
    800049d6:	fffff097          	auipc	ra,0xfffff
    800049da:	da8080e7          	jalr	-600(ra) # 8000377e <bwrite>
    brelse(from);
    800049de:	854e                	mv	a0,s3
    800049e0:	fffff097          	auipc	ra,0xfffff
    800049e4:	ddc080e7          	jalr	-548(ra) # 800037bc <brelse>
    brelse(to);
    800049e8:	8526                	mv	a0,s1
    800049ea:	fffff097          	auipc	ra,0xfffff
    800049ee:	dd2080e7          	jalr	-558(ra) # 800037bc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049f2:	2905                	addiw	s2,s2,1
    800049f4:	0a91                	addi	s5,s5,4
    800049f6:	02ca2783          	lw	a5,44(s4)
    800049fa:	f8f94ee3          	blt	s2,a5,80004996 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800049fe:	00000097          	auipc	ra,0x0
    80004a02:	c7a080e7          	jalr	-902(ra) # 80004678 <write_head>
    install_trans(); // Now install writes to home locations
    80004a06:	00000097          	auipc	ra,0x0
    80004a0a:	cec080e7          	jalr	-788(ra) # 800046f2 <install_trans>
    log.lh.n = 0;
    80004a0e:	0001e797          	auipc	a5,0x1e
    80004a12:	b207a323          	sw	zero,-1242(a5) # 80022534 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	c62080e7          	jalr	-926(ra) # 80004678 <write_head>
    80004a1e:	bdfd                	j	8000491c <end_op+0x52>

0000000080004a20 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a20:	1101                	addi	sp,sp,-32
    80004a22:	ec06                	sd	ra,24(sp)
    80004a24:	e822                	sd	s0,16(sp)
    80004a26:	e426                	sd	s1,8(sp)
    80004a28:	e04a                	sd	s2,0(sp)
    80004a2a:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a2c:	0001e717          	auipc	a4,0x1e
    80004a30:	b0872703          	lw	a4,-1272(a4) # 80022534 <log+0x2c>
    80004a34:	47f5                	li	a5,29
    80004a36:	08e7c063          	blt	a5,a4,80004ab6 <log_write+0x96>
    80004a3a:	84aa                	mv	s1,a0
    80004a3c:	0001e797          	auipc	a5,0x1e
    80004a40:	ae87a783          	lw	a5,-1304(a5) # 80022524 <log+0x1c>
    80004a44:	37fd                	addiw	a5,a5,-1
    80004a46:	06f75863          	bge	a4,a5,80004ab6 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a4a:	0001e797          	auipc	a5,0x1e
    80004a4e:	ade7a783          	lw	a5,-1314(a5) # 80022528 <log+0x20>
    80004a52:	06f05a63          	blez	a5,80004ac6 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004a56:	0001e917          	auipc	s2,0x1e
    80004a5a:	ab290913          	addi	s2,s2,-1358 # 80022508 <log>
    80004a5e:	854a                	mv	a0,s2
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	258080e7          	jalr	600(ra) # 80000cb8 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004a68:	02c92603          	lw	a2,44(s2)
    80004a6c:	06c05563          	blez	a2,80004ad6 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004a70:	44cc                	lw	a1,12(s1)
    80004a72:	0001e717          	auipc	a4,0x1e
    80004a76:	ac670713          	addi	a4,a4,-1338 # 80022538 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a7a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004a7c:	4314                	lw	a3,0(a4)
    80004a7e:	04b68d63          	beq	a3,a1,80004ad8 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004a82:	2785                	addiw	a5,a5,1
    80004a84:	0711                	addi	a4,a4,4
    80004a86:	fec79be3          	bne	a5,a2,80004a7c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a8a:	0621                	addi	a2,a2,8
    80004a8c:	060a                	slli	a2,a2,0x2
    80004a8e:	0001e797          	auipc	a5,0x1e
    80004a92:	a7a78793          	addi	a5,a5,-1414 # 80022508 <log>
    80004a96:	963e                	add	a2,a2,a5
    80004a98:	44dc                	lw	a5,12(s1)
    80004a9a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a9c:	8526                	mv	a0,s1
    80004a9e:	fffff097          	auipc	ra,0xfffff
    80004aa2:	dbc080e7          	jalr	-580(ra) # 8000385a <bpin>
    log.lh.n++;
    80004aa6:	0001e717          	auipc	a4,0x1e
    80004aaa:	a6270713          	addi	a4,a4,-1438 # 80022508 <log>
    80004aae:	575c                	lw	a5,44(a4)
    80004ab0:	2785                	addiw	a5,a5,1
    80004ab2:	d75c                	sw	a5,44(a4)
    80004ab4:	a83d                	j	80004af2 <log_write+0xd2>
    panic("too big a transaction");
    80004ab6:	00004517          	auipc	a0,0x4
    80004aba:	e5250513          	addi	a0,a0,-430 # 80008908 <sysnames+0x210>
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	b12080e7          	jalr	-1262(ra) # 800005d0 <panic>
    panic("log_write outside of trans");
    80004ac6:	00004517          	auipc	a0,0x4
    80004aca:	e5a50513          	addi	a0,a0,-422 # 80008920 <sysnames+0x228>
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	b02080e7          	jalr	-1278(ra) # 800005d0 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004ad6:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004ad8:	00878713          	addi	a4,a5,8
    80004adc:	00271693          	slli	a3,a4,0x2
    80004ae0:	0001e717          	auipc	a4,0x1e
    80004ae4:	a2870713          	addi	a4,a4,-1496 # 80022508 <log>
    80004ae8:	9736                	add	a4,a4,a3
    80004aea:	44d4                	lw	a3,12(s1)
    80004aec:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004aee:	faf607e3          	beq	a2,a5,80004a9c <log_write+0x7c>
  }
  release(&log.lock);
    80004af2:	0001e517          	auipc	a0,0x1e
    80004af6:	a1650513          	addi	a0,a0,-1514 # 80022508 <log>
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	272080e7          	jalr	626(ra) # 80000d6c <release>
}
    80004b02:	60e2                	ld	ra,24(sp)
    80004b04:	6442                	ld	s0,16(sp)
    80004b06:	64a2                	ld	s1,8(sp)
    80004b08:	6902                	ld	s2,0(sp)
    80004b0a:	6105                	addi	sp,sp,32
    80004b0c:	8082                	ret

0000000080004b0e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b0e:	1101                	addi	sp,sp,-32
    80004b10:	ec06                	sd	ra,24(sp)
    80004b12:	e822                	sd	s0,16(sp)
    80004b14:	e426                	sd	s1,8(sp)
    80004b16:	e04a                	sd	s2,0(sp)
    80004b18:	1000                	addi	s0,sp,32
    80004b1a:	84aa                	mv	s1,a0
    80004b1c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b1e:	00004597          	auipc	a1,0x4
    80004b22:	e2258593          	addi	a1,a1,-478 # 80008940 <sysnames+0x248>
    80004b26:	0521                	addi	a0,a0,8
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	100080e7          	jalr	256(ra) # 80000c28 <initlock>
  lk->name = name;
    80004b30:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b34:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b38:	0204a423          	sw	zero,40(s1)
}
    80004b3c:	60e2                	ld	ra,24(sp)
    80004b3e:	6442                	ld	s0,16(sp)
    80004b40:	64a2                	ld	s1,8(sp)
    80004b42:	6902                	ld	s2,0(sp)
    80004b44:	6105                	addi	sp,sp,32
    80004b46:	8082                	ret

0000000080004b48 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b48:	1101                	addi	sp,sp,-32
    80004b4a:	ec06                	sd	ra,24(sp)
    80004b4c:	e822                	sd	s0,16(sp)
    80004b4e:	e426                	sd	s1,8(sp)
    80004b50:	e04a                	sd	s2,0(sp)
    80004b52:	1000                	addi	s0,sp,32
    80004b54:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b56:	00850913          	addi	s2,a0,8
    80004b5a:	854a                	mv	a0,s2
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	15c080e7          	jalr	348(ra) # 80000cb8 <acquire>
  while (lk->locked) {
    80004b64:	409c                	lw	a5,0(s1)
    80004b66:	cb89                	beqz	a5,80004b78 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b68:	85ca                	mv	a1,s2
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	ffffe097          	auipc	ra,0xffffe
    80004b70:	cb6080e7          	jalr	-842(ra) # 80002822 <sleep>
  while (lk->locked) {
    80004b74:	409c                	lw	a5,0(s1)
    80004b76:	fbed                	bnez	a5,80004b68 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b78:	4785                	li	a5,1
    80004b7a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b7c:	ffffd097          	auipc	ra,0xffffd
    80004b80:	2c6080e7          	jalr	710(ra) # 80001e42 <myproc>
    80004b84:	5d1c                	lw	a5,56(a0)
    80004b86:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b88:	854a                	mv	a0,s2
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	1e2080e7          	jalr	482(ra) # 80000d6c <release>
}
    80004b92:	60e2                	ld	ra,24(sp)
    80004b94:	6442                	ld	s0,16(sp)
    80004b96:	64a2                	ld	s1,8(sp)
    80004b98:	6902                	ld	s2,0(sp)
    80004b9a:	6105                	addi	sp,sp,32
    80004b9c:	8082                	ret

0000000080004b9e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b9e:	1101                	addi	sp,sp,-32
    80004ba0:	ec06                	sd	ra,24(sp)
    80004ba2:	e822                	sd	s0,16(sp)
    80004ba4:	e426                	sd	s1,8(sp)
    80004ba6:	e04a                	sd	s2,0(sp)
    80004ba8:	1000                	addi	s0,sp,32
    80004baa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bac:	00850913          	addi	s2,a0,8
    80004bb0:	854a                	mv	a0,s2
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	106080e7          	jalr	262(ra) # 80000cb8 <acquire>
  lk->locked = 0;
    80004bba:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004bbe:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004bc2:	8526                	mv	a0,s1
    80004bc4:	ffffe097          	auipc	ra,0xffffe
    80004bc8:	de4080e7          	jalr	-540(ra) # 800029a8 <wakeup>
  release(&lk->lk);
    80004bcc:	854a                	mv	a0,s2
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	19e080e7          	jalr	414(ra) # 80000d6c <release>
}
    80004bd6:	60e2                	ld	ra,24(sp)
    80004bd8:	6442                	ld	s0,16(sp)
    80004bda:	64a2                	ld	s1,8(sp)
    80004bdc:	6902                	ld	s2,0(sp)
    80004bde:	6105                	addi	sp,sp,32
    80004be0:	8082                	ret

0000000080004be2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004be2:	7179                	addi	sp,sp,-48
    80004be4:	f406                	sd	ra,40(sp)
    80004be6:	f022                	sd	s0,32(sp)
    80004be8:	ec26                	sd	s1,24(sp)
    80004bea:	e84a                	sd	s2,16(sp)
    80004bec:	e44e                	sd	s3,8(sp)
    80004bee:	1800                	addi	s0,sp,48
    80004bf0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004bf2:	00850913          	addi	s2,a0,8
    80004bf6:	854a                	mv	a0,s2
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	0c0080e7          	jalr	192(ra) # 80000cb8 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c00:	409c                	lw	a5,0(s1)
    80004c02:	ef99                	bnez	a5,80004c20 <holdingsleep+0x3e>
    80004c04:	4481                	li	s1,0
  release(&lk->lk);
    80004c06:	854a                	mv	a0,s2
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	164080e7          	jalr	356(ra) # 80000d6c <release>
  return r;
}
    80004c10:	8526                	mv	a0,s1
    80004c12:	70a2                	ld	ra,40(sp)
    80004c14:	7402                	ld	s0,32(sp)
    80004c16:	64e2                	ld	s1,24(sp)
    80004c18:	6942                	ld	s2,16(sp)
    80004c1a:	69a2                	ld	s3,8(sp)
    80004c1c:	6145                	addi	sp,sp,48
    80004c1e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c20:	0284a983          	lw	s3,40(s1)
    80004c24:	ffffd097          	auipc	ra,0xffffd
    80004c28:	21e080e7          	jalr	542(ra) # 80001e42 <myproc>
    80004c2c:	5d04                	lw	s1,56(a0)
    80004c2e:	413484b3          	sub	s1,s1,s3
    80004c32:	0014b493          	seqz	s1,s1
    80004c36:	bfc1                	j	80004c06 <holdingsleep+0x24>

0000000080004c38 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c38:	1141                	addi	sp,sp,-16
    80004c3a:	e406                	sd	ra,8(sp)
    80004c3c:	e022                	sd	s0,0(sp)
    80004c3e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c40:	00004597          	auipc	a1,0x4
    80004c44:	d1058593          	addi	a1,a1,-752 # 80008950 <sysnames+0x258>
    80004c48:	0001e517          	auipc	a0,0x1e
    80004c4c:	a0850513          	addi	a0,a0,-1528 # 80022650 <ftable>
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	fd8080e7          	jalr	-40(ra) # 80000c28 <initlock>
}
    80004c58:	60a2                	ld	ra,8(sp)
    80004c5a:	6402                	ld	s0,0(sp)
    80004c5c:	0141                	addi	sp,sp,16
    80004c5e:	8082                	ret

0000000080004c60 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c60:	1101                	addi	sp,sp,-32
    80004c62:	ec06                	sd	ra,24(sp)
    80004c64:	e822                	sd	s0,16(sp)
    80004c66:	e426                	sd	s1,8(sp)
    80004c68:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c6a:	0001e517          	auipc	a0,0x1e
    80004c6e:	9e650513          	addi	a0,a0,-1562 # 80022650 <ftable>
    80004c72:	ffffc097          	auipc	ra,0xffffc
    80004c76:	046080e7          	jalr	70(ra) # 80000cb8 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c7a:	0001e497          	auipc	s1,0x1e
    80004c7e:	9ee48493          	addi	s1,s1,-1554 # 80022668 <ftable+0x18>
    80004c82:	0001f717          	auipc	a4,0x1f
    80004c86:	98670713          	addi	a4,a4,-1658 # 80023608 <ftable+0xfb8>
    if(f->ref == 0){
    80004c8a:	40dc                	lw	a5,4(s1)
    80004c8c:	cf99                	beqz	a5,80004caa <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c8e:	02848493          	addi	s1,s1,40
    80004c92:	fee49ce3          	bne	s1,a4,80004c8a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c96:	0001e517          	auipc	a0,0x1e
    80004c9a:	9ba50513          	addi	a0,a0,-1606 # 80022650 <ftable>
    80004c9e:	ffffc097          	auipc	ra,0xffffc
    80004ca2:	0ce080e7          	jalr	206(ra) # 80000d6c <release>
  return 0;
    80004ca6:	4481                	li	s1,0
    80004ca8:	a819                	j	80004cbe <filealloc+0x5e>
      f->ref = 1;
    80004caa:	4785                	li	a5,1
    80004cac:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004cae:	0001e517          	auipc	a0,0x1e
    80004cb2:	9a250513          	addi	a0,a0,-1630 # 80022650 <ftable>
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	0b6080e7          	jalr	182(ra) # 80000d6c <release>
}
    80004cbe:	8526                	mv	a0,s1
    80004cc0:	60e2                	ld	ra,24(sp)
    80004cc2:	6442                	ld	s0,16(sp)
    80004cc4:	64a2                	ld	s1,8(sp)
    80004cc6:	6105                	addi	sp,sp,32
    80004cc8:	8082                	ret

0000000080004cca <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004cca:	1101                	addi	sp,sp,-32
    80004ccc:	ec06                	sd	ra,24(sp)
    80004cce:	e822                	sd	s0,16(sp)
    80004cd0:	e426                	sd	s1,8(sp)
    80004cd2:	1000                	addi	s0,sp,32
    80004cd4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004cd6:	0001e517          	auipc	a0,0x1e
    80004cda:	97a50513          	addi	a0,a0,-1670 # 80022650 <ftable>
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	fda080e7          	jalr	-38(ra) # 80000cb8 <acquire>
  if(f->ref < 1)
    80004ce6:	40dc                	lw	a5,4(s1)
    80004ce8:	02f05263          	blez	a5,80004d0c <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004cec:	2785                	addiw	a5,a5,1
    80004cee:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004cf0:	0001e517          	auipc	a0,0x1e
    80004cf4:	96050513          	addi	a0,a0,-1696 # 80022650 <ftable>
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	074080e7          	jalr	116(ra) # 80000d6c <release>
  return f;
}
    80004d00:	8526                	mv	a0,s1
    80004d02:	60e2                	ld	ra,24(sp)
    80004d04:	6442                	ld	s0,16(sp)
    80004d06:	64a2                	ld	s1,8(sp)
    80004d08:	6105                	addi	sp,sp,32
    80004d0a:	8082                	ret
    panic("filedup");
    80004d0c:	00004517          	auipc	a0,0x4
    80004d10:	c4c50513          	addi	a0,a0,-948 # 80008958 <sysnames+0x260>
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	8bc080e7          	jalr	-1860(ra) # 800005d0 <panic>

0000000080004d1c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d1c:	7139                	addi	sp,sp,-64
    80004d1e:	fc06                	sd	ra,56(sp)
    80004d20:	f822                	sd	s0,48(sp)
    80004d22:	f426                	sd	s1,40(sp)
    80004d24:	f04a                	sd	s2,32(sp)
    80004d26:	ec4e                	sd	s3,24(sp)
    80004d28:	e852                	sd	s4,16(sp)
    80004d2a:	e456                	sd	s5,8(sp)
    80004d2c:	0080                	addi	s0,sp,64
    80004d2e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d30:	0001e517          	auipc	a0,0x1e
    80004d34:	92050513          	addi	a0,a0,-1760 # 80022650 <ftable>
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	f80080e7          	jalr	-128(ra) # 80000cb8 <acquire>
  if(f->ref < 1)
    80004d40:	40dc                	lw	a5,4(s1)
    80004d42:	06f05163          	blez	a5,80004da4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d46:	37fd                	addiw	a5,a5,-1
    80004d48:	0007871b          	sext.w	a4,a5
    80004d4c:	c0dc                	sw	a5,4(s1)
    80004d4e:	06e04363          	bgtz	a4,80004db4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d52:	0004a903          	lw	s2,0(s1)
    80004d56:	0094ca83          	lbu	s5,9(s1)
    80004d5a:	0104ba03          	ld	s4,16(s1)
    80004d5e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d62:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d66:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d6a:	0001e517          	auipc	a0,0x1e
    80004d6e:	8e650513          	addi	a0,a0,-1818 # 80022650 <ftable>
    80004d72:	ffffc097          	auipc	ra,0xffffc
    80004d76:	ffa080e7          	jalr	-6(ra) # 80000d6c <release>

  if(ff.type == FD_PIPE){
    80004d7a:	4785                	li	a5,1
    80004d7c:	04f90d63          	beq	s2,a5,80004dd6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d80:	3979                	addiw	s2,s2,-2
    80004d82:	4785                	li	a5,1
    80004d84:	0527e063          	bltu	a5,s2,80004dc4 <fileclose+0xa8>
    begin_op();
    80004d88:	00000097          	auipc	ra,0x0
    80004d8c:	ac2080e7          	jalr	-1342(ra) # 8000484a <begin_op>
    iput(ff.ip);
    80004d90:	854e                	mv	a0,s3
    80004d92:	fffff097          	auipc	ra,0xfffff
    80004d96:	2b6080e7          	jalr	694(ra) # 80004048 <iput>
    end_op();
    80004d9a:	00000097          	auipc	ra,0x0
    80004d9e:	b30080e7          	jalr	-1232(ra) # 800048ca <end_op>
    80004da2:	a00d                	j	80004dc4 <fileclose+0xa8>
    panic("fileclose");
    80004da4:	00004517          	auipc	a0,0x4
    80004da8:	bbc50513          	addi	a0,a0,-1092 # 80008960 <sysnames+0x268>
    80004dac:	ffffc097          	auipc	ra,0xffffc
    80004db0:	824080e7          	jalr	-2012(ra) # 800005d0 <panic>
    release(&ftable.lock);
    80004db4:	0001e517          	auipc	a0,0x1e
    80004db8:	89c50513          	addi	a0,a0,-1892 # 80022650 <ftable>
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	fb0080e7          	jalr	-80(ra) # 80000d6c <release>
  }
}
    80004dc4:	70e2                	ld	ra,56(sp)
    80004dc6:	7442                	ld	s0,48(sp)
    80004dc8:	74a2                	ld	s1,40(sp)
    80004dca:	7902                	ld	s2,32(sp)
    80004dcc:	69e2                	ld	s3,24(sp)
    80004dce:	6a42                	ld	s4,16(sp)
    80004dd0:	6aa2                	ld	s5,8(sp)
    80004dd2:	6121                	addi	sp,sp,64
    80004dd4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004dd6:	85d6                	mv	a1,s5
    80004dd8:	8552                	mv	a0,s4
    80004dda:	00000097          	auipc	ra,0x0
    80004dde:	372080e7          	jalr	882(ra) # 8000514c <pipeclose>
    80004de2:	b7cd                	j	80004dc4 <fileclose+0xa8>

0000000080004de4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004de4:	715d                	addi	sp,sp,-80
    80004de6:	e486                	sd	ra,72(sp)
    80004de8:	e0a2                	sd	s0,64(sp)
    80004dea:	fc26                	sd	s1,56(sp)
    80004dec:	f84a                	sd	s2,48(sp)
    80004dee:	f44e                	sd	s3,40(sp)
    80004df0:	0880                	addi	s0,sp,80
    80004df2:	84aa                	mv	s1,a0
    80004df4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004df6:	ffffd097          	auipc	ra,0xffffd
    80004dfa:	04c080e7          	jalr	76(ra) # 80001e42 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004dfe:	409c                	lw	a5,0(s1)
    80004e00:	37f9                	addiw	a5,a5,-2
    80004e02:	4705                	li	a4,1
    80004e04:	04f76763          	bltu	a4,a5,80004e52 <filestat+0x6e>
    80004e08:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e0a:	6c88                	ld	a0,24(s1)
    80004e0c:	fffff097          	auipc	ra,0xfffff
    80004e10:	082080e7          	jalr	130(ra) # 80003e8e <ilock>
    stati(f->ip, &st);
    80004e14:	fb840593          	addi	a1,s0,-72
    80004e18:	6c88                	ld	a0,24(s1)
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	2fe080e7          	jalr	766(ra) # 80004118 <stati>
    iunlock(f->ip);
    80004e22:	6c88                	ld	a0,24(s1)
    80004e24:	fffff097          	auipc	ra,0xfffff
    80004e28:	12c080e7          	jalr	300(ra) # 80003f50 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e2c:	46e1                	li	a3,24
    80004e2e:	fb840613          	addi	a2,s0,-72
    80004e32:	85ce                	mv	a1,s3
    80004e34:	05093503          	ld	a0,80(s2)
    80004e38:	ffffd097          	auipc	ra,0xffffd
    80004e3c:	adc080e7          	jalr	-1316(ra) # 80001914 <copyout>
    80004e40:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e44:	60a6                	ld	ra,72(sp)
    80004e46:	6406                	ld	s0,64(sp)
    80004e48:	74e2                	ld	s1,56(sp)
    80004e4a:	7942                	ld	s2,48(sp)
    80004e4c:	79a2                	ld	s3,40(sp)
    80004e4e:	6161                	addi	sp,sp,80
    80004e50:	8082                	ret
  return -1;
    80004e52:	557d                	li	a0,-1
    80004e54:	bfc5                	j	80004e44 <filestat+0x60>

0000000080004e56 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e56:	7179                	addi	sp,sp,-48
    80004e58:	f406                	sd	ra,40(sp)
    80004e5a:	f022                	sd	s0,32(sp)
    80004e5c:	ec26                	sd	s1,24(sp)
    80004e5e:	e84a                	sd	s2,16(sp)
    80004e60:	e44e                	sd	s3,8(sp)
    80004e62:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e64:	00854783          	lbu	a5,8(a0)
    80004e68:	c3d5                	beqz	a5,80004f0c <fileread+0xb6>
    80004e6a:	84aa                	mv	s1,a0
    80004e6c:	89ae                	mv	s3,a1
    80004e6e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e70:	411c                	lw	a5,0(a0)
    80004e72:	4705                	li	a4,1
    80004e74:	04e78963          	beq	a5,a4,80004ec6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e78:	470d                	li	a4,3
    80004e7a:	04e78d63          	beq	a5,a4,80004ed4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e7e:	4709                	li	a4,2
    80004e80:	06e79e63          	bne	a5,a4,80004efc <fileread+0xa6>
    ilock(f->ip);
    80004e84:	6d08                	ld	a0,24(a0)
    80004e86:	fffff097          	auipc	ra,0xfffff
    80004e8a:	008080e7          	jalr	8(ra) # 80003e8e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e8e:	874a                	mv	a4,s2
    80004e90:	5094                	lw	a3,32(s1)
    80004e92:	864e                	mv	a2,s3
    80004e94:	4585                	li	a1,1
    80004e96:	6c88                	ld	a0,24(s1)
    80004e98:	fffff097          	auipc	ra,0xfffff
    80004e9c:	2aa080e7          	jalr	682(ra) # 80004142 <readi>
    80004ea0:	892a                	mv	s2,a0
    80004ea2:	00a05563          	blez	a0,80004eac <fileread+0x56>
      f->off += r;
    80004ea6:	509c                	lw	a5,32(s1)
    80004ea8:	9fa9                	addw	a5,a5,a0
    80004eaa:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004eac:	6c88                	ld	a0,24(s1)
    80004eae:	fffff097          	auipc	ra,0xfffff
    80004eb2:	0a2080e7          	jalr	162(ra) # 80003f50 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004eb6:	854a                	mv	a0,s2
    80004eb8:	70a2                	ld	ra,40(sp)
    80004eba:	7402                	ld	s0,32(sp)
    80004ebc:	64e2                	ld	s1,24(sp)
    80004ebe:	6942                	ld	s2,16(sp)
    80004ec0:	69a2                	ld	s3,8(sp)
    80004ec2:	6145                	addi	sp,sp,48
    80004ec4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ec6:	6908                	ld	a0,16(a0)
    80004ec8:	00000097          	auipc	ra,0x0
    80004ecc:	418080e7          	jalr	1048(ra) # 800052e0 <piperead>
    80004ed0:	892a                	mv	s2,a0
    80004ed2:	b7d5                	j	80004eb6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ed4:	02451783          	lh	a5,36(a0)
    80004ed8:	03079693          	slli	a3,a5,0x30
    80004edc:	92c1                	srli	a3,a3,0x30
    80004ede:	4725                	li	a4,9
    80004ee0:	02d76863          	bltu	a4,a3,80004f10 <fileread+0xba>
    80004ee4:	0792                	slli	a5,a5,0x4
    80004ee6:	0001d717          	auipc	a4,0x1d
    80004eea:	6ca70713          	addi	a4,a4,1738 # 800225b0 <devsw>
    80004eee:	97ba                	add	a5,a5,a4
    80004ef0:	639c                	ld	a5,0(a5)
    80004ef2:	c38d                	beqz	a5,80004f14 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ef4:	4505                	li	a0,1
    80004ef6:	9782                	jalr	a5
    80004ef8:	892a                	mv	s2,a0
    80004efa:	bf75                	j	80004eb6 <fileread+0x60>
    panic("fileread");
    80004efc:	00004517          	auipc	a0,0x4
    80004f00:	a7450513          	addi	a0,a0,-1420 # 80008970 <sysnames+0x278>
    80004f04:	ffffb097          	auipc	ra,0xffffb
    80004f08:	6cc080e7          	jalr	1740(ra) # 800005d0 <panic>
    return -1;
    80004f0c:	597d                	li	s2,-1
    80004f0e:	b765                	j	80004eb6 <fileread+0x60>
      return -1;
    80004f10:	597d                	li	s2,-1
    80004f12:	b755                	j	80004eb6 <fileread+0x60>
    80004f14:	597d                	li	s2,-1
    80004f16:	b745                	j	80004eb6 <fileread+0x60>

0000000080004f18 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004f18:	00954783          	lbu	a5,9(a0)
    80004f1c:	14078563          	beqz	a5,80005066 <filewrite+0x14e>
{
    80004f20:	715d                	addi	sp,sp,-80
    80004f22:	e486                	sd	ra,72(sp)
    80004f24:	e0a2                	sd	s0,64(sp)
    80004f26:	fc26                	sd	s1,56(sp)
    80004f28:	f84a                	sd	s2,48(sp)
    80004f2a:	f44e                	sd	s3,40(sp)
    80004f2c:	f052                	sd	s4,32(sp)
    80004f2e:	ec56                	sd	s5,24(sp)
    80004f30:	e85a                	sd	s6,16(sp)
    80004f32:	e45e                	sd	s7,8(sp)
    80004f34:	e062                	sd	s8,0(sp)
    80004f36:	0880                	addi	s0,sp,80
    80004f38:	892a                	mv	s2,a0
    80004f3a:	8aae                	mv	s5,a1
    80004f3c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f3e:	411c                	lw	a5,0(a0)
    80004f40:	4705                	li	a4,1
    80004f42:	02e78263          	beq	a5,a4,80004f66 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f46:	470d                	li	a4,3
    80004f48:	02e78563          	beq	a5,a4,80004f72 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f4c:	4709                	li	a4,2
    80004f4e:	10e79463          	bne	a5,a4,80005056 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f52:	0ec05e63          	blez	a2,8000504e <filewrite+0x136>
    int i = 0;
    80004f56:	4981                	li	s3,0
    80004f58:	6b05                	lui	s6,0x1
    80004f5a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f5e:	6b85                	lui	s7,0x1
    80004f60:	c00b8b9b          	addiw	s7,s7,-1024
    80004f64:	a851                	j	80004ff8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004f66:	6908                	ld	a0,16(a0)
    80004f68:	00000097          	auipc	ra,0x0
    80004f6c:	254080e7          	jalr	596(ra) # 800051bc <pipewrite>
    80004f70:	a85d                	j	80005026 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f72:	02451783          	lh	a5,36(a0)
    80004f76:	03079693          	slli	a3,a5,0x30
    80004f7a:	92c1                	srli	a3,a3,0x30
    80004f7c:	4725                	li	a4,9
    80004f7e:	0ed76663          	bltu	a4,a3,8000506a <filewrite+0x152>
    80004f82:	0792                	slli	a5,a5,0x4
    80004f84:	0001d717          	auipc	a4,0x1d
    80004f88:	62c70713          	addi	a4,a4,1580 # 800225b0 <devsw>
    80004f8c:	97ba                	add	a5,a5,a4
    80004f8e:	679c                	ld	a5,8(a5)
    80004f90:	cff9                	beqz	a5,8000506e <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004f92:	4505                	li	a0,1
    80004f94:	9782                	jalr	a5
    80004f96:	a841                	j	80005026 <filewrite+0x10e>
    80004f98:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f9c:	00000097          	auipc	ra,0x0
    80004fa0:	8ae080e7          	jalr	-1874(ra) # 8000484a <begin_op>
      ilock(f->ip);
    80004fa4:	01893503          	ld	a0,24(s2)
    80004fa8:	fffff097          	auipc	ra,0xfffff
    80004fac:	ee6080e7          	jalr	-282(ra) # 80003e8e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004fb0:	8762                	mv	a4,s8
    80004fb2:	02092683          	lw	a3,32(s2)
    80004fb6:	01598633          	add	a2,s3,s5
    80004fba:	4585                	li	a1,1
    80004fbc:	01893503          	ld	a0,24(s2)
    80004fc0:	fffff097          	auipc	ra,0xfffff
    80004fc4:	278080e7          	jalr	632(ra) # 80004238 <writei>
    80004fc8:	84aa                	mv	s1,a0
    80004fca:	02a05f63          	blez	a0,80005008 <filewrite+0xf0>
        f->off += r;
    80004fce:	02092783          	lw	a5,32(s2)
    80004fd2:	9fa9                	addw	a5,a5,a0
    80004fd4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004fd8:	01893503          	ld	a0,24(s2)
    80004fdc:	fffff097          	auipc	ra,0xfffff
    80004fe0:	f74080e7          	jalr	-140(ra) # 80003f50 <iunlock>
      end_op();
    80004fe4:	00000097          	auipc	ra,0x0
    80004fe8:	8e6080e7          	jalr	-1818(ra) # 800048ca <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004fec:	049c1963          	bne	s8,s1,8000503e <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004ff0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ff4:	0349d663          	bge	s3,s4,80005020 <filewrite+0x108>
      int n1 = n - i;
    80004ff8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ffc:	84be                	mv	s1,a5
    80004ffe:	2781                	sext.w	a5,a5
    80005000:	f8fb5ce3          	bge	s6,a5,80004f98 <filewrite+0x80>
    80005004:	84de                	mv	s1,s7
    80005006:	bf49                	j	80004f98 <filewrite+0x80>
      iunlock(f->ip);
    80005008:	01893503          	ld	a0,24(s2)
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	f44080e7          	jalr	-188(ra) # 80003f50 <iunlock>
      end_op();
    80005014:	00000097          	auipc	ra,0x0
    80005018:	8b6080e7          	jalr	-1866(ra) # 800048ca <end_op>
      if(r < 0)
    8000501c:	fc04d8e3          	bgez	s1,80004fec <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80005020:	8552                	mv	a0,s4
    80005022:	033a1863          	bne	s4,s3,80005052 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005026:	60a6                	ld	ra,72(sp)
    80005028:	6406                	ld	s0,64(sp)
    8000502a:	74e2                	ld	s1,56(sp)
    8000502c:	7942                	ld	s2,48(sp)
    8000502e:	79a2                	ld	s3,40(sp)
    80005030:	7a02                	ld	s4,32(sp)
    80005032:	6ae2                	ld	s5,24(sp)
    80005034:	6b42                	ld	s6,16(sp)
    80005036:	6ba2                	ld	s7,8(sp)
    80005038:	6c02                	ld	s8,0(sp)
    8000503a:	6161                	addi	sp,sp,80
    8000503c:	8082                	ret
        panic("short filewrite");
    8000503e:	00004517          	auipc	a0,0x4
    80005042:	94250513          	addi	a0,a0,-1726 # 80008980 <sysnames+0x288>
    80005046:	ffffb097          	auipc	ra,0xffffb
    8000504a:	58a080e7          	jalr	1418(ra) # 800005d0 <panic>
    int i = 0;
    8000504e:	4981                	li	s3,0
    80005050:	bfc1                	j	80005020 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80005052:	557d                	li	a0,-1
    80005054:	bfc9                	j	80005026 <filewrite+0x10e>
    panic("filewrite");
    80005056:	00004517          	auipc	a0,0x4
    8000505a:	93a50513          	addi	a0,a0,-1734 # 80008990 <sysnames+0x298>
    8000505e:	ffffb097          	auipc	ra,0xffffb
    80005062:	572080e7          	jalr	1394(ra) # 800005d0 <panic>
    return -1;
    80005066:	557d                	li	a0,-1
}
    80005068:	8082                	ret
      return -1;
    8000506a:	557d                	li	a0,-1
    8000506c:	bf6d                	j	80005026 <filewrite+0x10e>
    8000506e:	557d                	li	a0,-1
    80005070:	bf5d                	j	80005026 <filewrite+0x10e>

0000000080005072 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005072:	7179                	addi	sp,sp,-48
    80005074:	f406                	sd	ra,40(sp)
    80005076:	f022                	sd	s0,32(sp)
    80005078:	ec26                	sd	s1,24(sp)
    8000507a:	e84a                	sd	s2,16(sp)
    8000507c:	e44e                	sd	s3,8(sp)
    8000507e:	e052                	sd	s4,0(sp)
    80005080:	1800                	addi	s0,sp,48
    80005082:	84aa                	mv	s1,a0
    80005084:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005086:	0005b023          	sd	zero,0(a1)
    8000508a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000508e:	00000097          	auipc	ra,0x0
    80005092:	bd2080e7          	jalr	-1070(ra) # 80004c60 <filealloc>
    80005096:	e088                	sd	a0,0(s1)
    80005098:	c551                	beqz	a0,80005124 <pipealloc+0xb2>
    8000509a:	00000097          	auipc	ra,0x0
    8000509e:	bc6080e7          	jalr	-1082(ra) # 80004c60 <filealloc>
    800050a2:	00aa3023          	sd	a0,0(s4)
    800050a6:	c92d                	beqz	a0,80005118 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050a8:	ffffc097          	auipc	ra,0xffffc
    800050ac:	ad6080e7          	jalr	-1322(ra) # 80000b7e <kalloc>
    800050b0:	892a                	mv	s2,a0
    800050b2:	c125                	beqz	a0,80005112 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800050b4:	4985                	li	s3,1
    800050b6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800050ba:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800050be:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800050c2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800050c6:	00003597          	auipc	a1,0x3
    800050ca:	49258593          	addi	a1,a1,1170 # 80008558 <states.1775+0x198>
    800050ce:	ffffc097          	auipc	ra,0xffffc
    800050d2:	b5a080e7          	jalr	-1190(ra) # 80000c28 <initlock>
  (*f0)->type = FD_PIPE;
    800050d6:	609c                	ld	a5,0(s1)
    800050d8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800050dc:	609c                	ld	a5,0(s1)
    800050de:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800050e2:	609c                	ld	a5,0(s1)
    800050e4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800050e8:	609c                	ld	a5,0(s1)
    800050ea:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800050ee:	000a3783          	ld	a5,0(s4)
    800050f2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800050f6:	000a3783          	ld	a5,0(s4)
    800050fa:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800050fe:	000a3783          	ld	a5,0(s4)
    80005102:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005106:	000a3783          	ld	a5,0(s4)
    8000510a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000510e:	4501                	li	a0,0
    80005110:	a025                	j	80005138 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005112:	6088                	ld	a0,0(s1)
    80005114:	e501                	bnez	a0,8000511c <pipealloc+0xaa>
    80005116:	a039                	j	80005124 <pipealloc+0xb2>
    80005118:	6088                	ld	a0,0(s1)
    8000511a:	c51d                	beqz	a0,80005148 <pipealloc+0xd6>
    fileclose(*f0);
    8000511c:	00000097          	auipc	ra,0x0
    80005120:	c00080e7          	jalr	-1024(ra) # 80004d1c <fileclose>
  if(*f1)
    80005124:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005128:	557d                	li	a0,-1
  if(*f1)
    8000512a:	c799                	beqz	a5,80005138 <pipealloc+0xc6>
    fileclose(*f1);
    8000512c:	853e                	mv	a0,a5
    8000512e:	00000097          	auipc	ra,0x0
    80005132:	bee080e7          	jalr	-1042(ra) # 80004d1c <fileclose>
  return -1;
    80005136:	557d                	li	a0,-1
}
    80005138:	70a2                	ld	ra,40(sp)
    8000513a:	7402                	ld	s0,32(sp)
    8000513c:	64e2                	ld	s1,24(sp)
    8000513e:	6942                	ld	s2,16(sp)
    80005140:	69a2                	ld	s3,8(sp)
    80005142:	6a02                	ld	s4,0(sp)
    80005144:	6145                	addi	sp,sp,48
    80005146:	8082                	ret
  return -1;
    80005148:	557d                	li	a0,-1
    8000514a:	b7fd                	j	80005138 <pipealloc+0xc6>

000000008000514c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000514c:	1101                	addi	sp,sp,-32
    8000514e:	ec06                	sd	ra,24(sp)
    80005150:	e822                	sd	s0,16(sp)
    80005152:	e426                	sd	s1,8(sp)
    80005154:	e04a                	sd	s2,0(sp)
    80005156:	1000                	addi	s0,sp,32
    80005158:	84aa                	mv	s1,a0
    8000515a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000515c:	ffffc097          	auipc	ra,0xffffc
    80005160:	b5c080e7          	jalr	-1188(ra) # 80000cb8 <acquire>
  if(writable){
    80005164:	02090d63          	beqz	s2,8000519e <pipeclose+0x52>
    pi->writeopen = 0;
    80005168:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000516c:	21848513          	addi	a0,s1,536
    80005170:	ffffe097          	auipc	ra,0xffffe
    80005174:	838080e7          	jalr	-1992(ra) # 800029a8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005178:	2204b783          	ld	a5,544(s1)
    8000517c:	eb95                	bnez	a5,800051b0 <pipeclose+0x64>
    release(&pi->lock);
    8000517e:	8526                	mv	a0,s1
    80005180:	ffffc097          	auipc	ra,0xffffc
    80005184:	bec080e7          	jalr	-1044(ra) # 80000d6c <release>
    kfree((char*)pi);
    80005188:	8526                	mv	a0,s1
    8000518a:	ffffc097          	auipc	ra,0xffffc
    8000518e:	8f8080e7          	jalr	-1800(ra) # 80000a82 <kfree>
  } else
    release(&pi->lock);
}
    80005192:	60e2                	ld	ra,24(sp)
    80005194:	6442                	ld	s0,16(sp)
    80005196:	64a2                	ld	s1,8(sp)
    80005198:	6902                	ld	s2,0(sp)
    8000519a:	6105                	addi	sp,sp,32
    8000519c:	8082                	ret
    pi->readopen = 0;
    8000519e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800051a2:	21c48513          	addi	a0,s1,540
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	802080e7          	jalr	-2046(ra) # 800029a8 <wakeup>
    800051ae:	b7e9                	j	80005178 <pipeclose+0x2c>
    release(&pi->lock);
    800051b0:	8526                	mv	a0,s1
    800051b2:	ffffc097          	auipc	ra,0xffffc
    800051b6:	bba080e7          	jalr	-1094(ra) # 80000d6c <release>
}
    800051ba:	bfe1                	j	80005192 <pipeclose+0x46>

00000000800051bc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800051bc:	7119                	addi	sp,sp,-128
    800051be:	fc86                	sd	ra,120(sp)
    800051c0:	f8a2                	sd	s0,112(sp)
    800051c2:	f4a6                	sd	s1,104(sp)
    800051c4:	f0ca                	sd	s2,96(sp)
    800051c6:	ecce                	sd	s3,88(sp)
    800051c8:	e8d2                	sd	s4,80(sp)
    800051ca:	e4d6                	sd	s5,72(sp)
    800051cc:	e0da                	sd	s6,64(sp)
    800051ce:	fc5e                	sd	s7,56(sp)
    800051d0:	f862                	sd	s8,48(sp)
    800051d2:	f466                	sd	s9,40(sp)
    800051d4:	f06a                	sd	s10,32(sp)
    800051d6:	ec6e                	sd	s11,24(sp)
    800051d8:	0100                	addi	s0,sp,128
    800051da:	84aa                	mv	s1,a0
    800051dc:	8cae                	mv	s9,a1
    800051de:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    800051e0:	ffffd097          	auipc	ra,0xffffd
    800051e4:	c62080e7          	jalr	-926(ra) # 80001e42 <myproc>
    800051e8:	892a                	mv	s2,a0

  acquire(&pi->lock);
    800051ea:	8526                	mv	a0,s1
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	acc080e7          	jalr	-1332(ra) # 80000cb8 <acquire>
  for(i = 0; i < n; i++){
    800051f4:	0d605963          	blez	s6,800052c6 <pipewrite+0x10a>
    800051f8:	89a6                	mv	s3,s1
    800051fa:	3b7d                	addiw	s6,s6,-1
    800051fc:	1b02                	slli	s6,s6,0x20
    800051fe:	020b5b13          	srli	s6,s6,0x20
    80005202:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80005204:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005208:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000520c:	5dfd                	li	s11,-1
    8000520e:	000b8d1b          	sext.w	s10,s7
    80005212:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80005214:	2184a783          	lw	a5,536(s1)
    80005218:	21c4a703          	lw	a4,540(s1)
    8000521c:	2007879b          	addiw	a5,a5,512
    80005220:	02f71b63          	bne	a4,a5,80005256 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80005224:	2204a783          	lw	a5,544(s1)
    80005228:	cbad                	beqz	a5,8000529a <pipewrite+0xde>
    8000522a:	03092783          	lw	a5,48(s2)
    8000522e:	e7b5                	bnez	a5,8000529a <pipewrite+0xde>
      wakeup(&pi->nread);
    80005230:	8556                	mv	a0,s5
    80005232:	ffffd097          	auipc	ra,0xffffd
    80005236:	776080e7          	jalr	1910(ra) # 800029a8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000523a:	85ce                	mv	a1,s3
    8000523c:	8552                	mv	a0,s4
    8000523e:	ffffd097          	auipc	ra,0xffffd
    80005242:	5e4080e7          	jalr	1508(ra) # 80002822 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80005246:	2184a783          	lw	a5,536(s1)
    8000524a:	21c4a703          	lw	a4,540(s1)
    8000524e:	2007879b          	addiw	a5,a5,512
    80005252:	fcf709e3          	beq	a4,a5,80005224 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005256:	4685                	li	a3,1
    80005258:	019b8633          	add	a2,s7,s9
    8000525c:	f8f40593          	addi	a1,s0,-113
    80005260:	05093503          	ld	a0,80(s2)
    80005264:	ffffc097          	auipc	ra,0xffffc
    80005268:	73c080e7          	jalr	1852(ra) # 800019a0 <copyin>
    8000526c:	05b50e63          	beq	a0,s11,800052c8 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005270:	21c4a783          	lw	a5,540(s1)
    80005274:	0017871b          	addiw	a4,a5,1
    80005278:	20e4ae23          	sw	a4,540(s1)
    8000527c:	1ff7f793          	andi	a5,a5,511
    80005280:	97a6                	add	a5,a5,s1
    80005282:	f8f44703          	lbu	a4,-113(s0)
    80005286:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    8000528a:	001d0c1b          	addiw	s8,s10,1
    8000528e:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80005292:	036b8b63          	beq	s7,s6,800052c8 <pipewrite+0x10c>
    80005296:	8bbe                	mv	s7,a5
    80005298:	bf9d                	j	8000520e <pipewrite+0x52>
        release(&pi->lock);
    8000529a:	8526                	mv	a0,s1
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	ad0080e7          	jalr	-1328(ra) # 80000d6c <release>
        return -1;
    800052a4:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    800052a6:	8562                	mv	a0,s8
    800052a8:	70e6                	ld	ra,120(sp)
    800052aa:	7446                	ld	s0,112(sp)
    800052ac:	74a6                	ld	s1,104(sp)
    800052ae:	7906                	ld	s2,96(sp)
    800052b0:	69e6                	ld	s3,88(sp)
    800052b2:	6a46                	ld	s4,80(sp)
    800052b4:	6aa6                	ld	s5,72(sp)
    800052b6:	6b06                	ld	s6,64(sp)
    800052b8:	7be2                	ld	s7,56(sp)
    800052ba:	7c42                	ld	s8,48(sp)
    800052bc:	7ca2                	ld	s9,40(sp)
    800052be:	7d02                	ld	s10,32(sp)
    800052c0:	6de2                	ld	s11,24(sp)
    800052c2:	6109                	addi	sp,sp,128
    800052c4:	8082                	ret
  for(i = 0; i < n; i++){
    800052c6:	4c01                	li	s8,0
  wakeup(&pi->nread);
    800052c8:	21848513          	addi	a0,s1,536
    800052cc:	ffffd097          	auipc	ra,0xffffd
    800052d0:	6dc080e7          	jalr	1756(ra) # 800029a8 <wakeup>
  release(&pi->lock);
    800052d4:	8526                	mv	a0,s1
    800052d6:	ffffc097          	auipc	ra,0xffffc
    800052da:	a96080e7          	jalr	-1386(ra) # 80000d6c <release>
  return i;
    800052de:	b7e1                	j	800052a6 <pipewrite+0xea>

00000000800052e0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052e0:	715d                	addi	sp,sp,-80
    800052e2:	e486                	sd	ra,72(sp)
    800052e4:	e0a2                	sd	s0,64(sp)
    800052e6:	fc26                	sd	s1,56(sp)
    800052e8:	f84a                	sd	s2,48(sp)
    800052ea:	f44e                	sd	s3,40(sp)
    800052ec:	f052                	sd	s4,32(sp)
    800052ee:	ec56                	sd	s5,24(sp)
    800052f0:	e85a                	sd	s6,16(sp)
    800052f2:	0880                	addi	s0,sp,80
    800052f4:	84aa                	mv	s1,a0
    800052f6:	892e                	mv	s2,a1
    800052f8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800052fa:	ffffd097          	auipc	ra,0xffffd
    800052fe:	b48080e7          	jalr	-1208(ra) # 80001e42 <myproc>
    80005302:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005304:	8b26                	mv	s6,s1
    80005306:	8526                	mv	a0,s1
    80005308:	ffffc097          	auipc	ra,0xffffc
    8000530c:	9b0080e7          	jalr	-1616(ra) # 80000cb8 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005310:	2184a703          	lw	a4,536(s1)
    80005314:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005318:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000531c:	02f71463          	bne	a4,a5,80005344 <piperead+0x64>
    80005320:	2244a783          	lw	a5,548(s1)
    80005324:	c385                	beqz	a5,80005344 <piperead+0x64>
    if(pr->killed){
    80005326:	030a2783          	lw	a5,48(s4)
    8000532a:	ebc1                	bnez	a5,800053ba <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000532c:	85da                	mv	a1,s6
    8000532e:	854e                	mv	a0,s3
    80005330:	ffffd097          	auipc	ra,0xffffd
    80005334:	4f2080e7          	jalr	1266(ra) # 80002822 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005338:	2184a703          	lw	a4,536(s1)
    8000533c:	21c4a783          	lw	a5,540(s1)
    80005340:	fef700e3          	beq	a4,a5,80005320 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005344:	09505263          	blez	s5,800053c8 <piperead+0xe8>
    80005348:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000534a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000534c:	2184a783          	lw	a5,536(s1)
    80005350:	21c4a703          	lw	a4,540(s1)
    80005354:	02f70d63          	beq	a4,a5,8000538e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005358:	0017871b          	addiw	a4,a5,1
    8000535c:	20e4ac23          	sw	a4,536(s1)
    80005360:	1ff7f793          	andi	a5,a5,511
    80005364:	97a6                	add	a5,a5,s1
    80005366:	0187c783          	lbu	a5,24(a5)
    8000536a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000536e:	4685                	li	a3,1
    80005370:	fbf40613          	addi	a2,s0,-65
    80005374:	85ca                	mv	a1,s2
    80005376:	050a3503          	ld	a0,80(s4)
    8000537a:	ffffc097          	auipc	ra,0xffffc
    8000537e:	59a080e7          	jalr	1434(ra) # 80001914 <copyout>
    80005382:	01650663          	beq	a0,s6,8000538e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005386:	2985                	addiw	s3,s3,1
    80005388:	0905                	addi	s2,s2,1
    8000538a:	fd3a91e3          	bne	s5,s3,8000534c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000538e:	21c48513          	addi	a0,s1,540
    80005392:	ffffd097          	auipc	ra,0xffffd
    80005396:	616080e7          	jalr	1558(ra) # 800029a8 <wakeup>
  release(&pi->lock);
    8000539a:	8526                	mv	a0,s1
    8000539c:	ffffc097          	auipc	ra,0xffffc
    800053a0:	9d0080e7          	jalr	-1584(ra) # 80000d6c <release>
  return i;
}
    800053a4:	854e                	mv	a0,s3
    800053a6:	60a6                	ld	ra,72(sp)
    800053a8:	6406                	ld	s0,64(sp)
    800053aa:	74e2                	ld	s1,56(sp)
    800053ac:	7942                	ld	s2,48(sp)
    800053ae:	79a2                	ld	s3,40(sp)
    800053b0:	7a02                	ld	s4,32(sp)
    800053b2:	6ae2                	ld	s5,24(sp)
    800053b4:	6b42                	ld	s6,16(sp)
    800053b6:	6161                	addi	sp,sp,80
    800053b8:	8082                	ret
      release(&pi->lock);
    800053ba:	8526                	mv	a0,s1
    800053bc:	ffffc097          	auipc	ra,0xffffc
    800053c0:	9b0080e7          	jalr	-1616(ra) # 80000d6c <release>
      return -1;
    800053c4:	59fd                	li	s3,-1
    800053c6:	bff9                	j	800053a4 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053c8:	4981                	li	s3,0
    800053ca:	b7d1                	j	8000538e <piperead+0xae>

00000000800053cc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800053cc:	df010113          	addi	sp,sp,-528
    800053d0:	20113423          	sd	ra,520(sp)
    800053d4:	20813023          	sd	s0,512(sp)
    800053d8:	ffa6                	sd	s1,504(sp)
    800053da:	fbca                	sd	s2,496(sp)
    800053dc:	f7ce                	sd	s3,488(sp)
    800053de:	f3d2                	sd	s4,480(sp)
    800053e0:	efd6                	sd	s5,472(sp)
    800053e2:	ebda                	sd	s6,464(sp)
    800053e4:	e7de                	sd	s7,456(sp)
    800053e6:	e3e2                	sd	s8,448(sp)
    800053e8:	ff66                	sd	s9,440(sp)
    800053ea:	fb6a                	sd	s10,432(sp)
    800053ec:	f76e                	sd	s11,424(sp)
    800053ee:	0c00                	addi	s0,sp,528
    800053f0:	84aa                	mv	s1,a0
    800053f2:	dea43c23          	sd	a0,-520(s0)
    800053f6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800053fa:	ffffd097          	auipc	ra,0xffffd
    800053fe:	a48080e7          	jalr	-1464(ra) # 80001e42 <myproc>
    80005402:	892a                	mv	s2,a0

  begin_op();
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	446080e7          	jalr	1094(ra) # 8000484a <begin_op>

  if((ip = namei(path)) == 0){
    8000540c:	8526                	mv	a0,s1
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	230080e7          	jalr	560(ra) # 8000463e <namei>
    80005416:	c92d                	beqz	a0,80005488 <exec+0xbc>
    80005418:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	a74080e7          	jalr	-1420(ra) # 80003e8e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005422:	04000713          	li	a4,64
    80005426:	4681                	li	a3,0
    80005428:	e4840613          	addi	a2,s0,-440
    8000542c:	4581                	li	a1,0
    8000542e:	8526                	mv	a0,s1
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	d12080e7          	jalr	-750(ra) # 80004142 <readi>
    80005438:	04000793          	li	a5,64
    8000543c:	00f51a63          	bne	a0,a5,80005450 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005440:	e4842703          	lw	a4,-440(s0)
    80005444:	464c47b7          	lui	a5,0x464c4
    80005448:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000544c:	04f70463          	beq	a4,a5,80005494 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005450:	8526                	mv	a0,s1
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	c9e080e7          	jalr	-866(ra) # 800040f0 <iunlockput>
    end_op();
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	470080e7          	jalr	1136(ra) # 800048ca <end_op>
  }
  return -1;
    80005462:	557d                	li	a0,-1
}
    80005464:	20813083          	ld	ra,520(sp)
    80005468:	20013403          	ld	s0,512(sp)
    8000546c:	74fe                	ld	s1,504(sp)
    8000546e:	795e                	ld	s2,496(sp)
    80005470:	79be                	ld	s3,488(sp)
    80005472:	7a1e                	ld	s4,480(sp)
    80005474:	6afe                	ld	s5,472(sp)
    80005476:	6b5e                	ld	s6,464(sp)
    80005478:	6bbe                	ld	s7,456(sp)
    8000547a:	6c1e                	ld	s8,448(sp)
    8000547c:	7cfa                	ld	s9,440(sp)
    8000547e:	7d5a                	ld	s10,432(sp)
    80005480:	7dba                	ld	s11,424(sp)
    80005482:	21010113          	addi	sp,sp,528
    80005486:	8082                	ret
    end_op();
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	442080e7          	jalr	1090(ra) # 800048ca <end_op>
    return -1;
    80005490:	557d                	li	a0,-1
    80005492:	bfc9                	j	80005464 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005494:	854a                	mv	a0,s2
    80005496:	ffffd097          	auipc	ra,0xffffd
    8000549a:	a70080e7          	jalr	-1424(ra) # 80001f06 <proc_pagetable>
    8000549e:	8baa                	mv	s7,a0
    800054a0:	d945                	beqz	a0,80005450 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054a2:	e6842983          	lw	s3,-408(s0)
    800054a6:	e8045783          	lhu	a5,-384(s0)
    800054aa:	c7ad                	beqz	a5,80005514 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800054ac:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054ae:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    800054b0:	6c85                	lui	s9,0x1
    800054b2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800054b6:	def43823          	sd	a5,-528(s0)
    800054ba:	a4bd                	j	80005728 <exec+0x35c>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800054bc:	00003517          	auipc	a0,0x3
    800054c0:	4e450513          	addi	a0,a0,1252 # 800089a0 <sysnames+0x2a8>
    800054c4:	ffffb097          	auipc	ra,0xffffb
    800054c8:	10c080e7          	jalr	268(ra) # 800005d0 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800054cc:	8756                	mv	a4,s5
    800054ce:	012d86bb          	addw	a3,s11,s2
    800054d2:	4581                	li	a1,0
    800054d4:	8526                	mv	a0,s1
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	c6c080e7          	jalr	-916(ra) # 80004142 <readi>
    800054de:	2501                	sext.w	a0,a0
    800054e0:	1eaa9b63          	bne	s5,a0,800056d6 <exec+0x30a>
  for(i = 0; i < sz; i += PGSIZE){
    800054e4:	6785                	lui	a5,0x1
    800054e6:	0127893b          	addw	s2,a5,s2
    800054ea:	77fd                	lui	a5,0xfffff
    800054ec:	01478a3b          	addw	s4,a5,s4
    800054f0:	23897363          	bgeu	s2,s8,80005716 <exec+0x34a>
    pa = walkaddr(pagetable, va + i);
    800054f4:	02091593          	slli	a1,s2,0x20
    800054f8:	9181                	srli	a1,a1,0x20
    800054fa:	95ea                	add	a1,a1,s10
    800054fc:	855e                	mv	a0,s7
    800054fe:	ffffc097          	auipc	ra,0xffffc
    80005502:	c64080e7          	jalr	-924(ra) # 80001162 <walkaddr>
    80005506:	862a                	mv	a2,a0
    if(pa == 0)
    80005508:	d955                	beqz	a0,800054bc <exec+0xf0>
      n = PGSIZE;
    8000550a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000550c:	fd9a70e3          	bgeu	s4,s9,800054cc <exec+0x100>
      n = sz - i;
    80005510:	8ad2                	mv	s5,s4
    80005512:	bf6d                	j	800054cc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005514:	4901                	li	s2,0
  iunlockput(ip);
    80005516:	8526                	mv	a0,s1
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	bd8080e7          	jalr	-1064(ra) # 800040f0 <iunlockput>
  end_op();
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	3aa080e7          	jalr	938(ra) # 800048ca <end_op>
  p = myproc();
    80005528:	ffffd097          	auipc	ra,0xffffd
    8000552c:	91a080e7          	jalr	-1766(ra) # 80001e42 <myproc>
    80005530:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005532:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005536:	6785                	lui	a5,0x1
    80005538:	17fd                	addi	a5,a5,-1
    8000553a:	993e                	add	s2,s2,a5
    8000553c:	757d                	lui	a0,0xfffff
    8000553e:	00a977b3          	and	a5,s2,a0
    80005542:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005546:	6609                	lui	a2,0x2
    80005548:	963e                	add	a2,a2,a5
    8000554a:	85be                	mv	a1,a5
    8000554c:	855e                	mv	a0,s7
    8000554e:	ffffc097          	auipc	ra,0xffffc
    80005552:	070080e7          	jalr	112(ra) # 800015be <uvmalloc>
    80005556:	8b2a                	mv	s6,a0
  ip = 0;
    80005558:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000555a:	16050e63          	beqz	a0,800056d6 <exec+0x30a>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000555e:	75f9                	lui	a1,0xffffe
    80005560:	95aa                	add	a1,a1,a0
    80005562:	855e                	mv	a0,s7
    80005564:	ffffc097          	auipc	ra,0xffffc
    80005568:	37e080e7          	jalr	894(ra) # 800018e2 <uvmclear>
  stackbase = sp - PGSIZE;
    8000556c:	7c7d                	lui	s8,0xfffff
    8000556e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005570:	e0043783          	ld	a5,-512(s0)
    80005574:	6388                	ld	a0,0(a5)
    80005576:	c535                	beqz	a0,800055e2 <exec+0x216>
    80005578:	e8840993          	addi	s3,s0,-376
    8000557c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005580:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005582:	ffffc097          	auipc	ra,0xffffc
    80005586:	9ba080e7          	jalr	-1606(ra) # 80000f3c <strlen>
    8000558a:	2505                	addiw	a0,a0,1
    8000558c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005590:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005594:	17896563          	bltu	s2,s8,800056fe <exec+0x332>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005598:	e0043d83          	ld	s11,-512(s0)
    8000559c:	000dba03          	ld	s4,0(s11)
    800055a0:	8552                	mv	a0,s4
    800055a2:	ffffc097          	auipc	ra,0xffffc
    800055a6:	99a080e7          	jalr	-1638(ra) # 80000f3c <strlen>
    800055aa:	0015069b          	addiw	a3,a0,1
    800055ae:	8652                	mv	a2,s4
    800055b0:	85ca                	mv	a1,s2
    800055b2:	855e                	mv	a0,s7
    800055b4:	ffffc097          	auipc	ra,0xffffc
    800055b8:	360080e7          	jalr	864(ra) # 80001914 <copyout>
    800055bc:	14054563          	bltz	a0,80005706 <exec+0x33a>
    ustack[argc] = sp;
    800055c0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055c4:	0485                	addi	s1,s1,1
    800055c6:	008d8793          	addi	a5,s11,8
    800055ca:	e0f43023          	sd	a5,-512(s0)
    800055ce:	008db503          	ld	a0,8(s11)
    800055d2:	c911                	beqz	a0,800055e6 <exec+0x21a>
    if(argc >= MAXARG)
    800055d4:	09a1                	addi	s3,s3,8
    800055d6:	fb3c96e3          	bne	s9,s3,80005582 <exec+0x1b6>
  sz = sz1;
    800055da:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055de:	4481                	li	s1,0
    800055e0:	a8dd                	j	800056d6 <exec+0x30a>
  sp = sz;
    800055e2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800055e4:	4481                	li	s1,0
  ustack[argc] = 0;
    800055e6:	00349793          	slli	a5,s1,0x3
    800055ea:	f9040713          	addi	a4,s0,-112
    800055ee:	97ba                	add	a5,a5,a4
    800055f0:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    800055f4:	00148693          	addi	a3,s1,1
    800055f8:	068e                	slli	a3,a3,0x3
    800055fa:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800055fe:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005602:	01897663          	bgeu	s2,s8,8000560e <exec+0x242>
  sz = sz1;
    80005606:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000560a:	4481                	li	s1,0
    8000560c:	a0e9                	j	800056d6 <exec+0x30a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000560e:	e8840613          	addi	a2,s0,-376
    80005612:	85ca                	mv	a1,s2
    80005614:	855e                	mv	a0,s7
    80005616:	ffffc097          	auipc	ra,0xffffc
    8000561a:	2fe080e7          	jalr	766(ra) # 80001914 <copyout>
    8000561e:	0e054863          	bltz	a0,8000570e <exec+0x342>
  p->trapframe->a1 = sp;
    80005622:	058ab783          	ld	a5,88(s5)
    80005626:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000562a:	df843783          	ld	a5,-520(s0)
    8000562e:	0007c703          	lbu	a4,0(a5)
    80005632:	cf11                	beqz	a4,8000564e <exec+0x282>
    80005634:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005636:	02f00693          	li	a3,47
    8000563a:	a029                	j	80005644 <exec+0x278>
  for(last=s=path; *s; s++)
    8000563c:	0785                	addi	a5,a5,1
    8000563e:	fff7c703          	lbu	a4,-1(a5)
    80005642:	c711                	beqz	a4,8000564e <exec+0x282>
    if(*s == '/')
    80005644:	fed71ce3          	bne	a4,a3,8000563c <exec+0x270>
      last = s+1;
    80005648:	def43c23          	sd	a5,-520(s0)
    8000564c:	bfc5                	j	8000563c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000564e:	4641                	li	a2,16
    80005650:	df843583          	ld	a1,-520(s0)
    80005654:	160a8513          	addi	a0,s5,352
    80005658:	ffffc097          	auipc	ra,0xffffc
    8000565c:	8b2080e7          	jalr	-1870(ra) # 80000f0a <safestrcpy>
  oldpagetable = p->pagetable;
    80005660:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005664:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005668:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000566c:	058ab783          	ld	a5,88(s5)
    80005670:	e6043703          	ld	a4,-416(s0)
    80005674:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005676:	058ab783          	ld	a5,88(s5)
    8000567a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000567e:	85ea                	mv	a1,s10
    80005680:	ffffd097          	auipc	ra,0xffffd
    80005684:	922080e7          	jalr	-1758(ra) # 80001fa2 <proc_freepagetable>
  if (pagecopy(p->pagetable, p->kpagetable, 0, p->sz) != 0) {
    80005688:	048ab683          	ld	a3,72(s5)
    8000568c:	4601                	li	a2,0
    8000568e:	178ab583          	ld	a1,376(s5)
    80005692:	050ab503          	ld	a0,80(s5)
    80005696:	ffffc097          	auipc	ra,0xffffc
    8000569a:	0d2080e7          	jalr	210(ra) # 80001768 <pagecopy>
    8000569e:	c509                	beqz	a0,800056a8 <exec+0x2dc>
  sz = sz1;
    800056a0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056a4:	4481                	li	s1,0
    800056a6:	a805                	j	800056d6 <exec+0x30a>
  ukvminithard(p->kpagetable);
    800056a8:	178ab503          	ld	a0,376(s5)
    800056ac:	ffffc097          	auipc	ra,0xffffc
    800056b0:	9d0080e7          	jalr	-1584(ra) # 8000107c <ukvminithard>
  if (p->pid == 1)
    800056b4:	038aa703          	lw	a4,56(s5)
    800056b8:	4785                	li	a5,1
    800056ba:	00f70563          	beq	a4,a5,800056c4 <exec+0x2f8>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800056be:	0004851b          	sext.w	a0,s1
    800056c2:	b34d                	j	80005464 <exec+0x98>
    vmprint(p->pagetable);
    800056c4:	050ab503          	ld	a0,80(s5)
    800056c8:	ffffc097          	auipc	ra,0xffffc
    800056cc:	3b4080e7          	jalr	948(ra) # 80001a7c <vmprint>
    800056d0:	b7fd                	j	800056be <exec+0x2f2>
    800056d2:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800056d6:	e0843583          	ld	a1,-504(s0)
    800056da:	855e                	mv	a0,s7
    800056dc:	ffffd097          	auipc	ra,0xffffd
    800056e0:	8c6080e7          	jalr	-1850(ra) # 80001fa2 <proc_freepagetable>
  if(ip){
    800056e4:	d60496e3          	bnez	s1,80005450 <exec+0x84>
  return -1;
    800056e8:	557d                	li	a0,-1
    800056ea:	bbad                	j	80005464 <exec+0x98>
    800056ec:	e1243423          	sd	s2,-504(s0)
    800056f0:	b7dd                	j	800056d6 <exec+0x30a>
    800056f2:	e1243423          	sd	s2,-504(s0)
    800056f6:	b7c5                	j	800056d6 <exec+0x30a>
    800056f8:	e1243423          	sd	s2,-504(s0)
    800056fc:	bfe9                	j	800056d6 <exec+0x30a>
  sz = sz1;
    800056fe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005702:	4481                	li	s1,0
    80005704:	bfc9                	j	800056d6 <exec+0x30a>
  sz = sz1;
    80005706:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000570a:	4481                	li	s1,0
    8000570c:	b7e9                	j	800056d6 <exec+0x30a>
  sz = sz1;
    8000570e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005712:	4481                	li	s1,0
    80005714:	b7c9                	j	800056d6 <exec+0x30a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005716:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000571a:	2b05                	addiw	s6,s6,1
    8000571c:	0389899b          	addiw	s3,s3,56
    80005720:	e8045783          	lhu	a5,-384(s0)
    80005724:	defb59e3          	bge	s6,a5,80005516 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005728:	2981                	sext.w	s3,s3
    8000572a:	03800713          	li	a4,56
    8000572e:	86ce                	mv	a3,s3
    80005730:	e1040613          	addi	a2,s0,-496
    80005734:	4581                	li	a1,0
    80005736:	8526                	mv	a0,s1
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	a0a080e7          	jalr	-1526(ra) # 80004142 <readi>
    80005740:	03800793          	li	a5,56
    80005744:	f8f517e3          	bne	a0,a5,800056d2 <exec+0x306>
    if(ph.type != ELF_PROG_LOAD)
    80005748:	e1042783          	lw	a5,-496(s0)
    8000574c:	4705                	li	a4,1
    8000574e:	fce796e3          	bne	a5,a4,8000571a <exec+0x34e>
    if(ph.memsz < ph.filesz)
    80005752:	e3843603          	ld	a2,-456(s0)
    80005756:	e3043783          	ld	a5,-464(s0)
    8000575a:	f8f669e3          	bltu	a2,a5,800056ec <exec+0x320>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000575e:	e2043783          	ld	a5,-480(s0)
    80005762:	963e                	add	a2,a2,a5
    80005764:	f8f667e3          	bltu	a2,a5,800056f2 <exec+0x326>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005768:	85ca                	mv	a1,s2
    8000576a:	855e                	mv	a0,s7
    8000576c:	ffffc097          	auipc	ra,0xffffc
    80005770:	e52080e7          	jalr	-430(ra) # 800015be <uvmalloc>
    80005774:	e0a43423          	sd	a0,-504(s0)
    80005778:	d141                	beqz	a0,800056f8 <exec+0x32c>
    if(ph.vaddr % PGSIZE != 0)
    8000577a:	e2043d03          	ld	s10,-480(s0)
    8000577e:	df043783          	ld	a5,-528(s0)
    80005782:	00fd77b3          	and	a5,s10,a5
    80005786:	fba1                	bnez	a5,800056d6 <exec+0x30a>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005788:	e1842d83          	lw	s11,-488(s0)
    8000578c:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005790:	f80c03e3          	beqz	s8,80005716 <exec+0x34a>
    80005794:	8a62                	mv	s4,s8
    80005796:	4901                	li	s2,0
    80005798:	bbb1                	j	800054f4 <exec+0x128>

000000008000579a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000579a:	7179                	addi	sp,sp,-48
    8000579c:	f406                	sd	ra,40(sp)
    8000579e:	f022                	sd	s0,32(sp)
    800057a0:	ec26                	sd	s1,24(sp)
    800057a2:	e84a                	sd	s2,16(sp)
    800057a4:	1800                	addi	s0,sp,48
    800057a6:	892e                	mv	s2,a1
    800057a8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800057aa:	fdc40593          	addi	a1,s0,-36
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	9d0080e7          	jalr	-1584(ra) # 8000317e <argint>
    800057b6:	04054063          	bltz	a0,800057f6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800057ba:	fdc42703          	lw	a4,-36(s0)
    800057be:	47bd                	li	a5,15
    800057c0:	02e7ed63          	bltu	a5,a4,800057fa <argfd+0x60>
    800057c4:	ffffc097          	auipc	ra,0xffffc
    800057c8:	67e080e7          	jalr	1662(ra) # 80001e42 <myproc>
    800057cc:	fdc42703          	lw	a4,-36(s0)
    800057d0:	01a70793          	addi	a5,a4,26
    800057d4:	078e                	slli	a5,a5,0x3
    800057d6:	953e                	add	a0,a0,a5
    800057d8:	651c                	ld	a5,8(a0)
    800057da:	c395                	beqz	a5,800057fe <argfd+0x64>
    return -1;
  if(pfd)
    800057dc:	00090463          	beqz	s2,800057e4 <argfd+0x4a>
    *pfd = fd;
    800057e0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800057e4:	4501                	li	a0,0
  if(pf)
    800057e6:	c091                	beqz	s1,800057ea <argfd+0x50>
    *pf = f;
    800057e8:	e09c                	sd	a5,0(s1)
}
    800057ea:	70a2                	ld	ra,40(sp)
    800057ec:	7402                	ld	s0,32(sp)
    800057ee:	64e2                	ld	s1,24(sp)
    800057f0:	6942                	ld	s2,16(sp)
    800057f2:	6145                	addi	sp,sp,48
    800057f4:	8082                	ret
    return -1;
    800057f6:	557d                	li	a0,-1
    800057f8:	bfcd                	j	800057ea <argfd+0x50>
    return -1;
    800057fa:	557d                	li	a0,-1
    800057fc:	b7fd                	j	800057ea <argfd+0x50>
    800057fe:	557d                	li	a0,-1
    80005800:	b7ed                	j	800057ea <argfd+0x50>

0000000080005802 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005802:	1101                	addi	sp,sp,-32
    80005804:	ec06                	sd	ra,24(sp)
    80005806:	e822                	sd	s0,16(sp)
    80005808:	e426                	sd	s1,8(sp)
    8000580a:	1000                	addi	s0,sp,32
    8000580c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000580e:	ffffc097          	auipc	ra,0xffffc
    80005812:	634080e7          	jalr	1588(ra) # 80001e42 <myproc>
    80005816:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005818:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd70b8>
    8000581c:	4501                	li	a0,0
    8000581e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005820:	6398                	ld	a4,0(a5)
    80005822:	cb19                	beqz	a4,80005838 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005824:	2505                	addiw	a0,a0,1
    80005826:	07a1                	addi	a5,a5,8
    80005828:	fed51ce3          	bne	a0,a3,80005820 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000582c:	557d                	li	a0,-1
}
    8000582e:	60e2                	ld	ra,24(sp)
    80005830:	6442                	ld	s0,16(sp)
    80005832:	64a2                	ld	s1,8(sp)
    80005834:	6105                	addi	sp,sp,32
    80005836:	8082                	ret
      p->ofile[fd] = f;
    80005838:	01a50793          	addi	a5,a0,26
    8000583c:	078e                	slli	a5,a5,0x3
    8000583e:	963e                	add	a2,a2,a5
    80005840:	e604                	sd	s1,8(a2)
      return fd;
    80005842:	b7f5                	j	8000582e <fdalloc+0x2c>

0000000080005844 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005844:	715d                	addi	sp,sp,-80
    80005846:	e486                	sd	ra,72(sp)
    80005848:	e0a2                	sd	s0,64(sp)
    8000584a:	fc26                	sd	s1,56(sp)
    8000584c:	f84a                	sd	s2,48(sp)
    8000584e:	f44e                	sd	s3,40(sp)
    80005850:	f052                	sd	s4,32(sp)
    80005852:	ec56                	sd	s5,24(sp)
    80005854:	0880                	addi	s0,sp,80
    80005856:	89ae                	mv	s3,a1
    80005858:	8ab2                	mv	s5,a2
    8000585a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000585c:	fb040593          	addi	a1,s0,-80
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	dfc080e7          	jalr	-516(ra) # 8000465c <nameiparent>
    80005868:	892a                	mv	s2,a0
    8000586a:	12050f63          	beqz	a0,800059a8 <create+0x164>
    return 0;

  ilock(dp);
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	620080e7          	jalr	1568(ra) # 80003e8e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005876:	4601                	li	a2,0
    80005878:	fb040593          	addi	a1,s0,-80
    8000587c:	854a                	mv	a0,s2
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	aee080e7          	jalr	-1298(ra) # 8000436c <dirlookup>
    80005886:	84aa                	mv	s1,a0
    80005888:	c921                	beqz	a0,800058d8 <create+0x94>
    iunlockput(dp);
    8000588a:	854a                	mv	a0,s2
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	864080e7          	jalr	-1948(ra) # 800040f0 <iunlockput>
    ilock(ip);
    80005894:	8526                	mv	a0,s1
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	5f8080e7          	jalr	1528(ra) # 80003e8e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000589e:	2981                	sext.w	s3,s3
    800058a0:	4789                	li	a5,2
    800058a2:	02f99463          	bne	s3,a5,800058ca <create+0x86>
    800058a6:	0444d783          	lhu	a5,68(s1)
    800058aa:	37f9                	addiw	a5,a5,-2
    800058ac:	17c2                	slli	a5,a5,0x30
    800058ae:	93c1                	srli	a5,a5,0x30
    800058b0:	4705                	li	a4,1
    800058b2:	00f76c63          	bltu	a4,a5,800058ca <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800058b6:	8526                	mv	a0,s1
    800058b8:	60a6                	ld	ra,72(sp)
    800058ba:	6406                	ld	s0,64(sp)
    800058bc:	74e2                	ld	s1,56(sp)
    800058be:	7942                	ld	s2,48(sp)
    800058c0:	79a2                	ld	s3,40(sp)
    800058c2:	7a02                	ld	s4,32(sp)
    800058c4:	6ae2                	ld	s5,24(sp)
    800058c6:	6161                	addi	sp,sp,80
    800058c8:	8082                	ret
    iunlockput(ip);
    800058ca:	8526                	mv	a0,s1
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	824080e7          	jalr	-2012(ra) # 800040f0 <iunlockput>
    return 0;
    800058d4:	4481                	li	s1,0
    800058d6:	b7c5                	j	800058b6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800058d8:	85ce                	mv	a1,s3
    800058da:	00092503          	lw	a0,0(s2)
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	418080e7          	jalr	1048(ra) # 80003cf6 <ialloc>
    800058e6:	84aa                	mv	s1,a0
    800058e8:	c529                	beqz	a0,80005932 <create+0xee>
  ilock(ip);
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	5a4080e7          	jalr	1444(ra) # 80003e8e <ilock>
  ip->major = major;
    800058f2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800058f6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800058fa:	4785                	li	a5,1
    800058fc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005900:	8526                	mv	a0,s1
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	4c2080e7          	jalr	1218(ra) # 80003dc4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000590a:	2981                	sext.w	s3,s3
    8000590c:	4785                	li	a5,1
    8000590e:	02f98a63          	beq	s3,a5,80005942 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005912:	40d0                	lw	a2,4(s1)
    80005914:	fb040593          	addi	a1,s0,-80
    80005918:	854a                	mv	a0,s2
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	c62080e7          	jalr	-926(ra) # 8000457c <dirlink>
    80005922:	06054b63          	bltz	a0,80005998 <create+0x154>
  iunlockput(dp);
    80005926:	854a                	mv	a0,s2
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	7c8080e7          	jalr	1992(ra) # 800040f0 <iunlockput>
  return ip;
    80005930:	b759                	j	800058b6 <create+0x72>
    panic("create: ialloc");
    80005932:	00003517          	auipc	a0,0x3
    80005936:	08e50513          	addi	a0,a0,142 # 800089c0 <sysnames+0x2c8>
    8000593a:	ffffb097          	auipc	ra,0xffffb
    8000593e:	c96080e7          	jalr	-874(ra) # 800005d0 <panic>
    dp->nlink++;  // for ".."
    80005942:	04a95783          	lhu	a5,74(s2)
    80005946:	2785                	addiw	a5,a5,1
    80005948:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000594c:	854a                	mv	a0,s2
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	476080e7          	jalr	1142(ra) # 80003dc4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005956:	40d0                	lw	a2,4(s1)
    80005958:	00003597          	auipc	a1,0x3
    8000595c:	07858593          	addi	a1,a1,120 # 800089d0 <sysnames+0x2d8>
    80005960:	8526                	mv	a0,s1
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	c1a080e7          	jalr	-998(ra) # 8000457c <dirlink>
    8000596a:	00054f63          	bltz	a0,80005988 <create+0x144>
    8000596e:	00492603          	lw	a2,4(s2)
    80005972:	00003597          	auipc	a1,0x3
    80005976:	92e58593          	addi	a1,a1,-1746 # 800082a0 <digits+0x250>
    8000597a:	8526                	mv	a0,s1
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	c00080e7          	jalr	-1024(ra) # 8000457c <dirlink>
    80005984:	f80557e3          	bgez	a0,80005912 <create+0xce>
      panic("create dots");
    80005988:	00003517          	auipc	a0,0x3
    8000598c:	05050513          	addi	a0,a0,80 # 800089d8 <sysnames+0x2e0>
    80005990:	ffffb097          	auipc	ra,0xffffb
    80005994:	c40080e7          	jalr	-960(ra) # 800005d0 <panic>
    panic("create: dirlink");
    80005998:	00003517          	auipc	a0,0x3
    8000599c:	05050513          	addi	a0,a0,80 # 800089e8 <sysnames+0x2f0>
    800059a0:	ffffb097          	auipc	ra,0xffffb
    800059a4:	c30080e7          	jalr	-976(ra) # 800005d0 <panic>
    return 0;
    800059a8:	84aa                	mv	s1,a0
    800059aa:	b731                	j	800058b6 <create+0x72>

00000000800059ac <sys_dup>:
{
    800059ac:	7179                	addi	sp,sp,-48
    800059ae:	f406                	sd	ra,40(sp)
    800059b0:	f022                	sd	s0,32(sp)
    800059b2:	ec26                	sd	s1,24(sp)
    800059b4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800059b6:	fd840613          	addi	a2,s0,-40
    800059ba:	4581                	li	a1,0
    800059bc:	4501                	li	a0,0
    800059be:	00000097          	auipc	ra,0x0
    800059c2:	ddc080e7          	jalr	-548(ra) # 8000579a <argfd>
    return -1;
    800059c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800059c8:	02054363          	bltz	a0,800059ee <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800059cc:	fd843503          	ld	a0,-40(s0)
    800059d0:	00000097          	auipc	ra,0x0
    800059d4:	e32080e7          	jalr	-462(ra) # 80005802 <fdalloc>
    800059d8:	84aa                	mv	s1,a0
    return -1;
    800059da:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800059dc:	00054963          	bltz	a0,800059ee <sys_dup+0x42>
  filedup(f);
    800059e0:	fd843503          	ld	a0,-40(s0)
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	2e6080e7          	jalr	742(ra) # 80004cca <filedup>
  return fd;
    800059ec:	87a6                	mv	a5,s1
}
    800059ee:	853e                	mv	a0,a5
    800059f0:	70a2                	ld	ra,40(sp)
    800059f2:	7402                	ld	s0,32(sp)
    800059f4:	64e2                	ld	s1,24(sp)
    800059f6:	6145                	addi	sp,sp,48
    800059f8:	8082                	ret

00000000800059fa <sys_read>:
{
    800059fa:	7179                	addi	sp,sp,-48
    800059fc:	f406                	sd	ra,40(sp)
    800059fe:	f022                	sd	s0,32(sp)
    80005a00:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a02:	fe840613          	addi	a2,s0,-24
    80005a06:	4581                	li	a1,0
    80005a08:	4501                	li	a0,0
    80005a0a:	00000097          	auipc	ra,0x0
    80005a0e:	d90080e7          	jalr	-624(ra) # 8000579a <argfd>
    return -1;
    80005a12:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a14:	04054163          	bltz	a0,80005a56 <sys_read+0x5c>
    80005a18:	fe440593          	addi	a1,s0,-28
    80005a1c:	4509                	li	a0,2
    80005a1e:	ffffd097          	auipc	ra,0xffffd
    80005a22:	760080e7          	jalr	1888(ra) # 8000317e <argint>
    return -1;
    80005a26:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a28:	02054763          	bltz	a0,80005a56 <sys_read+0x5c>
    80005a2c:	fd840593          	addi	a1,s0,-40
    80005a30:	4505                	li	a0,1
    80005a32:	ffffd097          	auipc	ra,0xffffd
    80005a36:	76e080e7          	jalr	1902(ra) # 800031a0 <argaddr>
    return -1;
    80005a3a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a3c:	00054d63          	bltz	a0,80005a56 <sys_read+0x5c>
  return fileread(f, p, n);
    80005a40:	fe442603          	lw	a2,-28(s0)
    80005a44:	fd843583          	ld	a1,-40(s0)
    80005a48:	fe843503          	ld	a0,-24(s0)
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	40a080e7          	jalr	1034(ra) # 80004e56 <fileread>
    80005a54:	87aa                	mv	a5,a0
}
    80005a56:	853e                	mv	a0,a5
    80005a58:	70a2                	ld	ra,40(sp)
    80005a5a:	7402                	ld	s0,32(sp)
    80005a5c:	6145                	addi	sp,sp,48
    80005a5e:	8082                	ret

0000000080005a60 <sys_write>:
{
    80005a60:	7179                	addi	sp,sp,-48
    80005a62:	f406                	sd	ra,40(sp)
    80005a64:	f022                	sd	s0,32(sp)
    80005a66:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a68:	fe840613          	addi	a2,s0,-24
    80005a6c:	4581                	li	a1,0
    80005a6e:	4501                	li	a0,0
    80005a70:	00000097          	auipc	ra,0x0
    80005a74:	d2a080e7          	jalr	-726(ra) # 8000579a <argfd>
    return -1;
    80005a78:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a7a:	04054163          	bltz	a0,80005abc <sys_write+0x5c>
    80005a7e:	fe440593          	addi	a1,s0,-28
    80005a82:	4509                	li	a0,2
    80005a84:	ffffd097          	auipc	ra,0xffffd
    80005a88:	6fa080e7          	jalr	1786(ra) # 8000317e <argint>
    return -1;
    80005a8c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a8e:	02054763          	bltz	a0,80005abc <sys_write+0x5c>
    80005a92:	fd840593          	addi	a1,s0,-40
    80005a96:	4505                	li	a0,1
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	708080e7          	jalr	1800(ra) # 800031a0 <argaddr>
    return -1;
    80005aa0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005aa2:	00054d63          	bltz	a0,80005abc <sys_write+0x5c>
  return filewrite(f, p, n);
    80005aa6:	fe442603          	lw	a2,-28(s0)
    80005aaa:	fd843583          	ld	a1,-40(s0)
    80005aae:	fe843503          	ld	a0,-24(s0)
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	466080e7          	jalr	1126(ra) # 80004f18 <filewrite>
    80005aba:	87aa                	mv	a5,a0
}
    80005abc:	853e                	mv	a0,a5
    80005abe:	70a2                	ld	ra,40(sp)
    80005ac0:	7402                	ld	s0,32(sp)
    80005ac2:	6145                	addi	sp,sp,48
    80005ac4:	8082                	ret

0000000080005ac6 <sys_close>:
{
    80005ac6:	1101                	addi	sp,sp,-32
    80005ac8:	ec06                	sd	ra,24(sp)
    80005aca:	e822                	sd	s0,16(sp)
    80005acc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005ace:	fe040613          	addi	a2,s0,-32
    80005ad2:	fec40593          	addi	a1,s0,-20
    80005ad6:	4501                	li	a0,0
    80005ad8:	00000097          	auipc	ra,0x0
    80005adc:	cc2080e7          	jalr	-830(ra) # 8000579a <argfd>
    return -1;
    80005ae0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ae2:	02054463          	bltz	a0,80005b0a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005ae6:	ffffc097          	auipc	ra,0xffffc
    80005aea:	35c080e7          	jalr	860(ra) # 80001e42 <myproc>
    80005aee:	fec42783          	lw	a5,-20(s0)
    80005af2:	07e9                	addi	a5,a5,26
    80005af4:	078e                	slli	a5,a5,0x3
    80005af6:	97aa                	add	a5,a5,a0
    80005af8:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005afc:	fe043503          	ld	a0,-32(s0)
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	21c080e7          	jalr	540(ra) # 80004d1c <fileclose>
  return 0;
    80005b08:	4781                	li	a5,0
}
    80005b0a:	853e                	mv	a0,a5
    80005b0c:	60e2                	ld	ra,24(sp)
    80005b0e:	6442                	ld	s0,16(sp)
    80005b10:	6105                	addi	sp,sp,32
    80005b12:	8082                	ret

0000000080005b14 <sys_fstat>:
{
    80005b14:	1101                	addi	sp,sp,-32
    80005b16:	ec06                	sd	ra,24(sp)
    80005b18:	e822                	sd	s0,16(sp)
    80005b1a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b1c:	fe840613          	addi	a2,s0,-24
    80005b20:	4581                	li	a1,0
    80005b22:	4501                	li	a0,0
    80005b24:	00000097          	auipc	ra,0x0
    80005b28:	c76080e7          	jalr	-906(ra) # 8000579a <argfd>
    return -1;
    80005b2c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b2e:	02054563          	bltz	a0,80005b58 <sys_fstat+0x44>
    80005b32:	fe040593          	addi	a1,s0,-32
    80005b36:	4505                	li	a0,1
    80005b38:	ffffd097          	auipc	ra,0xffffd
    80005b3c:	668080e7          	jalr	1640(ra) # 800031a0 <argaddr>
    return -1;
    80005b40:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b42:	00054b63          	bltz	a0,80005b58 <sys_fstat+0x44>
  return filestat(f, st);
    80005b46:	fe043583          	ld	a1,-32(s0)
    80005b4a:	fe843503          	ld	a0,-24(s0)
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	296080e7          	jalr	662(ra) # 80004de4 <filestat>
    80005b56:	87aa                	mv	a5,a0
}
    80005b58:	853e                	mv	a0,a5
    80005b5a:	60e2                	ld	ra,24(sp)
    80005b5c:	6442                	ld	s0,16(sp)
    80005b5e:	6105                	addi	sp,sp,32
    80005b60:	8082                	ret

0000000080005b62 <sys_link>:
{
    80005b62:	7169                	addi	sp,sp,-304
    80005b64:	f606                	sd	ra,296(sp)
    80005b66:	f222                	sd	s0,288(sp)
    80005b68:	ee26                	sd	s1,280(sp)
    80005b6a:	ea4a                	sd	s2,272(sp)
    80005b6c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b6e:	08000613          	li	a2,128
    80005b72:	ed040593          	addi	a1,s0,-304
    80005b76:	4501                	li	a0,0
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	64a080e7          	jalr	1610(ra) # 800031c2 <argstr>
    return -1;
    80005b80:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b82:	10054e63          	bltz	a0,80005c9e <sys_link+0x13c>
    80005b86:	08000613          	li	a2,128
    80005b8a:	f5040593          	addi	a1,s0,-176
    80005b8e:	4505                	li	a0,1
    80005b90:	ffffd097          	auipc	ra,0xffffd
    80005b94:	632080e7          	jalr	1586(ra) # 800031c2 <argstr>
    return -1;
    80005b98:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b9a:	10054263          	bltz	a0,80005c9e <sys_link+0x13c>
  begin_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	cac080e7          	jalr	-852(ra) # 8000484a <begin_op>
  if((ip = namei(old)) == 0){
    80005ba6:	ed040513          	addi	a0,s0,-304
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	a94080e7          	jalr	-1388(ra) # 8000463e <namei>
    80005bb2:	84aa                	mv	s1,a0
    80005bb4:	c551                	beqz	a0,80005c40 <sys_link+0xde>
  ilock(ip);
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	2d8080e7          	jalr	728(ra) # 80003e8e <ilock>
  if(ip->type == T_DIR){
    80005bbe:	04449703          	lh	a4,68(s1)
    80005bc2:	4785                	li	a5,1
    80005bc4:	08f70463          	beq	a4,a5,80005c4c <sys_link+0xea>
  ip->nlink++;
    80005bc8:	04a4d783          	lhu	a5,74(s1)
    80005bcc:	2785                	addiw	a5,a5,1
    80005bce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bd2:	8526                	mv	a0,s1
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	1f0080e7          	jalr	496(ra) # 80003dc4 <iupdate>
  iunlock(ip);
    80005bdc:	8526                	mv	a0,s1
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	372080e7          	jalr	882(ra) # 80003f50 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005be6:	fd040593          	addi	a1,s0,-48
    80005bea:	f5040513          	addi	a0,s0,-176
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	a6e080e7          	jalr	-1426(ra) # 8000465c <nameiparent>
    80005bf6:	892a                	mv	s2,a0
    80005bf8:	c935                	beqz	a0,80005c6c <sys_link+0x10a>
  ilock(dp);
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	294080e7          	jalr	660(ra) # 80003e8e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c02:	00092703          	lw	a4,0(s2)
    80005c06:	409c                	lw	a5,0(s1)
    80005c08:	04f71d63          	bne	a4,a5,80005c62 <sys_link+0x100>
    80005c0c:	40d0                	lw	a2,4(s1)
    80005c0e:	fd040593          	addi	a1,s0,-48
    80005c12:	854a                	mv	a0,s2
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	968080e7          	jalr	-1688(ra) # 8000457c <dirlink>
    80005c1c:	04054363          	bltz	a0,80005c62 <sys_link+0x100>
  iunlockput(dp);
    80005c20:	854a                	mv	a0,s2
    80005c22:	ffffe097          	auipc	ra,0xffffe
    80005c26:	4ce080e7          	jalr	1230(ra) # 800040f0 <iunlockput>
  iput(ip);
    80005c2a:	8526                	mv	a0,s1
    80005c2c:	ffffe097          	auipc	ra,0xffffe
    80005c30:	41c080e7          	jalr	1052(ra) # 80004048 <iput>
  end_op();
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	c96080e7          	jalr	-874(ra) # 800048ca <end_op>
  return 0;
    80005c3c:	4781                	li	a5,0
    80005c3e:	a085                	j	80005c9e <sys_link+0x13c>
    end_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	c8a080e7          	jalr	-886(ra) # 800048ca <end_op>
    return -1;
    80005c48:	57fd                	li	a5,-1
    80005c4a:	a891                	j	80005c9e <sys_link+0x13c>
    iunlockput(ip);
    80005c4c:	8526                	mv	a0,s1
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	4a2080e7          	jalr	1186(ra) # 800040f0 <iunlockput>
    end_op();
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	c74080e7          	jalr	-908(ra) # 800048ca <end_op>
    return -1;
    80005c5e:	57fd                	li	a5,-1
    80005c60:	a83d                	j	80005c9e <sys_link+0x13c>
    iunlockput(dp);
    80005c62:	854a                	mv	a0,s2
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	48c080e7          	jalr	1164(ra) # 800040f0 <iunlockput>
  ilock(ip);
    80005c6c:	8526                	mv	a0,s1
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	220080e7          	jalr	544(ra) # 80003e8e <ilock>
  ip->nlink--;
    80005c76:	04a4d783          	lhu	a5,74(s1)
    80005c7a:	37fd                	addiw	a5,a5,-1
    80005c7c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c80:	8526                	mv	a0,s1
    80005c82:	ffffe097          	auipc	ra,0xffffe
    80005c86:	142080e7          	jalr	322(ra) # 80003dc4 <iupdate>
  iunlockput(ip);
    80005c8a:	8526                	mv	a0,s1
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	464080e7          	jalr	1124(ra) # 800040f0 <iunlockput>
  end_op();
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	c36080e7          	jalr	-970(ra) # 800048ca <end_op>
  return -1;
    80005c9c:	57fd                	li	a5,-1
}
    80005c9e:	853e                	mv	a0,a5
    80005ca0:	70b2                	ld	ra,296(sp)
    80005ca2:	7412                	ld	s0,288(sp)
    80005ca4:	64f2                	ld	s1,280(sp)
    80005ca6:	6952                	ld	s2,272(sp)
    80005ca8:	6155                	addi	sp,sp,304
    80005caa:	8082                	ret

0000000080005cac <sys_unlink>:
{
    80005cac:	7151                	addi	sp,sp,-240
    80005cae:	f586                	sd	ra,232(sp)
    80005cb0:	f1a2                	sd	s0,224(sp)
    80005cb2:	eda6                	sd	s1,216(sp)
    80005cb4:	e9ca                	sd	s2,208(sp)
    80005cb6:	e5ce                	sd	s3,200(sp)
    80005cb8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005cba:	08000613          	li	a2,128
    80005cbe:	f3040593          	addi	a1,s0,-208
    80005cc2:	4501                	li	a0,0
    80005cc4:	ffffd097          	auipc	ra,0xffffd
    80005cc8:	4fe080e7          	jalr	1278(ra) # 800031c2 <argstr>
    80005ccc:	18054163          	bltz	a0,80005e4e <sys_unlink+0x1a2>
  begin_op();
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	b7a080e7          	jalr	-1158(ra) # 8000484a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005cd8:	fb040593          	addi	a1,s0,-80
    80005cdc:	f3040513          	addi	a0,s0,-208
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	97c080e7          	jalr	-1668(ra) # 8000465c <nameiparent>
    80005ce8:	84aa                	mv	s1,a0
    80005cea:	c979                	beqz	a0,80005dc0 <sys_unlink+0x114>
  ilock(dp);
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	1a2080e7          	jalr	418(ra) # 80003e8e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005cf4:	00003597          	auipc	a1,0x3
    80005cf8:	cdc58593          	addi	a1,a1,-804 # 800089d0 <sysnames+0x2d8>
    80005cfc:	fb040513          	addi	a0,s0,-80
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	652080e7          	jalr	1618(ra) # 80004352 <namecmp>
    80005d08:	14050a63          	beqz	a0,80005e5c <sys_unlink+0x1b0>
    80005d0c:	00002597          	auipc	a1,0x2
    80005d10:	59458593          	addi	a1,a1,1428 # 800082a0 <digits+0x250>
    80005d14:	fb040513          	addi	a0,s0,-80
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	63a080e7          	jalr	1594(ra) # 80004352 <namecmp>
    80005d20:	12050e63          	beqz	a0,80005e5c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d24:	f2c40613          	addi	a2,s0,-212
    80005d28:	fb040593          	addi	a1,s0,-80
    80005d2c:	8526                	mv	a0,s1
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	63e080e7          	jalr	1598(ra) # 8000436c <dirlookup>
    80005d36:	892a                	mv	s2,a0
    80005d38:	12050263          	beqz	a0,80005e5c <sys_unlink+0x1b0>
  ilock(ip);
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	152080e7          	jalr	338(ra) # 80003e8e <ilock>
  if(ip->nlink < 1)
    80005d44:	04a91783          	lh	a5,74(s2)
    80005d48:	08f05263          	blez	a5,80005dcc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d4c:	04491703          	lh	a4,68(s2)
    80005d50:	4785                	li	a5,1
    80005d52:	08f70563          	beq	a4,a5,80005ddc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d56:	4641                	li	a2,16
    80005d58:	4581                	li	a1,0
    80005d5a:	fc040513          	addi	a0,s0,-64
    80005d5e:	ffffb097          	auipc	ra,0xffffb
    80005d62:	056080e7          	jalr	86(ra) # 80000db4 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d66:	4741                	li	a4,16
    80005d68:	f2c42683          	lw	a3,-212(s0)
    80005d6c:	fc040613          	addi	a2,s0,-64
    80005d70:	4581                	li	a1,0
    80005d72:	8526                	mv	a0,s1
    80005d74:	ffffe097          	auipc	ra,0xffffe
    80005d78:	4c4080e7          	jalr	1220(ra) # 80004238 <writei>
    80005d7c:	47c1                	li	a5,16
    80005d7e:	0af51563          	bne	a0,a5,80005e28 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d82:	04491703          	lh	a4,68(s2)
    80005d86:	4785                	li	a5,1
    80005d88:	0af70863          	beq	a4,a5,80005e38 <sys_unlink+0x18c>
  iunlockput(dp);
    80005d8c:	8526                	mv	a0,s1
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	362080e7          	jalr	866(ra) # 800040f0 <iunlockput>
  ip->nlink--;
    80005d96:	04a95783          	lhu	a5,74(s2)
    80005d9a:	37fd                	addiw	a5,a5,-1
    80005d9c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005da0:	854a                	mv	a0,s2
    80005da2:	ffffe097          	auipc	ra,0xffffe
    80005da6:	022080e7          	jalr	34(ra) # 80003dc4 <iupdate>
  iunlockput(ip);
    80005daa:	854a                	mv	a0,s2
    80005dac:	ffffe097          	auipc	ra,0xffffe
    80005db0:	344080e7          	jalr	836(ra) # 800040f0 <iunlockput>
  end_op();
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	b16080e7          	jalr	-1258(ra) # 800048ca <end_op>
  return 0;
    80005dbc:	4501                	li	a0,0
    80005dbe:	a84d                	j	80005e70 <sys_unlink+0x1c4>
    end_op();
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	b0a080e7          	jalr	-1270(ra) # 800048ca <end_op>
    return -1;
    80005dc8:	557d                	li	a0,-1
    80005dca:	a05d                	j	80005e70 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005dcc:	00003517          	auipc	a0,0x3
    80005dd0:	c2c50513          	addi	a0,a0,-980 # 800089f8 <sysnames+0x300>
    80005dd4:	ffffa097          	auipc	ra,0xffffa
    80005dd8:	7fc080e7          	jalr	2044(ra) # 800005d0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ddc:	04c92703          	lw	a4,76(s2)
    80005de0:	02000793          	li	a5,32
    80005de4:	f6e7f9e3          	bgeu	a5,a4,80005d56 <sys_unlink+0xaa>
    80005de8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005dec:	4741                	li	a4,16
    80005dee:	86ce                	mv	a3,s3
    80005df0:	f1840613          	addi	a2,s0,-232
    80005df4:	4581                	li	a1,0
    80005df6:	854a                	mv	a0,s2
    80005df8:	ffffe097          	auipc	ra,0xffffe
    80005dfc:	34a080e7          	jalr	842(ra) # 80004142 <readi>
    80005e00:	47c1                	li	a5,16
    80005e02:	00f51b63          	bne	a0,a5,80005e18 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e06:	f1845783          	lhu	a5,-232(s0)
    80005e0a:	e7a1                	bnez	a5,80005e52 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e0c:	29c1                	addiw	s3,s3,16
    80005e0e:	04c92783          	lw	a5,76(s2)
    80005e12:	fcf9ede3          	bltu	s3,a5,80005dec <sys_unlink+0x140>
    80005e16:	b781                	j	80005d56 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e18:	00003517          	auipc	a0,0x3
    80005e1c:	bf850513          	addi	a0,a0,-1032 # 80008a10 <sysnames+0x318>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	7b0080e7          	jalr	1968(ra) # 800005d0 <panic>
    panic("unlink: writei");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	c0050513          	addi	a0,a0,-1024 # 80008a28 <sysnames+0x330>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	7a0080e7          	jalr	1952(ra) # 800005d0 <panic>
    dp->nlink--;
    80005e38:	04a4d783          	lhu	a5,74(s1)
    80005e3c:	37fd                	addiw	a5,a5,-1
    80005e3e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e42:	8526                	mv	a0,s1
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	f80080e7          	jalr	-128(ra) # 80003dc4 <iupdate>
    80005e4c:	b781                	j	80005d8c <sys_unlink+0xe0>
    return -1;
    80005e4e:	557d                	li	a0,-1
    80005e50:	a005                	j	80005e70 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e52:	854a                	mv	a0,s2
    80005e54:	ffffe097          	auipc	ra,0xffffe
    80005e58:	29c080e7          	jalr	668(ra) # 800040f0 <iunlockput>
  iunlockput(dp);
    80005e5c:	8526                	mv	a0,s1
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	292080e7          	jalr	658(ra) # 800040f0 <iunlockput>
  end_op();
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	a64080e7          	jalr	-1436(ra) # 800048ca <end_op>
  return -1;
    80005e6e:	557d                	li	a0,-1
}
    80005e70:	70ae                	ld	ra,232(sp)
    80005e72:	740e                	ld	s0,224(sp)
    80005e74:	64ee                	ld	s1,216(sp)
    80005e76:	694e                	ld	s2,208(sp)
    80005e78:	69ae                	ld	s3,200(sp)
    80005e7a:	616d                	addi	sp,sp,240
    80005e7c:	8082                	ret

0000000080005e7e <sys_open>:

uint64
sys_open(void)
{
    80005e7e:	7131                	addi	sp,sp,-192
    80005e80:	fd06                	sd	ra,184(sp)
    80005e82:	f922                	sd	s0,176(sp)
    80005e84:	f526                	sd	s1,168(sp)
    80005e86:	f14a                	sd	s2,160(sp)
    80005e88:	ed4e                	sd	s3,152(sp)
    80005e8a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e8c:	08000613          	li	a2,128
    80005e90:	f5040593          	addi	a1,s0,-176
    80005e94:	4501                	li	a0,0
    80005e96:	ffffd097          	auipc	ra,0xffffd
    80005e9a:	32c080e7          	jalr	812(ra) # 800031c2 <argstr>
    return -1;
    80005e9e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ea0:	0c054163          	bltz	a0,80005f62 <sys_open+0xe4>
    80005ea4:	f4c40593          	addi	a1,s0,-180
    80005ea8:	4505                	li	a0,1
    80005eaa:	ffffd097          	auipc	ra,0xffffd
    80005eae:	2d4080e7          	jalr	724(ra) # 8000317e <argint>
    80005eb2:	0a054863          	bltz	a0,80005f62 <sys_open+0xe4>

  begin_op();
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	994080e7          	jalr	-1644(ra) # 8000484a <begin_op>

  if(omode & O_CREATE){
    80005ebe:	f4c42783          	lw	a5,-180(s0)
    80005ec2:	2007f793          	andi	a5,a5,512
    80005ec6:	cbdd                	beqz	a5,80005f7c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ec8:	4681                	li	a3,0
    80005eca:	4601                	li	a2,0
    80005ecc:	4589                	li	a1,2
    80005ece:	f5040513          	addi	a0,s0,-176
    80005ed2:	00000097          	auipc	ra,0x0
    80005ed6:	972080e7          	jalr	-1678(ra) # 80005844 <create>
    80005eda:	892a                	mv	s2,a0
    if(ip == 0){
    80005edc:	c959                	beqz	a0,80005f72 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ede:	04491703          	lh	a4,68(s2)
    80005ee2:	478d                	li	a5,3
    80005ee4:	00f71763          	bne	a4,a5,80005ef2 <sys_open+0x74>
    80005ee8:	04695703          	lhu	a4,70(s2)
    80005eec:	47a5                	li	a5,9
    80005eee:	0ce7ec63          	bltu	a5,a4,80005fc6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	d6e080e7          	jalr	-658(ra) # 80004c60 <filealloc>
    80005efa:	89aa                	mv	s3,a0
    80005efc:	10050263          	beqz	a0,80006000 <sys_open+0x182>
    80005f00:	00000097          	auipc	ra,0x0
    80005f04:	902080e7          	jalr	-1790(ra) # 80005802 <fdalloc>
    80005f08:	84aa                	mv	s1,a0
    80005f0a:	0e054663          	bltz	a0,80005ff6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f0e:	04491703          	lh	a4,68(s2)
    80005f12:	478d                	li	a5,3
    80005f14:	0cf70463          	beq	a4,a5,80005fdc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f18:	4789                	li	a5,2
    80005f1a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f1e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f22:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f26:	f4c42783          	lw	a5,-180(s0)
    80005f2a:	0017c713          	xori	a4,a5,1
    80005f2e:	8b05                	andi	a4,a4,1
    80005f30:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f34:	0037f713          	andi	a4,a5,3
    80005f38:	00e03733          	snez	a4,a4
    80005f3c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f40:	4007f793          	andi	a5,a5,1024
    80005f44:	c791                	beqz	a5,80005f50 <sys_open+0xd2>
    80005f46:	04491703          	lh	a4,68(s2)
    80005f4a:	4789                	li	a5,2
    80005f4c:	08f70f63          	beq	a4,a5,80005fea <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f50:	854a                	mv	a0,s2
    80005f52:	ffffe097          	auipc	ra,0xffffe
    80005f56:	ffe080e7          	jalr	-2(ra) # 80003f50 <iunlock>
  end_op();
    80005f5a:	fffff097          	auipc	ra,0xfffff
    80005f5e:	970080e7          	jalr	-1680(ra) # 800048ca <end_op>

  return fd;
}
    80005f62:	8526                	mv	a0,s1
    80005f64:	70ea                	ld	ra,184(sp)
    80005f66:	744a                	ld	s0,176(sp)
    80005f68:	74aa                	ld	s1,168(sp)
    80005f6a:	790a                	ld	s2,160(sp)
    80005f6c:	69ea                	ld	s3,152(sp)
    80005f6e:	6129                	addi	sp,sp,192
    80005f70:	8082                	ret
      end_op();
    80005f72:	fffff097          	auipc	ra,0xfffff
    80005f76:	958080e7          	jalr	-1704(ra) # 800048ca <end_op>
      return -1;
    80005f7a:	b7e5                	j	80005f62 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f7c:	f5040513          	addi	a0,s0,-176
    80005f80:	ffffe097          	auipc	ra,0xffffe
    80005f84:	6be080e7          	jalr	1726(ra) # 8000463e <namei>
    80005f88:	892a                	mv	s2,a0
    80005f8a:	c905                	beqz	a0,80005fba <sys_open+0x13c>
    ilock(ip);
    80005f8c:	ffffe097          	auipc	ra,0xffffe
    80005f90:	f02080e7          	jalr	-254(ra) # 80003e8e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f94:	04491703          	lh	a4,68(s2)
    80005f98:	4785                	li	a5,1
    80005f9a:	f4f712e3          	bne	a4,a5,80005ede <sys_open+0x60>
    80005f9e:	f4c42783          	lw	a5,-180(s0)
    80005fa2:	dba1                	beqz	a5,80005ef2 <sys_open+0x74>
      iunlockput(ip);
    80005fa4:	854a                	mv	a0,s2
    80005fa6:	ffffe097          	auipc	ra,0xffffe
    80005faa:	14a080e7          	jalr	330(ra) # 800040f0 <iunlockput>
      end_op();
    80005fae:	fffff097          	auipc	ra,0xfffff
    80005fb2:	91c080e7          	jalr	-1764(ra) # 800048ca <end_op>
      return -1;
    80005fb6:	54fd                	li	s1,-1
    80005fb8:	b76d                	j	80005f62 <sys_open+0xe4>
      end_op();
    80005fba:	fffff097          	auipc	ra,0xfffff
    80005fbe:	910080e7          	jalr	-1776(ra) # 800048ca <end_op>
      return -1;
    80005fc2:	54fd                	li	s1,-1
    80005fc4:	bf79                	j	80005f62 <sys_open+0xe4>
    iunlockput(ip);
    80005fc6:	854a                	mv	a0,s2
    80005fc8:	ffffe097          	auipc	ra,0xffffe
    80005fcc:	128080e7          	jalr	296(ra) # 800040f0 <iunlockput>
    end_op();
    80005fd0:	fffff097          	auipc	ra,0xfffff
    80005fd4:	8fa080e7          	jalr	-1798(ra) # 800048ca <end_op>
    return -1;
    80005fd8:	54fd                	li	s1,-1
    80005fda:	b761                	j	80005f62 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005fdc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005fe0:	04691783          	lh	a5,70(s2)
    80005fe4:	02f99223          	sh	a5,36(s3)
    80005fe8:	bf2d                	j	80005f22 <sys_open+0xa4>
    itrunc(ip);
    80005fea:	854a                	mv	a0,s2
    80005fec:	ffffe097          	auipc	ra,0xffffe
    80005ff0:	fb0080e7          	jalr	-80(ra) # 80003f9c <itrunc>
    80005ff4:	bfb1                	j	80005f50 <sys_open+0xd2>
      fileclose(f);
    80005ff6:	854e                	mv	a0,s3
    80005ff8:	fffff097          	auipc	ra,0xfffff
    80005ffc:	d24080e7          	jalr	-732(ra) # 80004d1c <fileclose>
    iunlockput(ip);
    80006000:	854a                	mv	a0,s2
    80006002:	ffffe097          	auipc	ra,0xffffe
    80006006:	0ee080e7          	jalr	238(ra) # 800040f0 <iunlockput>
    end_op();
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	8c0080e7          	jalr	-1856(ra) # 800048ca <end_op>
    return -1;
    80006012:	54fd                	li	s1,-1
    80006014:	b7b9                	j	80005f62 <sys_open+0xe4>

0000000080006016 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006016:	7175                	addi	sp,sp,-144
    80006018:	e506                	sd	ra,136(sp)
    8000601a:	e122                	sd	s0,128(sp)
    8000601c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000601e:	fffff097          	auipc	ra,0xfffff
    80006022:	82c080e7          	jalr	-2004(ra) # 8000484a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006026:	08000613          	li	a2,128
    8000602a:	f7040593          	addi	a1,s0,-144
    8000602e:	4501                	li	a0,0
    80006030:	ffffd097          	auipc	ra,0xffffd
    80006034:	192080e7          	jalr	402(ra) # 800031c2 <argstr>
    80006038:	02054963          	bltz	a0,8000606a <sys_mkdir+0x54>
    8000603c:	4681                	li	a3,0
    8000603e:	4601                	li	a2,0
    80006040:	4585                	li	a1,1
    80006042:	f7040513          	addi	a0,s0,-144
    80006046:	fffff097          	auipc	ra,0xfffff
    8000604a:	7fe080e7          	jalr	2046(ra) # 80005844 <create>
    8000604e:	cd11                	beqz	a0,8000606a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006050:	ffffe097          	auipc	ra,0xffffe
    80006054:	0a0080e7          	jalr	160(ra) # 800040f0 <iunlockput>
  end_op();
    80006058:	fffff097          	auipc	ra,0xfffff
    8000605c:	872080e7          	jalr	-1934(ra) # 800048ca <end_op>
  return 0;
    80006060:	4501                	li	a0,0
}
    80006062:	60aa                	ld	ra,136(sp)
    80006064:	640a                	ld	s0,128(sp)
    80006066:	6149                	addi	sp,sp,144
    80006068:	8082                	ret
    end_op();
    8000606a:	fffff097          	auipc	ra,0xfffff
    8000606e:	860080e7          	jalr	-1952(ra) # 800048ca <end_op>
    return -1;
    80006072:	557d                	li	a0,-1
    80006074:	b7fd                	j	80006062 <sys_mkdir+0x4c>

0000000080006076 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006076:	7135                	addi	sp,sp,-160
    80006078:	ed06                	sd	ra,152(sp)
    8000607a:	e922                	sd	s0,144(sp)
    8000607c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000607e:	ffffe097          	auipc	ra,0xffffe
    80006082:	7cc080e7          	jalr	1996(ra) # 8000484a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006086:	08000613          	li	a2,128
    8000608a:	f7040593          	addi	a1,s0,-144
    8000608e:	4501                	li	a0,0
    80006090:	ffffd097          	auipc	ra,0xffffd
    80006094:	132080e7          	jalr	306(ra) # 800031c2 <argstr>
    80006098:	04054a63          	bltz	a0,800060ec <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000609c:	f6c40593          	addi	a1,s0,-148
    800060a0:	4505                	li	a0,1
    800060a2:	ffffd097          	auipc	ra,0xffffd
    800060a6:	0dc080e7          	jalr	220(ra) # 8000317e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060aa:	04054163          	bltz	a0,800060ec <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800060ae:	f6840593          	addi	a1,s0,-152
    800060b2:	4509                	li	a0,2
    800060b4:	ffffd097          	auipc	ra,0xffffd
    800060b8:	0ca080e7          	jalr	202(ra) # 8000317e <argint>
     argint(1, &major) < 0 ||
    800060bc:	02054863          	bltz	a0,800060ec <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800060c0:	f6841683          	lh	a3,-152(s0)
    800060c4:	f6c41603          	lh	a2,-148(s0)
    800060c8:	458d                	li	a1,3
    800060ca:	f7040513          	addi	a0,s0,-144
    800060ce:	fffff097          	auipc	ra,0xfffff
    800060d2:	776080e7          	jalr	1910(ra) # 80005844 <create>
     argint(2, &minor) < 0 ||
    800060d6:	c919                	beqz	a0,800060ec <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060d8:	ffffe097          	auipc	ra,0xffffe
    800060dc:	018080e7          	jalr	24(ra) # 800040f0 <iunlockput>
  end_op();
    800060e0:	ffffe097          	auipc	ra,0xffffe
    800060e4:	7ea080e7          	jalr	2026(ra) # 800048ca <end_op>
  return 0;
    800060e8:	4501                	li	a0,0
    800060ea:	a031                	j	800060f6 <sys_mknod+0x80>
    end_op();
    800060ec:	ffffe097          	auipc	ra,0xffffe
    800060f0:	7de080e7          	jalr	2014(ra) # 800048ca <end_op>
    return -1;
    800060f4:	557d                	li	a0,-1
}
    800060f6:	60ea                	ld	ra,152(sp)
    800060f8:	644a                	ld	s0,144(sp)
    800060fa:	610d                	addi	sp,sp,160
    800060fc:	8082                	ret

00000000800060fe <sys_chdir>:

uint64
sys_chdir(void)
{
    800060fe:	7135                	addi	sp,sp,-160
    80006100:	ed06                	sd	ra,152(sp)
    80006102:	e922                	sd	s0,144(sp)
    80006104:	e526                	sd	s1,136(sp)
    80006106:	e14a                	sd	s2,128(sp)
    80006108:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000610a:	ffffc097          	auipc	ra,0xffffc
    8000610e:	d38080e7          	jalr	-712(ra) # 80001e42 <myproc>
    80006112:	892a                	mv	s2,a0
  
  begin_op();
    80006114:	ffffe097          	auipc	ra,0xffffe
    80006118:	736080e7          	jalr	1846(ra) # 8000484a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000611c:	08000613          	li	a2,128
    80006120:	f6040593          	addi	a1,s0,-160
    80006124:	4501                	li	a0,0
    80006126:	ffffd097          	auipc	ra,0xffffd
    8000612a:	09c080e7          	jalr	156(ra) # 800031c2 <argstr>
    8000612e:	04054b63          	bltz	a0,80006184 <sys_chdir+0x86>
    80006132:	f6040513          	addi	a0,s0,-160
    80006136:	ffffe097          	auipc	ra,0xffffe
    8000613a:	508080e7          	jalr	1288(ra) # 8000463e <namei>
    8000613e:	84aa                	mv	s1,a0
    80006140:	c131                	beqz	a0,80006184 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006142:	ffffe097          	auipc	ra,0xffffe
    80006146:	d4c080e7          	jalr	-692(ra) # 80003e8e <ilock>
  if(ip->type != T_DIR){
    8000614a:	04449703          	lh	a4,68(s1)
    8000614e:	4785                	li	a5,1
    80006150:	04f71063          	bne	a4,a5,80006190 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006154:	8526                	mv	a0,s1
    80006156:	ffffe097          	auipc	ra,0xffffe
    8000615a:	dfa080e7          	jalr	-518(ra) # 80003f50 <iunlock>
  iput(p->cwd);
    8000615e:	15893503          	ld	a0,344(s2)
    80006162:	ffffe097          	auipc	ra,0xffffe
    80006166:	ee6080e7          	jalr	-282(ra) # 80004048 <iput>
  end_op();
    8000616a:	ffffe097          	auipc	ra,0xffffe
    8000616e:	760080e7          	jalr	1888(ra) # 800048ca <end_op>
  p->cwd = ip;
    80006172:	14993c23          	sd	s1,344(s2)
  return 0;
    80006176:	4501                	li	a0,0
}
    80006178:	60ea                	ld	ra,152(sp)
    8000617a:	644a                	ld	s0,144(sp)
    8000617c:	64aa                	ld	s1,136(sp)
    8000617e:	690a                	ld	s2,128(sp)
    80006180:	610d                	addi	sp,sp,160
    80006182:	8082                	ret
    end_op();
    80006184:	ffffe097          	auipc	ra,0xffffe
    80006188:	746080e7          	jalr	1862(ra) # 800048ca <end_op>
    return -1;
    8000618c:	557d                	li	a0,-1
    8000618e:	b7ed                	j	80006178 <sys_chdir+0x7a>
    iunlockput(ip);
    80006190:	8526                	mv	a0,s1
    80006192:	ffffe097          	auipc	ra,0xffffe
    80006196:	f5e080e7          	jalr	-162(ra) # 800040f0 <iunlockput>
    end_op();
    8000619a:	ffffe097          	auipc	ra,0xffffe
    8000619e:	730080e7          	jalr	1840(ra) # 800048ca <end_op>
    return -1;
    800061a2:	557d                	li	a0,-1
    800061a4:	bfd1                	j	80006178 <sys_chdir+0x7a>

00000000800061a6 <sys_exec>:

uint64
sys_exec(void)
{
    800061a6:	7145                	addi	sp,sp,-464
    800061a8:	e786                	sd	ra,456(sp)
    800061aa:	e3a2                	sd	s0,448(sp)
    800061ac:	ff26                	sd	s1,440(sp)
    800061ae:	fb4a                	sd	s2,432(sp)
    800061b0:	f74e                	sd	s3,424(sp)
    800061b2:	f352                	sd	s4,416(sp)
    800061b4:	ef56                	sd	s5,408(sp)
    800061b6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800061b8:	08000613          	li	a2,128
    800061bc:	f4040593          	addi	a1,s0,-192
    800061c0:	4501                	li	a0,0
    800061c2:	ffffd097          	auipc	ra,0xffffd
    800061c6:	000080e7          	jalr	ra # 800031c2 <argstr>
    return -1;
    800061ca:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800061cc:	0c054a63          	bltz	a0,800062a0 <sys_exec+0xfa>
    800061d0:	e3840593          	addi	a1,s0,-456
    800061d4:	4505                	li	a0,1
    800061d6:	ffffd097          	auipc	ra,0xffffd
    800061da:	fca080e7          	jalr	-54(ra) # 800031a0 <argaddr>
    800061de:	0c054163          	bltz	a0,800062a0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800061e2:	10000613          	li	a2,256
    800061e6:	4581                	li	a1,0
    800061e8:	e4040513          	addi	a0,s0,-448
    800061ec:	ffffb097          	auipc	ra,0xffffb
    800061f0:	bc8080e7          	jalr	-1080(ra) # 80000db4 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800061f4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800061f8:	89a6                	mv	s3,s1
    800061fa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800061fc:	02000a13          	li	s4,32
    80006200:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006204:	00391513          	slli	a0,s2,0x3
    80006208:	e3040593          	addi	a1,s0,-464
    8000620c:	e3843783          	ld	a5,-456(s0)
    80006210:	953e                	add	a0,a0,a5
    80006212:	ffffd097          	auipc	ra,0xffffd
    80006216:	ed2080e7          	jalr	-302(ra) # 800030e4 <fetchaddr>
    8000621a:	02054a63          	bltz	a0,8000624e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000621e:	e3043783          	ld	a5,-464(s0)
    80006222:	c3b9                	beqz	a5,80006268 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006224:	ffffb097          	auipc	ra,0xffffb
    80006228:	95a080e7          	jalr	-1702(ra) # 80000b7e <kalloc>
    8000622c:	85aa                	mv	a1,a0
    8000622e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006232:	cd11                	beqz	a0,8000624e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006234:	6605                	lui	a2,0x1
    80006236:	e3043503          	ld	a0,-464(s0)
    8000623a:	ffffd097          	auipc	ra,0xffffd
    8000623e:	efc080e7          	jalr	-260(ra) # 80003136 <fetchstr>
    80006242:	00054663          	bltz	a0,8000624e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006246:	0905                	addi	s2,s2,1
    80006248:	09a1                	addi	s3,s3,8
    8000624a:	fb491be3          	bne	s2,s4,80006200 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000624e:	10048913          	addi	s2,s1,256
    80006252:	6088                	ld	a0,0(s1)
    80006254:	c529                	beqz	a0,8000629e <sys_exec+0xf8>
    kfree(argv[i]);
    80006256:	ffffb097          	auipc	ra,0xffffb
    8000625a:	82c080e7          	jalr	-2004(ra) # 80000a82 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000625e:	04a1                	addi	s1,s1,8
    80006260:	ff2499e3          	bne	s1,s2,80006252 <sys_exec+0xac>
  return -1;
    80006264:	597d                	li	s2,-1
    80006266:	a82d                	j	800062a0 <sys_exec+0xfa>
      argv[i] = 0;
    80006268:	0a8e                	slli	s5,s5,0x3
    8000626a:	fc040793          	addi	a5,s0,-64
    8000626e:	9abe                	add	s5,s5,a5
    80006270:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006274:	e4040593          	addi	a1,s0,-448
    80006278:	f4040513          	addi	a0,s0,-192
    8000627c:	fffff097          	auipc	ra,0xfffff
    80006280:	150080e7          	jalr	336(ra) # 800053cc <exec>
    80006284:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006286:	10048993          	addi	s3,s1,256
    8000628a:	6088                	ld	a0,0(s1)
    8000628c:	c911                	beqz	a0,800062a0 <sys_exec+0xfa>
    kfree(argv[i]);
    8000628e:	ffffa097          	auipc	ra,0xffffa
    80006292:	7f4080e7          	jalr	2036(ra) # 80000a82 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006296:	04a1                	addi	s1,s1,8
    80006298:	ff3499e3          	bne	s1,s3,8000628a <sys_exec+0xe4>
    8000629c:	a011                	j	800062a0 <sys_exec+0xfa>
  return -1;
    8000629e:	597d                	li	s2,-1
}
    800062a0:	854a                	mv	a0,s2
    800062a2:	60be                	ld	ra,456(sp)
    800062a4:	641e                	ld	s0,448(sp)
    800062a6:	74fa                	ld	s1,440(sp)
    800062a8:	795a                	ld	s2,432(sp)
    800062aa:	79ba                	ld	s3,424(sp)
    800062ac:	7a1a                	ld	s4,416(sp)
    800062ae:	6afa                	ld	s5,408(sp)
    800062b0:	6179                	addi	sp,sp,464
    800062b2:	8082                	ret

00000000800062b4 <sys_pipe>:

uint64
sys_pipe(void)
{
    800062b4:	7139                	addi	sp,sp,-64
    800062b6:	fc06                	sd	ra,56(sp)
    800062b8:	f822                	sd	s0,48(sp)
    800062ba:	f426                	sd	s1,40(sp)
    800062bc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800062be:	ffffc097          	auipc	ra,0xffffc
    800062c2:	b84080e7          	jalr	-1148(ra) # 80001e42 <myproc>
    800062c6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800062c8:	fd840593          	addi	a1,s0,-40
    800062cc:	4501                	li	a0,0
    800062ce:	ffffd097          	auipc	ra,0xffffd
    800062d2:	ed2080e7          	jalr	-302(ra) # 800031a0 <argaddr>
    return -1;
    800062d6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800062d8:	0e054063          	bltz	a0,800063b8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800062dc:	fc840593          	addi	a1,s0,-56
    800062e0:	fd040513          	addi	a0,s0,-48
    800062e4:	fffff097          	auipc	ra,0xfffff
    800062e8:	d8e080e7          	jalr	-626(ra) # 80005072 <pipealloc>
    return -1;
    800062ec:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800062ee:	0c054563          	bltz	a0,800063b8 <sys_pipe+0x104>
  fd0 = -1;
    800062f2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800062f6:	fd043503          	ld	a0,-48(s0)
    800062fa:	fffff097          	auipc	ra,0xfffff
    800062fe:	508080e7          	jalr	1288(ra) # 80005802 <fdalloc>
    80006302:	fca42223          	sw	a0,-60(s0)
    80006306:	08054c63          	bltz	a0,8000639e <sys_pipe+0xea>
    8000630a:	fc843503          	ld	a0,-56(s0)
    8000630e:	fffff097          	auipc	ra,0xfffff
    80006312:	4f4080e7          	jalr	1268(ra) # 80005802 <fdalloc>
    80006316:	fca42023          	sw	a0,-64(s0)
    8000631a:	06054863          	bltz	a0,8000638a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000631e:	4691                	li	a3,4
    80006320:	fc440613          	addi	a2,s0,-60
    80006324:	fd843583          	ld	a1,-40(s0)
    80006328:	68a8                	ld	a0,80(s1)
    8000632a:	ffffb097          	auipc	ra,0xffffb
    8000632e:	5ea080e7          	jalr	1514(ra) # 80001914 <copyout>
    80006332:	02054063          	bltz	a0,80006352 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006336:	4691                	li	a3,4
    80006338:	fc040613          	addi	a2,s0,-64
    8000633c:	fd843583          	ld	a1,-40(s0)
    80006340:	0591                	addi	a1,a1,4
    80006342:	68a8                	ld	a0,80(s1)
    80006344:	ffffb097          	auipc	ra,0xffffb
    80006348:	5d0080e7          	jalr	1488(ra) # 80001914 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000634c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000634e:	06055563          	bgez	a0,800063b8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006352:	fc442783          	lw	a5,-60(s0)
    80006356:	07e9                	addi	a5,a5,26
    80006358:	078e                	slli	a5,a5,0x3
    8000635a:	97a6                	add	a5,a5,s1
    8000635c:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006360:	fc042503          	lw	a0,-64(s0)
    80006364:	0569                	addi	a0,a0,26
    80006366:	050e                	slli	a0,a0,0x3
    80006368:	9526                	add	a0,a0,s1
    8000636a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000636e:	fd043503          	ld	a0,-48(s0)
    80006372:	fffff097          	auipc	ra,0xfffff
    80006376:	9aa080e7          	jalr	-1622(ra) # 80004d1c <fileclose>
    fileclose(wf);
    8000637a:	fc843503          	ld	a0,-56(s0)
    8000637e:	fffff097          	auipc	ra,0xfffff
    80006382:	99e080e7          	jalr	-1634(ra) # 80004d1c <fileclose>
    return -1;
    80006386:	57fd                	li	a5,-1
    80006388:	a805                	j	800063b8 <sys_pipe+0x104>
    if(fd0 >= 0)
    8000638a:	fc442783          	lw	a5,-60(s0)
    8000638e:	0007c863          	bltz	a5,8000639e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006392:	01a78513          	addi	a0,a5,26
    80006396:	050e                	slli	a0,a0,0x3
    80006398:	9526                	add	a0,a0,s1
    8000639a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000639e:	fd043503          	ld	a0,-48(s0)
    800063a2:	fffff097          	auipc	ra,0xfffff
    800063a6:	97a080e7          	jalr	-1670(ra) # 80004d1c <fileclose>
    fileclose(wf);
    800063aa:	fc843503          	ld	a0,-56(s0)
    800063ae:	fffff097          	auipc	ra,0xfffff
    800063b2:	96e080e7          	jalr	-1682(ra) # 80004d1c <fileclose>
    return -1;
    800063b6:	57fd                	li	a5,-1
}
    800063b8:	853e                	mv	a0,a5
    800063ba:	70e2                	ld	ra,56(sp)
    800063bc:	7442                	ld	s0,48(sp)
    800063be:	74a2                	ld	s1,40(sp)
    800063c0:	6121                	addi	sp,sp,64
    800063c2:	8082                	ret
	...

00000000800063d0 <kernelvec>:
    800063d0:	7111                	addi	sp,sp,-256
    800063d2:	e006                	sd	ra,0(sp)
    800063d4:	e40a                	sd	sp,8(sp)
    800063d6:	e80e                	sd	gp,16(sp)
    800063d8:	ec12                	sd	tp,24(sp)
    800063da:	f016                	sd	t0,32(sp)
    800063dc:	f41a                	sd	t1,40(sp)
    800063de:	f81e                	sd	t2,48(sp)
    800063e0:	fc22                	sd	s0,56(sp)
    800063e2:	e0a6                	sd	s1,64(sp)
    800063e4:	e4aa                	sd	a0,72(sp)
    800063e6:	e8ae                	sd	a1,80(sp)
    800063e8:	ecb2                	sd	a2,88(sp)
    800063ea:	f0b6                	sd	a3,96(sp)
    800063ec:	f4ba                	sd	a4,104(sp)
    800063ee:	f8be                	sd	a5,112(sp)
    800063f0:	fcc2                	sd	a6,120(sp)
    800063f2:	e146                	sd	a7,128(sp)
    800063f4:	e54a                	sd	s2,136(sp)
    800063f6:	e94e                	sd	s3,144(sp)
    800063f8:	ed52                	sd	s4,152(sp)
    800063fa:	f156                	sd	s5,160(sp)
    800063fc:	f55a                	sd	s6,168(sp)
    800063fe:	f95e                	sd	s7,176(sp)
    80006400:	fd62                	sd	s8,184(sp)
    80006402:	e1e6                	sd	s9,192(sp)
    80006404:	e5ea                	sd	s10,200(sp)
    80006406:	e9ee                	sd	s11,208(sp)
    80006408:	edf2                	sd	t3,216(sp)
    8000640a:	f1f6                	sd	t4,224(sp)
    8000640c:	f5fa                	sd	t5,232(sp)
    8000640e:	f9fe                	sd	t6,240(sp)
    80006410:	ba1fc0ef          	jal	ra,80002fb0 <kerneltrap>
    80006414:	6082                	ld	ra,0(sp)
    80006416:	6122                	ld	sp,8(sp)
    80006418:	61c2                	ld	gp,16(sp)
    8000641a:	7282                	ld	t0,32(sp)
    8000641c:	7322                	ld	t1,40(sp)
    8000641e:	73c2                	ld	t2,48(sp)
    80006420:	7462                	ld	s0,56(sp)
    80006422:	6486                	ld	s1,64(sp)
    80006424:	6526                	ld	a0,72(sp)
    80006426:	65c6                	ld	a1,80(sp)
    80006428:	6666                	ld	a2,88(sp)
    8000642a:	7686                	ld	a3,96(sp)
    8000642c:	7726                	ld	a4,104(sp)
    8000642e:	77c6                	ld	a5,112(sp)
    80006430:	7866                	ld	a6,120(sp)
    80006432:	688a                	ld	a7,128(sp)
    80006434:	692a                	ld	s2,136(sp)
    80006436:	69ca                	ld	s3,144(sp)
    80006438:	6a6a                	ld	s4,152(sp)
    8000643a:	7a8a                	ld	s5,160(sp)
    8000643c:	7b2a                	ld	s6,168(sp)
    8000643e:	7bca                	ld	s7,176(sp)
    80006440:	7c6a                	ld	s8,184(sp)
    80006442:	6c8e                	ld	s9,192(sp)
    80006444:	6d2e                	ld	s10,200(sp)
    80006446:	6dce                	ld	s11,208(sp)
    80006448:	6e6e                	ld	t3,216(sp)
    8000644a:	7e8e                	ld	t4,224(sp)
    8000644c:	7f2e                	ld	t5,232(sp)
    8000644e:	7fce                	ld	t6,240(sp)
    80006450:	6111                	addi	sp,sp,256
    80006452:	10200073          	sret
    80006456:	00000013          	nop
    8000645a:	00000013          	nop
    8000645e:	0001                	nop

0000000080006460 <timervec>:
    80006460:	34051573          	csrrw	a0,mscratch,a0
    80006464:	e10c                	sd	a1,0(a0)
    80006466:	e510                	sd	a2,8(a0)
    80006468:	e914                	sd	a3,16(a0)
    8000646a:	710c                	ld	a1,32(a0)
    8000646c:	7510                	ld	a2,40(a0)
    8000646e:	6194                	ld	a3,0(a1)
    80006470:	96b2                	add	a3,a3,a2
    80006472:	e194                	sd	a3,0(a1)
    80006474:	4589                	li	a1,2
    80006476:	14459073          	csrw	sip,a1
    8000647a:	6914                	ld	a3,16(a0)
    8000647c:	6510                	ld	a2,8(a0)
    8000647e:	610c                	ld	a1,0(a0)
    80006480:	34051573          	csrrw	a0,mscratch,a0
    80006484:	30200073          	mret
	...

000000008000648a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000648a:	1141                	addi	sp,sp,-16
    8000648c:	e422                	sd	s0,8(sp)
    8000648e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006490:	0c0007b7          	lui	a5,0xc000
    80006494:	4705                	li	a4,1
    80006496:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006498:	c3d8                	sw	a4,4(a5)
}
    8000649a:	6422                	ld	s0,8(sp)
    8000649c:	0141                	addi	sp,sp,16
    8000649e:	8082                	ret

00000000800064a0 <plicinithart>:

void
plicinithart(void)
{
    800064a0:	1141                	addi	sp,sp,-16
    800064a2:	e406                	sd	ra,8(sp)
    800064a4:	e022                	sd	s0,0(sp)
    800064a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064a8:	ffffc097          	auipc	ra,0xffffc
    800064ac:	96e080e7          	jalr	-1682(ra) # 80001e16 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800064b0:	0085171b          	slliw	a4,a0,0x8
    800064b4:	0c0027b7          	lui	a5,0xc002
    800064b8:	97ba                	add	a5,a5,a4
    800064ba:	40200713          	li	a4,1026
    800064be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800064c2:	00d5151b          	slliw	a0,a0,0xd
    800064c6:	0c2017b7          	lui	a5,0xc201
    800064ca:	953e                	add	a0,a0,a5
    800064cc:	00052023          	sw	zero,0(a0)
}
    800064d0:	60a2                	ld	ra,8(sp)
    800064d2:	6402                	ld	s0,0(sp)
    800064d4:	0141                	addi	sp,sp,16
    800064d6:	8082                	ret

00000000800064d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800064d8:	1141                	addi	sp,sp,-16
    800064da:	e406                	sd	ra,8(sp)
    800064dc:	e022                	sd	s0,0(sp)
    800064de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064e0:	ffffc097          	auipc	ra,0xffffc
    800064e4:	936080e7          	jalr	-1738(ra) # 80001e16 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800064e8:	00d5179b          	slliw	a5,a0,0xd
    800064ec:	0c201537          	lui	a0,0xc201
    800064f0:	953e                	add	a0,a0,a5
  return irq;
}
    800064f2:	4148                	lw	a0,4(a0)
    800064f4:	60a2                	ld	ra,8(sp)
    800064f6:	6402                	ld	s0,0(sp)
    800064f8:	0141                	addi	sp,sp,16
    800064fa:	8082                	ret

00000000800064fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800064fc:	1101                	addi	sp,sp,-32
    800064fe:	ec06                	sd	ra,24(sp)
    80006500:	e822                	sd	s0,16(sp)
    80006502:	e426                	sd	s1,8(sp)
    80006504:	1000                	addi	s0,sp,32
    80006506:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006508:	ffffc097          	auipc	ra,0xffffc
    8000650c:	90e080e7          	jalr	-1778(ra) # 80001e16 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006510:	00d5151b          	slliw	a0,a0,0xd
    80006514:	0c2017b7          	lui	a5,0xc201
    80006518:	97aa                	add	a5,a5,a0
    8000651a:	c3c4                	sw	s1,4(a5)
}
    8000651c:	60e2                	ld	ra,24(sp)
    8000651e:	6442                	ld	s0,16(sp)
    80006520:	64a2                	ld	s1,8(sp)
    80006522:	6105                	addi	sp,sp,32
    80006524:	8082                	ret

0000000080006526 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006526:	1141                	addi	sp,sp,-16
    80006528:	e406                	sd	ra,8(sp)
    8000652a:	e022                	sd	s0,0(sp)
    8000652c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000652e:	479d                	li	a5,7
    80006530:	04a7cc63          	blt	a5,a0,80006588 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80006534:	0001e797          	auipc	a5,0x1e
    80006538:	acc78793          	addi	a5,a5,-1332 # 80024000 <disk>
    8000653c:	00a78733          	add	a4,a5,a0
    80006540:	6789                	lui	a5,0x2
    80006542:	97ba                	add	a5,a5,a4
    80006544:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006548:	eba1                	bnez	a5,80006598 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    8000654a:	00451713          	slli	a4,a0,0x4
    8000654e:	00020797          	auipc	a5,0x20
    80006552:	ab27b783          	ld	a5,-1358(a5) # 80026000 <disk+0x2000>
    80006556:	97ba                	add	a5,a5,a4
    80006558:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000655c:	0001e797          	auipc	a5,0x1e
    80006560:	aa478793          	addi	a5,a5,-1372 # 80024000 <disk>
    80006564:	97aa                	add	a5,a5,a0
    80006566:	6509                	lui	a0,0x2
    80006568:	953e                	add	a0,a0,a5
    8000656a:	4785                	li	a5,1
    8000656c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006570:	00020517          	auipc	a0,0x20
    80006574:	aa850513          	addi	a0,a0,-1368 # 80026018 <disk+0x2018>
    80006578:	ffffc097          	auipc	ra,0xffffc
    8000657c:	430080e7          	jalr	1072(ra) # 800029a8 <wakeup>
}
    80006580:	60a2                	ld	ra,8(sp)
    80006582:	6402                	ld	s0,0(sp)
    80006584:	0141                	addi	sp,sp,16
    80006586:	8082                	ret
    panic("virtio_disk_intr 1");
    80006588:	00002517          	auipc	a0,0x2
    8000658c:	4b050513          	addi	a0,a0,1200 # 80008a38 <sysnames+0x340>
    80006590:	ffffa097          	auipc	ra,0xffffa
    80006594:	040080e7          	jalr	64(ra) # 800005d0 <panic>
    panic("virtio_disk_intr 2");
    80006598:	00002517          	auipc	a0,0x2
    8000659c:	4b850513          	addi	a0,a0,1208 # 80008a50 <sysnames+0x358>
    800065a0:	ffffa097          	auipc	ra,0xffffa
    800065a4:	030080e7          	jalr	48(ra) # 800005d0 <panic>

00000000800065a8 <virtio_disk_init>:
{
    800065a8:	1101                	addi	sp,sp,-32
    800065aa:	ec06                	sd	ra,24(sp)
    800065ac:	e822                	sd	s0,16(sp)
    800065ae:	e426                	sd	s1,8(sp)
    800065b0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800065b2:	00002597          	auipc	a1,0x2
    800065b6:	4b658593          	addi	a1,a1,1206 # 80008a68 <sysnames+0x370>
    800065ba:	00020517          	auipc	a0,0x20
    800065be:	aee50513          	addi	a0,a0,-1298 # 800260a8 <disk+0x20a8>
    800065c2:	ffffa097          	auipc	ra,0xffffa
    800065c6:	666080e7          	jalr	1638(ra) # 80000c28 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065ca:	100017b7          	lui	a5,0x10001
    800065ce:	4398                	lw	a4,0(a5)
    800065d0:	2701                	sext.w	a4,a4
    800065d2:	747277b7          	lui	a5,0x74727
    800065d6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065da:	0ef71163          	bne	a4,a5,800066bc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065de:	100017b7          	lui	a5,0x10001
    800065e2:	43dc                	lw	a5,4(a5)
    800065e4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065e6:	4705                	li	a4,1
    800065e8:	0ce79a63          	bne	a5,a4,800066bc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065ec:	100017b7          	lui	a5,0x10001
    800065f0:	479c                	lw	a5,8(a5)
    800065f2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065f4:	4709                	li	a4,2
    800065f6:	0ce79363          	bne	a5,a4,800066bc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800065fa:	100017b7          	lui	a5,0x10001
    800065fe:	47d8                	lw	a4,12(a5)
    80006600:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006602:	554d47b7          	lui	a5,0x554d4
    80006606:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000660a:	0af71963          	bne	a4,a5,800066bc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000660e:	100017b7          	lui	a5,0x10001
    80006612:	4705                	li	a4,1
    80006614:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006616:	470d                	li	a4,3
    80006618:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000661a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000661c:	c7ffe737          	lui	a4,0xc7ffe
    80006620:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd673f>
    80006624:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006626:	2701                	sext.w	a4,a4
    80006628:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000662a:	472d                	li	a4,11
    8000662c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000662e:	473d                	li	a4,15
    80006630:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006632:	6705                	lui	a4,0x1
    80006634:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006636:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000663a:	5bdc                	lw	a5,52(a5)
    8000663c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000663e:	c7d9                	beqz	a5,800066cc <virtio_disk_init+0x124>
  if(max < NUM)
    80006640:	471d                	li	a4,7
    80006642:	08f77d63          	bgeu	a4,a5,800066dc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006646:	100014b7          	lui	s1,0x10001
    8000664a:	47a1                	li	a5,8
    8000664c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000664e:	6609                	lui	a2,0x2
    80006650:	4581                	li	a1,0
    80006652:	0001e517          	auipc	a0,0x1e
    80006656:	9ae50513          	addi	a0,a0,-1618 # 80024000 <disk>
    8000665a:	ffffa097          	auipc	ra,0xffffa
    8000665e:	75a080e7          	jalr	1882(ra) # 80000db4 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006662:	0001e717          	auipc	a4,0x1e
    80006666:	99e70713          	addi	a4,a4,-1634 # 80024000 <disk>
    8000666a:	00c75793          	srli	a5,a4,0xc
    8000666e:	2781                	sext.w	a5,a5
    80006670:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006672:	00020797          	auipc	a5,0x20
    80006676:	98e78793          	addi	a5,a5,-1650 # 80026000 <disk+0x2000>
    8000667a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000667c:	0001e717          	auipc	a4,0x1e
    80006680:	a0470713          	addi	a4,a4,-1532 # 80024080 <disk+0x80>
    80006684:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006686:	0001f717          	auipc	a4,0x1f
    8000668a:	97a70713          	addi	a4,a4,-1670 # 80025000 <disk+0x1000>
    8000668e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006690:	4705                	li	a4,1
    80006692:	00e78c23          	sb	a4,24(a5)
    80006696:	00e78ca3          	sb	a4,25(a5)
    8000669a:	00e78d23          	sb	a4,26(a5)
    8000669e:	00e78da3          	sb	a4,27(a5)
    800066a2:	00e78e23          	sb	a4,28(a5)
    800066a6:	00e78ea3          	sb	a4,29(a5)
    800066aa:	00e78f23          	sb	a4,30(a5)
    800066ae:	00e78fa3          	sb	a4,31(a5)
}
    800066b2:	60e2                	ld	ra,24(sp)
    800066b4:	6442                	ld	s0,16(sp)
    800066b6:	64a2                	ld	s1,8(sp)
    800066b8:	6105                	addi	sp,sp,32
    800066ba:	8082                	ret
    panic("could not find virtio disk");
    800066bc:	00002517          	auipc	a0,0x2
    800066c0:	3bc50513          	addi	a0,a0,956 # 80008a78 <sysnames+0x380>
    800066c4:	ffffa097          	auipc	ra,0xffffa
    800066c8:	f0c080e7          	jalr	-244(ra) # 800005d0 <panic>
    panic("virtio disk has no queue 0");
    800066cc:	00002517          	auipc	a0,0x2
    800066d0:	3cc50513          	addi	a0,a0,972 # 80008a98 <sysnames+0x3a0>
    800066d4:	ffffa097          	auipc	ra,0xffffa
    800066d8:	efc080e7          	jalr	-260(ra) # 800005d0 <panic>
    panic("virtio disk max queue too short");
    800066dc:	00002517          	auipc	a0,0x2
    800066e0:	3dc50513          	addi	a0,a0,988 # 80008ab8 <sysnames+0x3c0>
    800066e4:	ffffa097          	auipc	ra,0xffffa
    800066e8:	eec080e7          	jalr	-276(ra) # 800005d0 <panic>

00000000800066ec <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800066ec:	7119                	addi	sp,sp,-128
    800066ee:	fc86                	sd	ra,120(sp)
    800066f0:	f8a2                	sd	s0,112(sp)
    800066f2:	f4a6                	sd	s1,104(sp)
    800066f4:	f0ca                	sd	s2,96(sp)
    800066f6:	ecce                	sd	s3,88(sp)
    800066f8:	e8d2                	sd	s4,80(sp)
    800066fa:	e4d6                	sd	s5,72(sp)
    800066fc:	e0da                	sd	s6,64(sp)
    800066fe:	fc5e                	sd	s7,56(sp)
    80006700:	f862                	sd	s8,48(sp)
    80006702:	f466                	sd	s9,40(sp)
    80006704:	f06a                	sd	s10,32(sp)
    80006706:	0100                	addi	s0,sp,128
    80006708:	892a                	mv	s2,a0
    8000670a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000670c:	00c52c83          	lw	s9,12(a0)
    80006710:	001c9c9b          	slliw	s9,s9,0x1
    80006714:	1c82                	slli	s9,s9,0x20
    80006716:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000671a:	00020517          	auipc	a0,0x20
    8000671e:	98e50513          	addi	a0,a0,-1650 # 800260a8 <disk+0x20a8>
    80006722:	ffffa097          	auipc	ra,0xffffa
    80006726:	596080e7          	jalr	1430(ra) # 80000cb8 <acquire>
  for(int i = 0; i < 3; i++){
    8000672a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000672c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000672e:	0001eb97          	auipc	s7,0x1e
    80006732:	8d2b8b93          	addi	s7,s7,-1838 # 80024000 <disk>
    80006736:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006738:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000673a:	8a4e                	mv	s4,s3
    8000673c:	a051                	j	800067c0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000673e:	00fb86b3          	add	a3,s7,a5
    80006742:	96da                	add	a3,a3,s6
    80006744:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006748:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000674a:	0207c563          	bltz	a5,80006774 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000674e:	2485                	addiw	s1,s1,1
    80006750:	0711                	addi	a4,a4,4
    80006752:	23548d63          	beq	s1,s5,8000698c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006756:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006758:	00020697          	auipc	a3,0x20
    8000675c:	8c068693          	addi	a3,a3,-1856 # 80026018 <disk+0x2018>
    80006760:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006762:	0006c583          	lbu	a1,0(a3)
    80006766:	fde1                	bnez	a1,8000673e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006768:	2785                	addiw	a5,a5,1
    8000676a:	0685                	addi	a3,a3,1
    8000676c:	ff879be3          	bne	a5,s8,80006762 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006770:	57fd                	li	a5,-1
    80006772:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006774:	02905a63          	blez	s1,800067a8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006778:	f9042503          	lw	a0,-112(s0)
    8000677c:	00000097          	auipc	ra,0x0
    80006780:	daa080e7          	jalr	-598(ra) # 80006526 <free_desc>
      for(int j = 0; j < i; j++)
    80006784:	4785                	li	a5,1
    80006786:	0297d163          	bge	a5,s1,800067a8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000678a:	f9442503          	lw	a0,-108(s0)
    8000678e:	00000097          	auipc	ra,0x0
    80006792:	d98080e7          	jalr	-616(ra) # 80006526 <free_desc>
      for(int j = 0; j < i; j++)
    80006796:	4789                	li	a5,2
    80006798:	0097d863          	bge	a5,s1,800067a8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000679c:	f9842503          	lw	a0,-104(s0)
    800067a0:	00000097          	auipc	ra,0x0
    800067a4:	d86080e7          	jalr	-634(ra) # 80006526 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800067a8:	00020597          	auipc	a1,0x20
    800067ac:	90058593          	addi	a1,a1,-1792 # 800260a8 <disk+0x20a8>
    800067b0:	00020517          	auipc	a0,0x20
    800067b4:	86850513          	addi	a0,a0,-1944 # 80026018 <disk+0x2018>
    800067b8:	ffffc097          	auipc	ra,0xffffc
    800067bc:	06a080e7          	jalr	106(ra) # 80002822 <sleep>
  for(int i = 0; i < 3; i++){
    800067c0:	f9040713          	addi	a4,s0,-112
    800067c4:	84ce                	mv	s1,s3
    800067c6:	bf41                	j	80006756 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800067c8:	4785                	li	a5,1
    800067ca:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800067ce:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800067d2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800067d6:	f9042983          	lw	s3,-112(s0)
    800067da:	00499493          	slli	s1,s3,0x4
    800067de:	00020a17          	auipc	s4,0x20
    800067e2:	822a0a13          	addi	s4,s4,-2014 # 80026000 <disk+0x2000>
    800067e6:	000a3a83          	ld	s5,0(s4)
    800067ea:	9aa6                	add	s5,s5,s1
    800067ec:	f8040513          	addi	a0,s0,-128
    800067f0:	ffffb097          	auipc	ra,0xffffb
    800067f4:	9b4080e7          	jalr	-1612(ra) # 800011a4 <kvmpa>
    800067f8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800067fc:	000a3783          	ld	a5,0(s4)
    80006800:	97a6                	add	a5,a5,s1
    80006802:	4741                	li	a4,16
    80006804:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006806:	000a3783          	ld	a5,0(s4)
    8000680a:	97a6                	add	a5,a5,s1
    8000680c:	4705                	li	a4,1
    8000680e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006812:	f9442703          	lw	a4,-108(s0)
    80006816:	000a3783          	ld	a5,0(s4)
    8000681a:	97a6                	add	a5,a5,s1
    8000681c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006820:	0712                	slli	a4,a4,0x4
    80006822:	000a3783          	ld	a5,0(s4)
    80006826:	97ba                	add	a5,a5,a4
    80006828:	05890693          	addi	a3,s2,88
    8000682c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000682e:	000a3783          	ld	a5,0(s4)
    80006832:	97ba                	add	a5,a5,a4
    80006834:	40000693          	li	a3,1024
    80006838:	c794                	sw	a3,8(a5)
  if(write)
    8000683a:	100d0a63          	beqz	s10,8000694e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000683e:	0001f797          	auipc	a5,0x1f
    80006842:	7c27b783          	ld	a5,1986(a5) # 80026000 <disk+0x2000>
    80006846:	97ba                	add	a5,a5,a4
    80006848:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000684c:	0001d517          	auipc	a0,0x1d
    80006850:	7b450513          	addi	a0,a0,1972 # 80024000 <disk>
    80006854:	0001f797          	auipc	a5,0x1f
    80006858:	7ac78793          	addi	a5,a5,1964 # 80026000 <disk+0x2000>
    8000685c:	6394                	ld	a3,0(a5)
    8000685e:	96ba                	add	a3,a3,a4
    80006860:	00c6d603          	lhu	a2,12(a3)
    80006864:	00166613          	ori	a2,a2,1
    80006868:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000686c:	f9842683          	lw	a3,-104(s0)
    80006870:	6390                	ld	a2,0(a5)
    80006872:	9732                	add	a4,a4,a2
    80006874:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006878:	20098613          	addi	a2,s3,512
    8000687c:	0612                	slli	a2,a2,0x4
    8000687e:	962a                	add	a2,a2,a0
    80006880:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006884:	00469713          	slli	a4,a3,0x4
    80006888:	6394                	ld	a3,0(a5)
    8000688a:	96ba                	add	a3,a3,a4
    8000688c:	6589                	lui	a1,0x2
    8000688e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006892:	94ae                	add	s1,s1,a1
    80006894:	94aa                	add	s1,s1,a0
    80006896:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006898:	6394                	ld	a3,0(a5)
    8000689a:	96ba                	add	a3,a3,a4
    8000689c:	4585                	li	a1,1
    8000689e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800068a0:	6394                	ld	a3,0(a5)
    800068a2:	96ba                	add	a3,a3,a4
    800068a4:	4509                	li	a0,2
    800068a6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800068aa:	6394                	ld	a3,0(a5)
    800068ac:	9736                	add	a4,a4,a3
    800068ae:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800068b2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800068b6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800068ba:	6794                	ld	a3,8(a5)
    800068bc:	0026d703          	lhu	a4,2(a3)
    800068c0:	8b1d                	andi	a4,a4,7
    800068c2:	2709                	addiw	a4,a4,2
    800068c4:	0706                	slli	a4,a4,0x1
    800068c6:	9736                	add	a4,a4,a3
    800068c8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800068cc:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800068d0:	6798                	ld	a4,8(a5)
    800068d2:	00275783          	lhu	a5,2(a4)
    800068d6:	2785                	addiw	a5,a5,1
    800068d8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800068dc:	100017b7          	lui	a5,0x10001
    800068e0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800068e4:	00492703          	lw	a4,4(s2)
    800068e8:	4785                	li	a5,1
    800068ea:	02f71163          	bne	a4,a5,8000690c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800068ee:	0001f997          	auipc	s3,0x1f
    800068f2:	7ba98993          	addi	s3,s3,1978 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    800068f6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800068f8:	85ce                	mv	a1,s3
    800068fa:	854a                	mv	a0,s2
    800068fc:	ffffc097          	auipc	ra,0xffffc
    80006900:	f26080e7          	jalr	-218(ra) # 80002822 <sleep>
  while(b->disk == 1) {
    80006904:	00492783          	lw	a5,4(s2)
    80006908:	fe9788e3          	beq	a5,s1,800068f8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000690c:	f9042483          	lw	s1,-112(s0)
    80006910:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006914:	00479713          	slli	a4,a5,0x4
    80006918:	0001d797          	auipc	a5,0x1d
    8000691c:	6e878793          	addi	a5,a5,1768 # 80024000 <disk>
    80006920:	97ba                	add	a5,a5,a4
    80006922:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006926:	0001f917          	auipc	s2,0x1f
    8000692a:	6da90913          	addi	s2,s2,1754 # 80026000 <disk+0x2000>
    free_desc(i);
    8000692e:	8526                	mv	a0,s1
    80006930:	00000097          	auipc	ra,0x0
    80006934:	bf6080e7          	jalr	-1034(ra) # 80006526 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006938:	0492                	slli	s1,s1,0x4
    8000693a:	00093783          	ld	a5,0(s2)
    8000693e:	94be                	add	s1,s1,a5
    80006940:	00c4d783          	lhu	a5,12(s1)
    80006944:	8b85                	andi	a5,a5,1
    80006946:	cf89                	beqz	a5,80006960 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006948:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000694c:	b7cd                	j	8000692e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000694e:	0001f797          	auipc	a5,0x1f
    80006952:	6b27b783          	ld	a5,1714(a5) # 80026000 <disk+0x2000>
    80006956:	97ba                	add	a5,a5,a4
    80006958:	4689                	li	a3,2
    8000695a:	00d79623          	sh	a3,12(a5)
    8000695e:	b5fd                	j	8000684c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006960:	0001f517          	auipc	a0,0x1f
    80006964:	74850513          	addi	a0,a0,1864 # 800260a8 <disk+0x20a8>
    80006968:	ffffa097          	auipc	ra,0xffffa
    8000696c:	404080e7          	jalr	1028(ra) # 80000d6c <release>
}
    80006970:	70e6                	ld	ra,120(sp)
    80006972:	7446                	ld	s0,112(sp)
    80006974:	74a6                	ld	s1,104(sp)
    80006976:	7906                	ld	s2,96(sp)
    80006978:	69e6                	ld	s3,88(sp)
    8000697a:	6a46                	ld	s4,80(sp)
    8000697c:	6aa6                	ld	s5,72(sp)
    8000697e:	6b06                	ld	s6,64(sp)
    80006980:	7be2                	ld	s7,56(sp)
    80006982:	7c42                	ld	s8,48(sp)
    80006984:	7ca2                	ld	s9,40(sp)
    80006986:	7d02                	ld	s10,32(sp)
    80006988:	6109                	addi	sp,sp,128
    8000698a:	8082                	ret
  if(write)
    8000698c:	e20d1ee3          	bnez	s10,800067c8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006990:	f8042023          	sw	zero,-128(s0)
    80006994:	bd2d                	j	800067ce <virtio_disk_rw+0xe2>

0000000080006996 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006996:	1101                	addi	sp,sp,-32
    80006998:	ec06                	sd	ra,24(sp)
    8000699a:	e822                	sd	s0,16(sp)
    8000699c:	e426                	sd	s1,8(sp)
    8000699e:	e04a                	sd	s2,0(sp)
    800069a0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800069a2:	0001f517          	auipc	a0,0x1f
    800069a6:	70650513          	addi	a0,a0,1798 # 800260a8 <disk+0x20a8>
    800069aa:	ffffa097          	auipc	ra,0xffffa
    800069ae:	30e080e7          	jalr	782(ra) # 80000cb8 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800069b2:	0001f717          	auipc	a4,0x1f
    800069b6:	64e70713          	addi	a4,a4,1614 # 80026000 <disk+0x2000>
    800069ba:	02075783          	lhu	a5,32(a4)
    800069be:	6b18                	ld	a4,16(a4)
    800069c0:	00275683          	lhu	a3,2(a4)
    800069c4:	8ebd                	xor	a3,a3,a5
    800069c6:	8a9d                	andi	a3,a3,7
    800069c8:	cab9                	beqz	a3,80006a1e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800069ca:	0001d917          	auipc	s2,0x1d
    800069ce:	63690913          	addi	s2,s2,1590 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800069d2:	0001f497          	auipc	s1,0x1f
    800069d6:	62e48493          	addi	s1,s1,1582 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800069da:	078e                	slli	a5,a5,0x3
    800069dc:	97ba                	add	a5,a5,a4
    800069de:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800069e0:	20078713          	addi	a4,a5,512
    800069e4:	0712                	slli	a4,a4,0x4
    800069e6:	974a                	add	a4,a4,s2
    800069e8:	03074703          	lbu	a4,48(a4)
    800069ec:	ef21                	bnez	a4,80006a44 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800069ee:	20078793          	addi	a5,a5,512
    800069f2:	0792                	slli	a5,a5,0x4
    800069f4:	97ca                	add	a5,a5,s2
    800069f6:	7798                	ld	a4,40(a5)
    800069f8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800069fc:	7788                	ld	a0,40(a5)
    800069fe:	ffffc097          	auipc	ra,0xffffc
    80006a02:	faa080e7          	jalr	-86(ra) # 800029a8 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006a06:	0204d783          	lhu	a5,32(s1)
    80006a0a:	2785                	addiw	a5,a5,1
    80006a0c:	8b9d                	andi	a5,a5,7
    80006a0e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006a12:	6898                	ld	a4,16(s1)
    80006a14:	00275683          	lhu	a3,2(a4)
    80006a18:	8a9d                	andi	a3,a3,7
    80006a1a:	fcf690e3          	bne	a3,a5,800069da <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006a1e:	10001737          	lui	a4,0x10001
    80006a22:	533c                	lw	a5,96(a4)
    80006a24:	8b8d                	andi	a5,a5,3
    80006a26:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006a28:	0001f517          	auipc	a0,0x1f
    80006a2c:	68050513          	addi	a0,a0,1664 # 800260a8 <disk+0x20a8>
    80006a30:	ffffa097          	auipc	ra,0xffffa
    80006a34:	33c080e7          	jalr	828(ra) # 80000d6c <release>
}
    80006a38:	60e2                	ld	ra,24(sp)
    80006a3a:	6442                	ld	s0,16(sp)
    80006a3c:	64a2                	ld	s1,8(sp)
    80006a3e:	6902                	ld	s2,0(sp)
    80006a40:	6105                	addi	sp,sp,32
    80006a42:	8082                	ret
      panic("virtio_disk_intr status");
    80006a44:	00002517          	auipc	a0,0x2
    80006a48:	09450513          	addi	a0,a0,148 # 80008ad8 <sysnames+0x3e0>
    80006a4c:	ffffa097          	auipc	ra,0xffffa
    80006a50:	b84080e7          	jalr	-1148(ra) # 800005d0 <panic>

0000000080006a54 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006a54:	1141                	addi	sp,sp,-16
    80006a56:	e422                	sd	s0,8(sp)
    80006a58:	0800                	addi	s0,sp,16
  return -1;
}
    80006a5a:	557d                	li	a0,-1
    80006a5c:	6422                	ld	s0,8(sp)
    80006a5e:	0141                	addi	sp,sp,16
    80006a60:	8082                	ret

0000000080006a62 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006a62:	7179                	addi	sp,sp,-48
    80006a64:	f406                	sd	ra,40(sp)
    80006a66:	f022                	sd	s0,32(sp)
    80006a68:	ec26                	sd	s1,24(sp)
    80006a6a:	e84a                	sd	s2,16(sp)
    80006a6c:	e44e                	sd	s3,8(sp)
    80006a6e:	e052                	sd	s4,0(sp)
    80006a70:	1800                	addi	s0,sp,48
    80006a72:	892a                	mv	s2,a0
    80006a74:	89ae                	mv	s3,a1
    80006a76:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006a78:	00020517          	auipc	a0,0x20
    80006a7c:	58850513          	addi	a0,a0,1416 # 80027000 <stats>
    80006a80:	ffffa097          	auipc	ra,0xffffa
    80006a84:	238080e7          	jalr	568(ra) # 80000cb8 <acquire>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006a88:	00021797          	auipc	a5,0x21
    80006a8c:	57878793          	addi	a5,a5,1400 # 80028000 <stats+0x1000>
    80006a90:	4fd8                	lw	a4,28(a5)
    80006a92:	4f9c                	lw	a5,24(a5)
    80006a94:	9f99                	subw	a5,a5,a4
    80006a96:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006a9a:	06d05163          	blez	a3,80006afc <statsread+0x9a>
    if(m > n)
    80006a9e:	8a3e                	mv	s4,a5
    80006aa0:	00d4d363          	bge	s1,a3,80006aa6 <statsread+0x44>
    80006aa4:	8a26                	mv	s4,s1
    80006aa6:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006aaa:	86a6                	mv	a3,s1
    80006aac:	00020617          	auipc	a2,0x20
    80006ab0:	56c60613          	addi	a2,a2,1388 # 80027018 <stats+0x18>
    80006ab4:	963a                	add	a2,a2,a4
    80006ab6:	85ce                	mv	a1,s3
    80006ab8:	854a                	mv	a0,s2
    80006aba:	ffffc097          	auipc	ra,0xffffc
    80006abe:	fca080e7          	jalr	-54(ra) # 80002a84 <either_copyout>
    80006ac2:	57fd                	li	a5,-1
    80006ac4:	00f50b63          	beq	a0,a5,80006ada <statsread+0x78>
      stats.off += m;
    80006ac8:	00021717          	auipc	a4,0x21
    80006acc:	53870713          	addi	a4,a4,1336 # 80028000 <stats+0x1000>
    80006ad0:	4f5c                	lw	a5,28(a4)
    80006ad2:	01478a3b          	addw	s4,a5,s4
    80006ad6:	01472e23          	sw	s4,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006ada:	00020517          	auipc	a0,0x20
    80006ade:	52650513          	addi	a0,a0,1318 # 80027000 <stats>
    80006ae2:	ffffa097          	auipc	ra,0xffffa
    80006ae6:	28a080e7          	jalr	650(ra) # 80000d6c <release>
  return m;
}
    80006aea:	8526                	mv	a0,s1
    80006aec:	70a2                	ld	ra,40(sp)
    80006aee:	7402                	ld	s0,32(sp)
    80006af0:	64e2                	ld	s1,24(sp)
    80006af2:	6942                	ld	s2,16(sp)
    80006af4:	69a2                	ld	s3,8(sp)
    80006af6:	6a02                	ld	s4,0(sp)
    80006af8:	6145                	addi	sp,sp,48
    80006afa:	8082                	ret
    stats.sz = 0;
    80006afc:	00021797          	auipc	a5,0x21
    80006b00:	50478793          	addi	a5,a5,1284 # 80028000 <stats+0x1000>
    80006b04:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    80006b08:	0007ae23          	sw	zero,28(a5)
    m = -1;
    80006b0c:	54fd                	li	s1,-1
    80006b0e:	b7f1                	j	80006ada <statsread+0x78>

0000000080006b10 <statsinit>:

void
statsinit(void)
{
    80006b10:	1141                	addi	sp,sp,-16
    80006b12:	e406                	sd	ra,8(sp)
    80006b14:	e022                	sd	s0,0(sp)
    80006b16:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    80006b18:	00002597          	auipc	a1,0x2
    80006b1c:	fd858593          	addi	a1,a1,-40 # 80008af0 <sysnames+0x3f8>
    80006b20:	00020517          	auipc	a0,0x20
    80006b24:	4e050513          	addi	a0,a0,1248 # 80027000 <stats>
    80006b28:	ffffa097          	auipc	ra,0xffffa
    80006b2c:	100080e7          	jalr	256(ra) # 80000c28 <initlock>

  devsw[STATS].read = statsread;
    80006b30:	0001c797          	auipc	a5,0x1c
    80006b34:	a8078793          	addi	a5,a5,-1408 # 800225b0 <devsw>
    80006b38:	00000717          	auipc	a4,0x0
    80006b3c:	f2a70713          	addi	a4,a4,-214 # 80006a62 <statsread>
    80006b40:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006b42:	00000717          	auipc	a4,0x0
    80006b46:	f1270713          	addi	a4,a4,-238 # 80006a54 <statswrite>
    80006b4a:	f798                	sd	a4,40(a5)
}
    80006b4c:	60a2                	ld	ra,8(sp)
    80006b4e:	6402                	ld	s0,0(sp)
    80006b50:	0141                	addi	sp,sp,16
    80006b52:	8082                	ret

0000000080006b54 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006b54:	1101                	addi	sp,sp,-32
    80006b56:	ec22                	sd	s0,24(sp)
    80006b58:	1000                	addi	s0,sp,32
    80006b5a:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    80006b5c:	c299                	beqz	a3,80006b62 <sprintint+0xe>
    80006b5e:	0805c163          	bltz	a1,80006be0 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006b62:	2581                	sext.w	a1,a1
    80006b64:	4301                	li	t1,0

  i = 0;
    80006b66:	fe040713          	addi	a4,s0,-32
    80006b6a:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    80006b6c:	2601                	sext.w	a2,a2
    80006b6e:	00002697          	auipc	a3,0x2
    80006b72:	f8a68693          	addi	a3,a3,-118 # 80008af8 <digits>
    80006b76:	88aa                	mv	a7,a0
    80006b78:	2505                	addiw	a0,a0,1
    80006b7a:	02c5f7bb          	remuw	a5,a1,a2
    80006b7e:	1782                	slli	a5,a5,0x20
    80006b80:	9381                	srli	a5,a5,0x20
    80006b82:	97b6                	add	a5,a5,a3
    80006b84:	0007c783          	lbu	a5,0(a5)
    80006b88:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    80006b8c:	0005879b          	sext.w	a5,a1
    80006b90:	02c5d5bb          	divuw	a1,a1,a2
    80006b94:	0705                	addi	a4,a4,1
    80006b96:	fec7f0e3          	bgeu	a5,a2,80006b76 <sprintint+0x22>

  if(sign)
    80006b9a:	00030b63          	beqz	t1,80006bb0 <sprintint+0x5c>
    buf[i++] = '-';
    80006b9e:	ff040793          	addi	a5,s0,-16
    80006ba2:	97aa                	add	a5,a5,a0
    80006ba4:	02d00713          	li	a4,45
    80006ba8:	fee78823          	sb	a4,-16(a5)
    80006bac:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006bb0:	02a05c63          	blez	a0,80006be8 <sprintint+0x94>
    80006bb4:	fe040793          	addi	a5,s0,-32
    80006bb8:	00a78733          	add	a4,a5,a0
    80006bbc:	87c2                	mv	a5,a6
    80006bbe:	0805                	addi	a6,a6,1
    80006bc0:	fff5061b          	addiw	a2,a0,-1
    80006bc4:	1602                	slli	a2,a2,0x20
    80006bc6:	9201                	srli	a2,a2,0x20
    80006bc8:	9642                	add	a2,a2,a6
  *s = c;
    80006bca:	fff74683          	lbu	a3,-1(a4)
    80006bce:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006bd2:	177d                	addi	a4,a4,-1
    80006bd4:	0785                	addi	a5,a5,1
    80006bd6:	fec79ae3          	bne	a5,a2,80006bca <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006bda:	6462                	ld	s0,24(sp)
    80006bdc:	6105                	addi	sp,sp,32
    80006bde:	8082                	ret
    x = -xx;
    80006be0:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006be4:	4305                	li	t1,1
    x = -xx;
    80006be6:	b741                	j	80006b66 <sprintint+0x12>
  while(--i >= 0)
    80006be8:	4501                	li	a0,0
    80006bea:	bfc5                	j	80006bda <sprintint+0x86>

0000000080006bec <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006bec:	7171                	addi	sp,sp,-176
    80006bee:	fc86                	sd	ra,120(sp)
    80006bf0:	f8a2                	sd	s0,112(sp)
    80006bf2:	f4a6                	sd	s1,104(sp)
    80006bf4:	f0ca                	sd	s2,96(sp)
    80006bf6:	ecce                	sd	s3,88(sp)
    80006bf8:	e8d2                	sd	s4,80(sp)
    80006bfa:	e4d6                	sd	s5,72(sp)
    80006bfc:	e0da                	sd	s6,64(sp)
    80006bfe:	fc5e                	sd	s7,56(sp)
    80006c00:	f862                	sd	s8,48(sp)
    80006c02:	f466                	sd	s9,40(sp)
    80006c04:	f06a                	sd	s10,32(sp)
    80006c06:	ec6e                	sd	s11,24(sp)
    80006c08:	0100                	addi	s0,sp,128
    80006c0a:	e414                	sd	a3,8(s0)
    80006c0c:	e818                	sd	a4,16(s0)
    80006c0e:	ec1c                	sd	a5,24(s0)
    80006c10:	03043023          	sd	a6,32(s0)
    80006c14:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    80006c18:	ca0d                	beqz	a2,80006c4a <snprintf+0x5e>
    80006c1a:	8baa                	mv	s7,a0
    80006c1c:	89ae                	mv	s3,a1
    80006c1e:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006c20:	00840793          	addi	a5,s0,8
    80006c24:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    80006c28:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006c2a:	4901                	li	s2,0
    80006c2c:	02b05763          	blez	a1,80006c5a <snprintf+0x6e>
    if(c != '%'){
    80006c30:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006c34:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    80006c38:	02800d93          	li	s11,40
  *s = c;
    80006c3c:	02500d13          	li	s10,37
    switch(c){
    80006c40:	07800c93          	li	s9,120
    80006c44:	06400c13          	li	s8,100
    80006c48:	a01d                	j	80006c6e <snprintf+0x82>
    panic("null fmt");
    80006c4a:	00001517          	auipc	a0,0x1
    80006c4e:	3f650513          	addi	a0,a0,1014 # 80008040 <etext+0x40>
    80006c52:	ffffa097          	auipc	ra,0xffffa
    80006c56:	97e080e7          	jalr	-1666(ra) # 800005d0 <panic>
  int off = 0;
    80006c5a:	4481                	li	s1,0
    80006c5c:	a86d                	j	80006d16 <snprintf+0x12a>
  *s = c;
    80006c5e:	009b8733          	add	a4,s7,s1
    80006c62:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006c66:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006c68:	2905                	addiw	s2,s2,1
    80006c6a:	0b34d663          	bge	s1,s3,80006d16 <snprintf+0x12a>
    80006c6e:	012a07b3          	add	a5,s4,s2
    80006c72:	0007c783          	lbu	a5,0(a5)
    80006c76:	0007871b          	sext.w	a4,a5
    80006c7a:	cfd1                	beqz	a5,80006d16 <snprintf+0x12a>
    if(c != '%'){
    80006c7c:	ff5711e3          	bne	a4,s5,80006c5e <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006c80:	2905                	addiw	s2,s2,1
    80006c82:	012a07b3          	add	a5,s4,s2
    80006c86:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    80006c8a:	c7d1                	beqz	a5,80006d16 <snprintf+0x12a>
    switch(c){
    80006c8c:	05678c63          	beq	a5,s6,80006ce4 <snprintf+0xf8>
    80006c90:	02fb6763          	bltu	s6,a5,80006cbe <snprintf+0xd2>
    80006c94:	0b578763          	beq	a5,s5,80006d42 <snprintf+0x156>
    80006c98:	0b879b63          	bne	a5,s8,80006d4e <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    80006c9c:	f8843783          	ld	a5,-120(s0)
    80006ca0:	00878713          	addi	a4,a5,8
    80006ca4:	f8e43423          	sd	a4,-120(s0)
    80006ca8:	4685                	li	a3,1
    80006caa:	4629                	li	a2,10
    80006cac:	438c                	lw	a1,0(a5)
    80006cae:	009b8533          	add	a0,s7,s1
    80006cb2:	00000097          	auipc	ra,0x0
    80006cb6:	ea2080e7          	jalr	-350(ra) # 80006b54 <sprintint>
    80006cba:	9ca9                	addw	s1,s1,a0
      break;
    80006cbc:	b775                	j	80006c68 <snprintf+0x7c>
    switch(c){
    80006cbe:	09979863          	bne	a5,s9,80006d4e <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006cc2:	f8843783          	ld	a5,-120(s0)
    80006cc6:	00878713          	addi	a4,a5,8
    80006cca:	f8e43423          	sd	a4,-120(s0)
    80006cce:	4685                	li	a3,1
    80006cd0:	4641                	li	a2,16
    80006cd2:	438c                	lw	a1,0(a5)
    80006cd4:	009b8533          	add	a0,s7,s1
    80006cd8:	00000097          	auipc	ra,0x0
    80006cdc:	e7c080e7          	jalr	-388(ra) # 80006b54 <sprintint>
    80006ce0:	9ca9                	addw	s1,s1,a0
      break;
    80006ce2:	b759                	j	80006c68 <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006ce4:	f8843783          	ld	a5,-120(s0)
    80006ce8:	00878713          	addi	a4,a5,8
    80006cec:	f8e43423          	sd	a4,-120(s0)
    80006cf0:	639c                	ld	a5,0(a5)
    80006cf2:	c3b1                	beqz	a5,80006d36 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006cf4:	0007c703          	lbu	a4,0(a5)
    80006cf8:	db25                	beqz	a4,80006c68 <snprintf+0x7c>
    80006cfa:	0134de63          	bge	s1,s3,80006d16 <snprintf+0x12a>
    80006cfe:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006d02:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006d06:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006d08:	0785                	addi	a5,a5,1
    80006d0a:	0007c703          	lbu	a4,0(a5)
    80006d0e:	df29                	beqz	a4,80006c68 <snprintf+0x7c>
    80006d10:	0685                	addi	a3,a3,1
    80006d12:	fe9998e3          	bne	s3,s1,80006d02 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006d16:	8526                	mv	a0,s1
    80006d18:	70e6                	ld	ra,120(sp)
    80006d1a:	7446                	ld	s0,112(sp)
    80006d1c:	74a6                	ld	s1,104(sp)
    80006d1e:	7906                	ld	s2,96(sp)
    80006d20:	69e6                	ld	s3,88(sp)
    80006d22:	6a46                	ld	s4,80(sp)
    80006d24:	6aa6                	ld	s5,72(sp)
    80006d26:	6b06                	ld	s6,64(sp)
    80006d28:	7be2                	ld	s7,56(sp)
    80006d2a:	7c42                	ld	s8,48(sp)
    80006d2c:	7ca2                	ld	s9,40(sp)
    80006d2e:	7d02                	ld	s10,32(sp)
    80006d30:	6de2                	ld	s11,24(sp)
    80006d32:	614d                	addi	sp,sp,176
    80006d34:	8082                	ret
        s = "(null)";
    80006d36:	00001797          	auipc	a5,0x1
    80006d3a:	30278793          	addi	a5,a5,770 # 80008038 <etext+0x38>
      for(; *s && off < sz; s++)
    80006d3e:	876e                	mv	a4,s11
    80006d40:	bf6d                	j	80006cfa <snprintf+0x10e>
  *s = c;
    80006d42:	009b87b3          	add	a5,s7,s1
    80006d46:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006d4a:	2485                	addiw	s1,s1,1
      break;
    80006d4c:	bf31                	j	80006c68 <snprintf+0x7c>
  *s = c;
    80006d4e:	009b8733          	add	a4,s7,s1
    80006d52:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006d56:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006d5a:	975e                	add	a4,a4,s7
    80006d5c:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006d60:	2489                	addiw	s1,s1,2
      break;
    80006d62:	b719                	j	80006c68 <snprintf+0x7c>

0000000080006d64 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    80006d64:	7179                	addi	sp,sp,-48
    80006d66:	f406                	sd	ra,40(sp)
    80006d68:	f022                	sd	s0,32(sp)
    80006d6a:	ec26                	sd	s1,24(sp)
    80006d6c:	e84a                	sd	s2,16(sp)
    80006d6e:	e44e                	sd	s3,8(sp)
    80006d70:	e052                	sd	s4,0(sp)
    80006d72:	1800                	addi	s0,sp,48
    80006d74:	892a                	mv	s2,a0
    80006d76:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006d78:	00002a17          	auipc	s4,0x2
    80006d7c:	2b0a0a13          	addi	s4,s4,688 # 80009028 <stats>
    80006d80:	000a2683          	lw	a3,0(s4)
    80006d84:	00002617          	auipc	a2,0x2
    80006d88:	d8c60613          	addi	a2,a2,-628 # 80008b10 <digits+0x18>
    80006d8c:	00000097          	auipc	ra,0x0
    80006d90:	e60080e7          	jalr	-416(ra) # 80006bec <snprintf>
    80006d94:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    80006d96:	004a2683          	lw	a3,4(s4)
    80006d9a:	00002617          	auipc	a2,0x2
    80006d9e:	d8660613          	addi	a2,a2,-634 # 80008b20 <digits+0x28>
    80006da2:	85ce                	mv	a1,s3
    80006da4:	954a                	add	a0,a0,s2
    80006da6:	00000097          	auipc	ra,0x0
    80006daa:	e46080e7          	jalr	-442(ra) # 80006bec <snprintf>
  return n;
}
    80006dae:	9d25                	addw	a0,a0,s1
    80006db0:	70a2                	ld	ra,40(sp)
    80006db2:	7402                	ld	s0,32(sp)
    80006db4:	64e2                	ld	s1,24(sp)
    80006db6:	6942                	ld	s2,16(sp)
    80006db8:	69a2                	ld	s3,8(sp)
    80006dba:	6a02                	ld	s4,0(sp)
    80006dbc:	6145                	addi	sp,sp,48
    80006dbe:	8082                	ret

0000000080006dc0 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80006dc0:	7179                	addi	sp,sp,-48
    80006dc2:	f406                	sd	ra,40(sp)
    80006dc4:	f022                	sd	s0,32(sp)
    80006dc6:	ec26                	sd	s1,24(sp)
    80006dc8:	e84a                	sd	s2,16(sp)
    80006dca:	e44e                	sd	s3,8(sp)
    80006dcc:	1800                	addi	s0,sp,48
    80006dce:	89ae                	mv	s3,a1
    80006dd0:	84b2                	mv	s1,a2
    80006dd2:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006dd4:	ffffb097          	auipc	ra,0xffffb
    80006dd8:	06e080e7          	jalr	110(ra) # 80001e42 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    80006ddc:	653c                	ld	a5,72(a0)
    80006dde:	02f4ff63          	bgeu	s1,a5,80006e1c <copyin_new+0x5c>
    80006de2:	01248733          	add	a4,s1,s2
    80006de6:	02f77d63          	bgeu	a4,a5,80006e20 <copyin_new+0x60>
    80006dea:	02976d63          	bltu	a4,s1,80006e24 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    80006dee:	0009061b          	sext.w	a2,s2
    80006df2:	85a6                	mv	a1,s1
    80006df4:	854e                	mv	a0,s3
    80006df6:	ffffa097          	auipc	ra,0xffffa
    80006dfa:	01e080e7          	jalr	30(ra) # 80000e14 <memmove>
  stats.ncopyin++;   // XXX lock
    80006dfe:	00002717          	auipc	a4,0x2
    80006e02:	22a70713          	addi	a4,a4,554 # 80009028 <stats>
    80006e06:	431c                	lw	a5,0(a4)
    80006e08:	2785                	addiw	a5,a5,1
    80006e0a:	c31c                	sw	a5,0(a4)
  return 0;
    80006e0c:	4501                	li	a0,0
}
    80006e0e:	70a2                	ld	ra,40(sp)
    80006e10:	7402                	ld	s0,32(sp)
    80006e12:	64e2                	ld	s1,24(sp)
    80006e14:	6942                	ld	s2,16(sp)
    80006e16:	69a2                	ld	s3,8(sp)
    80006e18:	6145                	addi	sp,sp,48
    80006e1a:	8082                	ret
    return -1;
    80006e1c:	557d                	li	a0,-1
    80006e1e:	bfc5                	j	80006e0e <copyin_new+0x4e>
    80006e20:	557d                	li	a0,-1
    80006e22:	b7f5                	j	80006e0e <copyin_new+0x4e>
    80006e24:	557d                	li	a0,-1
    80006e26:	b7e5                	j	80006e0e <copyin_new+0x4e>

0000000080006e28 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006e28:	7179                	addi	sp,sp,-48
    80006e2a:	f406                	sd	ra,40(sp)
    80006e2c:	f022                	sd	s0,32(sp)
    80006e2e:	ec26                	sd	s1,24(sp)
    80006e30:	e84a                	sd	s2,16(sp)
    80006e32:	e44e                	sd	s3,8(sp)
    80006e34:	1800                	addi	s0,sp,48
    80006e36:	89ae                	mv	s3,a1
    80006e38:	8932                	mv	s2,a2
    80006e3a:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    80006e3c:	ffffb097          	auipc	ra,0xffffb
    80006e40:	006080e7          	jalr	6(ra) # 80001e42 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006e44:	00002717          	auipc	a4,0x2
    80006e48:	1e470713          	addi	a4,a4,484 # 80009028 <stats>
    80006e4c:	435c                	lw	a5,4(a4)
    80006e4e:	2785                	addiw	a5,a5,1
    80006e50:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006e52:	cc85                	beqz	s1,80006e8a <copyinstr_new+0x62>
    80006e54:	00990833          	add	a6,s2,s1
    80006e58:	87ca                	mv	a5,s2
    80006e5a:	6538                	ld	a4,72(a0)
    80006e5c:	00e7ff63          	bgeu	a5,a4,80006e7a <copyinstr_new+0x52>
    dst[i] = s[i];
    80006e60:	0007c683          	lbu	a3,0(a5)
    80006e64:	41278733          	sub	a4,a5,s2
    80006e68:	974e                	add	a4,a4,s3
    80006e6a:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    80006e6e:	c285                	beqz	a3,80006e8e <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006e70:	0785                	addi	a5,a5,1
    80006e72:	ff0794e3          	bne	a5,a6,80006e5a <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006e76:	557d                	li	a0,-1
    80006e78:	a011                	j	80006e7c <copyinstr_new+0x54>
    80006e7a:	557d                	li	a0,-1
}
    80006e7c:	70a2                	ld	ra,40(sp)
    80006e7e:	7402                	ld	s0,32(sp)
    80006e80:	64e2                	ld	s1,24(sp)
    80006e82:	6942                	ld	s2,16(sp)
    80006e84:	69a2                	ld	s3,8(sp)
    80006e86:	6145                	addi	sp,sp,48
    80006e88:	8082                	ret
  return -1;
    80006e8a:	557d                	li	a0,-1
    80006e8c:	bfc5                	j	80006e7c <copyinstr_new+0x54>
      return 0;
    80006e8e:	4501                	li	a0,0
    80006e90:	b7f5                	j	80006e7c <copyinstr_new+0x54>
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
