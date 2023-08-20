
user/_primes：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <runprocess>:

/*
 * Run as a prime-number processor
 * the listenfd is from your left neighbor
 */
void runprocess(int listenfd) {
   0:	711d                	addi	sp,sp,-96
   2:	ec86                	sd	ra,88(sp)
   4:	e8a2                	sd	s0,80(sp)
   6:	e4a6                	sd	s1,72(sp)
   8:	e0ca                	sd	s2,64(sp)
   a:	fc4e                	sd	s3,56(sp)
   c:	f852                	sd	s4,48(sp)
   e:	f456                	sd	s5,40(sp)
  10:	1080                	addi	s0,sp,96
  12:	892a                	mv	s2,a0
  int my_num = 0;
  int forked = 0;
  int passed_num = 0;
  14:	fa042e23          	sw	zero,-68(s0)
  int forked = 0;
  18:	4981                	li	s3,0
  int my_num = 0;
  1a:	4481                	li	s1,0
    }

    // if my initial read
    if (my_num == 0) {
      my_num = passed_num;
      printf("prime %d\n", my_num);
  1c:	00001a97          	auipc	s5,0x1
  20:	8cca8a93          	addi	s5,s5,-1844 # 8e8 <malloc+0xe4>
          runprocess(pipes[0]);
        }
      }

      // pass the number to right neighbor
      write(pipes[1], &passed_num, 4);
  24:	4a05                	li	s4,1
  26:	a885                	j	96 <runprocess+0x96>
      close(listenfd);
  28:	854a                	mv	a0,s2
  2a:	00000097          	auipc	ra,0x0
  2e:	3ac080e7          	jalr	940(ra) # 3d6 <close>
      if (forked) {
  32:	00099763          	bnez	s3,40 <runprocess+0x40>
      exit(0);
  36:	4501                	li	a0,0
  38:	00000097          	auipc	ra,0x0
  3c:	376080e7          	jalr	886(ra) # 3ae <exit>
        wait(&child_pid);
  40:	fac40513          	addi	a0,s0,-84
  44:	00000097          	auipc	ra,0x0
  48:	372080e7          	jalr	882(ra) # 3b6 <wait>
  4c:	b7ed                	j	36 <runprocess+0x36>
      my_num = passed_num;
  4e:	fbc42483          	lw	s1,-68(s0)
      printf("prime %d\n", my_num);
  52:	85a6                	mv	a1,s1
  54:	8556                	mv	a0,s5
  56:	00000097          	auipc	ra,0x0
  5a:	6f0080e7          	jalr	1776(ra) # 746 <printf>
  5e:	a0b1                	j	aa <runprocess+0xaa>
          close(pipes[1]);
  60:	fb442503          	lw	a0,-76(s0)
  64:	00000097          	auipc	ra,0x0
  68:	372080e7          	jalr	882(ra) # 3d6 <close>
          close(listenfd);
  6c:	854a                	mv	a0,s2
  6e:	00000097          	auipc	ra,0x0
  72:	368080e7          	jalr	872(ra) # 3d6 <close>
          runprocess(pipes[0]);
  76:	fb042503          	lw	a0,-80(s0)
  7a:	00000097          	auipc	ra,0x0
  7e:	f86080e7          	jalr	-122(ra) # 0 <runprocess>
      write(pipes[1], &passed_num, 4);
  82:	4611                	li	a2,4
  84:	fbc40593          	addi	a1,s0,-68
  88:	fb442503          	lw	a0,-76(s0)
  8c:	00000097          	auipc	ra,0x0
  90:	342080e7          	jalr	834(ra) # 3ce <write>
  94:	89d2                	mv	s3,s4
    int read_bytes = read(listenfd, &passed_num, 4);
  96:	4611                	li	a2,4
  98:	fbc40593          	addi	a1,s0,-68
  9c:	854a                	mv	a0,s2
  9e:	00000097          	auipc	ra,0x0
  a2:	328080e7          	jalr	808(ra) # 3c6 <read>
    if (read_bytes == 0) {
  a6:	d149                	beqz	a0,28 <runprocess+0x28>
    if (my_num == 0) {
  a8:	d0dd                	beqz	s1,4e <runprocess+0x4e>
    if (passed_num % my_num != 0) {
  aa:	fbc42783          	lw	a5,-68(s0)
  ae:	0297e7bb          	remw	a5,a5,s1
  b2:	d3f5                	beqz	a5,96 <runprocess+0x96>
      if (!forked) {
  b4:	fc0997e3          	bnez	s3,82 <runprocess+0x82>
        pipe(pipes);
  b8:	fb040513          	addi	a0,s0,-80
  bc:	00000097          	auipc	ra,0x0
  c0:	302080e7          	jalr	770(ra) # 3be <pipe>
        int ret = fork();
  c4:	00000097          	auipc	ra,0x0
  c8:	2e2080e7          	jalr	738(ra) # 3a6 <fork>
        if (ret == 0) {
  cc:	f951                	bnez	a0,60 <runprocess+0x60>
          close(pipes[0]);
  ce:	fb042503          	lw	a0,-80(s0)
  d2:	00000097          	auipc	ra,0x0
  d6:	304080e7          	jalr	772(ra) # 3d6 <close>
  da:	b765                	j	82 <runprocess+0x82>

00000000000000dc <main>:
    }
  }
}

int main(int argc, char *argv[]) {
  dc:	7179                	addi	sp,sp,-48
  de:	f406                	sd	ra,40(sp)
  e0:	f022                	sd	s0,32(sp)
  e2:	ec26                	sd	s1,24(sp)
  e4:	1800                	addi	s0,sp,48
  int pipes[2];
  pipe(pipes);
  e6:	fd840513          	addi	a0,s0,-40
  ea:	00000097          	auipc	ra,0x0
  ee:	2d4080e7          	jalr	724(ra) # 3be <pipe>
  for (int i = 2; i <= 35; i++) {
  f2:	4789                	li	a5,2
  f4:	fcf42a23          	sw	a5,-44(s0)
  f8:	02300493          	li	s1,35
    write(pipes[1], &i, 4);
  fc:	4611                	li	a2,4
  fe:	fd440593          	addi	a1,s0,-44
 102:	fdc42503          	lw	a0,-36(s0)
 106:	00000097          	auipc	ra,0x0
 10a:	2c8080e7          	jalr	712(ra) # 3ce <write>
  for (int i = 2; i <= 35; i++) {
 10e:	fd442783          	lw	a5,-44(s0)
 112:	2785                	addiw	a5,a5,1
 114:	0007871b          	sext.w	a4,a5
 118:	fcf42a23          	sw	a5,-44(s0)
 11c:	fee4d0e3          	bge	s1,a4,fc <main+0x20>
  }
  close(pipes[1]);
 120:	fdc42503          	lw	a0,-36(s0)
 124:	00000097          	auipc	ra,0x0
 128:	2b2080e7          	jalr	690(ra) # 3d6 <close>
  runprocess(pipes[0]);
 12c:	fd842503          	lw	a0,-40(s0)
 130:	00000097          	auipc	ra,0x0
 134:	ed0080e7          	jalr	-304(ra) # 0 <runprocess>

0000000000000138 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 138:	1141                	addi	sp,sp,-16
 13a:	e422                	sd	s0,8(sp)
 13c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 13e:	87aa                	mv	a5,a0
 140:	0585                	addi	a1,a1,1
 142:	0785                	addi	a5,a5,1
 144:	fff5c703          	lbu	a4,-1(a1)
 148:	fee78fa3          	sb	a4,-1(a5)
 14c:	fb75                	bnez	a4,140 <strcpy+0x8>
    ;
  return os;
}
 14e:	6422                	ld	s0,8(sp)
 150:	0141                	addi	sp,sp,16
 152:	8082                	ret

0000000000000154 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 154:	1141                	addi	sp,sp,-16
 156:	e422                	sd	s0,8(sp)
 158:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 15a:	00054783          	lbu	a5,0(a0)
 15e:	cb91                	beqz	a5,172 <strcmp+0x1e>
 160:	0005c703          	lbu	a4,0(a1)
 164:	00f71763          	bne	a4,a5,172 <strcmp+0x1e>
    p++, q++;
 168:	0505                	addi	a0,a0,1
 16a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 16c:	00054783          	lbu	a5,0(a0)
 170:	fbe5                	bnez	a5,160 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 172:	0005c503          	lbu	a0,0(a1)
}
 176:	40a7853b          	subw	a0,a5,a0
 17a:	6422                	ld	s0,8(sp)
 17c:	0141                	addi	sp,sp,16
 17e:	8082                	ret

0000000000000180 <strlen>:

uint
strlen(const char *s)
{
 180:	1141                	addi	sp,sp,-16
 182:	e422                	sd	s0,8(sp)
 184:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 186:	00054783          	lbu	a5,0(a0)
 18a:	cf91                	beqz	a5,1a6 <strlen+0x26>
 18c:	0505                	addi	a0,a0,1
 18e:	87aa                	mv	a5,a0
 190:	4685                	li	a3,1
 192:	9e89                	subw	a3,a3,a0
 194:	00f6853b          	addw	a0,a3,a5
 198:	0785                	addi	a5,a5,1
 19a:	fff7c703          	lbu	a4,-1(a5)
 19e:	fb7d                	bnez	a4,194 <strlen+0x14>
    ;
  return n;
}
 1a0:	6422                	ld	s0,8(sp)
 1a2:	0141                	addi	sp,sp,16
 1a4:	8082                	ret
  for(n = 0; s[n]; n++)
 1a6:	4501                	li	a0,0
 1a8:	bfe5                	j	1a0 <strlen+0x20>

00000000000001aa <memset>:

void*
memset(void *dst, int c, uint n)
{
 1aa:	1141                	addi	sp,sp,-16
 1ac:	e422                	sd	s0,8(sp)
 1ae:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1b0:	ce09                	beqz	a2,1ca <memset+0x20>
 1b2:	87aa                	mv	a5,a0
 1b4:	fff6071b          	addiw	a4,a2,-1
 1b8:	1702                	slli	a4,a4,0x20
 1ba:	9301                	srli	a4,a4,0x20
 1bc:	0705                	addi	a4,a4,1
 1be:	972a                	add	a4,a4,a0
    cdst[i] = c;
 1c0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1c4:	0785                	addi	a5,a5,1
 1c6:	fee79de3          	bne	a5,a4,1c0 <memset+0x16>
  }
  return dst;
}
 1ca:	6422                	ld	s0,8(sp)
 1cc:	0141                	addi	sp,sp,16
 1ce:	8082                	ret

00000000000001d0 <strchr>:

char*
strchr(const char *s, char c)
{
 1d0:	1141                	addi	sp,sp,-16
 1d2:	e422                	sd	s0,8(sp)
 1d4:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1d6:	00054783          	lbu	a5,0(a0)
 1da:	cb99                	beqz	a5,1f0 <strchr+0x20>
    if(*s == c)
 1dc:	00f58763          	beq	a1,a5,1ea <strchr+0x1a>
  for(; *s; s++)
 1e0:	0505                	addi	a0,a0,1
 1e2:	00054783          	lbu	a5,0(a0)
 1e6:	fbfd                	bnez	a5,1dc <strchr+0xc>
      return (char*)s;
  return 0;
 1e8:	4501                	li	a0,0
}
 1ea:	6422                	ld	s0,8(sp)
 1ec:	0141                	addi	sp,sp,16
 1ee:	8082                	ret
  return 0;
 1f0:	4501                	li	a0,0
 1f2:	bfe5                	j	1ea <strchr+0x1a>

00000000000001f4 <gets>:

char*
gets(char *buf, int max)
{
 1f4:	711d                	addi	sp,sp,-96
 1f6:	ec86                	sd	ra,88(sp)
 1f8:	e8a2                	sd	s0,80(sp)
 1fa:	e4a6                	sd	s1,72(sp)
 1fc:	e0ca                	sd	s2,64(sp)
 1fe:	fc4e                	sd	s3,56(sp)
 200:	f852                	sd	s4,48(sp)
 202:	f456                	sd	s5,40(sp)
 204:	f05a                	sd	s6,32(sp)
 206:	ec5e                	sd	s7,24(sp)
 208:	1080                	addi	s0,sp,96
 20a:	8baa                	mv	s7,a0
 20c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 20e:	892a                	mv	s2,a0
 210:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 212:	4aa9                	li	s5,10
 214:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 216:	89a6                	mv	s3,s1
 218:	2485                	addiw	s1,s1,1
 21a:	0344d863          	bge	s1,s4,24a <gets+0x56>
    cc = read(0, &c, 1);
 21e:	4605                	li	a2,1
 220:	faf40593          	addi	a1,s0,-81
 224:	4501                	li	a0,0
 226:	00000097          	auipc	ra,0x0
 22a:	1a0080e7          	jalr	416(ra) # 3c6 <read>
    if(cc < 1)
 22e:	00a05e63          	blez	a0,24a <gets+0x56>
    buf[i++] = c;
 232:	faf44783          	lbu	a5,-81(s0)
 236:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 23a:	01578763          	beq	a5,s5,248 <gets+0x54>
 23e:	0905                	addi	s2,s2,1
 240:	fd679be3          	bne	a5,s6,216 <gets+0x22>
  for(i=0; i+1 < max; ){
 244:	89a6                	mv	s3,s1
 246:	a011                	j	24a <gets+0x56>
 248:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 24a:	99de                	add	s3,s3,s7
 24c:	00098023          	sb	zero,0(s3)
  return buf;
}
 250:	855e                	mv	a0,s7
 252:	60e6                	ld	ra,88(sp)
 254:	6446                	ld	s0,80(sp)
 256:	64a6                	ld	s1,72(sp)
 258:	6906                	ld	s2,64(sp)
 25a:	79e2                	ld	s3,56(sp)
 25c:	7a42                	ld	s4,48(sp)
 25e:	7aa2                	ld	s5,40(sp)
 260:	7b02                	ld	s6,32(sp)
 262:	6be2                	ld	s7,24(sp)
 264:	6125                	addi	sp,sp,96
 266:	8082                	ret

0000000000000268 <stat>:

int
stat(const char *n, struct stat *st)
{
 268:	1101                	addi	sp,sp,-32
 26a:	ec06                	sd	ra,24(sp)
 26c:	e822                	sd	s0,16(sp)
 26e:	e426                	sd	s1,8(sp)
 270:	e04a                	sd	s2,0(sp)
 272:	1000                	addi	s0,sp,32
 274:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 276:	4581                	li	a1,0
 278:	00000097          	auipc	ra,0x0
 27c:	176080e7          	jalr	374(ra) # 3ee <open>
  if(fd < 0)
 280:	02054563          	bltz	a0,2aa <stat+0x42>
 284:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 286:	85ca                	mv	a1,s2
 288:	00000097          	auipc	ra,0x0
 28c:	17e080e7          	jalr	382(ra) # 406 <fstat>
 290:	892a                	mv	s2,a0
  close(fd);
 292:	8526                	mv	a0,s1
 294:	00000097          	auipc	ra,0x0
 298:	142080e7          	jalr	322(ra) # 3d6 <close>
  return r;
}
 29c:	854a                	mv	a0,s2
 29e:	60e2                	ld	ra,24(sp)
 2a0:	6442                	ld	s0,16(sp)
 2a2:	64a2                	ld	s1,8(sp)
 2a4:	6902                	ld	s2,0(sp)
 2a6:	6105                	addi	sp,sp,32
 2a8:	8082                	ret
    return -1;
 2aa:	597d                	li	s2,-1
 2ac:	bfc5                	j	29c <stat+0x34>

00000000000002ae <atoi>:

int
atoi(const char *s)
{
 2ae:	1141                	addi	sp,sp,-16
 2b0:	e422                	sd	s0,8(sp)
 2b2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2b4:	00054603          	lbu	a2,0(a0)
 2b8:	fd06079b          	addiw	a5,a2,-48
 2bc:	0ff7f793          	andi	a5,a5,255
 2c0:	4725                	li	a4,9
 2c2:	02f76963          	bltu	a4,a5,2f4 <atoi+0x46>
 2c6:	86aa                	mv	a3,a0
  n = 0;
 2c8:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2ca:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2cc:	0685                	addi	a3,a3,1
 2ce:	0025179b          	slliw	a5,a0,0x2
 2d2:	9fa9                	addw	a5,a5,a0
 2d4:	0017979b          	slliw	a5,a5,0x1
 2d8:	9fb1                	addw	a5,a5,a2
 2da:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2de:	0006c603          	lbu	a2,0(a3)
 2e2:	fd06071b          	addiw	a4,a2,-48
 2e6:	0ff77713          	andi	a4,a4,255
 2ea:	fee5f1e3          	bgeu	a1,a4,2cc <atoi+0x1e>
  return n;
}
 2ee:	6422                	ld	s0,8(sp)
 2f0:	0141                	addi	sp,sp,16
 2f2:	8082                	ret
  n = 0;
 2f4:	4501                	li	a0,0
 2f6:	bfe5                	j	2ee <atoi+0x40>

00000000000002f8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2f8:	1141                	addi	sp,sp,-16
 2fa:	e422                	sd	s0,8(sp)
 2fc:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2fe:	02b57663          	bgeu	a0,a1,32a <memmove+0x32>
    while(n-- > 0)
 302:	02c05163          	blez	a2,324 <memmove+0x2c>
 306:	fff6079b          	addiw	a5,a2,-1
 30a:	1782                	slli	a5,a5,0x20
 30c:	9381                	srli	a5,a5,0x20
 30e:	0785                	addi	a5,a5,1
 310:	97aa                	add	a5,a5,a0
  dst = vdst;
 312:	872a                	mv	a4,a0
      *dst++ = *src++;
 314:	0585                	addi	a1,a1,1
 316:	0705                	addi	a4,a4,1
 318:	fff5c683          	lbu	a3,-1(a1)
 31c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 320:	fee79ae3          	bne	a5,a4,314 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 324:	6422                	ld	s0,8(sp)
 326:	0141                	addi	sp,sp,16
 328:	8082                	ret
    dst += n;
 32a:	00c50733          	add	a4,a0,a2
    src += n;
 32e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 330:	fec05ae3          	blez	a2,324 <memmove+0x2c>
 334:	fff6079b          	addiw	a5,a2,-1
 338:	1782                	slli	a5,a5,0x20
 33a:	9381                	srli	a5,a5,0x20
 33c:	fff7c793          	not	a5,a5
 340:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 342:	15fd                	addi	a1,a1,-1
 344:	177d                	addi	a4,a4,-1
 346:	0005c683          	lbu	a3,0(a1)
 34a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 34e:	fee79ae3          	bne	a5,a4,342 <memmove+0x4a>
 352:	bfc9                	j	324 <memmove+0x2c>

0000000000000354 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 354:	1141                	addi	sp,sp,-16
 356:	e422                	sd	s0,8(sp)
 358:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 35a:	ca05                	beqz	a2,38a <memcmp+0x36>
 35c:	fff6069b          	addiw	a3,a2,-1
 360:	1682                	slli	a3,a3,0x20
 362:	9281                	srli	a3,a3,0x20
 364:	0685                	addi	a3,a3,1
 366:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 368:	00054783          	lbu	a5,0(a0)
 36c:	0005c703          	lbu	a4,0(a1)
 370:	00e79863          	bne	a5,a4,380 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 374:	0505                	addi	a0,a0,1
    p2++;
 376:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 378:	fed518e3          	bne	a0,a3,368 <memcmp+0x14>
  }
  return 0;
 37c:	4501                	li	a0,0
 37e:	a019                	j	384 <memcmp+0x30>
      return *p1 - *p2;
 380:	40e7853b          	subw	a0,a5,a4
}
 384:	6422                	ld	s0,8(sp)
 386:	0141                	addi	sp,sp,16
 388:	8082                	ret
  return 0;
 38a:	4501                	li	a0,0
 38c:	bfe5                	j	384 <memcmp+0x30>

000000000000038e <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 38e:	1141                	addi	sp,sp,-16
 390:	e406                	sd	ra,8(sp)
 392:	e022                	sd	s0,0(sp)
 394:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 396:	00000097          	auipc	ra,0x0
 39a:	f62080e7          	jalr	-158(ra) # 2f8 <memmove>
}
 39e:	60a2                	ld	ra,8(sp)
 3a0:	6402                	ld	s0,0(sp)
 3a2:	0141                	addi	sp,sp,16
 3a4:	8082                	ret

00000000000003a6 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3a6:	4885                	li	a7,1
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <exit>:
.global exit
exit:
 li a7, SYS_exit
 3ae:	4889                	li	a7,2
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3b6:	488d                	li	a7,3
 ecall
 3b8:	00000073          	ecall
 ret
 3bc:	8082                	ret

00000000000003be <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3be:	4891                	li	a7,4
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <read>:
.global read
read:
 li a7, SYS_read
 3c6:	4895                	li	a7,5
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <write>:
.global write
write:
 li a7, SYS_write
 3ce:	48c1                	li	a7,16
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <close>:
.global close
close:
 li a7, SYS_close
 3d6:	48d5                	li	a7,21
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <kill>:
.global kill
kill:
 li a7, SYS_kill
 3de:	4899                	li	a7,6
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3e6:	489d                	li	a7,7
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <open>:
.global open
open:
 li a7, SYS_open
 3ee:	48bd                	li	a7,15
 ecall
 3f0:	00000073          	ecall
 ret
 3f4:	8082                	ret

00000000000003f6 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3f6:	48c5                	li	a7,17
 ecall
 3f8:	00000073          	ecall
 ret
 3fc:	8082                	ret

00000000000003fe <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3fe:	48c9                	li	a7,18
 ecall
 400:	00000073          	ecall
 ret
 404:	8082                	ret

0000000000000406 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 406:	48a1                	li	a7,8
 ecall
 408:	00000073          	ecall
 ret
 40c:	8082                	ret

000000000000040e <link>:
.global link
link:
 li a7, SYS_link
 40e:	48cd                	li	a7,19
 ecall
 410:	00000073          	ecall
 ret
 414:	8082                	ret

0000000000000416 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 416:	48d1                	li	a7,20
 ecall
 418:	00000073          	ecall
 ret
 41c:	8082                	ret

000000000000041e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 41e:	48a5                	li	a7,9
 ecall
 420:	00000073          	ecall
 ret
 424:	8082                	ret

0000000000000426 <dup>:
.global dup
dup:
 li a7, SYS_dup
 426:	48a9                	li	a7,10
 ecall
 428:	00000073          	ecall
 ret
 42c:	8082                	ret

000000000000042e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 42e:	48ad                	li	a7,11
 ecall
 430:	00000073          	ecall
 ret
 434:	8082                	ret

0000000000000436 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 436:	48b1                	li	a7,12
 ecall
 438:	00000073          	ecall
 ret
 43c:	8082                	ret

000000000000043e <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 43e:	48b5                	li	a7,13
 ecall
 440:	00000073          	ecall
 ret
 444:	8082                	ret

0000000000000446 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 446:	48b9                	li	a7,14
 ecall
 448:	00000073          	ecall
 ret
 44c:	8082                	ret

000000000000044e <trace>:
.global trace
trace:
 li a7, SYS_trace
 44e:	48d9                	li	a7,22
 ecall
 450:	00000073          	ecall
 ret
 454:	8082                	ret

0000000000000456 <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 456:	48dd                	li	a7,23
 ecall
 458:	00000073          	ecall
 ret
 45c:	8082                	ret

000000000000045e <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 45e:	48e1                	li	a7,24
 ecall
 460:	00000073          	ecall
 ret
 464:	8082                	ret

0000000000000466 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 466:	48e5                	li	a7,25
 ecall
 468:	00000073          	ecall
 ret
 46c:	8082                	ret

000000000000046e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 46e:	1101                	addi	sp,sp,-32
 470:	ec06                	sd	ra,24(sp)
 472:	e822                	sd	s0,16(sp)
 474:	1000                	addi	s0,sp,32
 476:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 47a:	4605                	li	a2,1
 47c:	fef40593          	addi	a1,s0,-17
 480:	00000097          	auipc	ra,0x0
 484:	f4e080e7          	jalr	-178(ra) # 3ce <write>
}
 488:	60e2                	ld	ra,24(sp)
 48a:	6442                	ld	s0,16(sp)
 48c:	6105                	addi	sp,sp,32
 48e:	8082                	ret

0000000000000490 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 490:	7139                	addi	sp,sp,-64
 492:	fc06                	sd	ra,56(sp)
 494:	f822                	sd	s0,48(sp)
 496:	f426                	sd	s1,40(sp)
 498:	f04a                	sd	s2,32(sp)
 49a:	ec4e                	sd	s3,24(sp)
 49c:	0080                	addi	s0,sp,64
 49e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4a0:	c299                	beqz	a3,4a6 <printint+0x16>
 4a2:	0805c863          	bltz	a1,532 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4a6:	2581                	sext.w	a1,a1
  neg = 0;
 4a8:	4881                	li	a7,0
 4aa:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4ae:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4b0:	2601                	sext.w	a2,a2
 4b2:	00000517          	auipc	a0,0x0
 4b6:	44e50513          	addi	a0,a0,1102 # 900 <digits>
 4ba:	883a                	mv	a6,a4
 4bc:	2705                	addiw	a4,a4,1
 4be:	02c5f7bb          	remuw	a5,a1,a2
 4c2:	1782                	slli	a5,a5,0x20
 4c4:	9381                	srli	a5,a5,0x20
 4c6:	97aa                	add	a5,a5,a0
 4c8:	0007c783          	lbu	a5,0(a5)
 4cc:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4d0:	0005879b          	sext.w	a5,a1
 4d4:	02c5d5bb          	divuw	a1,a1,a2
 4d8:	0685                	addi	a3,a3,1
 4da:	fec7f0e3          	bgeu	a5,a2,4ba <printint+0x2a>
  if(neg)
 4de:	00088b63          	beqz	a7,4f4 <printint+0x64>
    buf[i++] = '-';
 4e2:	fd040793          	addi	a5,s0,-48
 4e6:	973e                	add	a4,a4,a5
 4e8:	02d00793          	li	a5,45
 4ec:	fef70823          	sb	a5,-16(a4)
 4f0:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4f4:	02e05863          	blez	a4,524 <printint+0x94>
 4f8:	fc040793          	addi	a5,s0,-64
 4fc:	00e78933          	add	s2,a5,a4
 500:	fff78993          	addi	s3,a5,-1
 504:	99ba                	add	s3,s3,a4
 506:	377d                	addiw	a4,a4,-1
 508:	1702                	slli	a4,a4,0x20
 50a:	9301                	srli	a4,a4,0x20
 50c:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 510:	fff94583          	lbu	a1,-1(s2)
 514:	8526                	mv	a0,s1
 516:	00000097          	auipc	ra,0x0
 51a:	f58080e7          	jalr	-168(ra) # 46e <putc>
  while(--i >= 0)
 51e:	197d                	addi	s2,s2,-1
 520:	ff3918e3          	bne	s2,s3,510 <printint+0x80>
}
 524:	70e2                	ld	ra,56(sp)
 526:	7442                	ld	s0,48(sp)
 528:	74a2                	ld	s1,40(sp)
 52a:	7902                	ld	s2,32(sp)
 52c:	69e2                	ld	s3,24(sp)
 52e:	6121                	addi	sp,sp,64
 530:	8082                	ret
    x = -xx;
 532:	40b005bb          	negw	a1,a1
    neg = 1;
 536:	4885                	li	a7,1
    x = -xx;
 538:	bf8d                	j	4aa <printint+0x1a>

000000000000053a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 53a:	7119                	addi	sp,sp,-128
 53c:	fc86                	sd	ra,120(sp)
 53e:	f8a2                	sd	s0,112(sp)
 540:	f4a6                	sd	s1,104(sp)
 542:	f0ca                	sd	s2,96(sp)
 544:	ecce                	sd	s3,88(sp)
 546:	e8d2                	sd	s4,80(sp)
 548:	e4d6                	sd	s5,72(sp)
 54a:	e0da                	sd	s6,64(sp)
 54c:	fc5e                	sd	s7,56(sp)
 54e:	f862                	sd	s8,48(sp)
 550:	f466                	sd	s9,40(sp)
 552:	f06a                	sd	s10,32(sp)
 554:	ec6e                	sd	s11,24(sp)
 556:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 558:	0005c903          	lbu	s2,0(a1)
 55c:	18090f63          	beqz	s2,6fa <vprintf+0x1c0>
 560:	8aaa                	mv	s5,a0
 562:	8b32                	mv	s6,a2
 564:	00158493          	addi	s1,a1,1
  state = 0;
 568:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 56a:	02500a13          	li	s4,37
      if(c == 'd'){
 56e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 572:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 576:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 57a:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 57e:	00000b97          	auipc	s7,0x0
 582:	382b8b93          	addi	s7,s7,898 # 900 <digits>
 586:	a839                	j	5a4 <vprintf+0x6a>
        putc(fd, c);
 588:	85ca                	mv	a1,s2
 58a:	8556                	mv	a0,s5
 58c:	00000097          	auipc	ra,0x0
 590:	ee2080e7          	jalr	-286(ra) # 46e <putc>
 594:	a019                	j	59a <vprintf+0x60>
    } else if(state == '%'){
 596:	01498f63          	beq	s3,s4,5b4 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 59a:	0485                	addi	s1,s1,1
 59c:	fff4c903          	lbu	s2,-1(s1)
 5a0:	14090d63          	beqz	s2,6fa <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5a4:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5a8:	fe0997e3          	bnez	s3,596 <vprintf+0x5c>
      if(c == '%'){
 5ac:	fd479ee3          	bne	a5,s4,588 <vprintf+0x4e>
        state = '%';
 5b0:	89be                	mv	s3,a5
 5b2:	b7e5                	j	59a <vprintf+0x60>
      if(c == 'd'){
 5b4:	05878063          	beq	a5,s8,5f4 <vprintf+0xba>
      } else if(c == 'l') {
 5b8:	05978c63          	beq	a5,s9,610 <vprintf+0xd6>
      } else if(c == 'x') {
 5bc:	07a78863          	beq	a5,s10,62c <vprintf+0xf2>
      } else if(c == 'p') {
 5c0:	09b78463          	beq	a5,s11,648 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5c4:	07300713          	li	a4,115
 5c8:	0ce78663          	beq	a5,a4,694 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5cc:	06300713          	li	a4,99
 5d0:	0ee78e63          	beq	a5,a4,6cc <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5d4:	11478863          	beq	a5,s4,6e4 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5d8:	85d2                	mv	a1,s4
 5da:	8556                	mv	a0,s5
 5dc:	00000097          	auipc	ra,0x0
 5e0:	e92080e7          	jalr	-366(ra) # 46e <putc>
        putc(fd, c);
 5e4:	85ca                	mv	a1,s2
 5e6:	8556                	mv	a0,s5
 5e8:	00000097          	auipc	ra,0x0
 5ec:	e86080e7          	jalr	-378(ra) # 46e <putc>
      }
      state = 0;
 5f0:	4981                	li	s3,0
 5f2:	b765                	j	59a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5f4:	008b0913          	addi	s2,s6,8
 5f8:	4685                	li	a3,1
 5fa:	4629                	li	a2,10
 5fc:	000b2583          	lw	a1,0(s6)
 600:	8556                	mv	a0,s5
 602:	00000097          	auipc	ra,0x0
 606:	e8e080e7          	jalr	-370(ra) # 490 <printint>
 60a:	8b4a                	mv	s6,s2
      state = 0;
 60c:	4981                	li	s3,0
 60e:	b771                	j	59a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 610:	008b0913          	addi	s2,s6,8
 614:	4681                	li	a3,0
 616:	4629                	li	a2,10
 618:	000b2583          	lw	a1,0(s6)
 61c:	8556                	mv	a0,s5
 61e:	00000097          	auipc	ra,0x0
 622:	e72080e7          	jalr	-398(ra) # 490 <printint>
 626:	8b4a                	mv	s6,s2
      state = 0;
 628:	4981                	li	s3,0
 62a:	bf85                	j	59a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 62c:	008b0913          	addi	s2,s6,8
 630:	4681                	li	a3,0
 632:	4641                	li	a2,16
 634:	000b2583          	lw	a1,0(s6)
 638:	8556                	mv	a0,s5
 63a:	00000097          	auipc	ra,0x0
 63e:	e56080e7          	jalr	-426(ra) # 490 <printint>
 642:	8b4a                	mv	s6,s2
      state = 0;
 644:	4981                	li	s3,0
 646:	bf91                	j	59a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 648:	008b0793          	addi	a5,s6,8
 64c:	f8f43423          	sd	a5,-120(s0)
 650:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 654:	03000593          	li	a1,48
 658:	8556                	mv	a0,s5
 65a:	00000097          	auipc	ra,0x0
 65e:	e14080e7          	jalr	-492(ra) # 46e <putc>
  putc(fd, 'x');
 662:	85ea                	mv	a1,s10
 664:	8556                	mv	a0,s5
 666:	00000097          	auipc	ra,0x0
 66a:	e08080e7          	jalr	-504(ra) # 46e <putc>
 66e:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 670:	03c9d793          	srli	a5,s3,0x3c
 674:	97de                	add	a5,a5,s7
 676:	0007c583          	lbu	a1,0(a5)
 67a:	8556                	mv	a0,s5
 67c:	00000097          	auipc	ra,0x0
 680:	df2080e7          	jalr	-526(ra) # 46e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 684:	0992                	slli	s3,s3,0x4
 686:	397d                	addiw	s2,s2,-1
 688:	fe0914e3          	bnez	s2,670 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 68c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 690:	4981                	li	s3,0
 692:	b721                	j	59a <vprintf+0x60>
        s = va_arg(ap, char*);
 694:	008b0993          	addi	s3,s6,8
 698:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 69c:	02090163          	beqz	s2,6be <vprintf+0x184>
        while(*s != 0){
 6a0:	00094583          	lbu	a1,0(s2)
 6a4:	c9a1                	beqz	a1,6f4 <vprintf+0x1ba>
          putc(fd, *s);
 6a6:	8556                	mv	a0,s5
 6a8:	00000097          	auipc	ra,0x0
 6ac:	dc6080e7          	jalr	-570(ra) # 46e <putc>
          s++;
 6b0:	0905                	addi	s2,s2,1
        while(*s != 0){
 6b2:	00094583          	lbu	a1,0(s2)
 6b6:	f9e5                	bnez	a1,6a6 <vprintf+0x16c>
        s = va_arg(ap, char*);
 6b8:	8b4e                	mv	s6,s3
      state = 0;
 6ba:	4981                	li	s3,0
 6bc:	bdf9                	j	59a <vprintf+0x60>
          s = "(null)";
 6be:	00000917          	auipc	s2,0x0
 6c2:	23a90913          	addi	s2,s2,570 # 8f8 <malloc+0xf4>
        while(*s != 0){
 6c6:	02800593          	li	a1,40
 6ca:	bff1                	j	6a6 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6cc:	008b0913          	addi	s2,s6,8
 6d0:	000b4583          	lbu	a1,0(s6)
 6d4:	8556                	mv	a0,s5
 6d6:	00000097          	auipc	ra,0x0
 6da:	d98080e7          	jalr	-616(ra) # 46e <putc>
 6de:	8b4a                	mv	s6,s2
      state = 0;
 6e0:	4981                	li	s3,0
 6e2:	bd65                	j	59a <vprintf+0x60>
        putc(fd, c);
 6e4:	85d2                	mv	a1,s4
 6e6:	8556                	mv	a0,s5
 6e8:	00000097          	auipc	ra,0x0
 6ec:	d86080e7          	jalr	-634(ra) # 46e <putc>
      state = 0;
 6f0:	4981                	li	s3,0
 6f2:	b565                	j	59a <vprintf+0x60>
        s = va_arg(ap, char*);
 6f4:	8b4e                	mv	s6,s3
      state = 0;
 6f6:	4981                	li	s3,0
 6f8:	b54d                	j	59a <vprintf+0x60>
    }
  }
}
 6fa:	70e6                	ld	ra,120(sp)
 6fc:	7446                	ld	s0,112(sp)
 6fe:	74a6                	ld	s1,104(sp)
 700:	7906                	ld	s2,96(sp)
 702:	69e6                	ld	s3,88(sp)
 704:	6a46                	ld	s4,80(sp)
 706:	6aa6                	ld	s5,72(sp)
 708:	6b06                	ld	s6,64(sp)
 70a:	7be2                	ld	s7,56(sp)
 70c:	7c42                	ld	s8,48(sp)
 70e:	7ca2                	ld	s9,40(sp)
 710:	7d02                	ld	s10,32(sp)
 712:	6de2                	ld	s11,24(sp)
 714:	6109                	addi	sp,sp,128
 716:	8082                	ret

0000000000000718 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 718:	715d                	addi	sp,sp,-80
 71a:	ec06                	sd	ra,24(sp)
 71c:	e822                	sd	s0,16(sp)
 71e:	1000                	addi	s0,sp,32
 720:	e010                	sd	a2,0(s0)
 722:	e414                	sd	a3,8(s0)
 724:	e818                	sd	a4,16(s0)
 726:	ec1c                	sd	a5,24(s0)
 728:	03043023          	sd	a6,32(s0)
 72c:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 730:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 734:	8622                	mv	a2,s0
 736:	00000097          	auipc	ra,0x0
 73a:	e04080e7          	jalr	-508(ra) # 53a <vprintf>
}
 73e:	60e2                	ld	ra,24(sp)
 740:	6442                	ld	s0,16(sp)
 742:	6161                	addi	sp,sp,80
 744:	8082                	ret

0000000000000746 <printf>:

void
printf(const char *fmt, ...)
{
 746:	711d                	addi	sp,sp,-96
 748:	ec06                	sd	ra,24(sp)
 74a:	e822                	sd	s0,16(sp)
 74c:	1000                	addi	s0,sp,32
 74e:	e40c                	sd	a1,8(s0)
 750:	e810                	sd	a2,16(s0)
 752:	ec14                	sd	a3,24(s0)
 754:	f018                	sd	a4,32(s0)
 756:	f41c                	sd	a5,40(s0)
 758:	03043823          	sd	a6,48(s0)
 75c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 760:	00840613          	addi	a2,s0,8
 764:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 768:	85aa                	mv	a1,a0
 76a:	4505                	li	a0,1
 76c:	00000097          	auipc	ra,0x0
 770:	dce080e7          	jalr	-562(ra) # 53a <vprintf>
}
 774:	60e2                	ld	ra,24(sp)
 776:	6442                	ld	s0,16(sp)
 778:	6125                	addi	sp,sp,96
 77a:	8082                	ret

000000000000077c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 77c:	1141                	addi	sp,sp,-16
 77e:	e422                	sd	s0,8(sp)
 780:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 782:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 786:	00000797          	auipc	a5,0x0
 78a:	1927b783          	ld	a5,402(a5) # 918 <freep>
 78e:	a805                	j	7be <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 790:	4618                	lw	a4,8(a2)
 792:	9db9                	addw	a1,a1,a4
 794:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 798:	6398                	ld	a4,0(a5)
 79a:	6318                	ld	a4,0(a4)
 79c:	fee53823          	sd	a4,-16(a0)
 7a0:	a091                	j	7e4 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7a2:	ff852703          	lw	a4,-8(a0)
 7a6:	9e39                	addw	a2,a2,a4
 7a8:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7aa:	ff053703          	ld	a4,-16(a0)
 7ae:	e398                	sd	a4,0(a5)
 7b0:	a099                	j	7f6 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7b2:	6398                	ld	a4,0(a5)
 7b4:	00e7e463          	bltu	a5,a4,7bc <free+0x40>
 7b8:	00e6ea63          	bltu	a3,a4,7cc <free+0x50>
{
 7bc:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7be:	fed7fae3          	bgeu	a5,a3,7b2 <free+0x36>
 7c2:	6398                	ld	a4,0(a5)
 7c4:	00e6e463          	bltu	a3,a4,7cc <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7c8:	fee7eae3          	bltu	a5,a4,7bc <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7cc:	ff852583          	lw	a1,-8(a0)
 7d0:	6390                	ld	a2,0(a5)
 7d2:	02059713          	slli	a4,a1,0x20
 7d6:	9301                	srli	a4,a4,0x20
 7d8:	0712                	slli	a4,a4,0x4
 7da:	9736                	add	a4,a4,a3
 7dc:	fae60ae3          	beq	a2,a4,790 <free+0x14>
    bp->s.ptr = p->s.ptr;
 7e0:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7e4:	4790                	lw	a2,8(a5)
 7e6:	02061713          	slli	a4,a2,0x20
 7ea:	9301                	srli	a4,a4,0x20
 7ec:	0712                	slli	a4,a4,0x4
 7ee:	973e                	add	a4,a4,a5
 7f0:	fae689e3          	beq	a3,a4,7a2 <free+0x26>
  } else
    p->s.ptr = bp;
 7f4:	e394                	sd	a3,0(a5)
  freep = p;
 7f6:	00000717          	auipc	a4,0x0
 7fa:	12f73123          	sd	a5,290(a4) # 918 <freep>
}
 7fe:	6422                	ld	s0,8(sp)
 800:	0141                	addi	sp,sp,16
 802:	8082                	ret

0000000000000804 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 804:	7139                	addi	sp,sp,-64
 806:	fc06                	sd	ra,56(sp)
 808:	f822                	sd	s0,48(sp)
 80a:	f426                	sd	s1,40(sp)
 80c:	f04a                	sd	s2,32(sp)
 80e:	ec4e                	sd	s3,24(sp)
 810:	e852                	sd	s4,16(sp)
 812:	e456                	sd	s5,8(sp)
 814:	e05a                	sd	s6,0(sp)
 816:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 818:	02051493          	slli	s1,a0,0x20
 81c:	9081                	srli	s1,s1,0x20
 81e:	04bd                	addi	s1,s1,15
 820:	8091                	srli	s1,s1,0x4
 822:	0014899b          	addiw	s3,s1,1
 826:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 828:	00000517          	auipc	a0,0x0
 82c:	0f053503          	ld	a0,240(a0) # 918 <freep>
 830:	c515                	beqz	a0,85c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 832:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 834:	4798                	lw	a4,8(a5)
 836:	02977f63          	bgeu	a4,s1,874 <malloc+0x70>
 83a:	8a4e                	mv	s4,s3
 83c:	0009871b          	sext.w	a4,s3
 840:	6685                	lui	a3,0x1
 842:	00d77363          	bgeu	a4,a3,848 <malloc+0x44>
 846:	6a05                	lui	s4,0x1
 848:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 84c:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 850:	00000917          	auipc	s2,0x0
 854:	0c890913          	addi	s2,s2,200 # 918 <freep>
  if(p == (char*)-1)
 858:	5afd                	li	s5,-1
 85a:	a88d                	j	8cc <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 85c:	00000797          	auipc	a5,0x0
 860:	0c478793          	addi	a5,a5,196 # 920 <base>
 864:	00000717          	auipc	a4,0x0
 868:	0af73a23          	sd	a5,180(a4) # 918 <freep>
 86c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 86e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 872:	b7e1                	j	83a <malloc+0x36>
      if(p->s.size == nunits)
 874:	02e48b63          	beq	s1,a4,8aa <malloc+0xa6>
        p->s.size -= nunits;
 878:	4137073b          	subw	a4,a4,s3
 87c:	c798                	sw	a4,8(a5)
        p += p->s.size;
 87e:	1702                	slli	a4,a4,0x20
 880:	9301                	srli	a4,a4,0x20
 882:	0712                	slli	a4,a4,0x4
 884:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 886:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 88a:	00000717          	auipc	a4,0x0
 88e:	08a73723          	sd	a0,142(a4) # 918 <freep>
      return (void*)(p + 1);
 892:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 896:	70e2                	ld	ra,56(sp)
 898:	7442                	ld	s0,48(sp)
 89a:	74a2                	ld	s1,40(sp)
 89c:	7902                	ld	s2,32(sp)
 89e:	69e2                	ld	s3,24(sp)
 8a0:	6a42                	ld	s4,16(sp)
 8a2:	6aa2                	ld	s5,8(sp)
 8a4:	6b02                	ld	s6,0(sp)
 8a6:	6121                	addi	sp,sp,64
 8a8:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8aa:	6398                	ld	a4,0(a5)
 8ac:	e118                	sd	a4,0(a0)
 8ae:	bff1                	j	88a <malloc+0x86>
  hp->s.size = nu;
 8b0:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8b4:	0541                	addi	a0,a0,16
 8b6:	00000097          	auipc	ra,0x0
 8ba:	ec6080e7          	jalr	-314(ra) # 77c <free>
  return freep;
 8be:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8c2:	d971                	beqz	a0,896 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8c4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8c6:	4798                	lw	a4,8(a5)
 8c8:	fa9776e3          	bgeu	a4,s1,874 <malloc+0x70>
    if(p == freep)
 8cc:	00093703          	ld	a4,0(s2)
 8d0:	853e                	mv	a0,a5
 8d2:	fef719e3          	bne	a4,a5,8c4 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8d6:	8552                	mv	a0,s4
 8d8:	00000097          	auipc	ra,0x0
 8dc:	b5e080e7          	jalr	-1186(ra) # 436 <sbrk>
  if(p == (char*)-1)
 8e0:	fd5518e3          	bne	a0,s5,8b0 <malloc+0xac>
        return 0;
 8e4:	4501                	li	a0,0
 8e6:	bf45                	j	896 <malloc+0x92>
