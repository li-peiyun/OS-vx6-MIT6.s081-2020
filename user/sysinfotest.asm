
user/_sysinfotest：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <sinfo>:
#include "kernel/sysinfo.h"
#include "user/user.h"


void
sinfo(struct sysinfo *info) {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
  if (sysinfo(info) < 0) {
   8:	00000097          	auipc	ra,0x0
   c:	656080e7          	jalr	1622(ra) # 65e <sysinfo>
  10:	00054663          	bltz	a0,1c <sinfo+0x1c>
    printf("FAIL: sysinfo failed");
    exit(1);
  }
}
  14:	60a2                	ld	ra,8(sp)
  16:	6402                	ld	s0,0(sp)
  18:	0141                	addi	sp,sp,16
  1a:	8082                	ret
    printf("FAIL: sysinfo failed");
  1c:	00001517          	auipc	a0,0x1
  20:	ad450513          	addi	a0,a0,-1324 # af0 <malloc+0xe4>
  24:	00001097          	auipc	ra,0x1
  28:	92a080e7          	jalr	-1750(ra) # 94e <printf>
    exit(1);
  2c:	4505                	li	a0,1
  2e:	00000097          	auipc	ra,0x0
  32:	588080e7          	jalr	1416(ra) # 5b6 <exit>

0000000000000036 <countfree>:
//
// use sbrk() to count how many free physical memory pages there are.
//
int
countfree()
{
  36:	7139                	addi	sp,sp,-64
  38:	fc06                	sd	ra,56(sp)
  3a:	f822                	sd	s0,48(sp)
  3c:	f426                	sd	s1,40(sp)
  3e:	f04a                	sd	s2,32(sp)
  40:	ec4e                	sd	s3,24(sp)
  42:	e852                	sd	s4,16(sp)
  44:	0080                	addi	s0,sp,64
  uint64 sz0 = (uint64)sbrk(0);
  46:	4501                	li	a0,0
  48:	00000097          	auipc	ra,0x0
  4c:	5f6080e7          	jalr	1526(ra) # 63e <sbrk>
  50:	8a2a                	mv	s4,a0
  struct sysinfo info;
  int n = 0;
  52:	4481                	li	s1,0

  while(1){
    if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  54:	597d                	li	s2,-1
      break;
    }
    n += PGSIZE;
  56:	6985                	lui	s3,0x1
    if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  58:	6505                	lui	a0,0x1
  5a:	00000097          	auipc	ra,0x0
  5e:	5e4080e7          	jalr	1508(ra) # 63e <sbrk>
  62:	01250563          	beq	a0,s2,6c <countfree+0x36>
    n += PGSIZE;
  66:	009984bb          	addw	s1,s3,s1
    if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  6a:	b7fd                	j	58 <countfree+0x22>
  }
  sinfo(&info);
  6c:	fc040513          	addi	a0,s0,-64
  70:	00000097          	auipc	ra,0x0
  74:	f90080e7          	jalr	-112(ra) # 0 <sinfo>
  if (info.freemem != 0) {
  78:	fc043583          	ld	a1,-64(s0)
  7c:	e58d                	bnez	a1,a6 <countfree+0x70>
    printf("FAIL: there is no free mem, but sysinfo.freemem=%d\n",
      info.freemem);
    exit(1);
  }
  sbrk(-((uint64)sbrk(0) - sz0));
  7e:	4501                	li	a0,0
  80:	00000097          	auipc	ra,0x0
  84:	5be080e7          	jalr	1470(ra) # 63e <sbrk>
  88:	40aa053b          	subw	a0,s4,a0
  8c:	00000097          	auipc	ra,0x0
  90:	5b2080e7          	jalr	1458(ra) # 63e <sbrk>
  return n;
}
  94:	8526                	mv	a0,s1
  96:	70e2                	ld	ra,56(sp)
  98:	7442                	ld	s0,48(sp)
  9a:	74a2                	ld	s1,40(sp)
  9c:	7902                	ld	s2,32(sp)
  9e:	69e2                	ld	s3,24(sp)
  a0:	6a42                	ld	s4,16(sp)
  a2:	6121                	addi	sp,sp,64
  a4:	8082                	ret
    printf("FAIL: there is no free mem, but sysinfo.freemem=%d\n",
  a6:	00001517          	auipc	a0,0x1
  aa:	a6250513          	addi	a0,a0,-1438 # b08 <malloc+0xfc>
  ae:	00001097          	auipc	ra,0x1
  b2:	8a0080e7          	jalr	-1888(ra) # 94e <printf>
    exit(1);
  b6:	4505                	li	a0,1
  b8:	00000097          	auipc	ra,0x0
  bc:	4fe080e7          	jalr	1278(ra) # 5b6 <exit>

00000000000000c0 <testmem>:

void
testmem() {
  c0:	7179                	addi	sp,sp,-48
  c2:	f406                	sd	ra,40(sp)
  c4:	f022                	sd	s0,32(sp)
  c6:	ec26                	sd	s1,24(sp)
  c8:	e84a                	sd	s2,16(sp)
  ca:	1800                	addi	s0,sp,48
  struct sysinfo info;
  uint64 n = countfree();
  cc:	00000097          	auipc	ra,0x0
  d0:	f6a080e7          	jalr	-150(ra) # 36 <countfree>
  d4:	84aa                	mv	s1,a0
  
  sinfo(&info);
  d6:	fd040513          	addi	a0,s0,-48
  da:	00000097          	auipc	ra,0x0
  de:	f26080e7          	jalr	-218(ra) # 0 <sinfo>

  if (info.freemem!= n) {
  e2:	fd043583          	ld	a1,-48(s0)
  e6:	04959e63          	bne	a1,s1,142 <testmem+0x82>
    printf("FAIL: free mem %d (bytes) instead of %d\n", info.freemem, n);
    exit(1);
  }
  
  if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  ea:	6505                	lui	a0,0x1
  ec:	00000097          	auipc	ra,0x0
  f0:	552080e7          	jalr	1362(ra) # 63e <sbrk>
  f4:	57fd                	li	a5,-1
  f6:	06f50463          	beq	a0,a5,15e <testmem+0x9e>
    printf("sbrk failed");
    exit(1);
  }

  sinfo(&info);
  fa:	fd040513          	addi	a0,s0,-48
  fe:	00000097          	auipc	ra,0x0
 102:	f02080e7          	jalr	-254(ra) # 0 <sinfo>
    
  if (info.freemem != n-PGSIZE) {
 106:	fd043603          	ld	a2,-48(s0)
 10a:	75fd                	lui	a1,0xfffff
 10c:	95a6                	add	a1,a1,s1
 10e:	06b61563          	bne	a2,a1,178 <testmem+0xb8>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n-PGSIZE, info.freemem);
    exit(1);
  }
  
  if((uint64)sbrk(-PGSIZE) == 0xffffffffffffffff){
 112:	757d                	lui	a0,0xfffff
 114:	00000097          	auipc	ra,0x0
 118:	52a080e7          	jalr	1322(ra) # 63e <sbrk>
 11c:	57fd                	li	a5,-1
 11e:	06f50a63          	beq	a0,a5,192 <testmem+0xd2>
    printf("sbrk failed");
    exit(1);
  }

  sinfo(&info);
 122:	fd040513          	addi	a0,s0,-48
 126:	00000097          	auipc	ra,0x0
 12a:	eda080e7          	jalr	-294(ra) # 0 <sinfo>
    
  if (info.freemem != n) {
 12e:	fd043603          	ld	a2,-48(s0)
 132:	06961d63          	bne	a2,s1,1ac <testmem+0xec>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n, info.freemem);
    exit(1);
  }
}
 136:	70a2                	ld	ra,40(sp)
 138:	7402                	ld	s0,32(sp)
 13a:	64e2                	ld	s1,24(sp)
 13c:	6942                	ld	s2,16(sp)
 13e:	6145                	addi	sp,sp,48
 140:	8082                	ret
    printf("FAIL: free mem %d (bytes) instead of %d\n", info.freemem, n);
 142:	8626                	mv	a2,s1
 144:	00001517          	auipc	a0,0x1
 148:	9fc50513          	addi	a0,a0,-1540 # b40 <malloc+0x134>
 14c:	00001097          	auipc	ra,0x1
 150:	802080e7          	jalr	-2046(ra) # 94e <printf>
    exit(1);
 154:	4505                	li	a0,1
 156:	00000097          	auipc	ra,0x0
 15a:	460080e7          	jalr	1120(ra) # 5b6 <exit>
    printf("sbrk failed");
 15e:	00001517          	auipc	a0,0x1
 162:	a1250513          	addi	a0,a0,-1518 # b70 <malloc+0x164>
 166:	00000097          	auipc	ra,0x0
 16a:	7e8080e7          	jalr	2024(ra) # 94e <printf>
    exit(1);
 16e:	4505                	li	a0,1
 170:	00000097          	auipc	ra,0x0
 174:	446080e7          	jalr	1094(ra) # 5b6 <exit>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n-PGSIZE, info.freemem);
 178:	00001517          	auipc	a0,0x1
 17c:	9c850513          	addi	a0,a0,-1592 # b40 <malloc+0x134>
 180:	00000097          	auipc	ra,0x0
 184:	7ce080e7          	jalr	1998(ra) # 94e <printf>
    exit(1);
 188:	4505                	li	a0,1
 18a:	00000097          	auipc	ra,0x0
 18e:	42c080e7          	jalr	1068(ra) # 5b6 <exit>
    printf("sbrk failed");
 192:	00001517          	auipc	a0,0x1
 196:	9de50513          	addi	a0,a0,-1570 # b70 <malloc+0x164>
 19a:	00000097          	auipc	ra,0x0
 19e:	7b4080e7          	jalr	1972(ra) # 94e <printf>
    exit(1);
 1a2:	4505                	li	a0,1
 1a4:	00000097          	auipc	ra,0x0
 1a8:	412080e7          	jalr	1042(ra) # 5b6 <exit>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n, info.freemem);
 1ac:	85a6                	mv	a1,s1
 1ae:	00001517          	auipc	a0,0x1
 1b2:	99250513          	addi	a0,a0,-1646 # b40 <malloc+0x134>
 1b6:	00000097          	auipc	ra,0x0
 1ba:	798080e7          	jalr	1944(ra) # 94e <printf>
    exit(1);
 1be:	4505                	li	a0,1
 1c0:	00000097          	auipc	ra,0x0
 1c4:	3f6080e7          	jalr	1014(ra) # 5b6 <exit>

00000000000001c8 <testcall>:

void
testcall() {
 1c8:	1101                	addi	sp,sp,-32
 1ca:	ec06                	sd	ra,24(sp)
 1cc:	e822                	sd	s0,16(sp)
 1ce:	1000                	addi	s0,sp,32
  struct sysinfo info;
  
  if (sysinfo(&info) < 0) {
 1d0:	fe040513          	addi	a0,s0,-32
 1d4:	00000097          	auipc	ra,0x0
 1d8:	48a080e7          	jalr	1162(ra) # 65e <sysinfo>
 1dc:	02054163          	bltz	a0,1fe <testcall+0x36>
    printf("FAIL: sysinfo failed\n");
    exit(1);
  }

  if (sysinfo((struct sysinfo *) 0xeaeb0b5b00002f5e) !=  0xffffffffffffffff) {
 1e0:	00001517          	auipc	a0,0x1
 1e4:	a8853503          	ld	a0,-1400(a0) # c68 <__SDATA_BEGIN__>
 1e8:	00000097          	auipc	ra,0x0
 1ec:	476080e7          	jalr	1142(ra) # 65e <sysinfo>
 1f0:	57fd                	li	a5,-1
 1f2:	02f51363          	bne	a0,a5,218 <testcall+0x50>
    printf("FAIL: sysinfo succeeded with bad argument\n");
    exit(1);
  }
}
 1f6:	60e2                	ld	ra,24(sp)
 1f8:	6442                	ld	s0,16(sp)
 1fa:	6105                	addi	sp,sp,32
 1fc:	8082                	ret
    printf("FAIL: sysinfo failed\n");
 1fe:	00001517          	auipc	a0,0x1
 202:	98250513          	addi	a0,a0,-1662 # b80 <malloc+0x174>
 206:	00000097          	auipc	ra,0x0
 20a:	748080e7          	jalr	1864(ra) # 94e <printf>
    exit(1);
 20e:	4505                	li	a0,1
 210:	00000097          	auipc	ra,0x0
 214:	3a6080e7          	jalr	934(ra) # 5b6 <exit>
    printf("FAIL: sysinfo succeeded with bad argument\n");
 218:	00001517          	auipc	a0,0x1
 21c:	98050513          	addi	a0,a0,-1664 # b98 <malloc+0x18c>
 220:	00000097          	auipc	ra,0x0
 224:	72e080e7          	jalr	1838(ra) # 94e <printf>
    exit(1);
 228:	4505                	li	a0,1
 22a:	00000097          	auipc	ra,0x0
 22e:	38c080e7          	jalr	908(ra) # 5b6 <exit>

0000000000000232 <testproc>:

void testproc() {
 232:	7139                	addi	sp,sp,-64
 234:	fc06                	sd	ra,56(sp)
 236:	f822                	sd	s0,48(sp)
 238:	f426                	sd	s1,40(sp)
 23a:	0080                	addi	s0,sp,64
  struct sysinfo info;
  uint64 nproc;
  int status;
  int pid;
  
  sinfo(&info);
 23c:	fd040513          	addi	a0,s0,-48
 240:	00000097          	auipc	ra,0x0
 244:	dc0080e7          	jalr	-576(ra) # 0 <sinfo>
  nproc = info.nproc;
 248:	fd843483          	ld	s1,-40(s0)

  pid = fork();
 24c:	00000097          	auipc	ra,0x0
 250:	362080e7          	jalr	866(ra) # 5ae <fork>
  if(pid < 0){
 254:	02054c63          	bltz	a0,28c <testproc+0x5a>
    printf("sysinfotest: fork failed\n");
    exit(1);
  }
  if(pid == 0){
 258:	ed21                	bnez	a0,2b0 <testproc+0x7e>
    sinfo(&info);
 25a:	fd040513          	addi	a0,s0,-48
 25e:	00000097          	auipc	ra,0x0
 262:	da2080e7          	jalr	-606(ra) # 0 <sinfo>
    if(info.nproc != nproc+1) {
 266:	fd843583          	ld	a1,-40(s0)
 26a:	00148613          	addi	a2,s1,1
 26e:	02c58c63          	beq	a1,a2,2a6 <testproc+0x74>
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc+1);
 272:	00001517          	auipc	a0,0x1
 276:	97650513          	addi	a0,a0,-1674 # be8 <malloc+0x1dc>
 27a:	00000097          	auipc	ra,0x0
 27e:	6d4080e7          	jalr	1748(ra) # 94e <printf>
      exit(1);
 282:	4505                	li	a0,1
 284:	00000097          	auipc	ra,0x0
 288:	332080e7          	jalr	818(ra) # 5b6 <exit>
    printf("sysinfotest: fork failed\n");
 28c:	00001517          	auipc	a0,0x1
 290:	93c50513          	addi	a0,a0,-1732 # bc8 <malloc+0x1bc>
 294:	00000097          	auipc	ra,0x0
 298:	6ba080e7          	jalr	1722(ra) # 94e <printf>
    exit(1);
 29c:	4505                	li	a0,1
 29e:	00000097          	auipc	ra,0x0
 2a2:	318080e7          	jalr	792(ra) # 5b6 <exit>
    }
    exit(0);
 2a6:	4501                	li	a0,0
 2a8:	00000097          	auipc	ra,0x0
 2ac:	30e080e7          	jalr	782(ra) # 5b6 <exit>
  }
  wait(&status);
 2b0:	fcc40513          	addi	a0,s0,-52
 2b4:	00000097          	auipc	ra,0x0
 2b8:	30a080e7          	jalr	778(ra) # 5be <wait>
  sinfo(&info);
 2bc:	fd040513          	addi	a0,s0,-48
 2c0:	00000097          	auipc	ra,0x0
 2c4:	d40080e7          	jalr	-704(ra) # 0 <sinfo>
  if(info.nproc != nproc) {
 2c8:	fd843583          	ld	a1,-40(s0)
 2cc:	00959763          	bne	a1,s1,2da <testproc+0xa8>
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc);
      exit(1);
  }
}
 2d0:	70e2                	ld	ra,56(sp)
 2d2:	7442                	ld	s0,48(sp)
 2d4:	74a2                	ld	s1,40(sp)
 2d6:	6121                	addi	sp,sp,64
 2d8:	8082                	ret
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc);
 2da:	8626                	mv	a2,s1
 2dc:	00001517          	auipc	a0,0x1
 2e0:	90c50513          	addi	a0,a0,-1780 # be8 <malloc+0x1dc>
 2e4:	00000097          	auipc	ra,0x0
 2e8:	66a080e7          	jalr	1642(ra) # 94e <printf>
      exit(1);
 2ec:	4505                	li	a0,1
 2ee:	00000097          	auipc	ra,0x0
 2f2:	2c8080e7          	jalr	712(ra) # 5b6 <exit>

00000000000002f6 <main>:

int
main(int argc, char *argv[])
{
 2f6:	1141                	addi	sp,sp,-16
 2f8:	e406                	sd	ra,8(sp)
 2fa:	e022                	sd	s0,0(sp)
 2fc:	0800                	addi	s0,sp,16
  printf("sysinfotest: start\n");
 2fe:	00001517          	auipc	a0,0x1
 302:	91a50513          	addi	a0,a0,-1766 # c18 <malloc+0x20c>
 306:	00000097          	auipc	ra,0x0
 30a:	648080e7          	jalr	1608(ra) # 94e <printf>
  testcall();
 30e:	00000097          	auipc	ra,0x0
 312:	eba080e7          	jalr	-326(ra) # 1c8 <testcall>
  testmem();
 316:	00000097          	auipc	ra,0x0
 31a:	daa080e7          	jalr	-598(ra) # c0 <testmem>
  testproc();
 31e:	00000097          	auipc	ra,0x0
 322:	f14080e7          	jalr	-236(ra) # 232 <testproc>
  printf("sysinfotest: OK\n");
 326:	00001517          	auipc	a0,0x1
 32a:	90a50513          	addi	a0,a0,-1782 # c30 <malloc+0x224>
 32e:	00000097          	auipc	ra,0x0
 332:	620080e7          	jalr	1568(ra) # 94e <printf>
  exit(0);
 336:	4501                	li	a0,0
 338:	00000097          	auipc	ra,0x0
 33c:	27e080e7          	jalr	638(ra) # 5b6 <exit>

0000000000000340 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 340:	1141                	addi	sp,sp,-16
 342:	e422                	sd	s0,8(sp)
 344:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 346:	87aa                	mv	a5,a0
 348:	0585                	addi	a1,a1,1
 34a:	0785                	addi	a5,a5,1
 34c:	fff5c703          	lbu	a4,-1(a1) # ffffffffffffefff <__global_pointer$+0xffffffffffffdb9e>
 350:	fee78fa3          	sb	a4,-1(a5)
 354:	fb75                	bnez	a4,348 <strcpy+0x8>
    ;
  return os;
}
 356:	6422                	ld	s0,8(sp)
 358:	0141                	addi	sp,sp,16
 35a:	8082                	ret

000000000000035c <strcmp>:

int
strcmp(const char *p, const char *q)
{
 35c:	1141                	addi	sp,sp,-16
 35e:	e422                	sd	s0,8(sp)
 360:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 362:	00054783          	lbu	a5,0(a0)
 366:	cb91                	beqz	a5,37a <strcmp+0x1e>
 368:	0005c703          	lbu	a4,0(a1)
 36c:	00f71763          	bne	a4,a5,37a <strcmp+0x1e>
    p++, q++;
 370:	0505                	addi	a0,a0,1
 372:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 374:	00054783          	lbu	a5,0(a0)
 378:	fbe5                	bnez	a5,368 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 37a:	0005c503          	lbu	a0,0(a1)
}
 37e:	40a7853b          	subw	a0,a5,a0
 382:	6422                	ld	s0,8(sp)
 384:	0141                	addi	sp,sp,16
 386:	8082                	ret

0000000000000388 <strlen>:

uint
strlen(const char *s)
{
 388:	1141                	addi	sp,sp,-16
 38a:	e422                	sd	s0,8(sp)
 38c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 38e:	00054783          	lbu	a5,0(a0)
 392:	cf91                	beqz	a5,3ae <strlen+0x26>
 394:	0505                	addi	a0,a0,1
 396:	87aa                	mv	a5,a0
 398:	4685                	li	a3,1
 39a:	9e89                	subw	a3,a3,a0
 39c:	00f6853b          	addw	a0,a3,a5
 3a0:	0785                	addi	a5,a5,1
 3a2:	fff7c703          	lbu	a4,-1(a5)
 3a6:	fb7d                	bnez	a4,39c <strlen+0x14>
    ;
  return n;
}
 3a8:	6422                	ld	s0,8(sp)
 3aa:	0141                	addi	sp,sp,16
 3ac:	8082                	ret
  for(n = 0; s[n]; n++)
 3ae:	4501                	li	a0,0
 3b0:	bfe5                	j	3a8 <strlen+0x20>

00000000000003b2 <memset>:

void*
memset(void *dst, int c, uint n)
{
 3b2:	1141                	addi	sp,sp,-16
 3b4:	e422                	sd	s0,8(sp)
 3b6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 3b8:	ce09                	beqz	a2,3d2 <memset+0x20>
 3ba:	87aa                	mv	a5,a0
 3bc:	fff6071b          	addiw	a4,a2,-1
 3c0:	1702                	slli	a4,a4,0x20
 3c2:	9301                	srli	a4,a4,0x20
 3c4:	0705                	addi	a4,a4,1
 3c6:	972a                	add	a4,a4,a0
    cdst[i] = c;
 3c8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 3cc:	0785                	addi	a5,a5,1
 3ce:	fee79de3          	bne	a5,a4,3c8 <memset+0x16>
  }
  return dst;
}
 3d2:	6422                	ld	s0,8(sp)
 3d4:	0141                	addi	sp,sp,16
 3d6:	8082                	ret

00000000000003d8 <strchr>:

char*
strchr(const char *s, char c)
{
 3d8:	1141                	addi	sp,sp,-16
 3da:	e422                	sd	s0,8(sp)
 3dc:	0800                	addi	s0,sp,16
  for(; *s; s++)
 3de:	00054783          	lbu	a5,0(a0)
 3e2:	cb99                	beqz	a5,3f8 <strchr+0x20>
    if(*s == c)
 3e4:	00f58763          	beq	a1,a5,3f2 <strchr+0x1a>
  for(; *s; s++)
 3e8:	0505                	addi	a0,a0,1
 3ea:	00054783          	lbu	a5,0(a0)
 3ee:	fbfd                	bnez	a5,3e4 <strchr+0xc>
      return (char*)s;
  return 0;
 3f0:	4501                	li	a0,0
}
 3f2:	6422                	ld	s0,8(sp)
 3f4:	0141                	addi	sp,sp,16
 3f6:	8082                	ret
  return 0;
 3f8:	4501                	li	a0,0
 3fa:	bfe5                	j	3f2 <strchr+0x1a>

00000000000003fc <gets>:

char*
gets(char *buf, int max)
{
 3fc:	711d                	addi	sp,sp,-96
 3fe:	ec86                	sd	ra,88(sp)
 400:	e8a2                	sd	s0,80(sp)
 402:	e4a6                	sd	s1,72(sp)
 404:	e0ca                	sd	s2,64(sp)
 406:	fc4e                	sd	s3,56(sp)
 408:	f852                	sd	s4,48(sp)
 40a:	f456                	sd	s5,40(sp)
 40c:	f05a                	sd	s6,32(sp)
 40e:	ec5e                	sd	s7,24(sp)
 410:	1080                	addi	s0,sp,96
 412:	8baa                	mv	s7,a0
 414:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 416:	892a                	mv	s2,a0
 418:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 41a:	4aa9                	li	s5,10
 41c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 41e:	89a6                	mv	s3,s1
 420:	2485                	addiw	s1,s1,1
 422:	0344d863          	bge	s1,s4,452 <gets+0x56>
    cc = read(0, &c, 1);
 426:	4605                	li	a2,1
 428:	faf40593          	addi	a1,s0,-81
 42c:	4501                	li	a0,0
 42e:	00000097          	auipc	ra,0x0
 432:	1a0080e7          	jalr	416(ra) # 5ce <read>
    if(cc < 1)
 436:	00a05e63          	blez	a0,452 <gets+0x56>
    buf[i++] = c;
 43a:	faf44783          	lbu	a5,-81(s0)
 43e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 442:	01578763          	beq	a5,s5,450 <gets+0x54>
 446:	0905                	addi	s2,s2,1
 448:	fd679be3          	bne	a5,s6,41e <gets+0x22>
  for(i=0; i+1 < max; ){
 44c:	89a6                	mv	s3,s1
 44e:	a011                	j	452 <gets+0x56>
 450:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 452:	99de                	add	s3,s3,s7
 454:	00098023          	sb	zero,0(s3) # 1000 <__BSS_END__+0x378>
  return buf;
}
 458:	855e                	mv	a0,s7
 45a:	60e6                	ld	ra,88(sp)
 45c:	6446                	ld	s0,80(sp)
 45e:	64a6                	ld	s1,72(sp)
 460:	6906                	ld	s2,64(sp)
 462:	79e2                	ld	s3,56(sp)
 464:	7a42                	ld	s4,48(sp)
 466:	7aa2                	ld	s5,40(sp)
 468:	7b02                	ld	s6,32(sp)
 46a:	6be2                	ld	s7,24(sp)
 46c:	6125                	addi	sp,sp,96
 46e:	8082                	ret

0000000000000470 <stat>:

int
stat(const char *n, struct stat *st)
{
 470:	1101                	addi	sp,sp,-32
 472:	ec06                	sd	ra,24(sp)
 474:	e822                	sd	s0,16(sp)
 476:	e426                	sd	s1,8(sp)
 478:	e04a                	sd	s2,0(sp)
 47a:	1000                	addi	s0,sp,32
 47c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 47e:	4581                	li	a1,0
 480:	00000097          	auipc	ra,0x0
 484:	176080e7          	jalr	374(ra) # 5f6 <open>
  if(fd < 0)
 488:	02054563          	bltz	a0,4b2 <stat+0x42>
 48c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 48e:	85ca                	mv	a1,s2
 490:	00000097          	auipc	ra,0x0
 494:	17e080e7          	jalr	382(ra) # 60e <fstat>
 498:	892a                	mv	s2,a0
  close(fd);
 49a:	8526                	mv	a0,s1
 49c:	00000097          	auipc	ra,0x0
 4a0:	142080e7          	jalr	322(ra) # 5de <close>
  return r;
}
 4a4:	854a                	mv	a0,s2
 4a6:	60e2                	ld	ra,24(sp)
 4a8:	6442                	ld	s0,16(sp)
 4aa:	64a2                	ld	s1,8(sp)
 4ac:	6902                	ld	s2,0(sp)
 4ae:	6105                	addi	sp,sp,32
 4b0:	8082                	ret
    return -1;
 4b2:	597d                	li	s2,-1
 4b4:	bfc5                	j	4a4 <stat+0x34>

00000000000004b6 <atoi>:

int
atoi(const char *s)
{
 4b6:	1141                	addi	sp,sp,-16
 4b8:	e422                	sd	s0,8(sp)
 4ba:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 4bc:	00054603          	lbu	a2,0(a0)
 4c0:	fd06079b          	addiw	a5,a2,-48
 4c4:	0ff7f793          	andi	a5,a5,255
 4c8:	4725                	li	a4,9
 4ca:	02f76963          	bltu	a4,a5,4fc <atoi+0x46>
 4ce:	86aa                	mv	a3,a0
  n = 0;
 4d0:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 4d2:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 4d4:	0685                	addi	a3,a3,1
 4d6:	0025179b          	slliw	a5,a0,0x2
 4da:	9fa9                	addw	a5,a5,a0
 4dc:	0017979b          	slliw	a5,a5,0x1
 4e0:	9fb1                	addw	a5,a5,a2
 4e2:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 4e6:	0006c603          	lbu	a2,0(a3)
 4ea:	fd06071b          	addiw	a4,a2,-48
 4ee:	0ff77713          	andi	a4,a4,255
 4f2:	fee5f1e3          	bgeu	a1,a4,4d4 <atoi+0x1e>
  return n;
}
 4f6:	6422                	ld	s0,8(sp)
 4f8:	0141                	addi	sp,sp,16
 4fa:	8082                	ret
  n = 0;
 4fc:	4501                	li	a0,0
 4fe:	bfe5                	j	4f6 <atoi+0x40>

0000000000000500 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 500:	1141                	addi	sp,sp,-16
 502:	e422                	sd	s0,8(sp)
 504:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 506:	02b57663          	bgeu	a0,a1,532 <memmove+0x32>
    while(n-- > 0)
 50a:	02c05163          	blez	a2,52c <memmove+0x2c>
 50e:	fff6079b          	addiw	a5,a2,-1
 512:	1782                	slli	a5,a5,0x20
 514:	9381                	srli	a5,a5,0x20
 516:	0785                	addi	a5,a5,1
 518:	97aa                	add	a5,a5,a0
  dst = vdst;
 51a:	872a                	mv	a4,a0
      *dst++ = *src++;
 51c:	0585                	addi	a1,a1,1
 51e:	0705                	addi	a4,a4,1
 520:	fff5c683          	lbu	a3,-1(a1)
 524:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 528:	fee79ae3          	bne	a5,a4,51c <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 52c:	6422                	ld	s0,8(sp)
 52e:	0141                	addi	sp,sp,16
 530:	8082                	ret
    dst += n;
 532:	00c50733          	add	a4,a0,a2
    src += n;
 536:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 538:	fec05ae3          	blez	a2,52c <memmove+0x2c>
 53c:	fff6079b          	addiw	a5,a2,-1
 540:	1782                	slli	a5,a5,0x20
 542:	9381                	srli	a5,a5,0x20
 544:	fff7c793          	not	a5,a5
 548:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 54a:	15fd                	addi	a1,a1,-1
 54c:	177d                	addi	a4,a4,-1
 54e:	0005c683          	lbu	a3,0(a1)
 552:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 556:	fee79ae3          	bne	a5,a4,54a <memmove+0x4a>
 55a:	bfc9                	j	52c <memmove+0x2c>

000000000000055c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 55c:	1141                	addi	sp,sp,-16
 55e:	e422                	sd	s0,8(sp)
 560:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 562:	ca05                	beqz	a2,592 <memcmp+0x36>
 564:	fff6069b          	addiw	a3,a2,-1
 568:	1682                	slli	a3,a3,0x20
 56a:	9281                	srli	a3,a3,0x20
 56c:	0685                	addi	a3,a3,1
 56e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 570:	00054783          	lbu	a5,0(a0)
 574:	0005c703          	lbu	a4,0(a1)
 578:	00e79863          	bne	a5,a4,588 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 57c:	0505                	addi	a0,a0,1
    p2++;
 57e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 580:	fed518e3          	bne	a0,a3,570 <memcmp+0x14>
  }
  return 0;
 584:	4501                	li	a0,0
 586:	a019                	j	58c <memcmp+0x30>
      return *p1 - *p2;
 588:	40e7853b          	subw	a0,a5,a4
}
 58c:	6422                	ld	s0,8(sp)
 58e:	0141                	addi	sp,sp,16
 590:	8082                	ret
  return 0;
 592:	4501                	li	a0,0
 594:	bfe5                	j	58c <memcmp+0x30>

0000000000000596 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 596:	1141                	addi	sp,sp,-16
 598:	e406                	sd	ra,8(sp)
 59a:	e022                	sd	s0,0(sp)
 59c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 59e:	00000097          	auipc	ra,0x0
 5a2:	f62080e7          	jalr	-158(ra) # 500 <memmove>
}
 5a6:	60a2                	ld	ra,8(sp)
 5a8:	6402                	ld	s0,0(sp)
 5aa:	0141                	addi	sp,sp,16
 5ac:	8082                	ret

00000000000005ae <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 5ae:	4885                	li	a7,1
 ecall
 5b0:	00000073          	ecall
 ret
 5b4:	8082                	ret

00000000000005b6 <exit>:
.global exit
exit:
 li a7, SYS_exit
 5b6:	4889                	li	a7,2
 ecall
 5b8:	00000073          	ecall
 ret
 5bc:	8082                	ret

00000000000005be <wait>:
.global wait
wait:
 li a7, SYS_wait
 5be:	488d                	li	a7,3
 ecall
 5c0:	00000073          	ecall
 ret
 5c4:	8082                	ret

00000000000005c6 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 5c6:	4891                	li	a7,4
 ecall
 5c8:	00000073          	ecall
 ret
 5cc:	8082                	ret

00000000000005ce <read>:
.global read
read:
 li a7, SYS_read
 5ce:	4895                	li	a7,5
 ecall
 5d0:	00000073          	ecall
 ret
 5d4:	8082                	ret

00000000000005d6 <write>:
.global write
write:
 li a7, SYS_write
 5d6:	48c1                	li	a7,16
 ecall
 5d8:	00000073          	ecall
 ret
 5dc:	8082                	ret

00000000000005de <close>:
.global close
close:
 li a7, SYS_close
 5de:	48d5                	li	a7,21
 ecall
 5e0:	00000073          	ecall
 ret
 5e4:	8082                	ret

00000000000005e6 <kill>:
.global kill
kill:
 li a7, SYS_kill
 5e6:	4899                	li	a7,6
 ecall
 5e8:	00000073          	ecall
 ret
 5ec:	8082                	ret

00000000000005ee <exec>:
.global exec
exec:
 li a7, SYS_exec
 5ee:	489d                	li	a7,7
 ecall
 5f0:	00000073          	ecall
 ret
 5f4:	8082                	ret

00000000000005f6 <open>:
.global open
open:
 li a7, SYS_open
 5f6:	48bd                	li	a7,15
 ecall
 5f8:	00000073          	ecall
 ret
 5fc:	8082                	ret

00000000000005fe <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 5fe:	48c5                	li	a7,17
 ecall
 600:	00000073          	ecall
 ret
 604:	8082                	ret

0000000000000606 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 606:	48c9                	li	a7,18
 ecall
 608:	00000073          	ecall
 ret
 60c:	8082                	ret

000000000000060e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 60e:	48a1                	li	a7,8
 ecall
 610:	00000073          	ecall
 ret
 614:	8082                	ret

0000000000000616 <link>:
.global link
link:
 li a7, SYS_link
 616:	48cd                	li	a7,19
 ecall
 618:	00000073          	ecall
 ret
 61c:	8082                	ret

000000000000061e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 61e:	48d1                	li	a7,20
 ecall
 620:	00000073          	ecall
 ret
 624:	8082                	ret

0000000000000626 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 626:	48a5                	li	a7,9
 ecall
 628:	00000073          	ecall
 ret
 62c:	8082                	ret

000000000000062e <dup>:
.global dup
dup:
 li a7, SYS_dup
 62e:	48a9                	li	a7,10
 ecall
 630:	00000073          	ecall
 ret
 634:	8082                	ret

0000000000000636 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 636:	48ad                	li	a7,11
 ecall
 638:	00000073          	ecall
 ret
 63c:	8082                	ret

000000000000063e <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 63e:	48b1                	li	a7,12
 ecall
 640:	00000073          	ecall
 ret
 644:	8082                	ret

0000000000000646 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 646:	48b5                	li	a7,13
 ecall
 648:	00000073          	ecall
 ret
 64c:	8082                	ret

000000000000064e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 64e:	48b9                	li	a7,14
 ecall
 650:	00000073          	ecall
 ret
 654:	8082                	ret

0000000000000656 <trace>:
.global trace
trace:
 li a7, SYS_trace
 656:	48d9                	li	a7,22
 ecall
 658:	00000073          	ecall
 ret
 65c:	8082                	ret

000000000000065e <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 65e:	48dd                	li	a7,23
 ecall
 660:	00000073          	ecall
 ret
 664:	8082                	ret

0000000000000666 <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 666:	48e1                	li	a7,24
 ecall
 668:	00000073          	ecall
 ret
 66c:	8082                	ret

000000000000066e <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 66e:	48e5                	li	a7,25
 ecall
 670:	00000073          	ecall
 ret
 674:	8082                	ret

0000000000000676 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 676:	1101                	addi	sp,sp,-32
 678:	ec06                	sd	ra,24(sp)
 67a:	e822                	sd	s0,16(sp)
 67c:	1000                	addi	s0,sp,32
 67e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 682:	4605                	li	a2,1
 684:	fef40593          	addi	a1,s0,-17
 688:	00000097          	auipc	ra,0x0
 68c:	f4e080e7          	jalr	-178(ra) # 5d6 <write>
}
 690:	60e2                	ld	ra,24(sp)
 692:	6442                	ld	s0,16(sp)
 694:	6105                	addi	sp,sp,32
 696:	8082                	ret

0000000000000698 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 698:	7139                	addi	sp,sp,-64
 69a:	fc06                	sd	ra,56(sp)
 69c:	f822                	sd	s0,48(sp)
 69e:	f426                	sd	s1,40(sp)
 6a0:	f04a                	sd	s2,32(sp)
 6a2:	ec4e                	sd	s3,24(sp)
 6a4:	0080                	addi	s0,sp,64
 6a6:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 6a8:	c299                	beqz	a3,6ae <printint+0x16>
 6aa:	0805c863          	bltz	a1,73a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 6ae:	2581                	sext.w	a1,a1
  neg = 0;
 6b0:	4881                	li	a7,0
 6b2:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 6b6:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 6b8:	2601                	sext.w	a2,a2
 6ba:	00000517          	auipc	a0,0x0
 6be:	59650513          	addi	a0,a0,1430 # c50 <digits>
 6c2:	883a                	mv	a6,a4
 6c4:	2705                	addiw	a4,a4,1
 6c6:	02c5f7bb          	remuw	a5,a1,a2
 6ca:	1782                	slli	a5,a5,0x20
 6cc:	9381                	srli	a5,a5,0x20
 6ce:	97aa                	add	a5,a5,a0
 6d0:	0007c783          	lbu	a5,0(a5)
 6d4:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 6d8:	0005879b          	sext.w	a5,a1
 6dc:	02c5d5bb          	divuw	a1,a1,a2
 6e0:	0685                	addi	a3,a3,1
 6e2:	fec7f0e3          	bgeu	a5,a2,6c2 <printint+0x2a>
  if(neg)
 6e6:	00088b63          	beqz	a7,6fc <printint+0x64>
    buf[i++] = '-';
 6ea:	fd040793          	addi	a5,s0,-48
 6ee:	973e                	add	a4,a4,a5
 6f0:	02d00793          	li	a5,45
 6f4:	fef70823          	sb	a5,-16(a4)
 6f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 6fc:	02e05863          	blez	a4,72c <printint+0x94>
 700:	fc040793          	addi	a5,s0,-64
 704:	00e78933          	add	s2,a5,a4
 708:	fff78993          	addi	s3,a5,-1
 70c:	99ba                	add	s3,s3,a4
 70e:	377d                	addiw	a4,a4,-1
 710:	1702                	slli	a4,a4,0x20
 712:	9301                	srli	a4,a4,0x20
 714:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 718:	fff94583          	lbu	a1,-1(s2)
 71c:	8526                	mv	a0,s1
 71e:	00000097          	auipc	ra,0x0
 722:	f58080e7          	jalr	-168(ra) # 676 <putc>
  while(--i >= 0)
 726:	197d                	addi	s2,s2,-1
 728:	ff3918e3          	bne	s2,s3,718 <printint+0x80>
}
 72c:	70e2                	ld	ra,56(sp)
 72e:	7442                	ld	s0,48(sp)
 730:	74a2                	ld	s1,40(sp)
 732:	7902                	ld	s2,32(sp)
 734:	69e2                	ld	s3,24(sp)
 736:	6121                	addi	sp,sp,64
 738:	8082                	ret
    x = -xx;
 73a:	40b005bb          	negw	a1,a1
    neg = 1;
 73e:	4885                	li	a7,1
    x = -xx;
 740:	bf8d                	j	6b2 <printint+0x1a>

0000000000000742 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 742:	7119                	addi	sp,sp,-128
 744:	fc86                	sd	ra,120(sp)
 746:	f8a2                	sd	s0,112(sp)
 748:	f4a6                	sd	s1,104(sp)
 74a:	f0ca                	sd	s2,96(sp)
 74c:	ecce                	sd	s3,88(sp)
 74e:	e8d2                	sd	s4,80(sp)
 750:	e4d6                	sd	s5,72(sp)
 752:	e0da                	sd	s6,64(sp)
 754:	fc5e                	sd	s7,56(sp)
 756:	f862                	sd	s8,48(sp)
 758:	f466                	sd	s9,40(sp)
 75a:	f06a                	sd	s10,32(sp)
 75c:	ec6e                	sd	s11,24(sp)
 75e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 760:	0005c903          	lbu	s2,0(a1)
 764:	18090f63          	beqz	s2,902 <vprintf+0x1c0>
 768:	8aaa                	mv	s5,a0
 76a:	8b32                	mv	s6,a2
 76c:	00158493          	addi	s1,a1,1
  state = 0;
 770:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 772:	02500a13          	li	s4,37
      if(c == 'd'){
 776:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 77a:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 77e:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 782:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 786:	00000b97          	auipc	s7,0x0
 78a:	4cab8b93          	addi	s7,s7,1226 # c50 <digits>
 78e:	a839                	j	7ac <vprintf+0x6a>
        putc(fd, c);
 790:	85ca                	mv	a1,s2
 792:	8556                	mv	a0,s5
 794:	00000097          	auipc	ra,0x0
 798:	ee2080e7          	jalr	-286(ra) # 676 <putc>
 79c:	a019                	j	7a2 <vprintf+0x60>
    } else if(state == '%'){
 79e:	01498f63          	beq	s3,s4,7bc <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 7a2:	0485                	addi	s1,s1,1
 7a4:	fff4c903          	lbu	s2,-1(s1)
 7a8:	14090d63          	beqz	s2,902 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 7ac:	0009079b          	sext.w	a5,s2
    if(state == 0){
 7b0:	fe0997e3          	bnez	s3,79e <vprintf+0x5c>
      if(c == '%'){
 7b4:	fd479ee3          	bne	a5,s4,790 <vprintf+0x4e>
        state = '%';
 7b8:	89be                	mv	s3,a5
 7ba:	b7e5                	j	7a2 <vprintf+0x60>
      if(c == 'd'){
 7bc:	05878063          	beq	a5,s8,7fc <vprintf+0xba>
      } else if(c == 'l') {
 7c0:	05978c63          	beq	a5,s9,818 <vprintf+0xd6>
      } else if(c == 'x') {
 7c4:	07a78863          	beq	a5,s10,834 <vprintf+0xf2>
      } else if(c == 'p') {
 7c8:	09b78463          	beq	a5,s11,850 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 7cc:	07300713          	li	a4,115
 7d0:	0ce78663          	beq	a5,a4,89c <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 7d4:	06300713          	li	a4,99
 7d8:	0ee78e63          	beq	a5,a4,8d4 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 7dc:	11478863          	beq	a5,s4,8ec <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 7e0:	85d2                	mv	a1,s4
 7e2:	8556                	mv	a0,s5
 7e4:	00000097          	auipc	ra,0x0
 7e8:	e92080e7          	jalr	-366(ra) # 676 <putc>
        putc(fd, c);
 7ec:	85ca                	mv	a1,s2
 7ee:	8556                	mv	a0,s5
 7f0:	00000097          	auipc	ra,0x0
 7f4:	e86080e7          	jalr	-378(ra) # 676 <putc>
      }
      state = 0;
 7f8:	4981                	li	s3,0
 7fa:	b765                	j	7a2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 7fc:	008b0913          	addi	s2,s6,8
 800:	4685                	li	a3,1
 802:	4629                	li	a2,10
 804:	000b2583          	lw	a1,0(s6)
 808:	8556                	mv	a0,s5
 80a:	00000097          	auipc	ra,0x0
 80e:	e8e080e7          	jalr	-370(ra) # 698 <printint>
 812:	8b4a                	mv	s6,s2
      state = 0;
 814:	4981                	li	s3,0
 816:	b771                	j	7a2 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 818:	008b0913          	addi	s2,s6,8
 81c:	4681                	li	a3,0
 81e:	4629                	li	a2,10
 820:	000b2583          	lw	a1,0(s6)
 824:	8556                	mv	a0,s5
 826:	00000097          	auipc	ra,0x0
 82a:	e72080e7          	jalr	-398(ra) # 698 <printint>
 82e:	8b4a                	mv	s6,s2
      state = 0;
 830:	4981                	li	s3,0
 832:	bf85                	j	7a2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 834:	008b0913          	addi	s2,s6,8
 838:	4681                	li	a3,0
 83a:	4641                	li	a2,16
 83c:	000b2583          	lw	a1,0(s6)
 840:	8556                	mv	a0,s5
 842:	00000097          	auipc	ra,0x0
 846:	e56080e7          	jalr	-426(ra) # 698 <printint>
 84a:	8b4a                	mv	s6,s2
      state = 0;
 84c:	4981                	li	s3,0
 84e:	bf91                	j	7a2 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 850:	008b0793          	addi	a5,s6,8
 854:	f8f43423          	sd	a5,-120(s0)
 858:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 85c:	03000593          	li	a1,48
 860:	8556                	mv	a0,s5
 862:	00000097          	auipc	ra,0x0
 866:	e14080e7          	jalr	-492(ra) # 676 <putc>
  putc(fd, 'x');
 86a:	85ea                	mv	a1,s10
 86c:	8556                	mv	a0,s5
 86e:	00000097          	auipc	ra,0x0
 872:	e08080e7          	jalr	-504(ra) # 676 <putc>
 876:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 878:	03c9d793          	srli	a5,s3,0x3c
 87c:	97de                	add	a5,a5,s7
 87e:	0007c583          	lbu	a1,0(a5)
 882:	8556                	mv	a0,s5
 884:	00000097          	auipc	ra,0x0
 888:	df2080e7          	jalr	-526(ra) # 676 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 88c:	0992                	slli	s3,s3,0x4
 88e:	397d                	addiw	s2,s2,-1
 890:	fe0914e3          	bnez	s2,878 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 894:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 898:	4981                	li	s3,0
 89a:	b721                	j	7a2 <vprintf+0x60>
        s = va_arg(ap, char*);
 89c:	008b0993          	addi	s3,s6,8
 8a0:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 8a4:	02090163          	beqz	s2,8c6 <vprintf+0x184>
        while(*s != 0){
 8a8:	00094583          	lbu	a1,0(s2)
 8ac:	c9a1                	beqz	a1,8fc <vprintf+0x1ba>
          putc(fd, *s);
 8ae:	8556                	mv	a0,s5
 8b0:	00000097          	auipc	ra,0x0
 8b4:	dc6080e7          	jalr	-570(ra) # 676 <putc>
          s++;
 8b8:	0905                	addi	s2,s2,1
        while(*s != 0){
 8ba:	00094583          	lbu	a1,0(s2)
 8be:	f9e5                	bnez	a1,8ae <vprintf+0x16c>
        s = va_arg(ap, char*);
 8c0:	8b4e                	mv	s6,s3
      state = 0;
 8c2:	4981                	li	s3,0
 8c4:	bdf9                	j	7a2 <vprintf+0x60>
          s = "(null)";
 8c6:	00000917          	auipc	s2,0x0
 8ca:	38290913          	addi	s2,s2,898 # c48 <malloc+0x23c>
        while(*s != 0){
 8ce:	02800593          	li	a1,40
 8d2:	bff1                	j	8ae <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 8d4:	008b0913          	addi	s2,s6,8
 8d8:	000b4583          	lbu	a1,0(s6)
 8dc:	8556                	mv	a0,s5
 8de:	00000097          	auipc	ra,0x0
 8e2:	d98080e7          	jalr	-616(ra) # 676 <putc>
 8e6:	8b4a                	mv	s6,s2
      state = 0;
 8e8:	4981                	li	s3,0
 8ea:	bd65                	j	7a2 <vprintf+0x60>
        putc(fd, c);
 8ec:	85d2                	mv	a1,s4
 8ee:	8556                	mv	a0,s5
 8f0:	00000097          	auipc	ra,0x0
 8f4:	d86080e7          	jalr	-634(ra) # 676 <putc>
      state = 0;
 8f8:	4981                	li	s3,0
 8fa:	b565                	j	7a2 <vprintf+0x60>
        s = va_arg(ap, char*);
 8fc:	8b4e                	mv	s6,s3
      state = 0;
 8fe:	4981                	li	s3,0
 900:	b54d                	j	7a2 <vprintf+0x60>
    }
  }
}
 902:	70e6                	ld	ra,120(sp)
 904:	7446                	ld	s0,112(sp)
 906:	74a6                	ld	s1,104(sp)
 908:	7906                	ld	s2,96(sp)
 90a:	69e6                	ld	s3,88(sp)
 90c:	6a46                	ld	s4,80(sp)
 90e:	6aa6                	ld	s5,72(sp)
 910:	6b06                	ld	s6,64(sp)
 912:	7be2                	ld	s7,56(sp)
 914:	7c42                	ld	s8,48(sp)
 916:	7ca2                	ld	s9,40(sp)
 918:	7d02                	ld	s10,32(sp)
 91a:	6de2                	ld	s11,24(sp)
 91c:	6109                	addi	sp,sp,128
 91e:	8082                	ret

0000000000000920 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 920:	715d                	addi	sp,sp,-80
 922:	ec06                	sd	ra,24(sp)
 924:	e822                	sd	s0,16(sp)
 926:	1000                	addi	s0,sp,32
 928:	e010                	sd	a2,0(s0)
 92a:	e414                	sd	a3,8(s0)
 92c:	e818                	sd	a4,16(s0)
 92e:	ec1c                	sd	a5,24(s0)
 930:	03043023          	sd	a6,32(s0)
 934:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 938:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 93c:	8622                	mv	a2,s0
 93e:	00000097          	auipc	ra,0x0
 942:	e04080e7          	jalr	-508(ra) # 742 <vprintf>
}
 946:	60e2                	ld	ra,24(sp)
 948:	6442                	ld	s0,16(sp)
 94a:	6161                	addi	sp,sp,80
 94c:	8082                	ret

000000000000094e <printf>:

void
printf(const char *fmt, ...)
{
 94e:	711d                	addi	sp,sp,-96
 950:	ec06                	sd	ra,24(sp)
 952:	e822                	sd	s0,16(sp)
 954:	1000                	addi	s0,sp,32
 956:	e40c                	sd	a1,8(s0)
 958:	e810                	sd	a2,16(s0)
 95a:	ec14                	sd	a3,24(s0)
 95c:	f018                	sd	a4,32(s0)
 95e:	f41c                	sd	a5,40(s0)
 960:	03043823          	sd	a6,48(s0)
 964:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 968:	00840613          	addi	a2,s0,8
 96c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 970:	85aa                	mv	a1,a0
 972:	4505                	li	a0,1
 974:	00000097          	auipc	ra,0x0
 978:	dce080e7          	jalr	-562(ra) # 742 <vprintf>
}
 97c:	60e2                	ld	ra,24(sp)
 97e:	6442                	ld	s0,16(sp)
 980:	6125                	addi	sp,sp,96
 982:	8082                	ret

0000000000000984 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 984:	1141                	addi	sp,sp,-16
 986:	e422                	sd	s0,8(sp)
 988:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 98a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 98e:	00000797          	auipc	a5,0x0
 992:	2e27b783          	ld	a5,738(a5) # c70 <freep>
 996:	a805                	j	9c6 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 998:	4618                	lw	a4,8(a2)
 99a:	9db9                	addw	a1,a1,a4
 99c:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 9a0:	6398                	ld	a4,0(a5)
 9a2:	6318                	ld	a4,0(a4)
 9a4:	fee53823          	sd	a4,-16(a0)
 9a8:	a091                	j	9ec <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 9aa:	ff852703          	lw	a4,-8(a0)
 9ae:	9e39                	addw	a2,a2,a4
 9b0:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 9b2:	ff053703          	ld	a4,-16(a0)
 9b6:	e398                	sd	a4,0(a5)
 9b8:	a099                	j	9fe <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9ba:	6398                	ld	a4,0(a5)
 9bc:	00e7e463          	bltu	a5,a4,9c4 <free+0x40>
 9c0:	00e6ea63          	bltu	a3,a4,9d4 <free+0x50>
{
 9c4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 9c6:	fed7fae3          	bgeu	a5,a3,9ba <free+0x36>
 9ca:	6398                	ld	a4,0(a5)
 9cc:	00e6e463          	bltu	a3,a4,9d4 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9d0:	fee7eae3          	bltu	a5,a4,9c4 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 9d4:	ff852583          	lw	a1,-8(a0)
 9d8:	6390                	ld	a2,0(a5)
 9da:	02059713          	slli	a4,a1,0x20
 9de:	9301                	srli	a4,a4,0x20
 9e0:	0712                	slli	a4,a4,0x4
 9e2:	9736                	add	a4,a4,a3
 9e4:	fae60ae3          	beq	a2,a4,998 <free+0x14>
    bp->s.ptr = p->s.ptr;
 9e8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 9ec:	4790                	lw	a2,8(a5)
 9ee:	02061713          	slli	a4,a2,0x20
 9f2:	9301                	srli	a4,a4,0x20
 9f4:	0712                	slli	a4,a4,0x4
 9f6:	973e                	add	a4,a4,a5
 9f8:	fae689e3          	beq	a3,a4,9aa <free+0x26>
  } else
    p->s.ptr = bp;
 9fc:	e394                	sd	a3,0(a5)
  freep = p;
 9fe:	00000717          	auipc	a4,0x0
 a02:	26f73923          	sd	a5,626(a4) # c70 <freep>
}
 a06:	6422                	ld	s0,8(sp)
 a08:	0141                	addi	sp,sp,16
 a0a:	8082                	ret

0000000000000a0c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 a0c:	7139                	addi	sp,sp,-64
 a0e:	fc06                	sd	ra,56(sp)
 a10:	f822                	sd	s0,48(sp)
 a12:	f426                	sd	s1,40(sp)
 a14:	f04a                	sd	s2,32(sp)
 a16:	ec4e                	sd	s3,24(sp)
 a18:	e852                	sd	s4,16(sp)
 a1a:	e456                	sd	s5,8(sp)
 a1c:	e05a                	sd	s6,0(sp)
 a1e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 a20:	02051493          	slli	s1,a0,0x20
 a24:	9081                	srli	s1,s1,0x20
 a26:	04bd                	addi	s1,s1,15
 a28:	8091                	srli	s1,s1,0x4
 a2a:	0014899b          	addiw	s3,s1,1
 a2e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 a30:	00000517          	auipc	a0,0x0
 a34:	24053503          	ld	a0,576(a0) # c70 <freep>
 a38:	c515                	beqz	a0,a64 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a3a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a3c:	4798                	lw	a4,8(a5)
 a3e:	02977f63          	bgeu	a4,s1,a7c <malloc+0x70>
 a42:	8a4e                	mv	s4,s3
 a44:	0009871b          	sext.w	a4,s3
 a48:	6685                	lui	a3,0x1
 a4a:	00d77363          	bgeu	a4,a3,a50 <malloc+0x44>
 a4e:	6a05                	lui	s4,0x1
 a50:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a54:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a58:	00000917          	auipc	s2,0x0
 a5c:	21890913          	addi	s2,s2,536 # c70 <freep>
  if(p == (char*)-1)
 a60:	5afd                	li	s5,-1
 a62:	a88d                	j	ad4 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 a64:	00000797          	auipc	a5,0x0
 a68:	21478793          	addi	a5,a5,532 # c78 <base>
 a6c:	00000717          	auipc	a4,0x0
 a70:	20f73223          	sd	a5,516(a4) # c70 <freep>
 a74:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a76:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a7a:	b7e1                	j	a42 <malloc+0x36>
      if(p->s.size == nunits)
 a7c:	02e48b63          	beq	s1,a4,ab2 <malloc+0xa6>
        p->s.size -= nunits;
 a80:	4137073b          	subw	a4,a4,s3
 a84:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a86:	1702                	slli	a4,a4,0x20
 a88:	9301                	srli	a4,a4,0x20
 a8a:	0712                	slli	a4,a4,0x4
 a8c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a8e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a92:	00000717          	auipc	a4,0x0
 a96:	1ca73f23          	sd	a0,478(a4) # c70 <freep>
      return (void*)(p + 1);
 a9a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a9e:	70e2                	ld	ra,56(sp)
 aa0:	7442                	ld	s0,48(sp)
 aa2:	74a2                	ld	s1,40(sp)
 aa4:	7902                	ld	s2,32(sp)
 aa6:	69e2                	ld	s3,24(sp)
 aa8:	6a42                	ld	s4,16(sp)
 aaa:	6aa2                	ld	s5,8(sp)
 aac:	6b02                	ld	s6,0(sp)
 aae:	6121                	addi	sp,sp,64
 ab0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 ab2:	6398                	ld	a4,0(a5)
 ab4:	e118                	sd	a4,0(a0)
 ab6:	bff1                	j	a92 <malloc+0x86>
  hp->s.size = nu;
 ab8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 abc:	0541                	addi	a0,a0,16
 abe:	00000097          	auipc	ra,0x0
 ac2:	ec6080e7          	jalr	-314(ra) # 984 <free>
  return freep;
 ac6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 aca:	d971                	beqz	a0,a9e <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 acc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 ace:	4798                	lw	a4,8(a5)
 ad0:	fa9776e3          	bgeu	a4,s1,a7c <malloc+0x70>
    if(p == freep)
 ad4:	00093703          	ld	a4,0(s2)
 ad8:	853e                	mv	a0,a5
 ada:	fef719e3          	bne	a4,a5,acc <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 ade:	8552                	mv	a0,s4
 ae0:	00000097          	auipc	ra,0x0
 ae4:	b5e080e7          	jalr	-1186(ra) # 63e <sbrk>
  if(p == (char*)-1)
 ae8:	fd5518e3          	bne	a0,s5,ab8 <malloc+0xac>
        return 0;
 aec:	4501                	li	a0,0
 aee:	bf45                	j	a9e <malloc+0x92>
