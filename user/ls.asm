
user/_ls：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <fmtname>:
#include "user/user.h"
#include "kernel/fs.h"

char*
fmtname(char *path)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
   e:	84aa                	mv	s1,a0
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
  10:	00000097          	auipc	ra,0x0
  14:	30c080e7          	jalr	780(ra) # 31c <strlen>
  18:	02051793          	slli	a5,a0,0x20
  1c:	9381                	srli	a5,a5,0x20
  1e:	97a6                	add	a5,a5,s1
  20:	02f00693          	li	a3,47
  24:	0097e963          	bltu	a5,s1,36 <fmtname+0x36>
  28:	0007c703          	lbu	a4,0(a5)
  2c:	00d70563          	beq	a4,a3,36 <fmtname+0x36>
  30:	17fd                	addi	a5,a5,-1
  32:	fe97fbe3          	bgeu	a5,s1,28 <fmtname+0x28>
    ;
  p++;
  36:	00178493          	addi	s1,a5,1

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
  3a:	8526                	mv	a0,s1
  3c:	00000097          	auipc	ra,0x0
  40:	2e0080e7          	jalr	736(ra) # 31c <strlen>
  44:	2501                	sext.w	a0,a0
  46:	47b5                	li	a5,13
  48:	00a7fa63          	bgeu	a5,a0,5c <fmtname+0x5c>
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  return buf;
}
  4c:	8526                	mv	a0,s1
  4e:	70a2                	ld	ra,40(sp)
  50:	7402                	ld	s0,32(sp)
  52:	64e2                	ld	s1,24(sp)
  54:	6942                	ld	s2,16(sp)
  56:	69a2                	ld	s3,8(sp)
  58:	6145                	addi	sp,sp,48
  5a:	8082                	ret
  memmove(buf, p, strlen(p));
  5c:	8526                	mv	a0,s1
  5e:	00000097          	auipc	ra,0x0
  62:	2be080e7          	jalr	702(ra) # 31c <strlen>
  66:	00001997          	auipc	s3,0x1
  6a:	aba98993          	addi	s3,s3,-1350 # b20 <buf.1120>
  6e:	0005061b          	sext.w	a2,a0
  72:	85a6                	mv	a1,s1
  74:	854e                	mv	a0,s3
  76:	00000097          	auipc	ra,0x0
  7a:	41e080e7          	jalr	1054(ra) # 494 <memmove>
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  7e:	8526                	mv	a0,s1
  80:	00000097          	auipc	ra,0x0
  84:	29c080e7          	jalr	668(ra) # 31c <strlen>
  88:	0005091b          	sext.w	s2,a0
  8c:	8526                	mv	a0,s1
  8e:	00000097          	auipc	ra,0x0
  92:	28e080e7          	jalr	654(ra) # 31c <strlen>
  96:	1902                	slli	s2,s2,0x20
  98:	02095913          	srli	s2,s2,0x20
  9c:	4639                	li	a2,14
  9e:	9e09                	subw	a2,a2,a0
  a0:	02000593          	li	a1,32
  a4:	01298533          	add	a0,s3,s2
  a8:	00000097          	auipc	ra,0x0
  ac:	29e080e7          	jalr	670(ra) # 346 <memset>
  return buf;
  b0:	84ce                	mv	s1,s3
  b2:	bf69                	j	4c <fmtname+0x4c>

00000000000000b4 <ls>:

void
ls(char *path)
{
  b4:	d9010113          	addi	sp,sp,-624
  b8:	26113423          	sd	ra,616(sp)
  bc:	26813023          	sd	s0,608(sp)
  c0:	24913c23          	sd	s1,600(sp)
  c4:	25213823          	sd	s2,592(sp)
  c8:	25313423          	sd	s3,584(sp)
  cc:	25413023          	sd	s4,576(sp)
  d0:	23513c23          	sd	s5,568(sp)
  d4:	1c80                	addi	s0,sp,624
  d6:	892a                	mv	s2,a0
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;

  if((fd = open(path, 0)) < 0){
  d8:	4581                	li	a1,0
  da:	00000097          	auipc	ra,0x0
  de:	4b0080e7          	jalr	1200(ra) # 58a <open>
  e2:	06054f63          	bltz	a0,160 <ls+0xac>
  e6:	84aa                	mv	s1,a0
    fprintf(2, "ls: cannot open %s\n", path);
    return;
  }

  if(fstat(fd, &st) < 0){
  e8:	d9840593          	addi	a1,s0,-616
  ec:	00000097          	auipc	ra,0x0
  f0:	4b6080e7          	jalr	1206(ra) # 5a2 <fstat>
  f4:	08054163          	bltz	a0,176 <ls+0xc2>
    fprintf(2, "ls: cannot stat %s\n", path);
    close(fd);
    return;
  }

  switch(st.type){
  f8:	da041783          	lh	a5,-608(s0)
  fc:	0007869b          	sext.w	a3,a5
 100:	4705                	li	a4,1
 102:	08e68a63          	beq	a3,a4,196 <ls+0xe2>
 106:	4709                	li	a4,2
 108:	02e69663          	bne	a3,a4,134 <ls+0x80>
  case T_FILE:
    printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
 10c:	854a                	mv	a0,s2
 10e:	00000097          	auipc	ra,0x0
 112:	ef2080e7          	jalr	-270(ra) # 0 <fmtname>
 116:	85aa                	mv	a1,a0
 118:	da843703          	ld	a4,-600(s0)
 11c:	d9c42683          	lw	a3,-612(s0)
 120:	da041603          	lh	a2,-608(s0)
 124:	00001517          	auipc	a0,0x1
 128:	99450513          	addi	a0,a0,-1644 # ab8 <malloc+0x118>
 12c:	00000097          	auipc	ra,0x0
 130:	7b6080e7          	jalr	1974(ra) # 8e2 <printf>
      }
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
    }
    break;
  }
  close(fd);
 134:	8526                	mv	a0,s1
 136:	00000097          	auipc	ra,0x0
 13a:	43c080e7          	jalr	1084(ra) # 572 <close>
}
 13e:	26813083          	ld	ra,616(sp)
 142:	26013403          	ld	s0,608(sp)
 146:	25813483          	ld	s1,600(sp)
 14a:	25013903          	ld	s2,592(sp)
 14e:	24813983          	ld	s3,584(sp)
 152:	24013a03          	ld	s4,576(sp)
 156:	23813a83          	ld	s5,568(sp)
 15a:	27010113          	addi	sp,sp,624
 15e:	8082                	ret
    fprintf(2, "ls: cannot open %s\n", path);
 160:	864a                	mv	a2,s2
 162:	00001597          	auipc	a1,0x1
 166:	92658593          	addi	a1,a1,-1754 # a88 <malloc+0xe8>
 16a:	4509                	li	a0,2
 16c:	00000097          	auipc	ra,0x0
 170:	748080e7          	jalr	1864(ra) # 8b4 <fprintf>
    return;
 174:	b7e9                	j	13e <ls+0x8a>
    fprintf(2, "ls: cannot stat %s\n", path);
 176:	864a                	mv	a2,s2
 178:	00001597          	auipc	a1,0x1
 17c:	92858593          	addi	a1,a1,-1752 # aa0 <malloc+0x100>
 180:	4509                	li	a0,2
 182:	00000097          	auipc	ra,0x0
 186:	732080e7          	jalr	1842(ra) # 8b4 <fprintf>
    close(fd);
 18a:	8526                	mv	a0,s1
 18c:	00000097          	auipc	ra,0x0
 190:	3e6080e7          	jalr	998(ra) # 572 <close>
    return;
 194:	b76d                	j	13e <ls+0x8a>
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
 196:	854a                	mv	a0,s2
 198:	00000097          	auipc	ra,0x0
 19c:	184080e7          	jalr	388(ra) # 31c <strlen>
 1a0:	2541                	addiw	a0,a0,16
 1a2:	20000793          	li	a5,512
 1a6:	00a7fb63          	bgeu	a5,a0,1bc <ls+0x108>
      printf("ls: path too long\n");
 1aa:	00001517          	auipc	a0,0x1
 1ae:	91e50513          	addi	a0,a0,-1762 # ac8 <malloc+0x128>
 1b2:	00000097          	auipc	ra,0x0
 1b6:	730080e7          	jalr	1840(ra) # 8e2 <printf>
      break;
 1ba:	bfad                	j	134 <ls+0x80>
    strcpy(buf, path);
 1bc:	85ca                	mv	a1,s2
 1be:	dc040513          	addi	a0,s0,-576
 1c2:	00000097          	auipc	ra,0x0
 1c6:	112080e7          	jalr	274(ra) # 2d4 <strcpy>
    p = buf+strlen(buf);
 1ca:	dc040513          	addi	a0,s0,-576
 1ce:	00000097          	auipc	ra,0x0
 1d2:	14e080e7          	jalr	334(ra) # 31c <strlen>
 1d6:	02051913          	slli	s2,a0,0x20
 1da:	02095913          	srli	s2,s2,0x20
 1de:	dc040793          	addi	a5,s0,-576
 1e2:	993e                	add	s2,s2,a5
    *p++ = '/';
 1e4:	00190993          	addi	s3,s2,1
 1e8:	02f00793          	li	a5,47
 1ec:	00f90023          	sb	a5,0(s2)
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 1f0:	00001a17          	auipc	s4,0x1
 1f4:	8f0a0a13          	addi	s4,s4,-1808 # ae0 <malloc+0x140>
        printf("ls: cannot stat %s\n", buf);
 1f8:	00001a97          	auipc	s5,0x1
 1fc:	8a8a8a93          	addi	s5,s5,-1880 # aa0 <malloc+0x100>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 200:	a801                	j	210 <ls+0x15c>
        printf("ls: cannot stat %s\n", buf);
 202:	dc040593          	addi	a1,s0,-576
 206:	8556                	mv	a0,s5
 208:	00000097          	auipc	ra,0x0
 20c:	6da080e7          	jalr	1754(ra) # 8e2 <printf>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 210:	4641                	li	a2,16
 212:	db040593          	addi	a1,s0,-592
 216:	8526                	mv	a0,s1
 218:	00000097          	auipc	ra,0x0
 21c:	34a080e7          	jalr	842(ra) # 562 <read>
 220:	47c1                	li	a5,16
 222:	f0f519e3          	bne	a0,a5,134 <ls+0x80>
      if(de.inum == 0)
 226:	db045783          	lhu	a5,-592(s0)
 22a:	d3fd                	beqz	a5,210 <ls+0x15c>
      memmove(p, de.name, DIRSIZ);
 22c:	4639                	li	a2,14
 22e:	db240593          	addi	a1,s0,-590
 232:	854e                	mv	a0,s3
 234:	00000097          	auipc	ra,0x0
 238:	260080e7          	jalr	608(ra) # 494 <memmove>
      p[DIRSIZ] = 0;
 23c:	000907a3          	sb	zero,15(s2)
      if(stat(buf, &st) < 0){
 240:	d9840593          	addi	a1,s0,-616
 244:	dc040513          	addi	a0,s0,-576
 248:	00000097          	auipc	ra,0x0
 24c:	1bc080e7          	jalr	444(ra) # 404 <stat>
 250:	fa0549e3          	bltz	a0,202 <ls+0x14e>
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 254:	dc040513          	addi	a0,s0,-576
 258:	00000097          	auipc	ra,0x0
 25c:	da8080e7          	jalr	-600(ra) # 0 <fmtname>
 260:	85aa                	mv	a1,a0
 262:	da843703          	ld	a4,-600(s0)
 266:	d9c42683          	lw	a3,-612(s0)
 26a:	da041603          	lh	a2,-608(s0)
 26e:	8552                	mv	a0,s4
 270:	00000097          	auipc	ra,0x0
 274:	672080e7          	jalr	1650(ra) # 8e2 <printf>
 278:	bf61                	j	210 <ls+0x15c>

000000000000027a <main>:

int
main(int argc, char *argv[])
{
 27a:	1101                	addi	sp,sp,-32
 27c:	ec06                	sd	ra,24(sp)
 27e:	e822                	sd	s0,16(sp)
 280:	e426                	sd	s1,8(sp)
 282:	e04a                	sd	s2,0(sp)
 284:	1000                	addi	s0,sp,32
  int i;

  if(argc < 2){
 286:	4785                	li	a5,1
 288:	02a7d963          	bge	a5,a0,2ba <main+0x40>
 28c:	00858493          	addi	s1,a1,8
 290:	ffe5091b          	addiw	s2,a0,-2
 294:	1902                	slli	s2,s2,0x20
 296:	02095913          	srli	s2,s2,0x20
 29a:	090e                	slli	s2,s2,0x3
 29c:	05c1                	addi	a1,a1,16
 29e:	992e                	add	s2,s2,a1
    ls(".");
    exit(0);
  }
  for(i=1; i<argc; i++)
    ls(argv[i]);
 2a0:	6088                	ld	a0,0(s1)
 2a2:	00000097          	auipc	ra,0x0
 2a6:	e12080e7          	jalr	-494(ra) # b4 <ls>
  for(i=1; i<argc; i++)
 2aa:	04a1                	addi	s1,s1,8
 2ac:	ff249ae3          	bne	s1,s2,2a0 <main+0x26>
  exit(0);
 2b0:	4501                	li	a0,0
 2b2:	00000097          	auipc	ra,0x0
 2b6:	298080e7          	jalr	664(ra) # 54a <exit>
    ls(".");
 2ba:	00001517          	auipc	a0,0x1
 2be:	83650513          	addi	a0,a0,-1994 # af0 <malloc+0x150>
 2c2:	00000097          	auipc	ra,0x0
 2c6:	df2080e7          	jalr	-526(ra) # b4 <ls>
    exit(0);
 2ca:	4501                	li	a0,0
 2cc:	00000097          	auipc	ra,0x0
 2d0:	27e080e7          	jalr	638(ra) # 54a <exit>

00000000000002d4 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 2d4:	1141                	addi	sp,sp,-16
 2d6:	e422                	sd	s0,8(sp)
 2d8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2da:	87aa                	mv	a5,a0
 2dc:	0585                	addi	a1,a1,1
 2de:	0785                	addi	a5,a5,1
 2e0:	fff5c703          	lbu	a4,-1(a1)
 2e4:	fee78fa3          	sb	a4,-1(a5)
 2e8:	fb75                	bnez	a4,2dc <strcpy+0x8>
    ;
  return os;
}
 2ea:	6422                	ld	s0,8(sp)
 2ec:	0141                	addi	sp,sp,16
 2ee:	8082                	ret

00000000000002f0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2f0:	1141                	addi	sp,sp,-16
 2f2:	e422                	sd	s0,8(sp)
 2f4:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2f6:	00054783          	lbu	a5,0(a0)
 2fa:	cb91                	beqz	a5,30e <strcmp+0x1e>
 2fc:	0005c703          	lbu	a4,0(a1)
 300:	00f71763          	bne	a4,a5,30e <strcmp+0x1e>
    p++, q++;
 304:	0505                	addi	a0,a0,1
 306:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 308:	00054783          	lbu	a5,0(a0)
 30c:	fbe5                	bnez	a5,2fc <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 30e:	0005c503          	lbu	a0,0(a1)
}
 312:	40a7853b          	subw	a0,a5,a0
 316:	6422                	ld	s0,8(sp)
 318:	0141                	addi	sp,sp,16
 31a:	8082                	ret

000000000000031c <strlen>:

uint
strlen(const char *s)
{
 31c:	1141                	addi	sp,sp,-16
 31e:	e422                	sd	s0,8(sp)
 320:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 322:	00054783          	lbu	a5,0(a0)
 326:	cf91                	beqz	a5,342 <strlen+0x26>
 328:	0505                	addi	a0,a0,1
 32a:	87aa                	mv	a5,a0
 32c:	4685                	li	a3,1
 32e:	9e89                	subw	a3,a3,a0
 330:	00f6853b          	addw	a0,a3,a5
 334:	0785                	addi	a5,a5,1
 336:	fff7c703          	lbu	a4,-1(a5)
 33a:	fb7d                	bnez	a4,330 <strlen+0x14>
    ;
  return n;
}
 33c:	6422                	ld	s0,8(sp)
 33e:	0141                	addi	sp,sp,16
 340:	8082                	ret
  for(n = 0; s[n]; n++)
 342:	4501                	li	a0,0
 344:	bfe5                	j	33c <strlen+0x20>

0000000000000346 <memset>:

void*
memset(void *dst, int c, uint n)
{
 346:	1141                	addi	sp,sp,-16
 348:	e422                	sd	s0,8(sp)
 34a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 34c:	ce09                	beqz	a2,366 <memset+0x20>
 34e:	87aa                	mv	a5,a0
 350:	fff6071b          	addiw	a4,a2,-1
 354:	1702                	slli	a4,a4,0x20
 356:	9301                	srli	a4,a4,0x20
 358:	0705                	addi	a4,a4,1
 35a:	972a                	add	a4,a4,a0
    cdst[i] = c;
 35c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 360:	0785                	addi	a5,a5,1
 362:	fee79de3          	bne	a5,a4,35c <memset+0x16>
  }
  return dst;
}
 366:	6422                	ld	s0,8(sp)
 368:	0141                	addi	sp,sp,16
 36a:	8082                	ret

000000000000036c <strchr>:

char*
strchr(const char *s, char c)
{
 36c:	1141                	addi	sp,sp,-16
 36e:	e422                	sd	s0,8(sp)
 370:	0800                	addi	s0,sp,16
  for(; *s; s++)
 372:	00054783          	lbu	a5,0(a0)
 376:	cb99                	beqz	a5,38c <strchr+0x20>
    if(*s == c)
 378:	00f58763          	beq	a1,a5,386 <strchr+0x1a>
  for(; *s; s++)
 37c:	0505                	addi	a0,a0,1
 37e:	00054783          	lbu	a5,0(a0)
 382:	fbfd                	bnez	a5,378 <strchr+0xc>
      return (char*)s;
  return 0;
 384:	4501                	li	a0,0
}
 386:	6422                	ld	s0,8(sp)
 388:	0141                	addi	sp,sp,16
 38a:	8082                	ret
  return 0;
 38c:	4501                	li	a0,0
 38e:	bfe5                	j	386 <strchr+0x1a>

0000000000000390 <gets>:

char*
gets(char *buf, int max)
{
 390:	711d                	addi	sp,sp,-96
 392:	ec86                	sd	ra,88(sp)
 394:	e8a2                	sd	s0,80(sp)
 396:	e4a6                	sd	s1,72(sp)
 398:	e0ca                	sd	s2,64(sp)
 39a:	fc4e                	sd	s3,56(sp)
 39c:	f852                	sd	s4,48(sp)
 39e:	f456                	sd	s5,40(sp)
 3a0:	f05a                	sd	s6,32(sp)
 3a2:	ec5e                	sd	s7,24(sp)
 3a4:	1080                	addi	s0,sp,96
 3a6:	8baa                	mv	s7,a0
 3a8:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 3aa:	892a                	mv	s2,a0
 3ac:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 3ae:	4aa9                	li	s5,10
 3b0:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 3b2:	89a6                	mv	s3,s1
 3b4:	2485                	addiw	s1,s1,1
 3b6:	0344d863          	bge	s1,s4,3e6 <gets+0x56>
    cc = read(0, &c, 1);
 3ba:	4605                	li	a2,1
 3bc:	faf40593          	addi	a1,s0,-81
 3c0:	4501                	li	a0,0
 3c2:	00000097          	auipc	ra,0x0
 3c6:	1a0080e7          	jalr	416(ra) # 562 <read>
    if(cc < 1)
 3ca:	00a05e63          	blez	a0,3e6 <gets+0x56>
    buf[i++] = c;
 3ce:	faf44783          	lbu	a5,-81(s0)
 3d2:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3d6:	01578763          	beq	a5,s5,3e4 <gets+0x54>
 3da:	0905                	addi	s2,s2,1
 3dc:	fd679be3          	bne	a5,s6,3b2 <gets+0x22>
  for(i=0; i+1 < max; ){
 3e0:	89a6                	mv	s3,s1
 3e2:	a011                	j	3e6 <gets+0x56>
 3e4:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3e6:	99de                	add	s3,s3,s7
 3e8:	00098023          	sb	zero,0(s3)
  return buf;
}
 3ec:	855e                	mv	a0,s7
 3ee:	60e6                	ld	ra,88(sp)
 3f0:	6446                	ld	s0,80(sp)
 3f2:	64a6                	ld	s1,72(sp)
 3f4:	6906                	ld	s2,64(sp)
 3f6:	79e2                	ld	s3,56(sp)
 3f8:	7a42                	ld	s4,48(sp)
 3fa:	7aa2                	ld	s5,40(sp)
 3fc:	7b02                	ld	s6,32(sp)
 3fe:	6be2                	ld	s7,24(sp)
 400:	6125                	addi	sp,sp,96
 402:	8082                	ret

0000000000000404 <stat>:

int
stat(const char *n, struct stat *st)
{
 404:	1101                	addi	sp,sp,-32
 406:	ec06                	sd	ra,24(sp)
 408:	e822                	sd	s0,16(sp)
 40a:	e426                	sd	s1,8(sp)
 40c:	e04a                	sd	s2,0(sp)
 40e:	1000                	addi	s0,sp,32
 410:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 412:	4581                	li	a1,0
 414:	00000097          	auipc	ra,0x0
 418:	176080e7          	jalr	374(ra) # 58a <open>
  if(fd < 0)
 41c:	02054563          	bltz	a0,446 <stat+0x42>
 420:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 422:	85ca                	mv	a1,s2
 424:	00000097          	auipc	ra,0x0
 428:	17e080e7          	jalr	382(ra) # 5a2 <fstat>
 42c:	892a                	mv	s2,a0
  close(fd);
 42e:	8526                	mv	a0,s1
 430:	00000097          	auipc	ra,0x0
 434:	142080e7          	jalr	322(ra) # 572 <close>
  return r;
}
 438:	854a                	mv	a0,s2
 43a:	60e2                	ld	ra,24(sp)
 43c:	6442                	ld	s0,16(sp)
 43e:	64a2                	ld	s1,8(sp)
 440:	6902                	ld	s2,0(sp)
 442:	6105                	addi	sp,sp,32
 444:	8082                	ret
    return -1;
 446:	597d                	li	s2,-1
 448:	bfc5                	j	438 <stat+0x34>

000000000000044a <atoi>:

int
atoi(const char *s)
{
 44a:	1141                	addi	sp,sp,-16
 44c:	e422                	sd	s0,8(sp)
 44e:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 450:	00054603          	lbu	a2,0(a0)
 454:	fd06079b          	addiw	a5,a2,-48
 458:	0ff7f793          	andi	a5,a5,255
 45c:	4725                	li	a4,9
 45e:	02f76963          	bltu	a4,a5,490 <atoi+0x46>
 462:	86aa                	mv	a3,a0
  n = 0;
 464:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 466:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 468:	0685                	addi	a3,a3,1
 46a:	0025179b          	slliw	a5,a0,0x2
 46e:	9fa9                	addw	a5,a5,a0
 470:	0017979b          	slliw	a5,a5,0x1
 474:	9fb1                	addw	a5,a5,a2
 476:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 47a:	0006c603          	lbu	a2,0(a3)
 47e:	fd06071b          	addiw	a4,a2,-48
 482:	0ff77713          	andi	a4,a4,255
 486:	fee5f1e3          	bgeu	a1,a4,468 <atoi+0x1e>
  return n;
}
 48a:	6422                	ld	s0,8(sp)
 48c:	0141                	addi	sp,sp,16
 48e:	8082                	ret
  n = 0;
 490:	4501                	li	a0,0
 492:	bfe5                	j	48a <atoi+0x40>

0000000000000494 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 494:	1141                	addi	sp,sp,-16
 496:	e422                	sd	s0,8(sp)
 498:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 49a:	02b57663          	bgeu	a0,a1,4c6 <memmove+0x32>
    while(n-- > 0)
 49e:	02c05163          	blez	a2,4c0 <memmove+0x2c>
 4a2:	fff6079b          	addiw	a5,a2,-1
 4a6:	1782                	slli	a5,a5,0x20
 4a8:	9381                	srli	a5,a5,0x20
 4aa:	0785                	addi	a5,a5,1
 4ac:	97aa                	add	a5,a5,a0
  dst = vdst;
 4ae:	872a                	mv	a4,a0
      *dst++ = *src++;
 4b0:	0585                	addi	a1,a1,1
 4b2:	0705                	addi	a4,a4,1
 4b4:	fff5c683          	lbu	a3,-1(a1)
 4b8:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4bc:	fee79ae3          	bne	a5,a4,4b0 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4c0:	6422                	ld	s0,8(sp)
 4c2:	0141                	addi	sp,sp,16
 4c4:	8082                	ret
    dst += n;
 4c6:	00c50733          	add	a4,a0,a2
    src += n;
 4ca:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4cc:	fec05ae3          	blez	a2,4c0 <memmove+0x2c>
 4d0:	fff6079b          	addiw	a5,a2,-1
 4d4:	1782                	slli	a5,a5,0x20
 4d6:	9381                	srli	a5,a5,0x20
 4d8:	fff7c793          	not	a5,a5
 4dc:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4de:	15fd                	addi	a1,a1,-1
 4e0:	177d                	addi	a4,a4,-1
 4e2:	0005c683          	lbu	a3,0(a1)
 4e6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4ea:	fee79ae3          	bne	a5,a4,4de <memmove+0x4a>
 4ee:	bfc9                	j	4c0 <memmove+0x2c>

00000000000004f0 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4f0:	1141                	addi	sp,sp,-16
 4f2:	e422                	sd	s0,8(sp)
 4f4:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4f6:	ca05                	beqz	a2,526 <memcmp+0x36>
 4f8:	fff6069b          	addiw	a3,a2,-1
 4fc:	1682                	slli	a3,a3,0x20
 4fe:	9281                	srli	a3,a3,0x20
 500:	0685                	addi	a3,a3,1
 502:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 504:	00054783          	lbu	a5,0(a0)
 508:	0005c703          	lbu	a4,0(a1)
 50c:	00e79863          	bne	a5,a4,51c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 510:	0505                	addi	a0,a0,1
    p2++;
 512:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 514:	fed518e3          	bne	a0,a3,504 <memcmp+0x14>
  }
  return 0;
 518:	4501                	li	a0,0
 51a:	a019                	j	520 <memcmp+0x30>
      return *p1 - *p2;
 51c:	40e7853b          	subw	a0,a5,a4
}
 520:	6422                	ld	s0,8(sp)
 522:	0141                	addi	sp,sp,16
 524:	8082                	ret
  return 0;
 526:	4501                	li	a0,0
 528:	bfe5                	j	520 <memcmp+0x30>

000000000000052a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 52a:	1141                	addi	sp,sp,-16
 52c:	e406                	sd	ra,8(sp)
 52e:	e022                	sd	s0,0(sp)
 530:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 532:	00000097          	auipc	ra,0x0
 536:	f62080e7          	jalr	-158(ra) # 494 <memmove>
}
 53a:	60a2                	ld	ra,8(sp)
 53c:	6402                	ld	s0,0(sp)
 53e:	0141                	addi	sp,sp,16
 540:	8082                	ret

0000000000000542 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 542:	4885                	li	a7,1
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <exit>:
.global exit
exit:
 li a7, SYS_exit
 54a:	4889                	li	a7,2
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <wait>:
.global wait
wait:
 li a7, SYS_wait
 552:	488d                	li	a7,3
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 55a:	4891                	li	a7,4
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <read>:
.global read
read:
 li a7, SYS_read
 562:	4895                	li	a7,5
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <write>:
.global write
write:
 li a7, SYS_write
 56a:	48c1                	li	a7,16
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <close>:
.global close
close:
 li a7, SYS_close
 572:	48d5                	li	a7,21
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <kill>:
.global kill
kill:
 li a7, SYS_kill
 57a:	4899                	li	a7,6
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <exec>:
.global exec
exec:
 li a7, SYS_exec
 582:	489d                	li	a7,7
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <open>:
.global open
open:
 li a7, SYS_open
 58a:	48bd                	li	a7,15
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 592:	48c5                	li	a7,17
 ecall
 594:	00000073          	ecall
 ret
 598:	8082                	ret

000000000000059a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 59a:	48c9                	li	a7,18
 ecall
 59c:	00000073          	ecall
 ret
 5a0:	8082                	ret

00000000000005a2 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 5a2:	48a1                	li	a7,8
 ecall
 5a4:	00000073          	ecall
 ret
 5a8:	8082                	ret

00000000000005aa <link>:
.global link
link:
 li a7, SYS_link
 5aa:	48cd                	li	a7,19
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5b2:	48d1                	li	a7,20
 ecall
 5b4:	00000073          	ecall
 ret
 5b8:	8082                	ret

00000000000005ba <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5ba:	48a5                	li	a7,9
 ecall
 5bc:	00000073          	ecall
 ret
 5c0:	8082                	ret

00000000000005c2 <dup>:
.global dup
dup:
 li a7, SYS_dup
 5c2:	48a9                	li	a7,10
 ecall
 5c4:	00000073          	ecall
 ret
 5c8:	8082                	ret

00000000000005ca <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5ca:	48ad                	li	a7,11
 ecall
 5cc:	00000073          	ecall
 ret
 5d0:	8082                	ret

00000000000005d2 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5d2:	48b1                	li	a7,12
 ecall
 5d4:	00000073          	ecall
 ret
 5d8:	8082                	ret

00000000000005da <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5da:	48b5                	li	a7,13
 ecall
 5dc:	00000073          	ecall
 ret
 5e0:	8082                	ret

00000000000005e2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5e2:	48b9                	li	a7,14
 ecall
 5e4:	00000073          	ecall
 ret
 5e8:	8082                	ret

00000000000005ea <trace>:
.global trace
trace:
 li a7, SYS_trace
 5ea:	48d9                	li	a7,22
 ecall
 5ec:	00000073          	ecall
 ret
 5f0:	8082                	ret

00000000000005f2 <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 5f2:	48dd                	li	a7,23
 ecall
 5f4:	00000073          	ecall
 ret
 5f8:	8082                	ret

00000000000005fa <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 5fa:	48e1                	li	a7,24
 ecall
 5fc:	00000073          	ecall
 ret
 600:	8082                	ret

0000000000000602 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 602:	48e5                	li	a7,25
 ecall
 604:	00000073          	ecall
 ret
 608:	8082                	ret

000000000000060a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 60a:	1101                	addi	sp,sp,-32
 60c:	ec06                	sd	ra,24(sp)
 60e:	e822                	sd	s0,16(sp)
 610:	1000                	addi	s0,sp,32
 612:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 616:	4605                	li	a2,1
 618:	fef40593          	addi	a1,s0,-17
 61c:	00000097          	auipc	ra,0x0
 620:	f4e080e7          	jalr	-178(ra) # 56a <write>
}
 624:	60e2                	ld	ra,24(sp)
 626:	6442                	ld	s0,16(sp)
 628:	6105                	addi	sp,sp,32
 62a:	8082                	ret

000000000000062c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 62c:	7139                	addi	sp,sp,-64
 62e:	fc06                	sd	ra,56(sp)
 630:	f822                	sd	s0,48(sp)
 632:	f426                	sd	s1,40(sp)
 634:	f04a                	sd	s2,32(sp)
 636:	ec4e                	sd	s3,24(sp)
 638:	0080                	addi	s0,sp,64
 63a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 63c:	c299                	beqz	a3,642 <printint+0x16>
 63e:	0805c863          	bltz	a1,6ce <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 642:	2581                	sext.w	a1,a1
  neg = 0;
 644:	4881                	li	a7,0
 646:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 64a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 64c:	2601                	sext.w	a2,a2
 64e:	00000517          	auipc	a0,0x0
 652:	4b250513          	addi	a0,a0,1202 # b00 <digits>
 656:	883a                	mv	a6,a4
 658:	2705                	addiw	a4,a4,1
 65a:	02c5f7bb          	remuw	a5,a1,a2
 65e:	1782                	slli	a5,a5,0x20
 660:	9381                	srli	a5,a5,0x20
 662:	97aa                	add	a5,a5,a0
 664:	0007c783          	lbu	a5,0(a5)
 668:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 66c:	0005879b          	sext.w	a5,a1
 670:	02c5d5bb          	divuw	a1,a1,a2
 674:	0685                	addi	a3,a3,1
 676:	fec7f0e3          	bgeu	a5,a2,656 <printint+0x2a>
  if(neg)
 67a:	00088b63          	beqz	a7,690 <printint+0x64>
    buf[i++] = '-';
 67e:	fd040793          	addi	a5,s0,-48
 682:	973e                	add	a4,a4,a5
 684:	02d00793          	li	a5,45
 688:	fef70823          	sb	a5,-16(a4)
 68c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 690:	02e05863          	blez	a4,6c0 <printint+0x94>
 694:	fc040793          	addi	a5,s0,-64
 698:	00e78933          	add	s2,a5,a4
 69c:	fff78993          	addi	s3,a5,-1
 6a0:	99ba                	add	s3,s3,a4
 6a2:	377d                	addiw	a4,a4,-1
 6a4:	1702                	slli	a4,a4,0x20
 6a6:	9301                	srli	a4,a4,0x20
 6a8:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6ac:	fff94583          	lbu	a1,-1(s2)
 6b0:	8526                	mv	a0,s1
 6b2:	00000097          	auipc	ra,0x0
 6b6:	f58080e7          	jalr	-168(ra) # 60a <putc>
  while(--i >= 0)
 6ba:	197d                	addi	s2,s2,-1
 6bc:	ff3918e3          	bne	s2,s3,6ac <printint+0x80>
}
 6c0:	70e2                	ld	ra,56(sp)
 6c2:	7442                	ld	s0,48(sp)
 6c4:	74a2                	ld	s1,40(sp)
 6c6:	7902                	ld	s2,32(sp)
 6c8:	69e2                	ld	s3,24(sp)
 6ca:	6121                	addi	sp,sp,64
 6cc:	8082                	ret
    x = -xx;
 6ce:	40b005bb          	negw	a1,a1
    neg = 1;
 6d2:	4885                	li	a7,1
    x = -xx;
 6d4:	bf8d                	j	646 <printint+0x1a>

00000000000006d6 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6d6:	7119                	addi	sp,sp,-128
 6d8:	fc86                	sd	ra,120(sp)
 6da:	f8a2                	sd	s0,112(sp)
 6dc:	f4a6                	sd	s1,104(sp)
 6de:	f0ca                	sd	s2,96(sp)
 6e0:	ecce                	sd	s3,88(sp)
 6e2:	e8d2                	sd	s4,80(sp)
 6e4:	e4d6                	sd	s5,72(sp)
 6e6:	e0da                	sd	s6,64(sp)
 6e8:	fc5e                	sd	s7,56(sp)
 6ea:	f862                	sd	s8,48(sp)
 6ec:	f466                	sd	s9,40(sp)
 6ee:	f06a                	sd	s10,32(sp)
 6f0:	ec6e                	sd	s11,24(sp)
 6f2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6f4:	0005c903          	lbu	s2,0(a1)
 6f8:	18090f63          	beqz	s2,896 <vprintf+0x1c0>
 6fc:	8aaa                	mv	s5,a0
 6fe:	8b32                	mv	s6,a2
 700:	00158493          	addi	s1,a1,1
  state = 0;
 704:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 706:	02500a13          	li	s4,37
      if(c == 'd'){
 70a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 70e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 712:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 716:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 71a:	00000b97          	auipc	s7,0x0
 71e:	3e6b8b93          	addi	s7,s7,998 # b00 <digits>
 722:	a839                	j	740 <vprintf+0x6a>
        putc(fd, c);
 724:	85ca                	mv	a1,s2
 726:	8556                	mv	a0,s5
 728:	00000097          	auipc	ra,0x0
 72c:	ee2080e7          	jalr	-286(ra) # 60a <putc>
 730:	a019                	j	736 <vprintf+0x60>
    } else if(state == '%'){
 732:	01498f63          	beq	s3,s4,750 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 736:	0485                	addi	s1,s1,1
 738:	fff4c903          	lbu	s2,-1(s1)
 73c:	14090d63          	beqz	s2,896 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 740:	0009079b          	sext.w	a5,s2
    if(state == 0){
 744:	fe0997e3          	bnez	s3,732 <vprintf+0x5c>
      if(c == '%'){
 748:	fd479ee3          	bne	a5,s4,724 <vprintf+0x4e>
        state = '%';
 74c:	89be                	mv	s3,a5
 74e:	b7e5                	j	736 <vprintf+0x60>
      if(c == 'd'){
 750:	05878063          	beq	a5,s8,790 <vprintf+0xba>
      } else if(c == 'l') {
 754:	05978c63          	beq	a5,s9,7ac <vprintf+0xd6>
      } else if(c == 'x') {
 758:	07a78863          	beq	a5,s10,7c8 <vprintf+0xf2>
      } else if(c == 'p') {
 75c:	09b78463          	beq	a5,s11,7e4 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 760:	07300713          	li	a4,115
 764:	0ce78663          	beq	a5,a4,830 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 768:	06300713          	li	a4,99
 76c:	0ee78e63          	beq	a5,a4,868 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 770:	11478863          	beq	a5,s4,880 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 774:	85d2                	mv	a1,s4
 776:	8556                	mv	a0,s5
 778:	00000097          	auipc	ra,0x0
 77c:	e92080e7          	jalr	-366(ra) # 60a <putc>
        putc(fd, c);
 780:	85ca                	mv	a1,s2
 782:	8556                	mv	a0,s5
 784:	00000097          	auipc	ra,0x0
 788:	e86080e7          	jalr	-378(ra) # 60a <putc>
      }
      state = 0;
 78c:	4981                	li	s3,0
 78e:	b765                	j	736 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 790:	008b0913          	addi	s2,s6,8
 794:	4685                	li	a3,1
 796:	4629                	li	a2,10
 798:	000b2583          	lw	a1,0(s6)
 79c:	8556                	mv	a0,s5
 79e:	00000097          	auipc	ra,0x0
 7a2:	e8e080e7          	jalr	-370(ra) # 62c <printint>
 7a6:	8b4a                	mv	s6,s2
      state = 0;
 7a8:	4981                	li	s3,0
 7aa:	b771                	j	736 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7ac:	008b0913          	addi	s2,s6,8
 7b0:	4681                	li	a3,0
 7b2:	4629                	li	a2,10
 7b4:	000b2583          	lw	a1,0(s6)
 7b8:	8556                	mv	a0,s5
 7ba:	00000097          	auipc	ra,0x0
 7be:	e72080e7          	jalr	-398(ra) # 62c <printint>
 7c2:	8b4a                	mv	s6,s2
      state = 0;
 7c4:	4981                	li	s3,0
 7c6:	bf85                	j	736 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7c8:	008b0913          	addi	s2,s6,8
 7cc:	4681                	li	a3,0
 7ce:	4641                	li	a2,16
 7d0:	000b2583          	lw	a1,0(s6)
 7d4:	8556                	mv	a0,s5
 7d6:	00000097          	auipc	ra,0x0
 7da:	e56080e7          	jalr	-426(ra) # 62c <printint>
 7de:	8b4a                	mv	s6,s2
      state = 0;
 7e0:	4981                	li	s3,0
 7e2:	bf91                	j	736 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7e4:	008b0793          	addi	a5,s6,8
 7e8:	f8f43423          	sd	a5,-120(s0)
 7ec:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7f0:	03000593          	li	a1,48
 7f4:	8556                	mv	a0,s5
 7f6:	00000097          	auipc	ra,0x0
 7fa:	e14080e7          	jalr	-492(ra) # 60a <putc>
  putc(fd, 'x');
 7fe:	85ea                	mv	a1,s10
 800:	8556                	mv	a0,s5
 802:	00000097          	auipc	ra,0x0
 806:	e08080e7          	jalr	-504(ra) # 60a <putc>
 80a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 80c:	03c9d793          	srli	a5,s3,0x3c
 810:	97de                	add	a5,a5,s7
 812:	0007c583          	lbu	a1,0(a5)
 816:	8556                	mv	a0,s5
 818:	00000097          	auipc	ra,0x0
 81c:	df2080e7          	jalr	-526(ra) # 60a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 820:	0992                	slli	s3,s3,0x4
 822:	397d                	addiw	s2,s2,-1
 824:	fe0914e3          	bnez	s2,80c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 828:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 82c:	4981                	li	s3,0
 82e:	b721                	j	736 <vprintf+0x60>
        s = va_arg(ap, char*);
 830:	008b0993          	addi	s3,s6,8
 834:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 838:	02090163          	beqz	s2,85a <vprintf+0x184>
        while(*s != 0){
 83c:	00094583          	lbu	a1,0(s2)
 840:	c9a1                	beqz	a1,890 <vprintf+0x1ba>
          putc(fd, *s);
 842:	8556                	mv	a0,s5
 844:	00000097          	auipc	ra,0x0
 848:	dc6080e7          	jalr	-570(ra) # 60a <putc>
          s++;
 84c:	0905                	addi	s2,s2,1
        while(*s != 0){
 84e:	00094583          	lbu	a1,0(s2)
 852:	f9e5                	bnez	a1,842 <vprintf+0x16c>
        s = va_arg(ap, char*);
 854:	8b4e                	mv	s6,s3
      state = 0;
 856:	4981                	li	s3,0
 858:	bdf9                	j	736 <vprintf+0x60>
          s = "(null)";
 85a:	00000917          	auipc	s2,0x0
 85e:	29e90913          	addi	s2,s2,670 # af8 <malloc+0x158>
        while(*s != 0){
 862:	02800593          	li	a1,40
 866:	bff1                	j	842 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 868:	008b0913          	addi	s2,s6,8
 86c:	000b4583          	lbu	a1,0(s6)
 870:	8556                	mv	a0,s5
 872:	00000097          	auipc	ra,0x0
 876:	d98080e7          	jalr	-616(ra) # 60a <putc>
 87a:	8b4a                	mv	s6,s2
      state = 0;
 87c:	4981                	li	s3,0
 87e:	bd65                	j	736 <vprintf+0x60>
        putc(fd, c);
 880:	85d2                	mv	a1,s4
 882:	8556                	mv	a0,s5
 884:	00000097          	auipc	ra,0x0
 888:	d86080e7          	jalr	-634(ra) # 60a <putc>
      state = 0;
 88c:	4981                	li	s3,0
 88e:	b565                	j	736 <vprintf+0x60>
        s = va_arg(ap, char*);
 890:	8b4e                	mv	s6,s3
      state = 0;
 892:	4981                	li	s3,0
 894:	b54d                	j	736 <vprintf+0x60>
    }
  }
}
 896:	70e6                	ld	ra,120(sp)
 898:	7446                	ld	s0,112(sp)
 89a:	74a6                	ld	s1,104(sp)
 89c:	7906                	ld	s2,96(sp)
 89e:	69e6                	ld	s3,88(sp)
 8a0:	6a46                	ld	s4,80(sp)
 8a2:	6aa6                	ld	s5,72(sp)
 8a4:	6b06                	ld	s6,64(sp)
 8a6:	7be2                	ld	s7,56(sp)
 8a8:	7c42                	ld	s8,48(sp)
 8aa:	7ca2                	ld	s9,40(sp)
 8ac:	7d02                	ld	s10,32(sp)
 8ae:	6de2                	ld	s11,24(sp)
 8b0:	6109                	addi	sp,sp,128
 8b2:	8082                	ret

00000000000008b4 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8b4:	715d                	addi	sp,sp,-80
 8b6:	ec06                	sd	ra,24(sp)
 8b8:	e822                	sd	s0,16(sp)
 8ba:	1000                	addi	s0,sp,32
 8bc:	e010                	sd	a2,0(s0)
 8be:	e414                	sd	a3,8(s0)
 8c0:	e818                	sd	a4,16(s0)
 8c2:	ec1c                	sd	a5,24(s0)
 8c4:	03043023          	sd	a6,32(s0)
 8c8:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8cc:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8d0:	8622                	mv	a2,s0
 8d2:	00000097          	auipc	ra,0x0
 8d6:	e04080e7          	jalr	-508(ra) # 6d6 <vprintf>
}
 8da:	60e2                	ld	ra,24(sp)
 8dc:	6442                	ld	s0,16(sp)
 8de:	6161                	addi	sp,sp,80
 8e0:	8082                	ret

00000000000008e2 <printf>:

void
printf(const char *fmt, ...)
{
 8e2:	711d                	addi	sp,sp,-96
 8e4:	ec06                	sd	ra,24(sp)
 8e6:	e822                	sd	s0,16(sp)
 8e8:	1000                	addi	s0,sp,32
 8ea:	e40c                	sd	a1,8(s0)
 8ec:	e810                	sd	a2,16(s0)
 8ee:	ec14                	sd	a3,24(s0)
 8f0:	f018                	sd	a4,32(s0)
 8f2:	f41c                	sd	a5,40(s0)
 8f4:	03043823          	sd	a6,48(s0)
 8f8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8fc:	00840613          	addi	a2,s0,8
 900:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 904:	85aa                	mv	a1,a0
 906:	4505                	li	a0,1
 908:	00000097          	auipc	ra,0x0
 90c:	dce080e7          	jalr	-562(ra) # 6d6 <vprintf>
}
 910:	60e2                	ld	ra,24(sp)
 912:	6442                	ld	s0,16(sp)
 914:	6125                	addi	sp,sp,96
 916:	8082                	ret

0000000000000918 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 918:	1141                	addi	sp,sp,-16
 91a:	e422                	sd	s0,8(sp)
 91c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 91e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 922:	00000797          	auipc	a5,0x0
 926:	1f67b783          	ld	a5,502(a5) # b18 <freep>
 92a:	a805                	j	95a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 92c:	4618                	lw	a4,8(a2)
 92e:	9db9                	addw	a1,a1,a4
 930:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 934:	6398                	ld	a4,0(a5)
 936:	6318                	ld	a4,0(a4)
 938:	fee53823          	sd	a4,-16(a0)
 93c:	a091                	j	980 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 93e:	ff852703          	lw	a4,-8(a0)
 942:	9e39                	addw	a2,a2,a4
 944:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 946:	ff053703          	ld	a4,-16(a0)
 94a:	e398                	sd	a4,0(a5)
 94c:	a099                	j	992 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 94e:	6398                	ld	a4,0(a5)
 950:	00e7e463          	bltu	a5,a4,958 <free+0x40>
 954:	00e6ea63          	bltu	a3,a4,968 <free+0x50>
{
 958:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 95a:	fed7fae3          	bgeu	a5,a3,94e <free+0x36>
 95e:	6398                	ld	a4,0(a5)
 960:	00e6e463          	bltu	a3,a4,968 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 964:	fee7eae3          	bltu	a5,a4,958 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 968:	ff852583          	lw	a1,-8(a0)
 96c:	6390                	ld	a2,0(a5)
 96e:	02059713          	slli	a4,a1,0x20
 972:	9301                	srli	a4,a4,0x20
 974:	0712                	slli	a4,a4,0x4
 976:	9736                	add	a4,a4,a3
 978:	fae60ae3          	beq	a2,a4,92c <free+0x14>
    bp->s.ptr = p->s.ptr;
 97c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 980:	4790                	lw	a2,8(a5)
 982:	02061713          	slli	a4,a2,0x20
 986:	9301                	srli	a4,a4,0x20
 988:	0712                	slli	a4,a4,0x4
 98a:	973e                	add	a4,a4,a5
 98c:	fae689e3          	beq	a3,a4,93e <free+0x26>
  } else
    p->s.ptr = bp;
 990:	e394                	sd	a3,0(a5)
  freep = p;
 992:	00000717          	auipc	a4,0x0
 996:	18f73323          	sd	a5,390(a4) # b18 <freep>
}
 99a:	6422                	ld	s0,8(sp)
 99c:	0141                	addi	sp,sp,16
 99e:	8082                	ret

00000000000009a0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9a0:	7139                	addi	sp,sp,-64
 9a2:	fc06                	sd	ra,56(sp)
 9a4:	f822                	sd	s0,48(sp)
 9a6:	f426                	sd	s1,40(sp)
 9a8:	f04a                	sd	s2,32(sp)
 9aa:	ec4e                	sd	s3,24(sp)
 9ac:	e852                	sd	s4,16(sp)
 9ae:	e456                	sd	s5,8(sp)
 9b0:	e05a                	sd	s6,0(sp)
 9b2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9b4:	02051493          	slli	s1,a0,0x20
 9b8:	9081                	srli	s1,s1,0x20
 9ba:	04bd                	addi	s1,s1,15
 9bc:	8091                	srli	s1,s1,0x4
 9be:	0014899b          	addiw	s3,s1,1
 9c2:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9c4:	00000517          	auipc	a0,0x0
 9c8:	15453503          	ld	a0,340(a0) # b18 <freep>
 9cc:	c515                	beqz	a0,9f8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9ce:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9d0:	4798                	lw	a4,8(a5)
 9d2:	02977f63          	bgeu	a4,s1,a10 <malloc+0x70>
 9d6:	8a4e                	mv	s4,s3
 9d8:	0009871b          	sext.w	a4,s3
 9dc:	6685                	lui	a3,0x1
 9de:	00d77363          	bgeu	a4,a3,9e4 <malloc+0x44>
 9e2:	6a05                	lui	s4,0x1
 9e4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9e8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9ec:	00000917          	auipc	s2,0x0
 9f0:	12c90913          	addi	s2,s2,300 # b18 <freep>
  if(p == (char*)-1)
 9f4:	5afd                	li	s5,-1
 9f6:	a88d                	j	a68 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9f8:	00000797          	auipc	a5,0x0
 9fc:	13878793          	addi	a5,a5,312 # b30 <base>
 a00:	00000717          	auipc	a4,0x0
 a04:	10f73c23          	sd	a5,280(a4) # b18 <freep>
 a08:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a0a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a0e:	b7e1                	j	9d6 <malloc+0x36>
      if(p->s.size == nunits)
 a10:	02e48b63          	beq	s1,a4,a46 <malloc+0xa6>
        p->s.size -= nunits;
 a14:	4137073b          	subw	a4,a4,s3
 a18:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a1a:	1702                	slli	a4,a4,0x20
 a1c:	9301                	srli	a4,a4,0x20
 a1e:	0712                	slli	a4,a4,0x4
 a20:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a22:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a26:	00000717          	auipc	a4,0x0
 a2a:	0ea73923          	sd	a0,242(a4) # b18 <freep>
      return (void*)(p + 1);
 a2e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a32:	70e2                	ld	ra,56(sp)
 a34:	7442                	ld	s0,48(sp)
 a36:	74a2                	ld	s1,40(sp)
 a38:	7902                	ld	s2,32(sp)
 a3a:	69e2                	ld	s3,24(sp)
 a3c:	6a42                	ld	s4,16(sp)
 a3e:	6aa2                	ld	s5,8(sp)
 a40:	6b02                	ld	s6,0(sp)
 a42:	6121                	addi	sp,sp,64
 a44:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a46:	6398                	ld	a4,0(a5)
 a48:	e118                	sd	a4,0(a0)
 a4a:	bff1                	j	a26 <malloc+0x86>
  hp->s.size = nu;
 a4c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a50:	0541                	addi	a0,a0,16
 a52:	00000097          	auipc	ra,0x0
 a56:	ec6080e7          	jalr	-314(ra) # 918 <free>
  return freep;
 a5a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a5e:	d971                	beqz	a0,a32 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a60:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a62:	4798                	lw	a4,8(a5)
 a64:	fa9776e3          	bgeu	a4,s1,a10 <malloc+0x70>
    if(p == freep)
 a68:	00093703          	ld	a4,0(s2)
 a6c:	853e                	mv	a0,a5
 a6e:	fef719e3          	bne	a4,a5,a60 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a72:	8552                	mv	a0,s4
 a74:	00000097          	auipc	ra,0x0
 a78:	b5e080e7          	jalr	-1186(ra) # 5d2 <sbrk>
  if(p == (char*)-1)
 a7c:	fd5518e3          	bne	a0,s5,a4c <malloc+0xac>
        return 0;
 a80:	4501                	li	a0,0
 a82:	bf45                	j	a32 <malloc+0x92>
