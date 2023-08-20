
user/_find：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <basename>:
#include "kernel/fs.h"
#include "kernel/stat.h"
#include "user/user.h"

/* retrieve the filename from whole path */
char *basename(char *pathname) {
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	addi	s0,sp,32
  char *prev = 0;
  char *curr = strchr(pathname, '/');
   a:	02f00593          	li	a1,47
   e:	00000097          	auipc	ra,0x0
  12:	2c0080e7          	jalr	704(ra) # 2ce <strchr>
  while (curr != 0) {
  16:	c105                	beqz	a0,36 <basename+0x36>
    prev = curr;
    curr = strchr(curr + 1, '/');
  18:	84aa                	mv	s1,a0
  1a:	02f00593          	li	a1,47
  1e:	0505                	addi	a0,a0,1
  20:	00000097          	auipc	ra,0x0
  24:	2ae080e7          	jalr	686(ra) # 2ce <strchr>
  while (curr != 0) {
  28:	f965                	bnez	a0,18 <basename+0x18>
  }
  return prev;
}
  2a:	8526                	mv	a0,s1
  2c:	60e2                	ld	ra,24(sp)
  2e:	6442                	ld	s0,16(sp)
  30:	64a2                	ld	s1,8(sp)
  32:	6105                	addi	sp,sp,32
  34:	8082                	ret
  char *prev = 0;
  36:	84aa                	mv	s1,a0
  return prev;
  38:	bfcd                	j	2a <basename+0x2a>

000000000000003a <find>:

/* recursive */
void find(char *curr_path, char *target) {
  3a:	d9010113          	addi	sp,sp,-624
  3e:	26113423          	sd	ra,616(sp)
  42:	26813023          	sd	s0,608(sp)
  46:	24913c23          	sd	s1,600(sp)
  4a:	25213823          	sd	s2,592(sp)
  4e:	25313423          	sd	s3,584(sp)
  52:	25413023          	sd	s4,576(sp)
  56:	23513c23          	sd	s5,568(sp)
  5a:	23613823          	sd	s6,560(sp)
  5e:	1c80                	addi	s0,sp,624
  60:	892a                	mv	s2,a0
  62:	8a2e                	mv	s4,a1
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;
  if ((fd = open(curr_path, O_RDONLY)) < 0) {
  64:	4581                	li	a1,0
  66:	00000097          	auipc	ra,0x0
  6a:	486080e7          	jalr	1158(ra) # 4ec <open>
  6e:	04054863          	bltz	a0,be <find+0x84>
  72:	84aa                	mv	s1,a0
    fprintf(2, "find: cannot open %s\n", curr_path);
    return;
  }

  if (fstat(fd, &st) < 0) {
  74:	d9840593          	addi	a1,s0,-616
  78:	00000097          	auipc	ra,0x0
  7c:	48c080e7          	jalr	1164(ra) # 504 <fstat>
  80:	06054c63          	bltz	a0,f8 <find+0xbe>
    fprintf(2, "find: cannot stat %s\n", curr_path);
    close(fd);
    return;
  }

  switch (st.type) {
  84:	da041783          	lh	a5,-608(s0)
  88:	0007869b          	sext.w	a3,a5
  8c:	4705                	li	a4,1
  8e:	08e68f63          	beq	a3,a4,12c <find+0xf2>
  92:	4709                	li	a4,2
  94:	02e69f63          	bne	a3,a4,d2 <find+0x98>

  case T_FILE:;
    char *f_name = basename(curr_path);
  98:	854a                	mv	a0,s2
  9a:	00000097          	auipc	ra,0x0
  9e:	f66080e7          	jalr	-154(ra) # 0 <basename>
    int match = 1;
    if (f_name == 0 || strcmp(f_name + 1, target) != 0) {
  a2:	c901                	beqz	a0,b2 <find+0x78>
  a4:	85d2                	mv	a1,s4
  a6:	0505                	addi	a0,a0,1
  a8:	00000097          	auipc	ra,0x0
  ac:	1aa080e7          	jalr	426(ra) # 252 <strcmp>
  b0:	c525                	beqz	a0,118 <find+0xde>
      match = 0;
    }
    if (match)
      printf("%s\n", curr_path);
    close(fd);
  b2:	8526                	mv	a0,s1
  b4:	00000097          	auipc	ra,0x0
  b8:	420080e7          	jalr	1056(ra) # 4d4 <close>
    break;
  bc:	a819                	j	d2 <find+0x98>
    fprintf(2, "find: cannot open %s\n", curr_path);
  be:	864a                	mv	a2,s2
  c0:	00001597          	auipc	a1,0x1
  c4:	92858593          	addi	a1,a1,-1752 # 9e8 <malloc+0xe6>
  c8:	4509                	li	a0,2
  ca:	00000097          	auipc	ra,0x0
  ce:	74c080e7          	jalr	1868(ra) # 816 <fprintf>
      find(buf, target); // recurse
    }
    close(fd);
    break;
  }
}
  d2:	26813083          	ld	ra,616(sp)
  d6:	26013403          	ld	s0,608(sp)
  da:	25813483          	ld	s1,600(sp)
  de:	25013903          	ld	s2,592(sp)
  e2:	24813983          	ld	s3,584(sp)
  e6:	24013a03          	ld	s4,576(sp)
  ea:	23813a83          	ld	s5,568(sp)
  ee:	23013b03          	ld	s6,560(sp)
  f2:	27010113          	addi	sp,sp,624
  f6:	8082                	ret
    fprintf(2, "find: cannot stat %s\n", curr_path);
  f8:	864a                	mv	a2,s2
  fa:	00001597          	auipc	a1,0x1
  fe:	90658593          	addi	a1,a1,-1786 # a00 <malloc+0xfe>
 102:	4509                	li	a0,2
 104:	00000097          	auipc	ra,0x0
 108:	712080e7          	jalr	1810(ra) # 816 <fprintf>
    close(fd);
 10c:	8526                	mv	a0,s1
 10e:	00000097          	auipc	ra,0x0
 112:	3c6080e7          	jalr	966(ra) # 4d4 <close>
    return;
 116:	bf75                	j	d2 <find+0x98>
      printf("%s\n", curr_path);
 118:	85ca                	mv	a1,s2
 11a:	00001517          	auipc	a0,0x1
 11e:	8fe50513          	addi	a0,a0,-1794 # a18 <malloc+0x116>
 122:	00000097          	auipc	ra,0x0
 126:	722080e7          	jalr	1826(ra) # 844 <printf>
 12a:	b761                	j	b2 <find+0x78>
    memset(buf, 0, sizeof(buf));
 12c:	20000613          	li	a2,512
 130:	4581                	li	a1,0
 132:	dc040513          	addi	a0,s0,-576
 136:	00000097          	auipc	ra,0x0
 13a:	172080e7          	jalr	370(ra) # 2a8 <memset>
    uint curr_path_len = strlen(curr_path);
 13e:	854a                	mv	a0,s2
 140:	00000097          	auipc	ra,0x0
 144:	13e080e7          	jalr	318(ra) # 27e <strlen>
 148:	0005099b          	sext.w	s3,a0
    memcpy(buf, curr_path, curr_path_len);
 14c:	864e                	mv	a2,s3
 14e:	85ca                	mv	a1,s2
 150:	dc040513          	addi	a0,s0,-576
 154:	00000097          	auipc	ra,0x0
 158:	338080e7          	jalr	824(ra) # 48c <memcpy>
    buf[curr_path_len] = '/';
 15c:	1982                	slli	s3,s3,0x20
 15e:	0209d993          	srli	s3,s3,0x20
 162:	fc040793          	addi	a5,s0,-64
 166:	97ce                	add	a5,a5,s3
 168:	02f00713          	li	a4,47
 16c:	e0e78023          	sb	a4,-512(a5)
    p = buf + curr_path_len + 1;
 170:	0985                	addi	s3,s3,1
 172:	dc040793          	addi	a5,s0,-576
 176:	99be                	add	s3,s3,a5
      if (de.inum == 0 || strcmp(de.name, ".") == 0 ||
 178:	00001a97          	auipc	s5,0x1
 17c:	8a8a8a93          	addi	s5,s5,-1880 # a20 <malloc+0x11e>
          strcmp(de.name, "..") == 0)
 180:	00001b17          	auipc	s6,0x1
 184:	8a8b0b13          	addi	s6,s6,-1880 # a28 <malloc+0x126>
      if (de.inum == 0 || strcmp(de.name, ".") == 0 ||
 188:	db240913          	addi	s2,s0,-590
    while (read(fd, &de, sizeof(de)) == sizeof(de)) {
 18c:	4641                	li	a2,16
 18e:	db040593          	addi	a1,s0,-592
 192:	8526                	mv	a0,s1
 194:	00000097          	auipc	ra,0x0
 198:	330080e7          	jalr	816(ra) # 4c4 <read>
 19c:	47c1                	li	a5,16
 19e:	04f51563          	bne	a0,a5,1e8 <find+0x1ae>
      if (de.inum == 0 || strcmp(de.name, ".") == 0 ||
 1a2:	db045783          	lhu	a5,-592(s0)
 1a6:	d3fd                	beqz	a5,18c <find+0x152>
 1a8:	85d6                	mv	a1,s5
 1aa:	854a                	mv	a0,s2
 1ac:	00000097          	auipc	ra,0x0
 1b0:	0a6080e7          	jalr	166(ra) # 252 <strcmp>
 1b4:	dd61                	beqz	a0,18c <find+0x152>
          strcmp(de.name, "..") == 0)
 1b6:	85da                	mv	a1,s6
 1b8:	854a                	mv	a0,s2
 1ba:	00000097          	auipc	ra,0x0
 1be:	098080e7          	jalr	152(ra) # 252 <strcmp>
      if (de.inum == 0 || strcmp(de.name, ".") == 0 ||
 1c2:	d569                	beqz	a0,18c <find+0x152>
      memcpy(p, de.name, DIRSIZ);
 1c4:	4639                	li	a2,14
 1c6:	db240593          	addi	a1,s0,-590
 1ca:	854e                	mv	a0,s3
 1cc:	00000097          	auipc	ra,0x0
 1d0:	2c0080e7          	jalr	704(ra) # 48c <memcpy>
      p[DIRSIZ] = 0;
 1d4:	00098723          	sb	zero,14(s3)
      find(buf, target); // recurse
 1d8:	85d2                	mv	a1,s4
 1da:	dc040513          	addi	a0,s0,-576
 1de:	00000097          	auipc	ra,0x0
 1e2:	e5c080e7          	jalr	-420(ra) # 3a <find>
 1e6:	b75d                	j	18c <find+0x152>
    close(fd);
 1e8:	8526                	mv	a0,s1
 1ea:	00000097          	auipc	ra,0x0
 1ee:	2ea080e7          	jalr	746(ra) # 4d4 <close>
    break;
 1f2:	b5c5                	j	d2 <find+0x98>

00000000000001f4 <main>:

int main(int argc, char *argv[]) {
 1f4:	1141                	addi	sp,sp,-16
 1f6:	e406                	sd	ra,8(sp)
 1f8:	e022                	sd	s0,0(sp)
 1fa:	0800                	addi	s0,sp,16
  if (argc != 3) {
 1fc:	470d                	li	a4,3
 1fe:	02e50063          	beq	a0,a4,21e <main+0x2a>
    fprintf(2, "usage: find [directory] [target filename]\n");
 202:	00001597          	auipc	a1,0x1
 206:	82e58593          	addi	a1,a1,-2002 # a30 <malloc+0x12e>
 20a:	4509                	li	a0,2
 20c:	00000097          	auipc	ra,0x0
 210:	60a080e7          	jalr	1546(ra) # 816 <fprintf>
    exit(1);
 214:	4505                	li	a0,1
 216:	00000097          	auipc	ra,0x0
 21a:	296080e7          	jalr	662(ra) # 4ac <exit>
 21e:	87ae                	mv	a5,a1
  }
  find(argv[1], argv[2]);
 220:	698c                	ld	a1,16(a1)
 222:	6788                	ld	a0,8(a5)
 224:	00000097          	auipc	ra,0x0
 228:	e16080e7          	jalr	-490(ra) # 3a <find>
  exit(0);
 22c:	4501                	li	a0,0
 22e:	00000097          	auipc	ra,0x0
 232:	27e080e7          	jalr	638(ra) # 4ac <exit>

0000000000000236 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 236:	1141                	addi	sp,sp,-16
 238:	e422                	sd	s0,8(sp)
 23a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 23c:	87aa                	mv	a5,a0
 23e:	0585                	addi	a1,a1,1
 240:	0785                	addi	a5,a5,1
 242:	fff5c703          	lbu	a4,-1(a1)
 246:	fee78fa3          	sb	a4,-1(a5)
 24a:	fb75                	bnez	a4,23e <strcpy+0x8>
    ;
  return os;
}
 24c:	6422                	ld	s0,8(sp)
 24e:	0141                	addi	sp,sp,16
 250:	8082                	ret

0000000000000252 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 252:	1141                	addi	sp,sp,-16
 254:	e422                	sd	s0,8(sp)
 256:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 258:	00054783          	lbu	a5,0(a0)
 25c:	cb91                	beqz	a5,270 <strcmp+0x1e>
 25e:	0005c703          	lbu	a4,0(a1)
 262:	00f71763          	bne	a4,a5,270 <strcmp+0x1e>
    p++, q++;
 266:	0505                	addi	a0,a0,1
 268:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 26a:	00054783          	lbu	a5,0(a0)
 26e:	fbe5                	bnez	a5,25e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 270:	0005c503          	lbu	a0,0(a1)
}
 274:	40a7853b          	subw	a0,a5,a0
 278:	6422                	ld	s0,8(sp)
 27a:	0141                	addi	sp,sp,16
 27c:	8082                	ret

000000000000027e <strlen>:

uint
strlen(const char *s)
{
 27e:	1141                	addi	sp,sp,-16
 280:	e422                	sd	s0,8(sp)
 282:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 284:	00054783          	lbu	a5,0(a0)
 288:	cf91                	beqz	a5,2a4 <strlen+0x26>
 28a:	0505                	addi	a0,a0,1
 28c:	87aa                	mv	a5,a0
 28e:	4685                	li	a3,1
 290:	9e89                	subw	a3,a3,a0
 292:	00f6853b          	addw	a0,a3,a5
 296:	0785                	addi	a5,a5,1
 298:	fff7c703          	lbu	a4,-1(a5)
 29c:	fb7d                	bnez	a4,292 <strlen+0x14>
    ;
  return n;
}
 29e:	6422                	ld	s0,8(sp)
 2a0:	0141                	addi	sp,sp,16
 2a2:	8082                	ret
  for(n = 0; s[n]; n++)
 2a4:	4501                	li	a0,0
 2a6:	bfe5                	j	29e <strlen+0x20>

00000000000002a8 <memset>:

void*
memset(void *dst, int c, uint n)
{
 2a8:	1141                	addi	sp,sp,-16
 2aa:	e422                	sd	s0,8(sp)
 2ac:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2ae:	ce09                	beqz	a2,2c8 <memset+0x20>
 2b0:	87aa                	mv	a5,a0
 2b2:	fff6071b          	addiw	a4,a2,-1
 2b6:	1702                	slli	a4,a4,0x20
 2b8:	9301                	srli	a4,a4,0x20
 2ba:	0705                	addi	a4,a4,1
 2bc:	972a                	add	a4,a4,a0
    cdst[i] = c;
 2be:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 2c2:	0785                	addi	a5,a5,1
 2c4:	fee79de3          	bne	a5,a4,2be <memset+0x16>
  }
  return dst;
}
 2c8:	6422                	ld	s0,8(sp)
 2ca:	0141                	addi	sp,sp,16
 2cc:	8082                	ret

00000000000002ce <strchr>:

char*
strchr(const char *s, char c)
{
 2ce:	1141                	addi	sp,sp,-16
 2d0:	e422                	sd	s0,8(sp)
 2d2:	0800                	addi	s0,sp,16
  for(; *s; s++)
 2d4:	00054783          	lbu	a5,0(a0)
 2d8:	cb99                	beqz	a5,2ee <strchr+0x20>
    if(*s == c)
 2da:	00f58763          	beq	a1,a5,2e8 <strchr+0x1a>
  for(; *s; s++)
 2de:	0505                	addi	a0,a0,1
 2e0:	00054783          	lbu	a5,0(a0)
 2e4:	fbfd                	bnez	a5,2da <strchr+0xc>
      return (char*)s;
  return 0;
 2e6:	4501                	li	a0,0
}
 2e8:	6422                	ld	s0,8(sp)
 2ea:	0141                	addi	sp,sp,16
 2ec:	8082                	ret
  return 0;
 2ee:	4501                	li	a0,0
 2f0:	bfe5                	j	2e8 <strchr+0x1a>

00000000000002f2 <gets>:

char*
gets(char *buf, int max)
{
 2f2:	711d                	addi	sp,sp,-96
 2f4:	ec86                	sd	ra,88(sp)
 2f6:	e8a2                	sd	s0,80(sp)
 2f8:	e4a6                	sd	s1,72(sp)
 2fa:	e0ca                	sd	s2,64(sp)
 2fc:	fc4e                	sd	s3,56(sp)
 2fe:	f852                	sd	s4,48(sp)
 300:	f456                	sd	s5,40(sp)
 302:	f05a                	sd	s6,32(sp)
 304:	ec5e                	sd	s7,24(sp)
 306:	1080                	addi	s0,sp,96
 308:	8baa                	mv	s7,a0
 30a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 30c:	892a                	mv	s2,a0
 30e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 310:	4aa9                	li	s5,10
 312:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 314:	89a6                	mv	s3,s1
 316:	2485                	addiw	s1,s1,1
 318:	0344d863          	bge	s1,s4,348 <gets+0x56>
    cc = read(0, &c, 1);
 31c:	4605                	li	a2,1
 31e:	faf40593          	addi	a1,s0,-81
 322:	4501                	li	a0,0
 324:	00000097          	auipc	ra,0x0
 328:	1a0080e7          	jalr	416(ra) # 4c4 <read>
    if(cc < 1)
 32c:	00a05e63          	blez	a0,348 <gets+0x56>
    buf[i++] = c;
 330:	faf44783          	lbu	a5,-81(s0)
 334:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 338:	01578763          	beq	a5,s5,346 <gets+0x54>
 33c:	0905                	addi	s2,s2,1
 33e:	fd679be3          	bne	a5,s6,314 <gets+0x22>
  for(i=0; i+1 < max; ){
 342:	89a6                	mv	s3,s1
 344:	a011                	j	348 <gets+0x56>
 346:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 348:	99de                	add	s3,s3,s7
 34a:	00098023          	sb	zero,0(s3)
  return buf;
}
 34e:	855e                	mv	a0,s7
 350:	60e6                	ld	ra,88(sp)
 352:	6446                	ld	s0,80(sp)
 354:	64a6                	ld	s1,72(sp)
 356:	6906                	ld	s2,64(sp)
 358:	79e2                	ld	s3,56(sp)
 35a:	7a42                	ld	s4,48(sp)
 35c:	7aa2                	ld	s5,40(sp)
 35e:	7b02                	ld	s6,32(sp)
 360:	6be2                	ld	s7,24(sp)
 362:	6125                	addi	sp,sp,96
 364:	8082                	ret

0000000000000366 <stat>:

int
stat(const char *n, struct stat *st)
{
 366:	1101                	addi	sp,sp,-32
 368:	ec06                	sd	ra,24(sp)
 36a:	e822                	sd	s0,16(sp)
 36c:	e426                	sd	s1,8(sp)
 36e:	e04a                	sd	s2,0(sp)
 370:	1000                	addi	s0,sp,32
 372:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 374:	4581                	li	a1,0
 376:	00000097          	auipc	ra,0x0
 37a:	176080e7          	jalr	374(ra) # 4ec <open>
  if(fd < 0)
 37e:	02054563          	bltz	a0,3a8 <stat+0x42>
 382:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 384:	85ca                	mv	a1,s2
 386:	00000097          	auipc	ra,0x0
 38a:	17e080e7          	jalr	382(ra) # 504 <fstat>
 38e:	892a                	mv	s2,a0
  close(fd);
 390:	8526                	mv	a0,s1
 392:	00000097          	auipc	ra,0x0
 396:	142080e7          	jalr	322(ra) # 4d4 <close>
  return r;
}
 39a:	854a                	mv	a0,s2
 39c:	60e2                	ld	ra,24(sp)
 39e:	6442                	ld	s0,16(sp)
 3a0:	64a2                	ld	s1,8(sp)
 3a2:	6902                	ld	s2,0(sp)
 3a4:	6105                	addi	sp,sp,32
 3a6:	8082                	ret
    return -1;
 3a8:	597d                	li	s2,-1
 3aa:	bfc5                	j	39a <stat+0x34>

00000000000003ac <atoi>:

int
atoi(const char *s)
{
 3ac:	1141                	addi	sp,sp,-16
 3ae:	e422                	sd	s0,8(sp)
 3b0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3b2:	00054603          	lbu	a2,0(a0)
 3b6:	fd06079b          	addiw	a5,a2,-48
 3ba:	0ff7f793          	andi	a5,a5,255
 3be:	4725                	li	a4,9
 3c0:	02f76963          	bltu	a4,a5,3f2 <atoi+0x46>
 3c4:	86aa                	mv	a3,a0
  n = 0;
 3c6:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 3c8:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 3ca:	0685                	addi	a3,a3,1
 3cc:	0025179b          	slliw	a5,a0,0x2
 3d0:	9fa9                	addw	a5,a5,a0
 3d2:	0017979b          	slliw	a5,a5,0x1
 3d6:	9fb1                	addw	a5,a5,a2
 3d8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 3dc:	0006c603          	lbu	a2,0(a3)
 3e0:	fd06071b          	addiw	a4,a2,-48
 3e4:	0ff77713          	andi	a4,a4,255
 3e8:	fee5f1e3          	bgeu	a1,a4,3ca <atoi+0x1e>
  return n;
}
 3ec:	6422                	ld	s0,8(sp)
 3ee:	0141                	addi	sp,sp,16
 3f0:	8082                	ret
  n = 0;
 3f2:	4501                	li	a0,0
 3f4:	bfe5                	j	3ec <atoi+0x40>

00000000000003f6 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 3f6:	1141                	addi	sp,sp,-16
 3f8:	e422                	sd	s0,8(sp)
 3fa:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 3fc:	02b57663          	bgeu	a0,a1,428 <memmove+0x32>
    while(n-- > 0)
 400:	02c05163          	blez	a2,422 <memmove+0x2c>
 404:	fff6079b          	addiw	a5,a2,-1
 408:	1782                	slli	a5,a5,0x20
 40a:	9381                	srli	a5,a5,0x20
 40c:	0785                	addi	a5,a5,1
 40e:	97aa                	add	a5,a5,a0
  dst = vdst;
 410:	872a                	mv	a4,a0
      *dst++ = *src++;
 412:	0585                	addi	a1,a1,1
 414:	0705                	addi	a4,a4,1
 416:	fff5c683          	lbu	a3,-1(a1)
 41a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 41e:	fee79ae3          	bne	a5,a4,412 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 422:	6422                	ld	s0,8(sp)
 424:	0141                	addi	sp,sp,16
 426:	8082                	ret
    dst += n;
 428:	00c50733          	add	a4,a0,a2
    src += n;
 42c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 42e:	fec05ae3          	blez	a2,422 <memmove+0x2c>
 432:	fff6079b          	addiw	a5,a2,-1
 436:	1782                	slli	a5,a5,0x20
 438:	9381                	srli	a5,a5,0x20
 43a:	fff7c793          	not	a5,a5
 43e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 440:	15fd                	addi	a1,a1,-1
 442:	177d                	addi	a4,a4,-1
 444:	0005c683          	lbu	a3,0(a1)
 448:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 44c:	fee79ae3          	bne	a5,a4,440 <memmove+0x4a>
 450:	bfc9                	j	422 <memmove+0x2c>

0000000000000452 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 452:	1141                	addi	sp,sp,-16
 454:	e422                	sd	s0,8(sp)
 456:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 458:	ca05                	beqz	a2,488 <memcmp+0x36>
 45a:	fff6069b          	addiw	a3,a2,-1
 45e:	1682                	slli	a3,a3,0x20
 460:	9281                	srli	a3,a3,0x20
 462:	0685                	addi	a3,a3,1
 464:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 466:	00054783          	lbu	a5,0(a0)
 46a:	0005c703          	lbu	a4,0(a1)
 46e:	00e79863          	bne	a5,a4,47e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 472:	0505                	addi	a0,a0,1
    p2++;
 474:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 476:	fed518e3          	bne	a0,a3,466 <memcmp+0x14>
  }
  return 0;
 47a:	4501                	li	a0,0
 47c:	a019                	j	482 <memcmp+0x30>
      return *p1 - *p2;
 47e:	40e7853b          	subw	a0,a5,a4
}
 482:	6422                	ld	s0,8(sp)
 484:	0141                	addi	sp,sp,16
 486:	8082                	ret
  return 0;
 488:	4501                	li	a0,0
 48a:	bfe5                	j	482 <memcmp+0x30>

000000000000048c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 48c:	1141                	addi	sp,sp,-16
 48e:	e406                	sd	ra,8(sp)
 490:	e022                	sd	s0,0(sp)
 492:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 494:	00000097          	auipc	ra,0x0
 498:	f62080e7          	jalr	-158(ra) # 3f6 <memmove>
}
 49c:	60a2                	ld	ra,8(sp)
 49e:	6402                	ld	s0,0(sp)
 4a0:	0141                	addi	sp,sp,16
 4a2:	8082                	ret

00000000000004a4 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4a4:	4885                	li	a7,1
 ecall
 4a6:	00000073          	ecall
 ret
 4aa:	8082                	ret

00000000000004ac <exit>:
.global exit
exit:
 li a7, SYS_exit
 4ac:	4889                	li	a7,2
 ecall
 4ae:	00000073          	ecall
 ret
 4b2:	8082                	ret

00000000000004b4 <wait>:
.global wait
wait:
 li a7, SYS_wait
 4b4:	488d                	li	a7,3
 ecall
 4b6:	00000073          	ecall
 ret
 4ba:	8082                	ret

00000000000004bc <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4bc:	4891                	li	a7,4
 ecall
 4be:	00000073          	ecall
 ret
 4c2:	8082                	ret

00000000000004c4 <read>:
.global read
read:
 li a7, SYS_read
 4c4:	4895                	li	a7,5
 ecall
 4c6:	00000073          	ecall
 ret
 4ca:	8082                	ret

00000000000004cc <write>:
.global write
write:
 li a7, SYS_write
 4cc:	48c1                	li	a7,16
 ecall
 4ce:	00000073          	ecall
 ret
 4d2:	8082                	ret

00000000000004d4 <close>:
.global close
close:
 li a7, SYS_close
 4d4:	48d5                	li	a7,21
 ecall
 4d6:	00000073          	ecall
 ret
 4da:	8082                	ret

00000000000004dc <kill>:
.global kill
kill:
 li a7, SYS_kill
 4dc:	4899                	li	a7,6
 ecall
 4de:	00000073          	ecall
 ret
 4e2:	8082                	ret

00000000000004e4 <exec>:
.global exec
exec:
 li a7, SYS_exec
 4e4:	489d                	li	a7,7
 ecall
 4e6:	00000073          	ecall
 ret
 4ea:	8082                	ret

00000000000004ec <open>:
.global open
open:
 li a7, SYS_open
 4ec:	48bd                	li	a7,15
 ecall
 4ee:	00000073          	ecall
 ret
 4f2:	8082                	ret

00000000000004f4 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 4f4:	48c5                	li	a7,17
 ecall
 4f6:	00000073          	ecall
 ret
 4fa:	8082                	ret

00000000000004fc <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 4fc:	48c9                	li	a7,18
 ecall
 4fe:	00000073          	ecall
 ret
 502:	8082                	ret

0000000000000504 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 504:	48a1                	li	a7,8
 ecall
 506:	00000073          	ecall
 ret
 50a:	8082                	ret

000000000000050c <link>:
.global link
link:
 li a7, SYS_link
 50c:	48cd                	li	a7,19
 ecall
 50e:	00000073          	ecall
 ret
 512:	8082                	ret

0000000000000514 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 514:	48d1                	li	a7,20
 ecall
 516:	00000073          	ecall
 ret
 51a:	8082                	ret

000000000000051c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 51c:	48a5                	li	a7,9
 ecall
 51e:	00000073          	ecall
 ret
 522:	8082                	ret

0000000000000524 <dup>:
.global dup
dup:
 li a7, SYS_dup
 524:	48a9                	li	a7,10
 ecall
 526:	00000073          	ecall
 ret
 52a:	8082                	ret

000000000000052c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 52c:	48ad                	li	a7,11
 ecall
 52e:	00000073          	ecall
 ret
 532:	8082                	ret

0000000000000534 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 534:	48b1                	li	a7,12
 ecall
 536:	00000073          	ecall
 ret
 53a:	8082                	ret

000000000000053c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 53c:	48b5                	li	a7,13
 ecall
 53e:	00000073          	ecall
 ret
 542:	8082                	ret

0000000000000544 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 544:	48b9                	li	a7,14
 ecall
 546:	00000073          	ecall
 ret
 54a:	8082                	ret

000000000000054c <trace>:
.global trace
trace:
 li a7, SYS_trace
 54c:	48d9                	li	a7,22
 ecall
 54e:	00000073          	ecall
 ret
 552:	8082                	ret

0000000000000554 <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 554:	48dd                	li	a7,23
 ecall
 556:	00000073          	ecall
 ret
 55a:	8082                	ret

000000000000055c <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 55c:	48e1                	li	a7,24
 ecall
 55e:	00000073          	ecall
 ret
 562:	8082                	ret

0000000000000564 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 564:	48e5                	li	a7,25
 ecall
 566:	00000073          	ecall
 ret
 56a:	8082                	ret

000000000000056c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 56c:	1101                	addi	sp,sp,-32
 56e:	ec06                	sd	ra,24(sp)
 570:	e822                	sd	s0,16(sp)
 572:	1000                	addi	s0,sp,32
 574:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 578:	4605                	li	a2,1
 57a:	fef40593          	addi	a1,s0,-17
 57e:	00000097          	auipc	ra,0x0
 582:	f4e080e7          	jalr	-178(ra) # 4cc <write>
}
 586:	60e2                	ld	ra,24(sp)
 588:	6442                	ld	s0,16(sp)
 58a:	6105                	addi	sp,sp,32
 58c:	8082                	ret

000000000000058e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 58e:	7139                	addi	sp,sp,-64
 590:	fc06                	sd	ra,56(sp)
 592:	f822                	sd	s0,48(sp)
 594:	f426                	sd	s1,40(sp)
 596:	f04a                	sd	s2,32(sp)
 598:	ec4e                	sd	s3,24(sp)
 59a:	0080                	addi	s0,sp,64
 59c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 59e:	c299                	beqz	a3,5a4 <printint+0x16>
 5a0:	0805c863          	bltz	a1,630 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5a4:	2581                	sext.w	a1,a1
  neg = 0;
 5a6:	4881                	li	a7,0
 5a8:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5ac:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5ae:	2601                	sext.w	a2,a2
 5b0:	00000517          	auipc	a0,0x0
 5b4:	4b850513          	addi	a0,a0,1208 # a68 <digits>
 5b8:	883a                	mv	a6,a4
 5ba:	2705                	addiw	a4,a4,1
 5bc:	02c5f7bb          	remuw	a5,a1,a2
 5c0:	1782                	slli	a5,a5,0x20
 5c2:	9381                	srli	a5,a5,0x20
 5c4:	97aa                	add	a5,a5,a0
 5c6:	0007c783          	lbu	a5,0(a5)
 5ca:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5ce:	0005879b          	sext.w	a5,a1
 5d2:	02c5d5bb          	divuw	a1,a1,a2
 5d6:	0685                	addi	a3,a3,1
 5d8:	fec7f0e3          	bgeu	a5,a2,5b8 <printint+0x2a>
  if(neg)
 5dc:	00088b63          	beqz	a7,5f2 <printint+0x64>
    buf[i++] = '-';
 5e0:	fd040793          	addi	a5,s0,-48
 5e4:	973e                	add	a4,a4,a5
 5e6:	02d00793          	li	a5,45
 5ea:	fef70823          	sb	a5,-16(a4)
 5ee:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 5f2:	02e05863          	blez	a4,622 <printint+0x94>
 5f6:	fc040793          	addi	a5,s0,-64
 5fa:	00e78933          	add	s2,a5,a4
 5fe:	fff78993          	addi	s3,a5,-1
 602:	99ba                	add	s3,s3,a4
 604:	377d                	addiw	a4,a4,-1
 606:	1702                	slli	a4,a4,0x20
 608:	9301                	srli	a4,a4,0x20
 60a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 60e:	fff94583          	lbu	a1,-1(s2)
 612:	8526                	mv	a0,s1
 614:	00000097          	auipc	ra,0x0
 618:	f58080e7          	jalr	-168(ra) # 56c <putc>
  while(--i >= 0)
 61c:	197d                	addi	s2,s2,-1
 61e:	ff3918e3          	bne	s2,s3,60e <printint+0x80>
}
 622:	70e2                	ld	ra,56(sp)
 624:	7442                	ld	s0,48(sp)
 626:	74a2                	ld	s1,40(sp)
 628:	7902                	ld	s2,32(sp)
 62a:	69e2                	ld	s3,24(sp)
 62c:	6121                	addi	sp,sp,64
 62e:	8082                	ret
    x = -xx;
 630:	40b005bb          	negw	a1,a1
    neg = 1;
 634:	4885                	li	a7,1
    x = -xx;
 636:	bf8d                	j	5a8 <printint+0x1a>

0000000000000638 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 638:	7119                	addi	sp,sp,-128
 63a:	fc86                	sd	ra,120(sp)
 63c:	f8a2                	sd	s0,112(sp)
 63e:	f4a6                	sd	s1,104(sp)
 640:	f0ca                	sd	s2,96(sp)
 642:	ecce                	sd	s3,88(sp)
 644:	e8d2                	sd	s4,80(sp)
 646:	e4d6                	sd	s5,72(sp)
 648:	e0da                	sd	s6,64(sp)
 64a:	fc5e                	sd	s7,56(sp)
 64c:	f862                	sd	s8,48(sp)
 64e:	f466                	sd	s9,40(sp)
 650:	f06a                	sd	s10,32(sp)
 652:	ec6e                	sd	s11,24(sp)
 654:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 656:	0005c903          	lbu	s2,0(a1)
 65a:	18090f63          	beqz	s2,7f8 <vprintf+0x1c0>
 65e:	8aaa                	mv	s5,a0
 660:	8b32                	mv	s6,a2
 662:	00158493          	addi	s1,a1,1
  state = 0;
 666:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 668:	02500a13          	li	s4,37
      if(c == 'd'){
 66c:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 670:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 674:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 678:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 67c:	00000b97          	auipc	s7,0x0
 680:	3ecb8b93          	addi	s7,s7,1004 # a68 <digits>
 684:	a839                	j	6a2 <vprintf+0x6a>
        putc(fd, c);
 686:	85ca                	mv	a1,s2
 688:	8556                	mv	a0,s5
 68a:	00000097          	auipc	ra,0x0
 68e:	ee2080e7          	jalr	-286(ra) # 56c <putc>
 692:	a019                	j	698 <vprintf+0x60>
    } else if(state == '%'){
 694:	01498f63          	beq	s3,s4,6b2 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 698:	0485                	addi	s1,s1,1
 69a:	fff4c903          	lbu	s2,-1(s1)
 69e:	14090d63          	beqz	s2,7f8 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6a2:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6a6:	fe0997e3          	bnez	s3,694 <vprintf+0x5c>
      if(c == '%'){
 6aa:	fd479ee3          	bne	a5,s4,686 <vprintf+0x4e>
        state = '%';
 6ae:	89be                	mv	s3,a5
 6b0:	b7e5                	j	698 <vprintf+0x60>
      if(c == 'd'){
 6b2:	05878063          	beq	a5,s8,6f2 <vprintf+0xba>
      } else if(c == 'l') {
 6b6:	05978c63          	beq	a5,s9,70e <vprintf+0xd6>
      } else if(c == 'x') {
 6ba:	07a78863          	beq	a5,s10,72a <vprintf+0xf2>
      } else if(c == 'p') {
 6be:	09b78463          	beq	a5,s11,746 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6c2:	07300713          	li	a4,115
 6c6:	0ce78663          	beq	a5,a4,792 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6ca:	06300713          	li	a4,99
 6ce:	0ee78e63          	beq	a5,a4,7ca <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 6d2:	11478863          	beq	a5,s4,7e2 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6d6:	85d2                	mv	a1,s4
 6d8:	8556                	mv	a0,s5
 6da:	00000097          	auipc	ra,0x0
 6de:	e92080e7          	jalr	-366(ra) # 56c <putc>
        putc(fd, c);
 6e2:	85ca                	mv	a1,s2
 6e4:	8556                	mv	a0,s5
 6e6:	00000097          	auipc	ra,0x0
 6ea:	e86080e7          	jalr	-378(ra) # 56c <putc>
      }
      state = 0;
 6ee:	4981                	li	s3,0
 6f0:	b765                	j	698 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 6f2:	008b0913          	addi	s2,s6,8
 6f6:	4685                	li	a3,1
 6f8:	4629                	li	a2,10
 6fa:	000b2583          	lw	a1,0(s6)
 6fe:	8556                	mv	a0,s5
 700:	00000097          	auipc	ra,0x0
 704:	e8e080e7          	jalr	-370(ra) # 58e <printint>
 708:	8b4a                	mv	s6,s2
      state = 0;
 70a:	4981                	li	s3,0
 70c:	b771                	j	698 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 70e:	008b0913          	addi	s2,s6,8
 712:	4681                	li	a3,0
 714:	4629                	li	a2,10
 716:	000b2583          	lw	a1,0(s6)
 71a:	8556                	mv	a0,s5
 71c:	00000097          	auipc	ra,0x0
 720:	e72080e7          	jalr	-398(ra) # 58e <printint>
 724:	8b4a                	mv	s6,s2
      state = 0;
 726:	4981                	li	s3,0
 728:	bf85                	j	698 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 72a:	008b0913          	addi	s2,s6,8
 72e:	4681                	li	a3,0
 730:	4641                	li	a2,16
 732:	000b2583          	lw	a1,0(s6)
 736:	8556                	mv	a0,s5
 738:	00000097          	auipc	ra,0x0
 73c:	e56080e7          	jalr	-426(ra) # 58e <printint>
 740:	8b4a                	mv	s6,s2
      state = 0;
 742:	4981                	li	s3,0
 744:	bf91                	j	698 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 746:	008b0793          	addi	a5,s6,8
 74a:	f8f43423          	sd	a5,-120(s0)
 74e:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 752:	03000593          	li	a1,48
 756:	8556                	mv	a0,s5
 758:	00000097          	auipc	ra,0x0
 75c:	e14080e7          	jalr	-492(ra) # 56c <putc>
  putc(fd, 'x');
 760:	85ea                	mv	a1,s10
 762:	8556                	mv	a0,s5
 764:	00000097          	auipc	ra,0x0
 768:	e08080e7          	jalr	-504(ra) # 56c <putc>
 76c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 76e:	03c9d793          	srli	a5,s3,0x3c
 772:	97de                	add	a5,a5,s7
 774:	0007c583          	lbu	a1,0(a5)
 778:	8556                	mv	a0,s5
 77a:	00000097          	auipc	ra,0x0
 77e:	df2080e7          	jalr	-526(ra) # 56c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 782:	0992                	slli	s3,s3,0x4
 784:	397d                	addiw	s2,s2,-1
 786:	fe0914e3          	bnez	s2,76e <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 78a:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 78e:	4981                	li	s3,0
 790:	b721                	j	698 <vprintf+0x60>
        s = va_arg(ap, char*);
 792:	008b0993          	addi	s3,s6,8
 796:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 79a:	02090163          	beqz	s2,7bc <vprintf+0x184>
        while(*s != 0){
 79e:	00094583          	lbu	a1,0(s2)
 7a2:	c9a1                	beqz	a1,7f2 <vprintf+0x1ba>
          putc(fd, *s);
 7a4:	8556                	mv	a0,s5
 7a6:	00000097          	auipc	ra,0x0
 7aa:	dc6080e7          	jalr	-570(ra) # 56c <putc>
          s++;
 7ae:	0905                	addi	s2,s2,1
        while(*s != 0){
 7b0:	00094583          	lbu	a1,0(s2)
 7b4:	f9e5                	bnez	a1,7a4 <vprintf+0x16c>
        s = va_arg(ap, char*);
 7b6:	8b4e                	mv	s6,s3
      state = 0;
 7b8:	4981                	li	s3,0
 7ba:	bdf9                	j	698 <vprintf+0x60>
          s = "(null)";
 7bc:	00000917          	auipc	s2,0x0
 7c0:	2a490913          	addi	s2,s2,676 # a60 <malloc+0x15e>
        while(*s != 0){
 7c4:	02800593          	li	a1,40
 7c8:	bff1                	j	7a4 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7ca:	008b0913          	addi	s2,s6,8
 7ce:	000b4583          	lbu	a1,0(s6)
 7d2:	8556                	mv	a0,s5
 7d4:	00000097          	auipc	ra,0x0
 7d8:	d98080e7          	jalr	-616(ra) # 56c <putc>
 7dc:	8b4a                	mv	s6,s2
      state = 0;
 7de:	4981                	li	s3,0
 7e0:	bd65                	j	698 <vprintf+0x60>
        putc(fd, c);
 7e2:	85d2                	mv	a1,s4
 7e4:	8556                	mv	a0,s5
 7e6:	00000097          	auipc	ra,0x0
 7ea:	d86080e7          	jalr	-634(ra) # 56c <putc>
      state = 0;
 7ee:	4981                	li	s3,0
 7f0:	b565                	j	698 <vprintf+0x60>
        s = va_arg(ap, char*);
 7f2:	8b4e                	mv	s6,s3
      state = 0;
 7f4:	4981                	li	s3,0
 7f6:	b54d                	j	698 <vprintf+0x60>
    }
  }
}
 7f8:	70e6                	ld	ra,120(sp)
 7fa:	7446                	ld	s0,112(sp)
 7fc:	74a6                	ld	s1,104(sp)
 7fe:	7906                	ld	s2,96(sp)
 800:	69e6                	ld	s3,88(sp)
 802:	6a46                	ld	s4,80(sp)
 804:	6aa6                	ld	s5,72(sp)
 806:	6b06                	ld	s6,64(sp)
 808:	7be2                	ld	s7,56(sp)
 80a:	7c42                	ld	s8,48(sp)
 80c:	7ca2                	ld	s9,40(sp)
 80e:	7d02                	ld	s10,32(sp)
 810:	6de2                	ld	s11,24(sp)
 812:	6109                	addi	sp,sp,128
 814:	8082                	ret

0000000000000816 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 816:	715d                	addi	sp,sp,-80
 818:	ec06                	sd	ra,24(sp)
 81a:	e822                	sd	s0,16(sp)
 81c:	1000                	addi	s0,sp,32
 81e:	e010                	sd	a2,0(s0)
 820:	e414                	sd	a3,8(s0)
 822:	e818                	sd	a4,16(s0)
 824:	ec1c                	sd	a5,24(s0)
 826:	03043023          	sd	a6,32(s0)
 82a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 82e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 832:	8622                	mv	a2,s0
 834:	00000097          	auipc	ra,0x0
 838:	e04080e7          	jalr	-508(ra) # 638 <vprintf>
}
 83c:	60e2                	ld	ra,24(sp)
 83e:	6442                	ld	s0,16(sp)
 840:	6161                	addi	sp,sp,80
 842:	8082                	ret

0000000000000844 <printf>:

void
printf(const char *fmt, ...)
{
 844:	711d                	addi	sp,sp,-96
 846:	ec06                	sd	ra,24(sp)
 848:	e822                	sd	s0,16(sp)
 84a:	1000                	addi	s0,sp,32
 84c:	e40c                	sd	a1,8(s0)
 84e:	e810                	sd	a2,16(s0)
 850:	ec14                	sd	a3,24(s0)
 852:	f018                	sd	a4,32(s0)
 854:	f41c                	sd	a5,40(s0)
 856:	03043823          	sd	a6,48(s0)
 85a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 85e:	00840613          	addi	a2,s0,8
 862:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 866:	85aa                	mv	a1,a0
 868:	4505                	li	a0,1
 86a:	00000097          	auipc	ra,0x0
 86e:	dce080e7          	jalr	-562(ra) # 638 <vprintf>
}
 872:	60e2                	ld	ra,24(sp)
 874:	6442                	ld	s0,16(sp)
 876:	6125                	addi	sp,sp,96
 878:	8082                	ret

000000000000087a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 87a:	1141                	addi	sp,sp,-16
 87c:	e422                	sd	s0,8(sp)
 87e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 880:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 884:	00000797          	auipc	a5,0x0
 888:	1fc7b783          	ld	a5,508(a5) # a80 <freep>
 88c:	a805                	j	8bc <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 88e:	4618                	lw	a4,8(a2)
 890:	9db9                	addw	a1,a1,a4
 892:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 896:	6398                	ld	a4,0(a5)
 898:	6318                	ld	a4,0(a4)
 89a:	fee53823          	sd	a4,-16(a0)
 89e:	a091                	j	8e2 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8a0:	ff852703          	lw	a4,-8(a0)
 8a4:	9e39                	addw	a2,a2,a4
 8a6:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8a8:	ff053703          	ld	a4,-16(a0)
 8ac:	e398                	sd	a4,0(a5)
 8ae:	a099                	j	8f4 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8b0:	6398                	ld	a4,0(a5)
 8b2:	00e7e463          	bltu	a5,a4,8ba <free+0x40>
 8b6:	00e6ea63          	bltu	a3,a4,8ca <free+0x50>
{
 8ba:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8bc:	fed7fae3          	bgeu	a5,a3,8b0 <free+0x36>
 8c0:	6398                	ld	a4,0(a5)
 8c2:	00e6e463          	bltu	a3,a4,8ca <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8c6:	fee7eae3          	bltu	a5,a4,8ba <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8ca:	ff852583          	lw	a1,-8(a0)
 8ce:	6390                	ld	a2,0(a5)
 8d0:	02059713          	slli	a4,a1,0x20
 8d4:	9301                	srli	a4,a4,0x20
 8d6:	0712                	slli	a4,a4,0x4
 8d8:	9736                	add	a4,a4,a3
 8da:	fae60ae3          	beq	a2,a4,88e <free+0x14>
    bp->s.ptr = p->s.ptr;
 8de:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 8e2:	4790                	lw	a2,8(a5)
 8e4:	02061713          	slli	a4,a2,0x20
 8e8:	9301                	srli	a4,a4,0x20
 8ea:	0712                	slli	a4,a4,0x4
 8ec:	973e                	add	a4,a4,a5
 8ee:	fae689e3          	beq	a3,a4,8a0 <free+0x26>
  } else
    p->s.ptr = bp;
 8f2:	e394                	sd	a3,0(a5)
  freep = p;
 8f4:	00000717          	auipc	a4,0x0
 8f8:	18f73623          	sd	a5,396(a4) # a80 <freep>
}
 8fc:	6422                	ld	s0,8(sp)
 8fe:	0141                	addi	sp,sp,16
 900:	8082                	ret

0000000000000902 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 902:	7139                	addi	sp,sp,-64
 904:	fc06                	sd	ra,56(sp)
 906:	f822                	sd	s0,48(sp)
 908:	f426                	sd	s1,40(sp)
 90a:	f04a                	sd	s2,32(sp)
 90c:	ec4e                	sd	s3,24(sp)
 90e:	e852                	sd	s4,16(sp)
 910:	e456                	sd	s5,8(sp)
 912:	e05a                	sd	s6,0(sp)
 914:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 916:	02051493          	slli	s1,a0,0x20
 91a:	9081                	srli	s1,s1,0x20
 91c:	04bd                	addi	s1,s1,15
 91e:	8091                	srli	s1,s1,0x4
 920:	0014899b          	addiw	s3,s1,1
 924:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 926:	00000517          	auipc	a0,0x0
 92a:	15a53503          	ld	a0,346(a0) # a80 <freep>
 92e:	c515                	beqz	a0,95a <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 930:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 932:	4798                	lw	a4,8(a5)
 934:	02977f63          	bgeu	a4,s1,972 <malloc+0x70>
 938:	8a4e                	mv	s4,s3
 93a:	0009871b          	sext.w	a4,s3
 93e:	6685                	lui	a3,0x1
 940:	00d77363          	bgeu	a4,a3,946 <malloc+0x44>
 944:	6a05                	lui	s4,0x1
 946:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 94a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 94e:	00000917          	auipc	s2,0x0
 952:	13290913          	addi	s2,s2,306 # a80 <freep>
  if(p == (char*)-1)
 956:	5afd                	li	s5,-1
 958:	a88d                	j	9ca <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 95a:	00000797          	auipc	a5,0x0
 95e:	12e78793          	addi	a5,a5,302 # a88 <base>
 962:	00000717          	auipc	a4,0x0
 966:	10f73f23          	sd	a5,286(a4) # a80 <freep>
 96a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 96c:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 970:	b7e1                	j	938 <malloc+0x36>
      if(p->s.size == nunits)
 972:	02e48b63          	beq	s1,a4,9a8 <malloc+0xa6>
        p->s.size -= nunits;
 976:	4137073b          	subw	a4,a4,s3
 97a:	c798                	sw	a4,8(a5)
        p += p->s.size;
 97c:	1702                	slli	a4,a4,0x20
 97e:	9301                	srli	a4,a4,0x20
 980:	0712                	slli	a4,a4,0x4
 982:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 984:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 988:	00000717          	auipc	a4,0x0
 98c:	0ea73c23          	sd	a0,248(a4) # a80 <freep>
      return (void*)(p + 1);
 990:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 994:	70e2                	ld	ra,56(sp)
 996:	7442                	ld	s0,48(sp)
 998:	74a2                	ld	s1,40(sp)
 99a:	7902                	ld	s2,32(sp)
 99c:	69e2                	ld	s3,24(sp)
 99e:	6a42                	ld	s4,16(sp)
 9a0:	6aa2                	ld	s5,8(sp)
 9a2:	6b02                	ld	s6,0(sp)
 9a4:	6121                	addi	sp,sp,64
 9a6:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9a8:	6398                	ld	a4,0(a5)
 9aa:	e118                	sd	a4,0(a0)
 9ac:	bff1                	j	988 <malloc+0x86>
  hp->s.size = nu;
 9ae:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9b2:	0541                	addi	a0,a0,16
 9b4:	00000097          	auipc	ra,0x0
 9b8:	ec6080e7          	jalr	-314(ra) # 87a <free>
  return freep;
 9bc:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9c0:	d971                	beqz	a0,994 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9c2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9c4:	4798                	lw	a4,8(a5)
 9c6:	fa9776e3          	bgeu	a4,s1,972 <malloc+0x70>
    if(p == freep)
 9ca:	00093703          	ld	a4,0(s2)
 9ce:	853e                	mv	a0,a5
 9d0:	fef719e3          	bne	a4,a5,9c2 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 9d4:	8552                	mv	a0,s4
 9d6:	00000097          	auipc	ra,0x0
 9da:	b5e080e7          	jalr	-1186(ra) # 534 <sbrk>
  if(p == (char*)-1)
 9de:	fd5518e3          	bne	a0,s5,9ae <malloc+0xac>
        return 0;
 9e2:	4501                	li	a0,0
 9e4:	bf45                	j	994 <malloc+0x92>
