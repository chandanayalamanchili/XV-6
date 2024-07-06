
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8c070713          	addi	a4,a4,-1856 # 80008910 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	f3e78793          	addi	a5,a5,-194 # 80005fa0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbc7f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	3fc080e7          	jalr	1020(ra) # 80002526 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	1a8080e7          	jalr	424(ra) # 80002370 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ee6080e7          	jalr	-282(ra) # 800020bc <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	2be080e7          	jalr	702(ra) # 800024d0 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	78450513          	addi	a0,a0,1924 # 80010a50 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	28a080e7          	jalr	650(ra) # 8000257c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	73270713          	addi	a4,a4,1842 # 80010a50 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	70878793          	addi	a5,a5,1800 # 80010a50 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7727a783          	lw	a5,1906(a5) # 80010ae8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6c670713          	addi	a4,a4,1734 # 80010a50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6b648493          	addi	s1,s1,1718 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	67a70713          	addi	a4,a4,1658 # 80010a50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72223          	sw	a5,1796(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	63e78793          	addi	a5,a5,1598 # 80010a50 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7ab23          	sw	a2,1718(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6aa50513          	addi	a0,a0,1706 # 80010ae8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	cda080e7          	jalr	-806(ra) # 80002120 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5f050513          	addi	a0,a0,1520 # 80010a50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	57078793          	addi	a5,a5,1392 # 800219e8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07a223          	sw	zero,1476(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	34f72823          	sw	a5,848(a4) # 800088d0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	554dad83          	lw	s11,1364(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	4fe50513          	addi	a0,a0,1278 # 80010af8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3a050513          	addi	a0,a0,928 # 80010af8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	38448493          	addi	s1,s1,900 # 80010af8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	34450513          	addi	a0,a0,836 # 80010b18 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0d07a783          	lw	a5,208(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0a07b783          	ld	a5,160(a5) # 800088d8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0a073703          	ld	a4,160(a4) # 800088e0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2b6a0a13          	addi	s4,s4,694 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	06e48493          	addi	s1,s1,110 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	06e98993          	addi	s3,s3,110 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	88c080e7          	jalr	-1908(ra) # 80002120 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	24850513          	addi	a0,a0,584 # 80010b18 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	ff07a783          	lw	a5,-16(a5) # 800088d0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	ff673703          	ld	a4,-10(a4) # 800088e0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fe67b783          	ld	a5,-26(a5) # 800088d8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	21a98993          	addi	s3,s3,538 # 80010b18 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fd248493          	addi	s1,s1,-46 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fd290913          	addi	s2,s2,-46 # 800088e0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	79e080e7          	jalr	1950(ra) # 800020bc <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1e448493          	addi	s1,s1,484 # 80010b18 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f8e7bc23          	sd	a4,-104(a5) # 800088e0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
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
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	15e48493          	addi	s1,s1,350 # 80010b18 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	18478793          	addi	a5,a5,388 # 80022b80 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	13490913          	addi	s2,s2,308 # 80010b50 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
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
    80000abe:	09650513          	addi	a0,a0,150 # 80010b50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	0b250513          	addi	a0,a0,178 # 80022b80 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
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
    80000af4:	06048493          	addi	s1,s1,96 # 80010b50 <kmem>
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
    80000b0c:	04850513          	addi	a0,a0,72 # 80010b50 <kmem>
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
    80000b38:	01c50513          	addi	a0,a0,28 # 80010b50 <kmem>
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
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
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
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
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
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
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
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
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
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

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
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
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
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

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
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

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
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc481>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a6070713          	addi	a4,a4,-1440 # 800088e8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	9aa080e7          	jalr	-1622(ra) # 80002868 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	11a080e7          	jalr	282(ra) # 80005fe0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	03c080e7          	jalr	60(ra) # 80001f0a <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	90a080e7          	jalr	-1782(ra) # 80002840 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	92a080e7          	jalr	-1750(ra) # 80002868 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	084080e7          	jalr	132(ra) # 80005fca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	092080e7          	jalr	146(ra) # 80005fe0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	214080e7          	jalr	532(ra) # 8000316a <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	8b4080e7          	jalr	-1868(ra) # 80003812 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	85a080e7          	jalr	-1958(ra) # 800047c0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	17a080e7          	jalr	378(ra) # 800060e8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d22080e7          	jalr	-734(ra) # 80001c98 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72223          	sw	a5,-1692(a4) # 800088e8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9587b783          	ld	a5,-1704(a5) # 800088f0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc477>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7be23          	sd	a0,1692(a5) # 800088f0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc480>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	75448493          	addi	s1,s1,1876 # 80010fa0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	f3aa0a13          	addi	s4,s4,-198 # 800177a0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8595                	srai	a1,a1,0x5
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	1a048493          	addi	s1,s1,416
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	28850513          	addi	a0,a0,648 # 80010b70 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	28850513          	addi	a0,a0,648 # 80010b88 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	69048493          	addi	s1,s1,1680 # 80010fa0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	e6e98993          	addi	s3,s3,-402 # 800177a0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8795                	srai	a5,a5,0x5
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	1a048493          	addi	s1,s1,416
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	20450513          	addi	a0,a0,516 # 80010ba0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1ac70713          	addi	a4,a4,428 # 80010b70 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	e7a080e7          	jalr	-390(ra) # 80002880 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407a523          	sw	zero,-438(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	d72080e7          	jalr	-654(ra) # 80003792 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	13a90913          	addi	s2,s2,314 # 80010b70 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e1c78793          	addi	a5,a5,-484 # 80008864 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3de48493          	addi	s1,s1,990 # 80010fa0 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	bd690913          	addi	s2,s2,-1066 # 800177a0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	1a048493          	addi	s1,s1,416
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a09d                	j	80001c5a <allocproc+0xa4>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	cd21                	beqz	a0,80001c68 <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c20:	c125                	beqz	a0,80001c80 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c46:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c4a:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	cb27a783          	lw	a5,-846(a5) # 80008900 <ticks>
    80001c56:	16f4a623          	sw	a5,364(s1)
}
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret
    freeproc(p);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	ef4080e7          	jalr	-268(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	016080e7          	jalr	22(ra) # 80000c8a <release>
    return 0;
    80001c7c:	84ca                	mv	s1,s2
    80001c7e:	bff1                	j	80001c5a <allocproc+0xa4>
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	edc080e7          	jalr	-292(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	ffe080e7          	jalr	-2(ra) # 80000c8a <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	b7d1                	j	80001c5a <allocproc+0xa4>

0000000080001c98 <userinit>:
{
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	f14080e7          	jalr	-236(ra) # 80001bb6 <allocproc>
    80001caa:	84aa                	mv	s1,a0
  initproc = p;
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	c4a7b623          	sd	a0,-948(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cb4:	03400613          	li	a2,52
    80001cb8:	00007597          	auipc	a1,0x7
    80001cbc:	bb858593          	addi	a1,a1,-1096 # 80008870 <initcode>
    80001cc0:	6928                	ld	a0,80(a0)
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	694080e7          	jalr	1684(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cca:	6785                	lui	a5,0x1
    80001ccc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cce:	6cb8                	ld	a4,88(s1)
    80001cd0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd8:	4641                	li	a2,16
    80001cda:	00006597          	auipc	a1,0x6
    80001cde:	52658593          	addi	a1,a1,1318 # 80008200 <digits+0x1c0>
    80001ce2:	15848513          	addi	a0,s1,344
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	136080e7          	jalr	310(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cee:	00006517          	auipc	a0,0x6
    80001cf2:	52250513          	addi	a0,a0,1314 # 80008210 <digits+0x1d0>
    80001cf6:	00002097          	auipc	ra,0x2
    80001cfa:	4c6080e7          	jalr	1222(ra) # 800041bc <namei>
    80001cfe:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d02:	478d                	li	a5,3
    80001d04:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f82080e7          	jalr	-126(ra) # 80000c8a <release>
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret

0000000080001d1a <growproc>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
    80001d26:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	c84080e7          	jalr	-892(ra) # 800019ac <myproc>
    80001d30:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d32:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d34:	01204c63          	bgtz	s2,80001d4c <growproc+0x32>
  else if (n < 0)
    80001d38:	02094663          	bltz	s2,80001d64 <growproc+0x4a>
  p->sz = sz;
    80001d3c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d3e:	4501                	li	a0,0
}
    80001d40:	60e2                	ld	ra,24(sp)
    80001d42:	6442                	ld	s0,16(sp)
    80001d44:	64a2                	ld	s1,8(sp)
    80001d46:	6902                	ld	s2,0(sp)
    80001d48:	6105                	addi	sp,sp,32
    80001d4a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d4c:	4691                	li	a3,4
    80001d4e:	00b90633          	add	a2,s2,a1
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	6bc080e7          	jalr	1724(ra) # 80001410 <uvmalloc>
    80001d5c:	85aa                	mv	a1,a0
    80001d5e:	fd79                	bnez	a0,80001d3c <growproc+0x22>
      return -1;
    80001d60:	557d                	li	a0,-1
    80001d62:	bff9                	j	80001d40 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	00b90633          	add	a2,s2,a1
    80001d68:	6928                	ld	a0,80(a0)
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	65e080e7          	jalr	1630(ra) # 800013c8 <uvmdealloc>
    80001d72:	85aa                	mv	a1,a0
    80001d74:	b7e1                	j	80001d3c <growproc+0x22>

0000000080001d76 <fork>:
{
    80001d76:	7139                	addi	sp,sp,-64
    80001d78:	fc06                	sd	ra,56(sp)
    80001d7a:	f822                	sd	s0,48(sp)
    80001d7c:	f426                	sd	s1,40(sp)
    80001d7e:	f04a                	sd	s2,32(sp)
    80001d80:	ec4e                	sd	s3,24(sp)
    80001d82:	e852                	sd	s4,16(sp)
    80001d84:	e456                	sd	s5,8(sp)
    80001d86:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	c24080e7          	jalr	-988(ra) # 800019ac <myproc>
    80001d90:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	e24080e7          	jalr	-476(ra) # 80001bb6 <allocproc>
    80001d9a:	10050c63          	beqz	a0,80001eb2 <fork+0x13c>
    80001d9e:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001da0:	048ab603          	ld	a2,72(s5)
    80001da4:	692c                	ld	a1,80(a0)
    80001da6:	050ab503          	ld	a0,80(s5)
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	7be080e7          	jalr	1982(ra) # 80001568 <uvmcopy>
    80001db2:	04054863          	bltz	a0,80001e02 <fork+0x8c>
  np->sz = p->sz;
    80001db6:	048ab783          	ld	a5,72(s5)
    80001dba:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dbe:	058ab683          	ld	a3,88(s5)
    80001dc2:	87b6                	mv	a5,a3
    80001dc4:	058a3703          	ld	a4,88(s4)
    80001dc8:	12068693          	addi	a3,a3,288
    80001dcc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd0:	6788                	ld	a0,8(a5)
    80001dd2:	6b8c                	ld	a1,16(a5)
    80001dd4:	6f90                	ld	a2,24(a5)
    80001dd6:	01073023          	sd	a6,0(a4)
    80001dda:	e708                	sd	a0,8(a4)
    80001ddc:	eb0c                	sd	a1,16(a4)
    80001dde:	ef10                	sd	a2,24(a4)
    80001de0:	02078793          	addi	a5,a5,32
    80001de4:	02070713          	addi	a4,a4,32
    80001de8:	fed792e3          	bne	a5,a3,80001dcc <fork+0x56>
  np->trapframe->a0 = 0;
    80001dec:	058a3783          	ld	a5,88(s4)
    80001df0:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001df4:	0d0a8493          	addi	s1,s5,208
    80001df8:	0d0a0913          	addi	s2,s4,208
    80001dfc:	150a8993          	addi	s3,s5,336
    80001e00:	a00d                	j	80001e22 <fork+0xac>
    freeproc(np);
    80001e02:	8552                	mv	a0,s4
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	d5a080e7          	jalr	-678(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e0c:	8552                	mv	a0,s4
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	e7c080e7          	jalr	-388(ra) # 80000c8a <release>
    return -1;
    80001e16:	597d                	li	s2,-1
    80001e18:	a059                	j	80001e9e <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e1a:	04a1                	addi	s1,s1,8
    80001e1c:	0921                	addi	s2,s2,8
    80001e1e:	01348b63          	beq	s1,s3,80001e34 <fork+0xbe>
    if (p->ofile[i])
    80001e22:	6088                	ld	a0,0(s1)
    80001e24:	d97d                	beqz	a0,80001e1a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e26:	00003097          	auipc	ra,0x3
    80001e2a:	a2c080e7          	jalr	-1492(ra) # 80004852 <filedup>
    80001e2e:	00a93023          	sd	a0,0(s2)
    80001e32:	b7e5                	j	80001e1a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e34:	150ab503          	ld	a0,336(s5)
    80001e38:	00002097          	auipc	ra,0x2
    80001e3c:	b9a080e7          	jalr	-1126(ra) # 800039d2 <idup>
    80001e40:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e44:	4641                	li	a2,16
    80001e46:	158a8593          	addi	a1,s5,344
    80001e4a:	158a0513          	addi	a0,s4,344
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	fce080e7          	jalr	-50(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e56:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e5a:	8552                	mv	a0,s4
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	e2e080e7          	jalr	-466(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e64:	0000f497          	auipc	s1,0xf
    80001e68:	d2448493          	addi	s1,s1,-732 # 80010b88 <wait_lock>
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	d68080e7          	jalr	-664(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e76:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e0e080e7          	jalr	-498(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e84:	8552                	mv	a0,s4
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	d50080e7          	jalr	-688(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e8e:	478d                	li	a5,3
    80001e90:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e94:	8552                	mv	a0,s4
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	df4080e7          	jalr	-524(ra) # 80000c8a <release>
}
    80001e9e:	854a                	mv	a0,s2
    80001ea0:	70e2                	ld	ra,56(sp)
    80001ea2:	7442                	ld	s0,48(sp)
    80001ea4:	74a2                	ld	s1,40(sp)
    80001ea6:	7902                	ld	s2,32(sp)
    80001ea8:	69e2                	ld	s3,24(sp)
    80001eaa:	6a42                	ld	s4,16(sp)
    80001eac:	6aa2                	ld	s5,8(sp)
    80001eae:	6121                	addi	sp,sp,64
    80001eb0:	8082                	ret
    return -1;
    80001eb2:	597d                	li	s2,-1
    80001eb4:	b7ed                	j	80001e9e <fork+0x128>

0000000080001eb6 <run_proc>:
void run_proc(struct proc* p, struct cpu* c){
    80001eb6:	1101                	addi	sp,sp,-32
    80001eb8:	ec06                	sd	ra,24(sp)
    80001eba:	e822                	sd	s0,16(sp)
    80001ebc:	e426                	sd	s1,8(sp)
    80001ebe:	e04a                	sd	s2,0(sp)
    80001ec0:	1000                	addi	s0,sp,32
    80001ec2:	84aa                	mv	s1,a0
    80001ec4:	892e                	mv	s2,a1
  acquire(&p->lock);
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	d10080e7          	jalr	-752(ra) # 80000bd6 <acquire>
  if (p->state == RUNNABLE)
    80001ece:	4c98                	lw	a4,24(s1)
    80001ed0:	478d                	li	a5,3
    80001ed2:	00f70d63          	beq	a4,a5,80001eec <run_proc+0x36>
  release(&p->lock);
    80001ed6:	8526                	mv	a0,s1
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	db2080e7          	jalr	-590(ra) # 80000c8a <release>
}
    80001ee0:	60e2                	ld	ra,24(sp)
    80001ee2:	6442                	ld	s0,16(sp)
    80001ee4:	64a2                	ld	s1,8(sp)
    80001ee6:	6902                	ld	s2,0(sp)
    80001ee8:	6105                	addi	sp,sp,32
    80001eea:	8082                	ret
    p->state = RUNNING;
    80001eec:	4791                	li	a5,4
    80001eee:	cc9c                	sw	a5,24(s1)
    c->proc = p;
    80001ef0:	00993023          	sd	s1,0(s2)
    swtch(&c->context, &p->context);
    80001ef4:	06048593          	addi	a1,s1,96
    80001ef8:	00890513          	addi	a0,s2,8
    80001efc:	00001097          	auipc	ra,0x1
    80001f00:	8da080e7          	jalr	-1830(ra) # 800027d6 <swtch>
    c->proc = 0;
    80001f04:	00093023          	sd	zero,0(s2)
    80001f08:	b7f9                	j	80001ed6 <run_proc+0x20>

0000000080001f0a <scheduler>:
{
    80001f0a:	7139                	addi	sp,sp,-64
    80001f0c:	fc06                	sd	ra,56(sp)
    80001f0e:	f822                	sd	s0,48(sp)
    80001f10:	f426                	sd	s1,40(sp)
    80001f12:	f04a                	sd	s2,32(sp)
    80001f14:	ec4e                	sd	s3,24(sp)
    80001f16:	e852                	sd	s4,16(sp)
    80001f18:	e456                	sd	s5,8(sp)
    80001f1a:	e05a                	sd	s6,0(sp)
    80001f1c:	0080                	addi	s0,sp,64
    80001f1e:	8792                	mv	a5,tp
  int id = r_tp();
    80001f20:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f22:	00779a93          	slli	s5,a5,0x7
    80001f26:	0000f717          	auipc	a4,0xf
    80001f2a:	c4a70713          	addi	a4,a4,-950 # 80010b70 <pid_lock>
    80001f2e:	9756                	add	a4,a4,s5
    80001f30:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f34:	0000f717          	auipc	a4,0xf
    80001f38:	c7470713          	addi	a4,a4,-908 # 80010ba8 <cpus+0x8>
    80001f3c:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f3e:	498d                	li	s3,3
        p->state = RUNNING;
    80001f40:	4b11                	li	s6,4
        c->proc = p;
    80001f42:	079e                	slli	a5,a5,0x7
    80001f44:	0000fa17          	auipc	s4,0xf
    80001f48:	c2ca0a13          	addi	s4,s4,-980 # 80010b70 <pid_lock>
    80001f4c:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f4e:	00016917          	auipc	s2,0x16
    80001f52:	85290913          	addi	s2,s2,-1966 # 800177a0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f5e:	10079073          	csrw	sstatus,a5
    80001f62:	0000f497          	auipc	s1,0xf
    80001f66:	03e48493          	addi	s1,s1,62 # 80010fa0 <proc>
    80001f6a:	a811                	j	80001f7e <scheduler+0x74>
      release(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	d1c080e7          	jalr	-740(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f76:	1a048493          	addi	s1,s1,416
    80001f7a:	fd248ee3          	beq	s1,s2,80001f56 <scheduler+0x4c>
      acquire(&p->lock);
    80001f7e:	8526                	mv	a0,s1
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	c56080e7          	jalr	-938(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f88:	4c9c                	lw	a5,24(s1)
    80001f8a:	ff3791e3          	bne	a5,s3,80001f6c <scheduler+0x62>
        p->state = RUNNING;
    80001f8e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f92:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f96:	06048593          	addi	a1,s1,96
    80001f9a:	8556                	mv	a0,s5
    80001f9c:	00001097          	auipc	ra,0x1
    80001fa0:	83a080e7          	jalr	-1990(ra) # 800027d6 <swtch>
        c->proc = 0;
    80001fa4:	020a3823          	sd	zero,48(s4)
    80001fa8:	b7d1                	j	80001f6c <scheduler+0x62>

0000000080001faa <sched>:
{
    80001faa:	7179                	addi	sp,sp,-48
    80001fac:	f406                	sd	ra,40(sp)
    80001fae:	f022                	sd	s0,32(sp)
    80001fb0:	ec26                	sd	s1,24(sp)
    80001fb2:	e84a                	sd	s2,16(sp)
    80001fb4:	e44e                	sd	s3,8(sp)
    80001fb6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	9f4080e7          	jalr	-1548(ra) # 800019ac <myproc>
    80001fc0:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	b9a080e7          	jalr	-1126(ra) # 80000b5c <holding>
    80001fca:	c93d                	beqz	a0,80002040 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fcc:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001fce:	2781                	sext.w	a5,a5
    80001fd0:	079e                	slli	a5,a5,0x7
    80001fd2:	0000f717          	auipc	a4,0xf
    80001fd6:	b9e70713          	addi	a4,a4,-1122 # 80010b70 <pid_lock>
    80001fda:	97ba                	add	a5,a5,a4
    80001fdc:	0a87a703          	lw	a4,168(a5)
    80001fe0:	4785                	li	a5,1
    80001fe2:	06f71763          	bne	a4,a5,80002050 <sched+0xa6>
  if (p->state == RUNNING)
    80001fe6:	4c98                	lw	a4,24(s1)
    80001fe8:	4791                	li	a5,4
    80001fea:	06f70b63          	beq	a4,a5,80002060 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fee:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ff2:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001ff4:	efb5                	bnez	a5,80002070 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001ff8:	0000f917          	auipc	s2,0xf
    80001ffc:	b7890913          	addi	s2,s2,-1160 # 80010b70 <pid_lock>
    80002000:	2781                	sext.w	a5,a5
    80002002:	079e                	slli	a5,a5,0x7
    80002004:	97ca                	add	a5,a5,s2
    80002006:	0ac7a983          	lw	s3,172(a5)
    8000200a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	0000f597          	auipc	a1,0xf
    80002014:	b9858593          	addi	a1,a1,-1128 # 80010ba8 <cpus+0x8>
    80002018:	95be                	add	a1,a1,a5
    8000201a:	06048513          	addi	a0,s1,96
    8000201e:	00000097          	auipc	ra,0x0
    80002022:	7b8080e7          	jalr	1976(ra) # 800027d6 <swtch>
    80002026:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002028:	2781                	sext.w	a5,a5
    8000202a:	079e                	slli	a5,a5,0x7
    8000202c:	993e                	add	s2,s2,a5
    8000202e:	0b392623          	sw	s3,172(s2)
}
    80002032:	70a2                	ld	ra,40(sp)
    80002034:	7402                	ld	s0,32(sp)
    80002036:	64e2                	ld	s1,24(sp)
    80002038:	6942                	ld	s2,16(sp)
    8000203a:	69a2                	ld	s3,8(sp)
    8000203c:	6145                	addi	sp,sp,48
    8000203e:	8082                	ret
    panic("sched p->lock");
    80002040:	00006517          	auipc	a0,0x6
    80002044:	1d850513          	addi	a0,a0,472 # 80008218 <digits+0x1d8>
    80002048:	ffffe097          	auipc	ra,0xffffe
    8000204c:	4f8080e7          	jalr	1272(ra) # 80000540 <panic>
    panic("sched locks");
    80002050:	00006517          	auipc	a0,0x6
    80002054:	1d850513          	addi	a0,a0,472 # 80008228 <digits+0x1e8>
    80002058:	ffffe097          	auipc	ra,0xffffe
    8000205c:	4e8080e7          	jalr	1256(ra) # 80000540 <panic>
    panic("sched running");
    80002060:	00006517          	auipc	a0,0x6
    80002064:	1d850513          	addi	a0,a0,472 # 80008238 <digits+0x1f8>
    80002068:	ffffe097          	auipc	ra,0xffffe
    8000206c:	4d8080e7          	jalr	1240(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	1d850513          	addi	a0,a0,472 # 80008248 <digits+0x208>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4c8080e7          	jalr	1224(ra) # 80000540 <panic>

0000000080002080 <yield>:
{
    80002080:	1101                	addi	sp,sp,-32
    80002082:	ec06                	sd	ra,24(sp)
    80002084:	e822                	sd	s0,16(sp)
    80002086:	e426                	sd	s1,8(sp)
    80002088:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	922080e7          	jalr	-1758(ra) # 800019ac <myproc>
    80002092:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	b42080e7          	jalr	-1214(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000209c:	478d                	li	a5,3
    8000209e:	cc9c                	sw	a5,24(s1)
  sched();
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	f0a080e7          	jalr	-246(ra) # 80001faa <sched>
  release(&p->lock);
    800020a8:	8526                	mv	a0,s1
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	be0080e7          	jalr	-1056(ra) # 80000c8a <release>
}
    800020b2:	60e2                	ld	ra,24(sp)
    800020b4:	6442                	ld	s0,16(sp)
    800020b6:	64a2                	ld	s1,8(sp)
    800020b8:	6105                	addi	sp,sp,32
    800020ba:	8082                	ret

00000000800020bc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020bc:	7179                	addi	sp,sp,-48
    800020be:	f406                	sd	ra,40(sp)
    800020c0:	f022                	sd	s0,32(sp)
    800020c2:	ec26                	sd	s1,24(sp)
    800020c4:	e84a                	sd	s2,16(sp)
    800020c6:	e44e                	sd	s3,8(sp)
    800020c8:	1800                	addi	s0,sp,48
    800020ca:	89aa                	mv	s3,a0
    800020cc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020ce:	00000097          	auipc	ra,0x0
    800020d2:	8de080e7          	jalr	-1826(ra) # 800019ac <myproc>
    800020d6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	afe080e7          	jalr	-1282(ra) # 80000bd6 <acquire>
  release(lk);
    800020e0:	854a                	mv	a0,s2
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	ba8080e7          	jalr	-1112(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020ea:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020ee:	4789                	li	a5,2
    800020f0:	cc9c                	sw	a5,24(s1)

  sched();
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	eb8080e7          	jalr	-328(ra) # 80001faa <sched>

  // Tidy up.
  p->chan = 0;
    800020fa:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	b8a080e7          	jalr	-1142(ra) # 80000c8a <release>
  acquire(lk);
    80002108:	854a                	mv	a0,s2
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	acc080e7          	jalr	-1332(ra) # 80000bd6 <acquire>
}
    80002112:	70a2                	ld	ra,40(sp)
    80002114:	7402                	ld	s0,32(sp)
    80002116:	64e2                	ld	s1,24(sp)
    80002118:	6942                	ld	s2,16(sp)
    8000211a:	69a2                	ld	s3,8(sp)
    8000211c:	6145                	addi	sp,sp,48
    8000211e:	8082                	ret

0000000080002120 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002120:	7139                	addi	sp,sp,-64
    80002122:	fc06                	sd	ra,56(sp)
    80002124:	f822                	sd	s0,48(sp)
    80002126:	f426                	sd	s1,40(sp)
    80002128:	f04a                	sd	s2,32(sp)
    8000212a:	ec4e                	sd	s3,24(sp)
    8000212c:	e852                	sd	s4,16(sp)
    8000212e:	e456                	sd	s5,8(sp)
    80002130:	0080                	addi	s0,sp,64
    80002132:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002134:	0000f497          	auipc	s1,0xf
    80002138:	e6c48493          	addi	s1,s1,-404 # 80010fa0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000213c:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000213e:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002140:	00015917          	auipc	s2,0x15
    80002144:	66090913          	addi	s2,s2,1632 # 800177a0 <tickslock>
    80002148:	a811                	j	8000215c <wakeup+0x3c>
      }
      release(&p->lock);
    8000214a:	8526                	mv	a0,s1
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b3e080e7          	jalr	-1218(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002154:	1a048493          	addi	s1,s1,416
    80002158:	03248663          	beq	s1,s2,80002184 <wakeup+0x64>
    if (p != myproc())
    8000215c:	00000097          	auipc	ra,0x0
    80002160:	850080e7          	jalr	-1968(ra) # 800019ac <myproc>
    80002164:	fea488e3          	beq	s1,a0,80002154 <wakeup+0x34>
      acquire(&p->lock);
    80002168:	8526                	mv	a0,s1
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	a6c080e7          	jalr	-1428(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002172:	4c9c                	lw	a5,24(s1)
    80002174:	fd379be3          	bne	a5,s3,8000214a <wakeup+0x2a>
    80002178:	709c                	ld	a5,32(s1)
    8000217a:	fd4798e3          	bne	a5,s4,8000214a <wakeup+0x2a>
        p->state = RUNNABLE;
    8000217e:	0154ac23          	sw	s5,24(s1)
    80002182:	b7e1                	j	8000214a <wakeup+0x2a>
    }
  }
}
    80002184:	70e2                	ld	ra,56(sp)
    80002186:	7442                	ld	s0,48(sp)
    80002188:	74a2                	ld	s1,40(sp)
    8000218a:	7902                	ld	s2,32(sp)
    8000218c:	69e2                	ld	s3,24(sp)
    8000218e:	6a42                	ld	s4,16(sp)
    80002190:	6aa2                	ld	s5,8(sp)
    80002192:	6121                	addi	sp,sp,64
    80002194:	8082                	ret

0000000080002196 <reparent>:
{
    80002196:	7179                	addi	sp,sp,-48
    80002198:	f406                	sd	ra,40(sp)
    8000219a:	f022                	sd	s0,32(sp)
    8000219c:	ec26                	sd	s1,24(sp)
    8000219e:	e84a                	sd	s2,16(sp)
    800021a0:	e44e                	sd	s3,8(sp)
    800021a2:	e052                	sd	s4,0(sp)
    800021a4:	1800                	addi	s0,sp,48
    800021a6:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021a8:	0000f497          	auipc	s1,0xf
    800021ac:	df848493          	addi	s1,s1,-520 # 80010fa0 <proc>
      pp->parent = initproc;
    800021b0:	00006a17          	auipc	s4,0x6
    800021b4:	748a0a13          	addi	s4,s4,1864 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021b8:	00015997          	auipc	s3,0x15
    800021bc:	5e898993          	addi	s3,s3,1512 # 800177a0 <tickslock>
    800021c0:	a029                	j	800021ca <reparent+0x34>
    800021c2:	1a048493          	addi	s1,s1,416
    800021c6:	01348d63          	beq	s1,s3,800021e0 <reparent+0x4a>
    if (pp->parent == p)
    800021ca:	7c9c                	ld	a5,56(s1)
    800021cc:	ff279be3          	bne	a5,s2,800021c2 <reparent+0x2c>
      pp->parent = initproc;
    800021d0:	000a3503          	ld	a0,0(s4)
    800021d4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021d6:	00000097          	auipc	ra,0x0
    800021da:	f4a080e7          	jalr	-182(ra) # 80002120 <wakeup>
    800021de:	b7d5                	j	800021c2 <reparent+0x2c>
}
    800021e0:	70a2                	ld	ra,40(sp)
    800021e2:	7402                	ld	s0,32(sp)
    800021e4:	64e2                	ld	s1,24(sp)
    800021e6:	6942                	ld	s2,16(sp)
    800021e8:	69a2                	ld	s3,8(sp)
    800021ea:	6a02                	ld	s4,0(sp)
    800021ec:	6145                	addi	sp,sp,48
    800021ee:	8082                	ret

00000000800021f0 <exit>:
{
    800021f0:	7179                	addi	sp,sp,-48
    800021f2:	f406                	sd	ra,40(sp)
    800021f4:	f022                	sd	s0,32(sp)
    800021f6:	ec26                	sd	s1,24(sp)
    800021f8:	e84a                	sd	s2,16(sp)
    800021fa:	e44e                	sd	s3,8(sp)
    800021fc:	e052                	sd	s4,0(sp)
    800021fe:	1800                	addi	s0,sp,48
    80002200:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	7aa080e7          	jalr	1962(ra) # 800019ac <myproc>
    8000220a:	89aa                	mv	s3,a0
  if (p == initproc)
    8000220c:	00006797          	auipc	a5,0x6
    80002210:	6ec7b783          	ld	a5,1772(a5) # 800088f8 <initproc>
    80002214:	0d050493          	addi	s1,a0,208
    80002218:	15050913          	addi	s2,a0,336
    8000221c:	02a79363          	bne	a5,a0,80002242 <exit+0x52>
    panic("init exiting");
    80002220:	00006517          	auipc	a0,0x6
    80002224:	04050513          	addi	a0,a0,64 # 80008260 <digits+0x220>
    80002228:	ffffe097          	auipc	ra,0xffffe
    8000222c:	318080e7          	jalr	792(ra) # 80000540 <panic>
      fileclose(f);
    80002230:	00002097          	auipc	ra,0x2
    80002234:	674080e7          	jalr	1652(ra) # 800048a4 <fileclose>
      p->ofile[fd] = 0;
    80002238:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000223c:	04a1                	addi	s1,s1,8
    8000223e:	01248563          	beq	s1,s2,80002248 <exit+0x58>
    if (p->ofile[fd])
    80002242:	6088                	ld	a0,0(s1)
    80002244:	f575                	bnez	a0,80002230 <exit+0x40>
    80002246:	bfdd                	j	8000223c <exit+0x4c>
  begin_op();
    80002248:	00002097          	auipc	ra,0x2
    8000224c:	194080e7          	jalr	404(ra) # 800043dc <begin_op>
  iput(p->cwd);
    80002250:	1509b503          	ld	a0,336(s3)
    80002254:	00002097          	auipc	ra,0x2
    80002258:	976080e7          	jalr	-1674(ra) # 80003bca <iput>
  end_op();
    8000225c:	00002097          	auipc	ra,0x2
    80002260:	1fe080e7          	jalr	510(ra) # 8000445a <end_op>
  p->cwd = 0;
    80002264:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002268:	0000f497          	auipc	s1,0xf
    8000226c:	92048493          	addi	s1,s1,-1760 # 80010b88 <wait_lock>
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	964080e7          	jalr	-1692(ra) # 80000bd6 <acquire>
  reparent(p);
    8000227a:	854e                	mv	a0,s3
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	f1a080e7          	jalr	-230(ra) # 80002196 <reparent>
  wakeup(p->parent);
    80002284:	0389b503          	ld	a0,56(s3)
    80002288:	00000097          	auipc	ra,0x0
    8000228c:	e98080e7          	jalr	-360(ra) # 80002120 <wakeup>
  acquire(&p->lock);
    80002290:	854e                	mv	a0,s3
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	944080e7          	jalr	-1724(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000229a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000229e:	4795                	li	a5,5
    800022a0:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800022a4:	00006797          	auipc	a5,0x6
    800022a8:	65c7a783          	lw	a5,1628(a5) # 80008900 <ticks>
    800022ac:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
  sched();
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	cf0080e7          	jalr	-784(ra) # 80001faa <sched>
  panic("zombie exit");
    800022c2:	00006517          	auipc	a0,0x6
    800022c6:	fae50513          	addi	a0,a0,-82 # 80008270 <digits+0x230>
    800022ca:	ffffe097          	auipc	ra,0xffffe
    800022ce:	276080e7          	jalr	630(ra) # 80000540 <panic>

00000000800022d2 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800022d2:	7179                	addi	sp,sp,-48
    800022d4:	f406                	sd	ra,40(sp)
    800022d6:	f022                	sd	s0,32(sp)
    800022d8:	ec26                	sd	s1,24(sp)
    800022da:	e84a                	sd	s2,16(sp)
    800022dc:	e44e                	sd	s3,8(sp)
    800022de:	1800                	addi	s0,sp,48
    800022e0:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022e2:	0000f497          	auipc	s1,0xf
    800022e6:	cbe48493          	addi	s1,s1,-834 # 80010fa0 <proc>
    800022ea:	00015997          	auipc	s3,0x15
    800022ee:	4b698993          	addi	s3,s3,1206 # 800177a0 <tickslock>
  {
    acquire(&p->lock);
    800022f2:	8526                	mv	a0,s1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	8e2080e7          	jalr	-1822(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800022fc:	589c                	lw	a5,48(s1)
    800022fe:	01278d63          	beq	a5,s2,80002318 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002302:	8526                	mv	a0,s1
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	986080e7          	jalr	-1658(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000230c:	1a048493          	addi	s1,s1,416
    80002310:	ff3491e3          	bne	s1,s3,800022f2 <kill+0x20>
  }
  return -1;
    80002314:	557d                	li	a0,-1
    80002316:	a829                	j	80002330 <kill+0x5e>
      p->killed = 1;
    80002318:	4785                	li	a5,1
    8000231a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000231c:	4c98                	lw	a4,24(s1)
    8000231e:	4789                	li	a5,2
    80002320:	00f70f63          	beq	a4,a5,8000233e <kill+0x6c>
      release(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	964080e7          	jalr	-1692(ra) # 80000c8a <release>
      return 0;
    8000232e:	4501                	li	a0,0
}
    80002330:	70a2                	ld	ra,40(sp)
    80002332:	7402                	ld	s0,32(sp)
    80002334:	64e2                	ld	s1,24(sp)
    80002336:	6942                	ld	s2,16(sp)
    80002338:	69a2                	ld	s3,8(sp)
    8000233a:	6145                	addi	sp,sp,48
    8000233c:	8082                	ret
        p->state = RUNNABLE;
    8000233e:	478d                	li	a5,3
    80002340:	cc9c                	sw	a5,24(s1)
    80002342:	b7cd                	j	80002324 <kill+0x52>

0000000080002344 <setkilled>:

void setkilled(struct proc *p)
{
    80002344:	1101                	addi	sp,sp,-32
    80002346:	ec06                	sd	ra,24(sp)
    80002348:	e822                	sd	s0,16(sp)
    8000234a:	e426                	sd	s1,8(sp)
    8000234c:	1000                	addi	s0,sp,32
    8000234e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	886080e7          	jalr	-1914(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002358:	4785                	li	a5,1
    8000235a:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000235c:	8526                	mv	a0,s1
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	92c080e7          	jalr	-1748(ra) # 80000c8a <release>
}
    80002366:	60e2                	ld	ra,24(sp)
    80002368:	6442                	ld	s0,16(sp)
    8000236a:	64a2                	ld	s1,8(sp)
    8000236c:	6105                	addi	sp,sp,32
    8000236e:	8082                	ret

0000000080002370 <killed>:

int killed(struct proc *p)
{
    80002370:	1101                	addi	sp,sp,-32
    80002372:	ec06                	sd	ra,24(sp)
    80002374:	e822                	sd	s0,16(sp)
    80002376:	e426                	sd	s1,8(sp)
    80002378:	e04a                	sd	s2,0(sp)
    8000237a:	1000                	addi	s0,sp,32
    8000237c:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	858080e7          	jalr	-1960(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002386:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	8fe080e7          	jalr	-1794(ra) # 80000c8a <release>
  return k;
}
    80002394:	854a                	mv	a0,s2
    80002396:	60e2                	ld	ra,24(sp)
    80002398:	6442                	ld	s0,16(sp)
    8000239a:	64a2                	ld	s1,8(sp)
    8000239c:	6902                	ld	s2,0(sp)
    8000239e:	6105                	addi	sp,sp,32
    800023a0:	8082                	ret

00000000800023a2 <wait>:
{
    800023a2:	715d                	addi	sp,sp,-80
    800023a4:	e486                	sd	ra,72(sp)
    800023a6:	e0a2                	sd	s0,64(sp)
    800023a8:	fc26                	sd	s1,56(sp)
    800023aa:	f84a                	sd	s2,48(sp)
    800023ac:	f44e                	sd	s3,40(sp)
    800023ae:	f052                	sd	s4,32(sp)
    800023b0:	ec56                	sd	s5,24(sp)
    800023b2:	e85a                	sd	s6,16(sp)
    800023b4:	e45e                	sd	s7,8(sp)
    800023b6:	e062                	sd	s8,0(sp)
    800023b8:	0880                	addi	s0,sp,80
    800023ba:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	5f0080e7          	jalr	1520(ra) # 800019ac <myproc>
    800023c4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023c6:	0000e517          	auipc	a0,0xe
    800023ca:	7c250513          	addi	a0,a0,1986 # 80010b88 <wait_lock>
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	808080e7          	jalr	-2040(ra) # 80000bd6 <acquire>
    havekids = 0;
    800023d6:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800023d8:	4a15                	li	s4,5
        havekids = 1;
    800023da:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023dc:	00015997          	auipc	s3,0x15
    800023e0:	3c498993          	addi	s3,s3,964 # 800177a0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800023e4:	0000ec17          	auipc	s8,0xe
    800023e8:	7a4c0c13          	addi	s8,s8,1956 # 80010b88 <wait_lock>
    havekids = 0;
    800023ec:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023ee:	0000f497          	auipc	s1,0xf
    800023f2:	bb248493          	addi	s1,s1,-1102 # 80010fa0 <proc>
    800023f6:	a0bd                	j	80002464 <wait+0xc2>
          pid = pp->pid;
    800023f8:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023fc:	000b0e63          	beqz	s6,80002418 <wait+0x76>
    80002400:	4691                	li	a3,4
    80002402:	02c48613          	addi	a2,s1,44
    80002406:	85da                	mv	a1,s6
    80002408:	05093503          	ld	a0,80(s2)
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	260080e7          	jalr	608(ra) # 8000166c <copyout>
    80002414:	02054563          	bltz	a0,8000243e <wait+0x9c>
          freeproc(pp);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	744080e7          	jalr	1860(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002422:	8526                	mv	a0,s1
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	866080e7          	jalr	-1946(ra) # 80000c8a <release>
          release(&wait_lock);
    8000242c:	0000e517          	auipc	a0,0xe
    80002430:	75c50513          	addi	a0,a0,1884 # 80010b88 <wait_lock>
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	856080e7          	jalr	-1962(ra) # 80000c8a <release>
          return pid;
    8000243c:	a0b5                	j	800024a8 <wait+0x106>
            release(&pp->lock);
    8000243e:	8526                	mv	a0,s1
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	84a080e7          	jalr	-1974(ra) # 80000c8a <release>
            release(&wait_lock);
    80002448:	0000e517          	auipc	a0,0xe
    8000244c:	74050513          	addi	a0,a0,1856 # 80010b88 <wait_lock>
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	83a080e7          	jalr	-1990(ra) # 80000c8a <release>
            return -1;
    80002458:	59fd                	li	s3,-1
    8000245a:	a0b9                	j	800024a8 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000245c:	1a048493          	addi	s1,s1,416
    80002460:	03348463          	beq	s1,s3,80002488 <wait+0xe6>
      if (pp->parent == p)
    80002464:	7c9c                	ld	a5,56(s1)
    80002466:	ff279be3          	bne	a5,s2,8000245c <wait+0xba>
        acquire(&pp->lock);
    8000246a:	8526                	mv	a0,s1
    8000246c:	ffffe097          	auipc	ra,0xffffe
    80002470:	76a080e7          	jalr	1898(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002474:	4c9c                	lw	a5,24(s1)
    80002476:	f94781e3          	beq	a5,s4,800023f8 <wait+0x56>
        release(&pp->lock);
    8000247a:	8526                	mv	a0,s1
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	80e080e7          	jalr	-2034(ra) # 80000c8a <release>
        havekids = 1;
    80002484:	8756                	mv	a4,s5
    80002486:	bfd9                	j	8000245c <wait+0xba>
    if (!havekids || killed(p))
    80002488:	c719                	beqz	a4,80002496 <wait+0xf4>
    8000248a:	854a                	mv	a0,s2
    8000248c:	00000097          	auipc	ra,0x0
    80002490:	ee4080e7          	jalr	-284(ra) # 80002370 <killed>
    80002494:	c51d                	beqz	a0,800024c2 <wait+0x120>
      release(&wait_lock);
    80002496:	0000e517          	auipc	a0,0xe
    8000249a:	6f250513          	addi	a0,a0,1778 # 80010b88 <wait_lock>
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	7ec080e7          	jalr	2028(ra) # 80000c8a <release>
      return -1;
    800024a6:	59fd                	li	s3,-1
}
    800024a8:	854e                	mv	a0,s3
    800024aa:	60a6                	ld	ra,72(sp)
    800024ac:	6406                	ld	s0,64(sp)
    800024ae:	74e2                	ld	s1,56(sp)
    800024b0:	7942                	ld	s2,48(sp)
    800024b2:	79a2                	ld	s3,40(sp)
    800024b4:	7a02                	ld	s4,32(sp)
    800024b6:	6ae2                	ld	s5,24(sp)
    800024b8:	6b42                	ld	s6,16(sp)
    800024ba:	6ba2                	ld	s7,8(sp)
    800024bc:	6c02                	ld	s8,0(sp)
    800024be:	6161                	addi	sp,sp,80
    800024c0:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024c2:	85e2                	mv	a1,s8
    800024c4:	854a                	mv	a0,s2
    800024c6:	00000097          	auipc	ra,0x0
    800024ca:	bf6080e7          	jalr	-1034(ra) # 800020bc <sleep>
    havekids = 0;
    800024ce:	bf39                	j	800023ec <wait+0x4a>

00000000800024d0 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024d0:	7179                	addi	sp,sp,-48
    800024d2:	f406                	sd	ra,40(sp)
    800024d4:	f022                	sd	s0,32(sp)
    800024d6:	ec26                	sd	s1,24(sp)
    800024d8:	e84a                	sd	s2,16(sp)
    800024da:	e44e                	sd	s3,8(sp)
    800024dc:	e052                	sd	s4,0(sp)
    800024de:	1800                	addi	s0,sp,48
    800024e0:	84aa                	mv	s1,a0
    800024e2:	892e                	mv	s2,a1
    800024e4:	89b2                	mv	s3,a2
    800024e6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	4c4080e7          	jalr	1220(ra) # 800019ac <myproc>
  if (user_dst)
    800024f0:	c08d                	beqz	s1,80002512 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024f2:	86d2                	mv	a3,s4
    800024f4:	864e                	mv	a2,s3
    800024f6:	85ca                	mv	a1,s2
    800024f8:	6928                	ld	a0,80(a0)
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	172080e7          	jalr	370(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002502:	70a2                	ld	ra,40(sp)
    80002504:	7402                	ld	s0,32(sp)
    80002506:	64e2                	ld	s1,24(sp)
    80002508:	6942                	ld	s2,16(sp)
    8000250a:	69a2                	ld	s3,8(sp)
    8000250c:	6a02                	ld	s4,0(sp)
    8000250e:	6145                	addi	sp,sp,48
    80002510:	8082                	ret
    memmove((char *)dst, src, len);
    80002512:	000a061b          	sext.w	a2,s4
    80002516:	85ce                	mv	a1,s3
    80002518:	854a                	mv	a0,s2
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	814080e7          	jalr	-2028(ra) # 80000d2e <memmove>
    return 0;
    80002522:	8526                	mv	a0,s1
    80002524:	bff9                	j	80002502 <either_copyout+0x32>

0000000080002526 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002526:	7179                	addi	sp,sp,-48
    80002528:	f406                	sd	ra,40(sp)
    8000252a:	f022                	sd	s0,32(sp)
    8000252c:	ec26                	sd	s1,24(sp)
    8000252e:	e84a                	sd	s2,16(sp)
    80002530:	e44e                	sd	s3,8(sp)
    80002532:	e052                	sd	s4,0(sp)
    80002534:	1800                	addi	s0,sp,48
    80002536:	892a                	mv	s2,a0
    80002538:	84ae                	mv	s1,a1
    8000253a:	89b2                	mv	s3,a2
    8000253c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	46e080e7          	jalr	1134(ra) # 800019ac <myproc>
  if (user_src)
    80002546:	c08d                	beqz	s1,80002568 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002548:	86d2                	mv	a3,s4
    8000254a:	864e                	mv	a2,s3
    8000254c:	85ca                	mv	a1,s2
    8000254e:	6928                	ld	a0,80(a0)
    80002550:	fffff097          	auipc	ra,0xfffff
    80002554:	1a8080e7          	jalr	424(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002558:	70a2                	ld	ra,40(sp)
    8000255a:	7402                	ld	s0,32(sp)
    8000255c:	64e2                	ld	s1,24(sp)
    8000255e:	6942                	ld	s2,16(sp)
    80002560:	69a2                	ld	s3,8(sp)
    80002562:	6a02                	ld	s4,0(sp)
    80002564:	6145                	addi	sp,sp,48
    80002566:	8082                	ret
    memmove(dst, (char *)src, len);
    80002568:	000a061b          	sext.w	a2,s4
    8000256c:	85ce                	mv	a1,s3
    8000256e:	854a                	mv	a0,s2
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	7be080e7          	jalr	1982(ra) # 80000d2e <memmove>
    return 0;
    80002578:	8526                	mv	a0,s1
    8000257a:	bff9                	j	80002558 <either_copyin+0x32>

000000008000257c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000257c:	715d                	addi	sp,sp,-80
    8000257e:	e486                	sd	ra,72(sp)
    80002580:	e0a2                	sd	s0,64(sp)
    80002582:	fc26                	sd	s1,56(sp)
    80002584:	f84a                	sd	s2,48(sp)
    80002586:	f44e                	sd	s3,40(sp)
    80002588:	f052                	sd	s4,32(sp)
    8000258a:	ec56                	sd	s5,24(sp)
    8000258c:	e85a                	sd	s6,16(sp)
    8000258e:	e45e                	sd	s7,8(sp)
    80002590:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002592:	00006517          	auipc	a0,0x6
    80002596:	b3650513          	addi	a0,a0,-1226 # 800080c8 <digits+0x88>
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	ff0080e7          	jalr	-16(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025a2:	0000f497          	auipc	s1,0xf
    800025a6:	b5648493          	addi	s1,s1,-1194 # 800110f8 <proc+0x158>
    800025aa:	00015917          	auipc	s2,0x15
    800025ae:	34e90913          	addi	s2,s2,846 # 800178f8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025b4:	00006997          	auipc	s3,0x6
    800025b8:	ccc98993          	addi	s3,s3,-820 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025bc:	00006a97          	auipc	s5,0x6
    800025c0:	ccca8a93          	addi	s5,s5,-820 # 80008288 <digits+0x248>
    printf("\n");
    800025c4:	00006a17          	auipc	s4,0x6
    800025c8:	b04a0a13          	addi	s4,s4,-1276 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025cc:	00006b97          	auipc	s7,0x6
    800025d0:	cfcb8b93          	addi	s7,s7,-772 # 800082c8 <states.0>
    800025d4:	a00d                	j	800025f6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025d6:	ed86a583          	lw	a1,-296(a3)
    800025da:	8556                	mv	a0,s5
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	fae080e7          	jalr	-82(ra) # 8000058a <printf>
    printf("\n");
    800025e4:	8552                	mv	a0,s4
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	fa4080e7          	jalr	-92(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025ee:	1a048493          	addi	s1,s1,416
    800025f2:	03248263          	beq	s1,s2,80002616 <procdump+0x9a>
    if (p->state == UNUSED)
    800025f6:	86a6                	mv	a3,s1
    800025f8:	ec04a783          	lw	a5,-320(s1)
    800025fc:	dbed                	beqz	a5,800025ee <procdump+0x72>
      state = "???";
    800025fe:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002600:	fcfb6be3          	bltu	s6,a5,800025d6 <procdump+0x5a>
    80002604:	02079713          	slli	a4,a5,0x20
    80002608:	01d75793          	srli	a5,a4,0x1d
    8000260c:	97de                	add	a5,a5,s7
    8000260e:	6390                	ld	a2,0(a5)
    80002610:	f279                	bnez	a2,800025d6 <procdump+0x5a>
      state = "???";
    80002612:	864e                	mv	a2,s3
    80002614:	b7c9                	j	800025d6 <procdump+0x5a>
  }
}
    80002616:	60a6                	ld	ra,72(sp)
    80002618:	6406                	ld	s0,64(sp)
    8000261a:	74e2                	ld	s1,56(sp)
    8000261c:	7942                	ld	s2,48(sp)
    8000261e:	79a2                	ld	s3,40(sp)
    80002620:	7a02                	ld	s4,32(sp)
    80002622:	6ae2                	ld	s5,24(sp)
    80002624:	6b42                	ld	s6,16(sp)
    80002626:	6ba2                	ld	s7,8(sp)
    80002628:	6161                	addi	sp,sp,80
    8000262a:	8082                	ret

000000008000262c <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000262c:	711d                	addi	sp,sp,-96
    8000262e:	ec86                	sd	ra,88(sp)
    80002630:	e8a2                	sd	s0,80(sp)
    80002632:	e4a6                	sd	s1,72(sp)
    80002634:	e0ca                	sd	s2,64(sp)
    80002636:	fc4e                	sd	s3,56(sp)
    80002638:	f852                	sd	s4,48(sp)
    8000263a:	f456                	sd	s5,40(sp)
    8000263c:	f05a                	sd	s6,32(sp)
    8000263e:	ec5e                	sd	s7,24(sp)
    80002640:	e862                	sd	s8,16(sp)
    80002642:	e466                	sd	s9,8(sp)
    80002644:	e06a                	sd	s10,0(sp)
    80002646:	1080                	addi	s0,sp,96
    80002648:	8b2a                	mv	s6,a0
    8000264a:	8bae                	mv	s7,a1
    8000264c:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    8000264e:	fffff097          	auipc	ra,0xfffff
    80002652:	35e080e7          	jalr	862(ra) # 800019ac <myproc>
    80002656:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002658:	0000e517          	auipc	a0,0xe
    8000265c:	53050513          	addi	a0,a0,1328 # 80010b88 <wait_lock>
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	576080e7          	jalr	1398(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002668:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000266a:	4a15                	li	s4,5
        havekids = 1;
    8000266c:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000266e:	00015997          	auipc	s3,0x15
    80002672:	13298993          	addi	s3,s3,306 # 800177a0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002676:	0000ed17          	auipc	s10,0xe
    8000267a:	512d0d13          	addi	s10,s10,1298 # 80010b88 <wait_lock>
    havekids = 0;
    8000267e:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002680:	0000f497          	auipc	s1,0xf
    80002684:	92048493          	addi	s1,s1,-1760 # 80010fa0 <proc>
    80002688:	a059                	j	8000270e <waitx+0xe2>
          pid = np->pid;
    8000268a:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000268e:	1684a783          	lw	a5,360(s1)
    80002692:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002696:	16c4a703          	lw	a4,364(s1)
    8000269a:	9f3d                	addw	a4,a4,a5
    8000269c:	1704a783          	lw	a5,368(s1)
    800026a0:	9f99                	subw	a5,a5,a4
    800026a2:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026a6:	000b0e63          	beqz	s6,800026c2 <waitx+0x96>
    800026aa:	4691                	li	a3,4
    800026ac:	02c48613          	addi	a2,s1,44
    800026b0:	85da                	mv	a1,s6
    800026b2:	05093503          	ld	a0,80(s2)
    800026b6:	fffff097          	auipc	ra,0xfffff
    800026ba:	fb6080e7          	jalr	-74(ra) # 8000166c <copyout>
    800026be:	02054563          	bltz	a0,800026e8 <waitx+0xbc>
          freeproc(np);
    800026c2:	8526                	mv	a0,s1
    800026c4:	fffff097          	auipc	ra,0xfffff
    800026c8:	49a080e7          	jalr	1178(ra) # 80001b5e <freeproc>
          release(&np->lock);
    800026cc:	8526                	mv	a0,s1
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	5bc080e7          	jalr	1468(ra) # 80000c8a <release>
          release(&wait_lock);
    800026d6:	0000e517          	auipc	a0,0xe
    800026da:	4b250513          	addi	a0,a0,1202 # 80010b88 <wait_lock>
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	5ac080e7          	jalr	1452(ra) # 80000c8a <release>
          return pid;
    800026e6:	a09d                	j	8000274c <waitx+0x120>
            release(&np->lock);
    800026e8:	8526                	mv	a0,s1
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	5a0080e7          	jalr	1440(ra) # 80000c8a <release>
            release(&wait_lock);
    800026f2:	0000e517          	auipc	a0,0xe
    800026f6:	49650513          	addi	a0,a0,1174 # 80010b88 <wait_lock>
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	590080e7          	jalr	1424(ra) # 80000c8a <release>
            return -1;
    80002702:	59fd                	li	s3,-1
    80002704:	a0a1                	j	8000274c <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002706:	1a048493          	addi	s1,s1,416
    8000270a:	03348463          	beq	s1,s3,80002732 <waitx+0x106>
      if (np->parent == p)
    8000270e:	7c9c                	ld	a5,56(s1)
    80002710:	ff279be3          	bne	a5,s2,80002706 <waitx+0xda>
        acquire(&np->lock);
    80002714:	8526                	mv	a0,s1
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	4c0080e7          	jalr	1216(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    8000271e:	4c9c                	lw	a5,24(s1)
    80002720:	f74785e3          	beq	a5,s4,8000268a <waitx+0x5e>
        release(&np->lock);
    80002724:	8526                	mv	a0,s1
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	564080e7          	jalr	1380(ra) # 80000c8a <release>
        havekids = 1;
    8000272e:	8756                	mv	a4,s5
    80002730:	bfd9                	j	80002706 <waitx+0xda>
    if (!havekids || p->killed)
    80002732:	c701                	beqz	a4,8000273a <waitx+0x10e>
    80002734:	02892783          	lw	a5,40(s2)
    80002738:	cb8d                	beqz	a5,8000276a <waitx+0x13e>
      release(&wait_lock);
    8000273a:	0000e517          	auipc	a0,0xe
    8000273e:	44e50513          	addi	a0,a0,1102 # 80010b88 <wait_lock>
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	548080e7          	jalr	1352(ra) # 80000c8a <release>
      return -1;
    8000274a:	59fd                	li	s3,-1
  }
}
    8000274c:	854e                	mv	a0,s3
    8000274e:	60e6                	ld	ra,88(sp)
    80002750:	6446                	ld	s0,80(sp)
    80002752:	64a6                	ld	s1,72(sp)
    80002754:	6906                	ld	s2,64(sp)
    80002756:	79e2                	ld	s3,56(sp)
    80002758:	7a42                	ld	s4,48(sp)
    8000275a:	7aa2                	ld	s5,40(sp)
    8000275c:	7b02                	ld	s6,32(sp)
    8000275e:	6be2                	ld	s7,24(sp)
    80002760:	6c42                	ld	s8,16(sp)
    80002762:	6ca2                	ld	s9,8(sp)
    80002764:	6d02                	ld	s10,0(sp)
    80002766:	6125                	addi	sp,sp,96
    80002768:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000276a:	85ea                	mv	a1,s10
    8000276c:	854a                	mv	a0,s2
    8000276e:	00000097          	auipc	ra,0x0
    80002772:	94e080e7          	jalr	-1714(ra) # 800020bc <sleep>
    havekids = 0;
    80002776:	b721                	j	8000267e <waitx+0x52>

0000000080002778 <update_time>:

void update_time()
{
    80002778:	7179                	addi	sp,sp,-48
    8000277a:	f406                	sd	ra,40(sp)
    8000277c:	f022                	sd	s0,32(sp)
    8000277e:	ec26                	sd	s1,24(sp)
    80002780:	e84a                	sd	s2,16(sp)
    80002782:	e44e                	sd	s3,8(sp)
    80002784:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002786:	0000f497          	auipc	s1,0xf
    8000278a:	81a48493          	addi	s1,s1,-2022 # 80010fa0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    8000278e:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002790:	00015917          	auipc	s2,0x15
    80002794:	01090913          	addi	s2,s2,16 # 800177a0 <tickslock>
    80002798:	a811                	j	800027ac <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    8000279a:	8526                	mv	a0,s1
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	4ee080e7          	jalr	1262(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027a4:	1a048493          	addi	s1,s1,416
    800027a8:	03248063          	beq	s1,s2,800027c8 <update_time+0x50>
    acquire(&p->lock);
    800027ac:	8526                	mv	a0,s1
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	428080e7          	jalr	1064(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    800027b6:	4c9c                	lw	a5,24(s1)
    800027b8:	ff3791e3          	bne	a5,s3,8000279a <update_time+0x22>
      p->rtime++;
    800027bc:	1684a783          	lw	a5,360(s1)
    800027c0:	2785                	addiw	a5,a5,1
    800027c2:	16f4a423          	sw	a5,360(s1)
    800027c6:	bfd1                	j	8000279a <update_time+0x22>
  }
    800027c8:	70a2                	ld	ra,40(sp)
    800027ca:	7402                	ld	s0,32(sp)
    800027cc:	64e2                	ld	s1,24(sp)
    800027ce:	6942                	ld	s2,16(sp)
    800027d0:	69a2                	ld	s3,8(sp)
    800027d2:	6145                	addi	sp,sp,48
    800027d4:	8082                	ret

00000000800027d6 <swtch>:
    800027d6:	00153023          	sd	ra,0(a0)
    800027da:	00253423          	sd	sp,8(a0)
    800027de:	e900                	sd	s0,16(a0)
    800027e0:	ed04                	sd	s1,24(a0)
    800027e2:	03253023          	sd	s2,32(a0)
    800027e6:	03353423          	sd	s3,40(a0)
    800027ea:	03453823          	sd	s4,48(a0)
    800027ee:	03553c23          	sd	s5,56(a0)
    800027f2:	05653023          	sd	s6,64(a0)
    800027f6:	05753423          	sd	s7,72(a0)
    800027fa:	05853823          	sd	s8,80(a0)
    800027fe:	05953c23          	sd	s9,88(a0)
    80002802:	07a53023          	sd	s10,96(a0)
    80002806:	07b53423          	sd	s11,104(a0)
    8000280a:	0005b083          	ld	ra,0(a1)
    8000280e:	0085b103          	ld	sp,8(a1)
    80002812:	6980                	ld	s0,16(a1)
    80002814:	6d84                	ld	s1,24(a1)
    80002816:	0205b903          	ld	s2,32(a1)
    8000281a:	0285b983          	ld	s3,40(a1)
    8000281e:	0305ba03          	ld	s4,48(a1)
    80002822:	0385ba83          	ld	s5,56(a1)
    80002826:	0405bb03          	ld	s6,64(a1)
    8000282a:	0485bb83          	ld	s7,72(a1)
    8000282e:	0505bc03          	ld	s8,80(a1)
    80002832:	0585bc83          	ld	s9,88(a1)
    80002836:	0605bd03          	ld	s10,96(a1)
    8000283a:	0685bd83          	ld	s11,104(a1)
    8000283e:	8082                	ret

0000000080002840 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002840:	1141                	addi	sp,sp,-16
    80002842:	e406                	sd	ra,8(sp)
    80002844:	e022                	sd	s0,0(sp)
    80002846:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002848:	00006597          	auipc	a1,0x6
    8000284c:	ab058593          	addi	a1,a1,-1360 # 800082f8 <states.0+0x30>
    80002850:	00015517          	auipc	a0,0x15
    80002854:	f5050513          	addi	a0,a0,-176 # 800177a0 <tickslock>
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	2ee080e7          	jalr	750(ra) # 80000b46 <initlock>
}
    80002860:	60a2                	ld	ra,8(sp)
    80002862:	6402                	ld	s0,0(sp)
    80002864:	0141                	addi	sp,sp,16
    80002866:	8082                	ret

0000000080002868 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002868:	1141                	addi	sp,sp,-16
    8000286a:	e422                	sd	s0,8(sp)
    8000286c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000286e:	00003797          	auipc	a5,0x3
    80002872:	6a278793          	addi	a5,a5,1698 # 80005f10 <kernelvec>
    80002876:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000287a:	6422                	ld	s0,8(sp)
    8000287c:	0141                	addi	sp,sp,16
    8000287e:	8082                	ret

0000000080002880 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002880:	1141                	addi	sp,sp,-16
    80002882:	e406                	sd	ra,8(sp)
    80002884:	e022                	sd	s0,0(sp)
    80002886:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002888:	fffff097          	auipc	ra,0xfffff
    8000288c:	124080e7          	jalr	292(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002890:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002894:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002896:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000289a:	00004697          	auipc	a3,0x4
    8000289e:	76668693          	addi	a3,a3,1894 # 80007000 <_trampoline>
    800028a2:	00004717          	auipc	a4,0x4
    800028a6:	75e70713          	addi	a4,a4,1886 # 80007000 <_trampoline>
    800028aa:	8f15                	sub	a4,a4,a3
    800028ac:	040007b7          	lui	a5,0x4000
    800028b0:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800028b2:	07b2                	slli	a5,a5,0xc
    800028b4:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028b6:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028ba:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028bc:	18002673          	csrr	a2,satp
    800028c0:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028c2:	6d30                	ld	a2,88(a0)
    800028c4:	6138                	ld	a4,64(a0)
    800028c6:	6585                	lui	a1,0x1
    800028c8:	972e                	add	a4,a4,a1
    800028ca:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028cc:	6d38                	ld	a4,88(a0)
    800028ce:	00000617          	auipc	a2,0x0
    800028d2:	13e60613          	addi	a2,a2,318 # 80002a0c <usertrap>
    800028d6:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800028d8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028da:	8612                	mv	a2,tp
    800028dc:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028de:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028e2:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028e6:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ea:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028ee:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028f0:	6f18                	ld	a4,24(a4)
    800028f2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028f6:	6928                	ld	a0,80(a0)
    800028f8:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028fa:	00004717          	auipc	a4,0x4
    800028fe:	7a270713          	addi	a4,a4,1954 # 8000709c <userret>
    80002902:	8f15                	sub	a4,a4,a3
    80002904:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002906:	577d                	li	a4,-1
    80002908:	177e                	slli	a4,a4,0x3f
    8000290a:	8d59                	or	a0,a0,a4
    8000290c:	9782                	jalr	a5
}
    8000290e:	60a2                	ld	ra,8(sp)
    80002910:	6402                	ld	s0,0(sp)
    80002912:	0141                	addi	sp,sp,16
    80002914:	8082                	ret

0000000080002916 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002916:	1101                	addi	sp,sp,-32
    80002918:	ec06                	sd	ra,24(sp)
    8000291a:	e822                	sd	s0,16(sp)
    8000291c:	e426                	sd	s1,8(sp)
    8000291e:	e04a                	sd	s2,0(sp)
    80002920:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002922:	00015917          	auipc	s2,0x15
    80002926:	e7e90913          	addi	s2,s2,-386 # 800177a0 <tickslock>
    8000292a:	854a                	mv	a0,s2
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	2aa080e7          	jalr	682(ra) # 80000bd6 <acquire>
  ticks++;
    80002934:	00006497          	auipc	s1,0x6
    80002938:	fcc48493          	addi	s1,s1,-52 # 80008900 <ticks>
    8000293c:	409c                	lw	a5,0(s1)
    8000293e:	2785                	addiw	a5,a5,1
    80002940:	c09c                	sw	a5,0(s1)
  update_time();
    80002942:	00000097          	auipc	ra,0x0
    80002946:	e36080e7          	jalr	-458(ra) # 80002778 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    8000294a:	8526                	mv	a0,s1
    8000294c:	fffff097          	auipc	ra,0xfffff
    80002950:	7d4080e7          	jalr	2004(ra) # 80002120 <wakeup>
  release(&tickslock);
    80002954:	854a                	mv	a0,s2
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	334080e7          	jalr	820(ra) # 80000c8a <release>
}
    8000295e:	60e2                	ld	ra,24(sp)
    80002960:	6442                	ld	s0,16(sp)
    80002962:	64a2                	ld	s1,8(sp)
    80002964:	6902                	ld	s2,0(sp)
    80002966:	6105                	addi	sp,sp,32
    80002968:	8082                	ret

000000008000296a <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    8000296a:	1101                	addi	sp,sp,-32
    8000296c:	ec06                	sd	ra,24(sp)
    8000296e:	e822                	sd	s0,16(sp)
    80002970:	e426                	sd	s1,8(sp)
    80002972:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002974:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002978:	00074d63          	bltz	a4,80002992 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    8000297c:	57fd                	li	a5,-1
    8000297e:	17fe                	slli	a5,a5,0x3f
    80002980:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002982:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002984:	06f70363          	beq	a4,a5,800029ea <devintr+0x80>
  }
    80002988:	60e2                	ld	ra,24(sp)
    8000298a:	6442                	ld	s0,16(sp)
    8000298c:	64a2                	ld	s1,8(sp)
    8000298e:	6105                	addi	sp,sp,32
    80002990:	8082                	ret
      (scause & 0xff) == 9)
    80002992:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002996:	46a5                	li	a3,9
    80002998:	fed792e3          	bne	a5,a3,8000297c <devintr+0x12>
    int irq = plic_claim();
    8000299c:	00003097          	auipc	ra,0x3
    800029a0:	67c080e7          	jalr	1660(ra) # 80006018 <plic_claim>
    800029a4:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    800029a6:	47a9                	li	a5,10
    800029a8:	02f50763          	beq	a0,a5,800029d6 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    800029ac:	4785                	li	a5,1
    800029ae:	02f50963          	beq	a0,a5,800029e0 <devintr+0x76>
    return 1;
    800029b2:	4505                	li	a0,1
    else if (irq)
    800029b4:	d8f1                	beqz	s1,80002988 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029b6:	85a6                	mv	a1,s1
    800029b8:	00006517          	auipc	a0,0x6
    800029bc:	94850513          	addi	a0,a0,-1720 # 80008300 <states.0+0x38>
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	bca080e7          	jalr	-1078(ra) # 8000058a <printf>
      plic_complete(irq);
    800029c8:	8526                	mv	a0,s1
    800029ca:	00003097          	auipc	ra,0x3
    800029ce:	672080e7          	jalr	1650(ra) # 8000603c <plic_complete>
    return 1;
    800029d2:	4505                	li	a0,1
    800029d4:	bf55                	j	80002988 <devintr+0x1e>
      uartintr();
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	fc2080e7          	jalr	-62(ra) # 80000998 <uartintr>
    800029de:	b7ed                	j	800029c8 <devintr+0x5e>
      virtio_disk_intr();
    800029e0:	00004097          	auipc	ra,0x4
    800029e4:	b24080e7          	jalr	-1244(ra) # 80006504 <virtio_disk_intr>
    800029e8:	b7c5                	j	800029c8 <devintr+0x5e>
    if (cpuid() == 0)
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	f96080e7          	jalr	-106(ra) # 80001980 <cpuid>
    800029f2:	c901                	beqz	a0,80002a02 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029f4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029f8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029fa:	14479073          	csrw	sip,a5
    return 2;
    800029fe:	4509                	li	a0,2
    80002a00:	b761                	j	80002988 <devintr+0x1e>
      clockintr();
    80002a02:	00000097          	auipc	ra,0x0
    80002a06:	f14080e7          	jalr	-236(ra) # 80002916 <clockintr>
    80002a0a:	b7ed                	j	800029f4 <devintr+0x8a>

0000000080002a0c <usertrap>:
{
    80002a0c:	1101                	addi	sp,sp,-32
    80002a0e:	ec06                	sd	ra,24(sp)
    80002a10:	e822                	sd	s0,16(sp)
    80002a12:	e426                	sd	s1,8(sp)
    80002a14:	e04a                	sd	s2,0(sp)
    80002a16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a18:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002a1c:	1007f793          	andi	a5,a5,256
    80002a20:	e7bd                	bnez	a5,80002a8e <usertrap+0x82>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a22:	00003797          	auipc	a5,0x3
    80002a26:	4ee78793          	addi	a5,a5,1262 # 80005f10 <kernelvec>
    80002a2a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	f7e080e7          	jalr	-130(ra) # 800019ac <myproc>
    80002a36:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a38:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a3a:	14102773          	csrr	a4,sepc
    80002a3e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a40:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a44:	47a1                	li	a5,8
    80002a46:	04f70c63          	beq	a4,a5,80002a9e <usertrap+0x92>
  else if ((which_dev = devintr()) != 0)
    80002a4a:	00000097          	auipc	ra,0x0
    80002a4e:	f20080e7          	jalr	-224(ra) # 8000296a <devintr>
    80002a52:	892a                	mv	s2,a0
    80002a54:	c561                	beqz	a0,80002b1c <usertrap+0x110>
    if (which_dev == 2 && p->alarm_on == 0)
    80002a56:	4789                	li	a5,2
    80002a58:	06f51763          	bne	a0,a5,80002ac6 <usertrap+0xba>
    80002a5c:	1984a783          	lw	a5,408(s1)
    80002a60:	ef81                	bnez	a5,80002a78 <usertrap+0x6c>
      p->cur_ticks++;
    80002a62:	18c4a783          	lw	a5,396(s1)
    80002a66:	2785                	addiw	a5,a5,1
    80002a68:	0007871b          	sext.w	a4,a5
    80002a6c:	18f4a623          	sw	a5,396(s1)
      if (p->cur_ticks == p->ticks){
    80002a70:	1884a783          	lw	a5,392(s1)
    80002a74:	06e78f63          	beq	a5,a4,80002af2 <usertrap+0xe6>
  if (killed(p))
    80002a78:	8526                	mv	a0,s1
    80002a7a:	00000097          	auipc	ra,0x0
    80002a7e:	8f6080e7          	jalr	-1802(ra) # 80002370 <killed>
    80002a82:	e17d                	bnez	a0,80002b68 <usertrap+0x15c>
    yield();
    80002a84:	fffff097          	auipc	ra,0xfffff
    80002a88:	5fc080e7          	jalr	1532(ra) # 80002080 <yield>
    80002a8c:	a099                	j	80002ad2 <usertrap+0xc6>
    panic("usertrap: not from user mode");
    80002a8e:	00006517          	auipc	a0,0x6
    80002a92:	89250513          	addi	a0,a0,-1902 # 80008320 <states.0+0x58>
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	aaa080e7          	jalr	-1366(ra) # 80000540 <panic>
    if (killed(p))
    80002a9e:	00000097          	auipc	ra,0x0
    80002aa2:	8d2080e7          	jalr	-1838(ra) # 80002370 <killed>
    80002aa6:	e121                	bnez	a0,80002ae6 <usertrap+0xda>
    p->trapframe->epc += 4;
    80002aa8:	6cb8                	ld	a4,88(s1)
    80002aaa:	6f1c                	ld	a5,24(a4)
    80002aac:	0791                	addi	a5,a5,4
    80002aae:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ab4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ab8:	10079073          	csrw	sstatus,a5
    syscall();
    80002abc:	00000097          	auipc	ra,0x0
    80002ac0:	302080e7          	jalr	770(ra) # 80002dbe <syscall>
  int which_dev = 0;
    80002ac4:	4901                	li	s2,0
  if (killed(p))
    80002ac6:	8526                	mv	a0,s1
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	8a8080e7          	jalr	-1880(ra) # 80002370 <killed>
    80002ad0:	e159                	bnez	a0,80002b56 <usertrap+0x14a>
  usertrapret();
    80002ad2:	00000097          	auipc	ra,0x0
    80002ad6:	dae080e7          	jalr	-594(ra) # 80002880 <usertrapret>
}
    80002ada:	60e2                	ld	ra,24(sp)
    80002adc:	6442                	ld	s0,16(sp)
    80002ade:	64a2                	ld	s1,8(sp)
    80002ae0:	6902                	ld	s2,0(sp)
    80002ae2:	6105                	addi	sp,sp,32
    80002ae4:	8082                	ret
      exit(-1);
    80002ae6:	557d                	li	a0,-1
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	708080e7          	jalr	1800(ra) # 800021f0 <exit>
    80002af0:	bf65                	j	80002aa8 <usertrap+0x9c>
        struct trapframe *tf = kalloc();
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	ff4080e7          	jalr	-12(ra) # 80000ae6 <kalloc>
    80002afa:	892a                	mv	s2,a0
      memmove(tf, p->trapframe, PGSIZE);
    80002afc:	6605                	lui	a2,0x1
    80002afe:	6cac                	ld	a1,88(s1)
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	22e080e7          	jalr	558(ra) # 80000d2e <memmove>
      p->alarm_tf = tf;
    80002b08:	1924b823          	sd	s2,400(s1)
        p->trapframe->epc = p->handler;
    80002b0c:	6cbc                	ld	a5,88(s1)
    80002b0e:	1804b703          	ld	a4,384(s1)
    80002b12:	ef98                	sd	a4,24(a5)
        p->alarm_on = 1;
    80002b14:	4785                	li	a5,1
    80002b16:	18f4ac23          	sw	a5,408(s1)
    80002b1a:	bfb9                	j	80002a78 <usertrap+0x6c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b1c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b20:	5890                	lw	a2,48(s1)
    80002b22:	00006517          	auipc	a0,0x6
    80002b26:	81e50513          	addi	a0,a0,-2018 # 80008340 <states.0+0x78>
    80002b2a:	ffffe097          	auipc	ra,0xffffe
    80002b2e:	a60080e7          	jalr	-1440(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b32:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b36:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b3a:	00006517          	auipc	a0,0x6
    80002b3e:	83650513          	addi	a0,a0,-1994 # 80008370 <states.0+0xa8>
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	a48080e7          	jalr	-1464(ra) # 8000058a <printf>
    setkilled(p);
    80002b4a:	8526                	mv	a0,s1
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	7f8080e7          	jalr	2040(ra) # 80002344 <setkilled>
    80002b54:	bf8d                	j	80002ac6 <usertrap+0xba>
    exit(-1);
    80002b56:	557d                	li	a0,-1
    80002b58:	fffff097          	auipc	ra,0xfffff
    80002b5c:	698080e7          	jalr	1688(ra) # 800021f0 <exit>
  if (which_dev == 2)
    80002b60:	4789                	li	a5,2
    80002b62:	f6f918e3          	bne	s2,a5,80002ad2 <usertrap+0xc6>
    80002b66:	bf39                	j	80002a84 <usertrap+0x78>
    exit(-1);
    80002b68:	557d                	li	a0,-1
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	686080e7          	jalr	1670(ra) # 800021f0 <exit>
  if (which_dev == 2)
    80002b72:	bf09                	j	80002a84 <usertrap+0x78>

0000000080002b74 <kerneltrap>:
{
    80002b74:	7179                	addi	sp,sp,-48
    80002b76:	f406                	sd	ra,40(sp)
    80002b78:	f022                	sd	s0,32(sp)
    80002b7a:	ec26                	sd	s1,24(sp)
    80002b7c:	e84a                	sd	s2,16(sp)
    80002b7e:	e44e                	sd	s3,8(sp)
    80002b80:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b82:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b86:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b8a:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002b8e:	1004f793          	andi	a5,s1,256
    80002b92:	cb85                	beqz	a5,80002bc2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b94:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b98:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002b9a:	ef85                	bnez	a5,80002bd2 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002b9c:	00000097          	auipc	ra,0x0
    80002ba0:	dce080e7          	jalr	-562(ra) # 8000296a <devintr>
    80002ba4:	cd1d                	beqz	a0,80002be2 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ba6:	4789                	li	a5,2
    80002ba8:	06f50a63          	beq	a0,a5,80002c1c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bac:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bb0:	10049073          	csrw	sstatus,s1
}
    80002bb4:	70a2                	ld	ra,40(sp)
    80002bb6:	7402                	ld	s0,32(sp)
    80002bb8:	64e2                	ld	s1,24(sp)
    80002bba:	6942                	ld	s2,16(sp)
    80002bbc:	69a2                	ld	s3,8(sp)
    80002bbe:	6145                	addi	sp,sp,48
    80002bc0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bc2:	00005517          	auipc	a0,0x5
    80002bc6:	7ce50513          	addi	a0,a0,1998 # 80008390 <states.0+0xc8>
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	976080e7          	jalr	-1674(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002bd2:	00005517          	auipc	a0,0x5
    80002bd6:	7e650513          	addi	a0,a0,2022 # 800083b8 <states.0+0xf0>
    80002bda:	ffffe097          	auipc	ra,0xffffe
    80002bde:	966080e7          	jalr	-1690(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002be2:	85ce                	mv	a1,s3
    80002be4:	00005517          	auipc	a0,0x5
    80002be8:	7f450513          	addi	a0,a0,2036 # 800083d8 <states.0+0x110>
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	99e080e7          	jalr	-1634(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bfc:	00005517          	auipc	a0,0x5
    80002c00:	7ec50513          	addi	a0,a0,2028 # 800083e8 <states.0+0x120>
    80002c04:	ffffe097          	auipc	ra,0xffffe
    80002c08:	986080e7          	jalr	-1658(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002c0c:	00005517          	auipc	a0,0x5
    80002c10:	7f450513          	addi	a0,a0,2036 # 80008400 <states.0+0x138>
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	92c080e7          	jalr	-1748(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c1c:	fffff097          	auipc	ra,0xfffff
    80002c20:	d90080e7          	jalr	-624(ra) # 800019ac <myproc>
    80002c24:	d541                	beqz	a0,80002bac <kerneltrap+0x38>
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	d86080e7          	jalr	-634(ra) # 800019ac <myproc>
    80002c2e:	4d18                	lw	a4,24(a0)
    80002c30:	4791                	li	a5,4
    80002c32:	f6f71de3          	bne	a4,a5,80002bac <kerneltrap+0x38>
    yield();
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	44a080e7          	jalr	1098(ra) # 80002080 <yield>
    80002c3e:	b7bd                	j	80002bac <kerneltrap+0x38>

0000000080002c40 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c40:	1101                	addi	sp,sp,-32
    80002c42:	ec06                	sd	ra,24(sp)
    80002c44:	e822                	sd	s0,16(sp)
    80002c46:	e426                	sd	s1,8(sp)
    80002c48:	1000                	addi	s0,sp,32
    80002c4a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	d60080e7          	jalr	-672(ra) # 800019ac <myproc>
  switch (n) {
    80002c54:	4795                	li	a5,5
    80002c56:	0497e163          	bltu	a5,s1,80002c98 <argraw+0x58>
    80002c5a:	048a                	slli	s1,s1,0x2
    80002c5c:	00005717          	auipc	a4,0x5
    80002c60:	7dc70713          	addi	a4,a4,2012 # 80008438 <states.0+0x170>
    80002c64:	94ba                	add	s1,s1,a4
    80002c66:	409c                	lw	a5,0(s1)
    80002c68:	97ba                	add	a5,a5,a4
    80002c6a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c6c:	6d3c                	ld	a5,88(a0)
    80002c6e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c70:	60e2                	ld	ra,24(sp)
    80002c72:	6442                	ld	s0,16(sp)
    80002c74:	64a2                	ld	s1,8(sp)
    80002c76:	6105                	addi	sp,sp,32
    80002c78:	8082                	ret
    return p->trapframe->a1;
    80002c7a:	6d3c                	ld	a5,88(a0)
    80002c7c:	7fa8                	ld	a0,120(a5)
    80002c7e:	bfcd                	j	80002c70 <argraw+0x30>
    return p->trapframe->a2;
    80002c80:	6d3c                	ld	a5,88(a0)
    80002c82:	63c8                	ld	a0,128(a5)
    80002c84:	b7f5                	j	80002c70 <argraw+0x30>
    return p->trapframe->a3;
    80002c86:	6d3c                	ld	a5,88(a0)
    80002c88:	67c8                	ld	a0,136(a5)
    80002c8a:	b7dd                	j	80002c70 <argraw+0x30>
    return p->trapframe->a4;
    80002c8c:	6d3c                	ld	a5,88(a0)
    80002c8e:	6bc8                	ld	a0,144(a5)
    80002c90:	b7c5                	j	80002c70 <argraw+0x30>
    return p->trapframe->a5;
    80002c92:	6d3c                	ld	a5,88(a0)
    80002c94:	6fc8                	ld	a0,152(a5)
    80002c96:	bfe9                	j	80002c70 <argraw+0x30>
  panic("argraw");
    80002c98:	00005517          	auipc	a0,0x5
    80002c9c:	77850513          	addi	a0,a0,1912 # 80008410 <states.0+0x148>
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	8a0080e7          	jalr	-1888(ra) # 80000540 <panic>

0000000080002ca8 <fetchaddr>:
{
    80002ca8:	1101                	addi	sp,sp,-32
    80002caa:	ec06                	sd	ra,24(sp)
    80002cac:	e822                	sd	s0,16(sp)
    80002cae:	e426                	sd	s1,8(sp)
    80002cb0:	e04a                	sd	s2,0(sp)
    80002cb2:	1000                	addi	s0,sp,32
    80002cb4:	84aa                	mv	s1,a0
    80002cb6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	cf4080e7          	jalr	-780(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002cc0:	653c                	ld	a5,72(a0)
    80002cc2:	02f4f863          	bgeu	s1,a5,80002cf2 <fetchaddr+0x4a>
    80002cc6:	00848713          	addi	a4,s1,8
    80002cca:	02e7e663          	bltu	a5,a4,80002cf6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cce:	46a1                	li	a3,8
    80002cd0:	8626                	mv	a2,s1
    80002cd2:	85ca                	mv	a1,s2
    80002cd4:	6928                	ld	a0,80(a0)
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	a22080e7          	jalr	-1502(ra) # 800016f8 <copyin>
    80002cde:	00a03533          	snez	a0,a0
    80002ce2:	40a00533          	neg	a0,a0
}
    80002ce6:	60e2                	ld	ra,24(sp)
    80002ce8:	6442                	ld	s0,16(sp)
    80002cea:	64a2                	ld	s1,8(sp)
    80002cec:	6902                	ld	s2,0(sp)
    80002cee:	6105                	addi	sp,sp,32
    80002cf0:	8082                	ret
    return -1;
    80002cf2:	557d                	li	a0,-1
    80002cf4:	bfcd                	j	80002ce6 <fetchaddr+0x3e>
    80002cf6:	557d                	li	a0,-1
    80002cf8:	b7fd                	j	80002ce6 <fetchaddr+0x3e>

0000000080002cfa <fetchstr>:
{
    80002cfa:	7179                	addi	sp,sp,-48
    80002cfc:	f406                	sd	ra,40(sp)
    80002cfe:	f022                	sd	s0,32(sp)
    80002d00:	ec26                	sd	s1,24(sp)
    80002d02:	e84a                	sd	s2,16(sp)
    80002d04:	e44e                	sd	s3,8(sp)
    80002d06:	1800                	addi	s0,sp,48
    80002d08:	892a                	mv	s2,a0
    80002d0a:	84ae                	mv	s1,a1
    80002d0c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	c9e080e7          	jalr	-866(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d16:	86ce                	mv	a3,s3
    80002d18:	864a                	mv	a2,s2
    80002d1a:	85a6                	mv	a1,s1
    80002d1c:	6928                	ld	a0,80(a0)
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	a68080e7          	jalr	-1432(ra) # 80001786 <copyinstr>
    80002d26:	00054e63          	bltz	a0,80002d42 <fetchstr+0x48>
  return strlen(buf);
    80002d2a:	8526                	mv	a0,s1
    80002d2c:	ffffe097          	auipc	ra,0xffffe
    80002d30:	122080e7          	jalr	290(ra) # 80000e4e <strlen>
}
    80002d34:	70a2                	ld	ra,40(sp)
    80002d36:	7402                	ld	s0,32(sp)
    80002d38:	64e2                	ld	s1,24(sp)
    80002d3a:	6942                	ld	s2,16(sp)
    80002d3c:	69a2                	ld	s3,8(sp)
    80002d3e:	6145                	addi	sp,sp,48
    80002d40:	8082                	ret
    return -1;
    80002d42:	557d                	li	a0,-1
    80002d44:	bfc5                	j	80002d34 <fetchstr+0x3a>

0000000080002d46 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002d46:	1101                	addi	sp,sp,-32
    80002d48:	ec06                	sd	ra,24(sp)
    80002d4a:	e822                	sd	s0,16(sp)
    80002d4c:	e426                	sd	s1,8(sp)
    80002d4e:	1000                	addi	s0,sp,32
    80002d50:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d52:	00000097          	auipc	ra,0x0
    80002d56:	eee080e7          	jalr	-274(ra) # 80002c40 <argraw>
    80002d5a:	c088                	sw	a0,0(s1)
}
    80002d5c:	60e2                	ld	ra,24(sp)
    80002d5e:	6442                	ld	s0,16(sp)
    80002d60:	64a2                	ld	s1,8(sp)
    80002d62:	6105                	addi	sp,sp,32
    80002d64:	8082                	ret

0000000080002d66 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002d66:	1101                	addi	sp,sp,-32
    80002d68:	ec06                	sd	ra,24(sp)
    80002d6a:	e822                	sd	s0,16(sp)
    80002d6c:	e426                	sd	s1,8(sp)
    80002d6e:	1000                	addi	s0,sp,32
    80002d70:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d72:	00000097          	auipc	ra,0x0
    80002d76:	ece080e7          	jalr	-306(ra) # 80002c40 <argraw>
    80002d7a:	e088                	sd	a0,0(s1)
}
    80002d7c:	60e2                	ld	ra,24(sp)
    80002d7e:	6442                	ld	s0,16(sp)
    80002d80:	64a2                	ld	s1,8(sp)
    80002d82:	6105                	addi	sp,sp,32
    80002d84:	8082                	ret

0000000080002d86 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d86:	7179                	addi	sp,sp,-48
    80002d88:	f406                	sd	ra,40(sp)
    80002d8a:	f022                	sd	s0,32(sp)
    80002d8c:	ec26                	sd	s1,24(sp)
    80002d8e:	e84a                	sd	s2,16(sp)
    80002d90:	1800                	addi	s0,sp,48
    80002d92:	84ae                	mv	s1,a1
    80002d94:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d96:	fd840593          	addi	a1,s0,-40
    80002d9a:	00000097          	auipc	ra,0x0
    80002d9e:	fcc080e7          	jalr	-52(ra) # 80002d66 <argaddr>
  return fetchstr(addr, buf, max);
    80002da2:	864a                	mv	a2,s2
    80002da4:	85a6                	mv	a1,s1
    80002da6:	fd843503          	ld	a0,-40(s0)
    80002daa:	00000097          	auipc	ra,0x0
    80002dae:	f50080e7          	jalr	-176(ra) # 80002cfa <fetchstr>
}
    80002db2:	70a2                	ld	ra,40(sp)
    80002db4:	7402                	ld	s0,32(sp)
    80002db6:	64e2                	ld	s1,24(sp)
    80002db8:	6942                	ld	s2,16(sp)
    80002dba:	6145                	addi	sp,sp,48
    80002dbc:	8082                	ret

0000000080002dbe <syscall>:
[SYS_sigalarm]  sys_sigalarm,
};

void
syscall(void)
{
    80002dbe:	1101                	addi	sp,sp,-32
    80002dc0:	ec06                	sd	ra,24(sp)
    80002dc2:	e822                	sd	s0,16(sp)
    80002dc4:	e426                	sd	s1,8(sp)
    80002dc6:	e04a                	sd	s2,0(sp)
    80002dc8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	be2080e7          	jalr	-1054(ra) # 800019ac <myproc>
    80002dd2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002dd4:	05853903          	ld	s2,88(a0)
    80002dd8:	0a893783          	ld	a5,168(s2)
    80002ddc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002de0:	37fd                	addiw	a5,a5,-1
    80002de2:	4761                	li	a4,24
    80002de4:	00f76f63          	bltu	a4,a5,80002e02 <syscall+0x44>
    80002de8:	00369713          	slli	a4,a3,0x3
    80002dec:	00005797          	auipc	a5,0x5
    80002df0:	66478793          	addi	a5,a5,1636 # 80008450 <syscalls>
    80002df4:	97ba                	add	a5,a5,a4
    80002df6:	639c                	ld	a5,0(a5)
    80002df8:	c789                	beqz	a5,80002e02 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002dfa:	9782                	jalr	a5
    80002dfc:	06a93823          	sd	a0,112(s2)
    80002e00:	a839                	j	80002e1e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e02:	15848613          	addi	a2,s1,344
    80002e06:	588c                	lw	a1,48(s1)
    80002e08:	00005517          	auipc	a0,0x5
    80002e0c:	61050513          	addi	a0,a0,1552 # 80008418 <states.0+0x150>
    80002e10:	ffffd097          	auipc	ra,0xffffd
    80002e14:	77a080e7          	jalr	1914(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e18:	6cbc                	ld	a5,88(s1)
    80002e1a:	577d                	li	a4,-1
    80002e1c:	fbb8                	sd	a4,112(a5)
  }
}
    80002e1e:	60e2                	ld	ra,24(sp)
    80002e20:	6442                	ld	s0,16(sp)
    80002e22:	64a2                	ld	s1,8(sp)
    80002e24:	6902                	ld	s2,0(sp)
    80002e26:	6105                	addi	sp,sp,32
    80002e28:	8082                	ret

0000000080002e2a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e2a:	1101                	addi	sp,sp,-32
    80002e2c:	ec06                	sd	ra,24(sp)
    80002e2e:	e822                	sd	s0,16(sp)
    80002e30:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e32:	fec40593          	addi	a1,s0,-20
    80002e36:	4501                	li	a0,0
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	f0e080e7          	jalr	-242(ra) # 80002d46 <argint>
  exit(n);
    80002e40:	fec42503          	lw	a0,-20(s0)
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	3ac080e7          	jalr	940(ra) # 800021f0 <exit>
  return 0; // not reached
}
    80002e4c:	4501                	li	a0,0
    80002e4e:	60e2                	ld	ra,24(sp)
    80002e50:	6442                	ld	s0,16(sp)
    80002e52:	6105                	addi	sp,sp,32
    80002e54:	8082                	ret

0000000080002e56 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e56:	1141                	addi	sp,sp,-16
    80002e58:	e406                	sd	ra,8(sp)
    80002e5a:	e022                	sd	s0,0(sp)
    80002e5c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	b4e080e7          	jalr	-1202(ra) # 800019ac <myproc>
}
    80002e66:	5908                	lw	a0,48(a0)
    80002e68:	60a2                	ld	ra,8(sp)
    80002e6a:	6402                	ld	s0,0(sp)
    80002e6c:	0141                	addi	sp,sp,16
    80002e6e:	8082                	ret

0000000080002e70 <sys_fork>:

uint64
sys_fork(void)
{
    80002e70:	1141                	addi	sp,sp,-16
    80002e72:	e406                	sd	ra,8(sp)
    80002e74:	e022                	sd	s0,0(sp)
    80002e76:	0800                	addi	s0,sp,16
  return fork();
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	efe080e7          	jalr	-258(ra) # 80001d76 <fork>
}
    80002e80:	60a2                	ld	ra,8(sp)
    80002e82:	6402                	ld	s0,0(sp)
    80002e84:	0141                	addi	sp,sp,16
    80002e86:	8082                	ret

0000000080002e88 <sys_wait>:

uint64
sys_wait(void)
{
    80002e88:	1101                	addi	sp,sp,-32
    80002e8a:	ec06                	sd	ra,24(sp)
    80002e8c:	e822                	sd	s0,16(sp)
    80002e8e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e90:	fe840593          	addi	a1,s0,-24
    80002e94:	4501                	li	a0,0
    80002e96:	00000097          	auipc	ra,0x0
    80002e9a:	ed0080e7          	jalr	-304(ra) # 80002d66 <argaddr>
  return wait(p);
    80002e9e:	fe843503          	ld	a0,-24(s0)
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	500080e7          	jalr	1280(ra) # 800023a2 <wait>
}
    80002eaa:	60e2                	ld	ra,24(sp)
    80002eac:	6442                	ld	s0,16(sp)
    80002eae:	6105                	addi	sp,sp,32
    80002eb0:	8082                	ret

0000000080002eb2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002eb2:	7179                	addi	sp,sp,-48
    80002eb4:	f406                	sd	ra,40(sp)
    80002eb6:	f022                	sd	s0,32(sp)
    80002eb8:	ec26                	sd	s1,24(sp)
    80002eba:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002ebc:	fdc40593          	addi	a1,s0,-36
    80002ec0:	4501                	li	a0,0
    80002ec2:	00000097          	auipc	ra,0x0
    80002ec6:	e84080e7          	jalr	-380(ra) # 80002d46 <argint>
  addr = myproc()->sz;
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	ae2080e7          	jalr	-1310(ra) # 800019ac <myproc>
    80002ed2:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002ed4:	fdc42503          	lw	a0,-36(s0)
    80002ed8:	fffff097          	auipc	ra,0xfffff
    80002edc:	e42080e7          	jalr	-446(ra) # 80001d1a <growproc>
    80002ee0:	00054863          	bltz	a0,80002ef0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002ee4:	8526                	mv	a0,s1
    80002ee6:	70a2                	ld	ra,40(sp)
    80002ee8:	7402                	ld	s0,32(sp)
    80002eea:	64e2                	ld	s1,24(sp)
    80002eec:	6145                	addi	sp,sp,48
    80002eee:	8082                	ret
    return -1;
    80002ef0:	54fd                	li	s1,-1
    80002ef2:	bfcd                	j	80002ee4 <sys_sbrk+0x32>

0000000080002ef4 <sys_sigalarm>:

uint64 sys_sigalarm(void)
{
    80002ef4:	1101                	addi	sp,sp,-32
    80002ef6:	ec06                	sd	ra,24(sp)
    80002ef8:	e822                	sd	s0,16(sp)
    80002efa:	1000                	addi	s0,sp,32
  uint64 addr;
  int ticks;
  
    argint(0, &ticks);
    80002efc:	fe440593          	addi	a1,s0,-28
    80002f00:	4501                	li	a0,0
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	e44080e7          	jalr	-444(ra) # 80002d46 <argint>
    argaddr(1, &addr);
    80002f0a:	fe840593          	addi	a1,s0,-24
    80002f0e:	4505                	li	a0,1
    80002f10:	00000097          	auipc	ra,0x0
    80002f14:	e56080e7          	jalr	-426(ra) # 80002d66 <argaddr>
    
    myproc()->ticks = ticks;
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	a94080e7          	jalr	-1388(ra) # 800019ac <myproc>
    80002f20:	fe442783          	lw	a5,-28(s0)
    80002f24:	18f52423          	sw	a5,392(a0)
    myproc()->handler = addr;
    80002f28:	fffff097          	auipc	ra,0xfffff
    80002f2c:	a84080e7          	jalr	-1404(ra) # 800019ac <myproc>
    80002f30:	fe843783          	ld	a5,-24(s0)
    80002f34:	18f53023          	sd	a5,384(a0)
    myproc()->alarm_on=0;
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	a74080e7          	jalr	-1420(ra) # 800019ac <myproc>
    80002f40:	18052c23          	sw	zero,408(a0)
  

  return 0;
}
    80002f44:	4501                	li	a0,0
    80002f46:	60e2                	ld	ra,24(sp)
    80002f48:	6442                	ld	s0,16(sp)
    80002f4a:	6105                	addi	sp,sp,32
    80002f4c:	8082                	ret

0000000080002f4e <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    80002f4e:	1101                	addi	sp,sp,-32
    80002f50:	ec06                	sd	ra,24(sp)
    80002f52:	e822                	sd	s0,16(sp)
    80002f54:	e426                	sd	s1,8(sp)
    80002f56:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	a54080e7          	jalr	-1452(ra) # 800019ac <myproc>
    80002f60:	84aa                	mv	s1,a0
  if (p->alarm_on){
    80002f62:	19852783          	lw	a5,408(a0)
    80002f66:	eb81                	bnez	a5,80002f76 <sys_sigreturn+0x28>
  memmove(p->trapframe, p->alarm_tf, PGSIZE);
  kfree(p->alarm_tf);
  p->alarm_on = 0;
  p->cur_ticks = 0;}
  return p->trapframe->a0;
    80002f68:	6cbc                	ld	a5,88(s1)
}
    80002f6a:	7ba8                	ld	a0,112(a5)
    80002f6c:	60e2                	ld	ra,24(sp)
    80002f6e:	6442                	ld	s0,16(sp)
    80002f70:	64a2                	ld	s1,8(sp)
    80002f72:	6105                	addi	sp,sp,32
    80002f74:	8082                	ret
  memmove(p->trapframe, p->alarm_tf, PGSIZE);
    80002f76:	6605                	lui	a2,0x1
    80002f78:	19053583          	ld	a1,400(a0)
    80002f7c:	6d28                	ld	a0,88(a0)
    80002f7e:	ffffe097          	auipc	ra,0xffffe
    80002f82:	db0080e7          	jalr	-592(ra) # 80000d2e <memmove>
  kfree(p->alarm_tf);
    80002f86:	1904b503          	ld	a0,400(s1)
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	a5e080e7          	jalr	-1442(ra) # 800009e8 <kfree>
  p->alarm_on = 0;
    80002f92:	1804ac23          	sw	zero,408(s1)
  p->cur_ticks = 0;}
    80002f96:	1804a623          	sw	zero,396(s1)
    80002f9a:	b7f9                	j	80002f68 <sys_sigreturn+0x1a>

0000000080002f9c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f9c:	7139                	addi	sp,sp,-64
    80002f9e:	fc06                	sd	ra,56(sp)
    80002fa0:	f822                	sd	s0,48(sp)
    80002fa2:	f426                	sd	s1,40(sp)
    80002fa4:	f04a                	sd	s2,32(sp)
    80002fa6:	ec4e                	sd	s3,24(sp)
    80002fa8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002faa:	fcc40593          	addi	a1,s0,-52
    80002fae:	4501                	li	a0,0
    80002fb0:	00000097          	auipc	ra,0x0
    80002fb4:	d96080e7          	jalr	-618(ra) # 80002d46 <argint>
  acquire(&tickslock);
    80002fb8:	00014517          	auipc	a0,0x14
    80002fbc:	7e850513          	addi	a0,a0,2024 # 800177a0 <tickslock>
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	c16080e7          	jalr	-1002(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002fc8:	00006917          	auipc	s2,0x6
    80002fcc:	93892903          	lw	s2,-1736(s2) # 80008900 <ticks>
  while (ticks - ticks0 < n)
    80002fd0:	fcc42783          	lw	a5,-52(s0)
    80002fd4:	cf9d                	beqz	a5,80003012 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fd6:	00014997          	auipc	s3,0x14
    80002fda:	7ca98993          	addi	s3,s3,1994 # 800177a0 <tickslock>
    80002fde:	00006497          	auipc	s1,0x6
    80002fe2:	92248493          	addi	s1,s1,-1758 # 80008900 <ticks>
    if (killed(myproc()))
    80002fe6:	fffff097          	auipc	ra,0xfffff
    80002fea:	9c6080e7          	jalr	-1594(ra) # 800019ac <myproc>
    80002fee:	fffff097          	auipc	ra,0xfffff
    80002ff2:	382080e7          	jalr	898(ra) # 80002370 <killed>
    80002ff6:	ed15                	bnez	a0,80003032 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ff8:	85ce                	mv	a1,s3
    80002ffa:	8526                	mv	a0,s1
    80002ffc:	fffff097          	auipc	ra,0xfffff
    80003000:	0c0080e7          	jalr	192(ra) # 800020bc <sleep>
  while (ticks - ticks0 < n)
    80003004:	409c                	lw	a5,0(s1)
    80003006:	412787bb          	subw	a5,a5,s2
    8000300a:	fcc42703          	lw	a4,-52(s0)
    8000300e:	fce7ece3          	bltu	a5,a4,80002fe6 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003012:	00014517          	auipc	a0,0x14
    80003016:	78e50513          	addi	a0,a0,1934 # 800177a0 <tickslock>
    8000301a:	ffffe097          	auipc	ra,0xffffe
    8000301e:	c70080e7          	jalr	-912(ra) # 80000c8a <release>
  return 0;
    80003022:	4501                	li	a0,0
}
    80003024:	70e2                	ld	ra,56(sp)
    80003026:	7442                	ld	s0,48(sp)
    80003028:	74a2                	ld	s1,40(sp)
    8000302a:	7902                	ld	s2,32(sp)
    8000302c:	69e2                	ld	s3,24(sp)
    8000302e:	6121                	addi	sp,sp,64
    80003030:	8082                	ret
      release(&tickslock);
    80003032:	00014517          	auipc	a0,0x14
    80003036:	76e50513          	addi	a0,a0,1902 # 800177a0 <tickslock>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	c50080e7          	jalr	-944(ra) # 80000c8a <release>
      return -1;
    80003042:	557d                	li	a0,-1
    80003044:	b7c5                	j	80003024 <sys_sleep+0x88>

0000000080003046 <sys_kill>:

uint64
sys_kill(void)
{
    80003046:	1101                	addi	sp,sp,-32
    80003048:	ec06                	sd	ra,24(sp)
    8000304a:	e822                	sd	s0,16(sp)
    8000304c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000304e:	fec40593          	addi	a1,s0,-20
    80003052:	4501                	li	a0,0
    80003054:	00000097          	auipc	ra,0x0
    80003058:	cf2080e7          	jalr	-782(ra) # 80002d46 <argint>
  return kill(pid);
    8000305c:	fec42503          	lw	a0,-20(s0)
    80003060:	fffff097          	auipc	ra,0xfffff
    80003064:	272080e7          	jalr	626(ra) # 800022d2 <kill>
}
    80003068:	60e2                	ld	ra,24(sp)
    8000306a:	6442                	ld	s0,16(sp)
    8000306c:	6105                	addi	sp,sp,32
    8000306e:	8082                	ret

0000000080003070 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003070:	1101                	addi	sp,sp,-32
    80003072:	ec06                	sd	ra,24(sp)
    80003074:	e822                	sd	s0,16(sp)
    80003076:	e426                	sd	s1,8(sp)
    80003078:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000307a:	00014517          	auipc	a0,0x14
    8000307e:	72650513          	addi	a0,a0,1830 # 800177a0 <tickslock>
    80003082:	ffffe097          	auipc	ra,0xffffe
    80003086:	b54080e7          	jalr	-1196(ra) # 80000bd6 <acquire>
  xticks = ticks;
    8000308a:	00006497          	auipc	s1,0x6
    8000308e:	8764a483          	lw	s1,-1930(s1) # 80008900 <ticks>
  release(&tickslock);
    80003092:	00014517          	auipc	a0,0x14
    80003096:	70e50513          	addi	a0,a0,1806 # 800177a0 <tickslock>
    8000309a:	ffffe097          	auipc	ra,0xffffe
    8000309e:	bf0080e7          	jalr	-1040(ra) # 80000c8a <release>
  return xticks;
}
    800030a2:	02049513          	slli	a0,s1,0x20
    800030a6:	9101                	srli	a0,a0,0x20
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	64a2                	ld	s1,8(sp)
    800030ae:	6105                	addi	sp,sp,32
    800030b0:	8082                	ret

00000000800030b2 <sys_waitx>:

uint64
sys_waitx(void)
{
    800030b2:	7139                	addi	sp,sp,-64
    800030b4:	fc06                	sd	ra,56(sp)
    800030b6:	f822                	sd	s0,48(sp)
    800030b8:	f426                	sd	s1,40(sp)
    800030ba:	f04a                	sd	s2,32(sp)
    800030bc:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800030be:	fd840593          	addi	a1,s0,-40
    800030c2:	4501                	li	a0,0
    800030c4:	00000097          	auipc	ra,0x0
    800030c8:	ca2080e7          	jalr	-862(ra) # 80002d66 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800030cc:	fd040593          	addi	a1,s0,-48
    800030d0:	4505                	li	a0,1
    800030d2:	00000097          	auipc	ra,0x0
    800030d6:	c94080e7          	jalr	-876(ra) # 80002d66 <argaddr>
  argaddr(2, &addr2);
    800030da:	fc840593          	addi	a1,s0,-56
    800030de:	4509                	li	a0,2
    800030e0:	00000097          	auipc	ra,0x0
    800030e4:	c86080e7          	jalr	-890(ra) # 80002d66 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800030e8:	fc040613          	addi	a2,s0,-64
    800030ec:	fc440593          	addi	a1,s0,-60
    800030f0:	fd843503          	ld	a0,-40(s0)
    800030f4:	fffff097          	auipc	ra,0xfffff
    800030f8:	538080e7          	jalr	1336(ra) # 8000262c <waitx>
    800030fc:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800030fe:	fffff097          	auipc	ra,0xfffff
    80003102:	8ae080e7          	jalr	-1874(ra) # 800019ac <myproc>
    80003106:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003108:	4691                	li	a3,4
    8000310a:	fc440613          	addi	a2,s0,-60
    8000310e:	fd043583          	ld	a1,-48(s0)
    80003112:	6928                	ld	a0,80(a0)
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	558080e7          	jalr	1368(ra) # 8000166c <copyout>
    return -1;
    8000311c:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000311e:	00054f63          	bltz	a0,8000313c <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003122:	4691                	li	a3,4
    80003124:	fc040613          	addi	a2,s0,-64
    80003128:	fc843583          	ld	a1,-56(s0)
    8000312c:	68a8                	ld	a0,80(s1)
    8000312e:	ffffe097          	auipc	ra,0xffffe
    80003132:	53e080e7          	jalr	1342(ra) # 8000166c <copyout>
    80003136:	00054a63          	bltz	a0,8000314a <sys_waitx+0x98>
    return -1;
  return ret;
    8000313a:	87ca                	mv	a5,s2
}
    8000313c:	853e                	mv	a0,a5
    8000313e:	70e2                	ld	ra,56(sp)
    80003140:	7442                	ld	s0,48(sp)
    80003142:	74a2                	ld	s1,40(sp)
    80003144:	7902                	ld	s2,32(sp)
    80003146:	6121                	addi	sp,sp,64
    80003148:	8082                	ret
    return -1;
    8000314a:	57fd                	li	a5,-1
    8000314c:	bfc5                	j	8000313c <sys_waitx+0x8a>

000000008000314e <sys_getreadcount>:

int sys_getreadcount(void)
{
    8000314e:	1141                	addi	sp,sp,-16
    80003150:	e406                	sd	ra,8(sp)
    80003152:	e022                	sd	s0,0(sp)
    80003154:	0800                	addi	s0,sp,16
  return myproc()->read_count;
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	856080e7          	jalr	-1962(ra) # 800019ac <myproc>
}
    8000315e:	17852503          	lw	a0,376(a0)
    80003162:	60a2                	ld	ra,8(sp)
    80003164:	6402                	ld	s0,0(sp)
    80003166:	0141                	addi	sp,sp,16
    80003168:	8082                	ret

000000008000316a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000316a:	7179                	addi	sp,sp,-48
    8000316c:	f406                	sd	ra,40(sp)
    8000316e:	f022                	sd	s0,32(sp)
    80003170:	ec26                	sd	s1,24(sp)
    80003172:	e84a                	sd	s2,16(sp)
    80003174:	e44e                	sd	s3,8(sp)
    80003176:	e052                	sd	s4,0(sp)
    80003178:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000317a:	00005597          	auipc	a1,0x5
    8000317e:	3a658593          	addi	a1,a1,934 # 80008520 <syscalls+0xd0>
    80003182:	00014517          	auipc	a0,0x14
    80003186:	63650513          	addi	a0,a0,1590 # 800177b8 <bcache>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	9bc080e7          	jalr	-1604(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003192:	0001c797          	auipc	a5,0x1c
    80003196:	62678793          	addi	a5,a5,1574 # 8001f7b8 <bcache+0x8000>
    8000319a:	0001d717          	auipc	a4,0x1d
    8000319e:	88670713          	addi	a4,a4,-1914 # 8001fa20 <bcache+0x8268>
    800031a2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031a6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031aa:	00014497          	auipc	s1,0x14
    800031ae:	62648493          	addi	s1,s1,1574 # 800177d0 <bcache+0x18>
    b->next = bcache.head.next;
    800031b2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031b4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031b6:	00005a17          	auipc	s4,0x5
    800031ba:	372a0a13          	addi	s4,s4,882 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    800031be:	2b893783          	ld	a5,696(s2)
    800031c2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800031c4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031c8:	85d2                	mv	a1,s4
    800031ca:	01048513          	addi	a0,s1,16
    800031ce:	00001097          	auipc	ra,0x1
    800031d2:	4c8080e7          	jalr	1224(ra) # 80004696 <initsleeplock>
    bcache.head.next->prev = b;
    800031d6:	2b893783          	ld	a5,696(s2)
    800031da:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031dc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031e0:	45848493          	addi	s1,s1,1112
    800031e4:	fd349de3          	bne	s1,s3,800031be <binit+0x54>
  }
}
    800031e8:	70a2                	ld	ra,40(sp)
    800031ea:	7402                	ld	s0,32(sp)
    800031ec:	64e2                	ld	s1,24(sp)
    800031ee:	6942                	ld	s2,16(sp)
    800031f0:	69a2                	ld	s3,8(sp)
    800031f2:	6a02                	ld	s4,0(sp)
    800031f4:	6145                	addi	sp,sp,48
    800031f6:	8082                	ret

00000000800031f8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031f8:	7179                	addi	sp,sp,-48
    800031fa:	f406                	sd	ra,40(sp)
    800031fc:	f022                	sd	s0,32(sp)
    800031fe:	ec26                	sd	s1,24(sp)
    80003200:	e84a                	sd	s2,16(sp)
    80003202:	e44e                	sd	s3,8(sp)
    80003204:	1800                	addi	s0,sp,48
    80003206:	892a                	mv	s2,a0
    80003208:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000320a:	00014517          	auipc	a0,0x14
    8000320e:	5ae50513          	addi	a0,a0,1454 # 800177b8 <bcache>
    80003212:	ffffe097          	auipc	ra,0xffffe
    80003216:	9c4080e7          	jalr	-1596(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000321a:	0001d497          	auipc	s1,0x1d
    8000321e:	8564b483          	ld	s1,-1962(s1) # 8001fa70 <bcache+0x82b8>
    80003222:	0001c797          	auipc	a5,0x1c
    80003226:	7fe78793          	addi	a5,a5,2046 # 8001fa20 <bcache+0x8268>
    8000322a:	02f48f63          	beq	s1,a5,80003268 <bread+0x70>
    8000322e:	873e                	mv	a4,a5
    80003230:	a021                	j	80003238 <bread+0x40>
    80003232:	68a4                	ld	s1,80(s1)
    80003234:	02e48a63          	beq	s1,a4,80003268 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003238:	449c                	lw	a5,8(s1)
    8000323a:	ff279ce3          	bne	a5,s2,80003232 <bread+0x3a>
    8000323e:	44dc                	lw	a5,12(s1)
    80003240:	ff3799e3          	bne	a5,s3,80003232 <bread+0x3a>
      b->refcnt++;
    80003244:	40bc                	lw	a5,64(s1)
    80003246:	2785                	addiw	a5,a5,1
    80003248:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000324a:	00014517          	auipc	a0,0x14
    8000324e:	56e50513          	addi	a0,a0,1390 # 800177b8 <bcache>
    80003252:	ffffe097          	auipc	ra,0xffffe
    80003256:	a38080e7          	jalr	-1480(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000325a:	01048513          	addi	a0,s1,16
    8000325e:	00001097          	auipc	ra,0x1
    80003262:	472080e7          	jalr	1138(ra) # 800046d0 <acquiresleep>
      return b;
    80003266:	a8b9                	j	800032c4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003268:	0001d497          	auipc	s1,0x1d
    8000326c:	8004b483          	ld	s1,-2048(s1) # 8001fa68 <bcache+0x82b0>
    80003270:	0001c797          	auipc	a5,0x1c
    80003274:	7b078793          	addi	a5,a5,1968 # 8001fa20 <bcache+0x8268>
    80003278:	00f48863          	beq	s1,a5,80003288 <bread+0x90>
    8000327c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000327e:	40bc                	lw	a5,64(s1)
    80003280:	cf81                	beqz	a5,80003298 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003282:	64a4                	ld	s1,72(s1)
    80003284:	fee49de3          	bne	s1,a4,8000327e <bread+0x86>
  panic("bget: no buffers");
    80003288:	00005517          	auipc	a0,0x5
    8000328c:	2a850513          	addi	a0,a0,680 # 80008530 <syscalls+0xe0>
    80003290:	ffffd097          	auipc	ra,0xffffd
    80003294:	2b0080e7          	jalr	688(ra) # 80000540 <panic>
      b->dev = dev;
    80003298:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000329c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032a0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032a4:	4785                	li	a5,1
    800032a6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032a8:	00014517          	auipc	a0,0x14
    800032ac:	51050513          	addi	a0,a0,1296 # 800177b8 <bcache>
    800032b0:	ffffe097          	auipc	ra,0xffffe
    800032b4:	9da080e7          	jalr	-1574(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800032b8:	01048513          	addi	a0,s1,16
    800032bc:	00001097          	auipc	ra,0x1
    800032c0:	414080e7          	jalr	1044(ra) # 800046d0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032c4:	409c                	lw	a5,0(s1)
    800032c6:	cb89                	beqz	a5,800032d8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032c8:	8526                	mv	a0,s1
    800032ca:	70a2                	ld	ra,40(sp)
    800032cc:	7402                	ld	s0,32(sp)
    800032ce:	64e2                	ld	s1,24(sp)
    800032d0:	6942                	ld	s2,16(sp)
    800032d2:	69a2                	ld	s3,8(sp)
    800032d4:	6145                	addi	sp,sp,48
    800032d6:	8082                	ret
    virtio_disk_rw(b, 0);
    800032d8:	4581                	li	a1,0
    800032da:	8526                	mv	a0,s1
    800032dc:	00003097          	auipc	ra,0x3
    800032e0:	ff6080e7          	jalr	-10(ra) # 800062d2 <virtio_disk_rw>
    b->valid = 1;
    800032e4:	4785                	li	a5,1
    800032e6:	c09c                	sw	a5,0(s1)
  return b;
    800032e8:	b7c5                	j	800032c8 <bread+0xd0>

00000000800032ea <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032ea:	1101                	addi	sp,sp,-32
    800032ec:	ec06                	sd	ra,24(sp)
    800032ee:	e822                	sd	s0,16(sp)
    800032f0:	e426                	sd	s1,8(sp)
    800032f2:	1000                	addi	s0,sp,32
    800032f4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032f6:	0541                	addi	a0,a0,16
    800032f8:	00001097          	auipc	ra,0x1
    800032fc:	472080e7          	jalr	1138(ra) # 8000476a <holdingsleep>
    80003300:	cd01                	beqz	a0,80003318 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003302:	4585                	li	a1,1
    80003304:	8526                	mv	a0,s1
    80003306:	00003097          	auipc	ra,0x3
    8000330a:	fcc080e7          	jalr	-52(ra) # 800062d2 <virtio_disk_rw>
}
    8000330e:	60e2                	ld	ra,24(sp)
    80003310:	6442                	ld	s0,16(sp)
    80003312:	64a2                	ld	s1,8(sp)
    80003314:	6105                	addi	sp,sp,32
    80003316:	8082                	ret
    panic("bwrite");
    80003318:	00005517          	auipc	a0,0x5
    8000331c:	23050513          	addi	a0,a0,560 # 80008548 <syscalls+0xf8>
    80003320:	ffffd097          	auipc	ra,0xffffd
    80003324:	220080e7          	jalr	544(ra) # 80000540 <panic>

0000000080003328 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003328:	1101                	addi	sp,sp,-32
    8000332a:	ec06                	sd	ra,24(sp)
    8000332c:	e822                	sd	s0,16(sp)
    8000332e:	e426                	sd	s1,8(sp)
    80003330:	e04a                	sd	s2,0(sp)
    80003332:	1000                	addi	s0,sp,32
    80003334:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003336:	01050913          	addi	s2,a0,16
    8000333a:	854a                	mv	a0,s2
    8000333c:	00001097          	auipc	ra,0x1
    80003340:	42e080e7          	jalr	1070(ra) # 8000476a <holdingsleep>
    80003344:	c92d                	beqz	a0,800033b6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003346:	854a                	mv	a0,s2
    80003348:	00001097          	auipc	ra,0x1
    8000334c:	3de080e7          	jalr	990(ra) # 80004726 <releasesleep>

  acquire(&bcache.lock);
    80003350:	00014517          	auipc	a0,0x14
    80003354:	46850513          	addi	a0,a0,1128 # 800177b8 <bcache>
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	87e080e7          	jalr	-1922(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003360:	40bc                	lw	a5,64(s1)
    80003362:	37fd                	addiw	a5,a5,-1
    80003364:	0007871b          	sext.w	a4,a5
    80003368:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000336a:	eb05                	bnez	a4,8000339a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000336c:	68bc                	ld	a5,80(s1)
    8000336e:	64b8                	ld	a4,72(s1)
    80003370:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003372:	64bc                	ld	a5,72(s1)
    80003374:	68b8                	ld	a4,80(s1)
    80003376:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003378:	0001c797          	auipc	a5,0x1c
    8000337c:	44078793          	addi	a5,a5,1088 # 8001f7b8 <bcache+0x8000>
    80003380:	2b87b703          	ld	a4,696(a5)
    80003384:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003386:	0001c717          	auipc	a4,0x1c
    8000338a:	69a70713          	addi	a4,a4,1690 # 8001fa20 <bcache+0x8268>
    8000338e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003390:	2b87b703          	ld	a4,696(a5)
    80003394:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003396:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000339a:	00014517          	auipc	a0,0x14
    8000339e:	41e50513          	addi	a0,a0,1054 # 800177b8 <bcache>
    800033a2:	ffffe097          	auipc	ra,0xffffe
    800033a6:	8e8080e7          	jalr	-1816(ra) # 80000c8a <release>
}
    800033aa:	60e2                	ld	ra,24(sp)
    800033ac:	6442                	ld	s0,16(sp)
    800033ae:	64a2                	ld	s1,8(sp)
    800033b0:	6902                	ld	s2,0(sp)
    800033b2:	6105                	addi	sp,sp,32
    800033b4:	8082                	ret
    panic("brelse");
    800033b6:	00005517          	auipc	a0,0x5
    800033ba:	19a50513          	addi	a0,a0,410 # 80008550 <syscalls+0x100>
    800033be:	ffffd097          	auipc	ra,0xffffd
    800033c2:	182080e7          	jalr	386(ra) # 80000540 <panic>

00000000800033c6 <bpin>:

void
bpin(struct buf *b) {
    800033c6:	1101                	addi	sp,sp,-32
    800033c8:	ec06                	sd	ra,24(sp)
    800033ca:	e822                	sd	s0,16(sp)
    800033cc:	e426                	sd	s1,8(sp)
    800033ce:	1000                	addi	s0,sp,32
    800033d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033d2:	00014517          	auipc	a0,0x14
    800033d6:	3e650513          	addi	a0,a0,998 # 800177b8 <bcache>
    800033da:	ffffd097          	auipc	ra,0xffffd
    800033de:	7fc080e7          	jalr	2044(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800033e2:	40bc                	lw	a5,64(s1)
    800033e4:	2785                	addiw	a5,a5,1
    800033e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033e8:	00014517          	auipc	a0,0x14
    800033ec:	3d050513          	addi	a0,a0,976 # 800177b8 <bcache>
    800033f0:	ffffe097          	auipc	ra,0xffffe
    800033f4:	89a080e7          	jalr	-1894(ra) # 80000c8a <release>
}
    800033f8:	60e2                	ld	ra,24(sp)
    800033fa:	6442                	ld	s0,16(sp)
    800033fc:	64a2                	ld	s1,8(sp)
    800033fe:	6105                	addi	sp,sp,32
    80003400:	8082                	ret

0000000080003402 <bunpin>:

void
bunpin(struct buf *b) {
    80003402:	1101                	addi	sp,sp,-32
    80003404:	ec06                	sd	ra,24(sp)
    80003406:	e822                	sd	s0,16(sp)
    80003408:	e426                	sd	s1,8(sp)
    8000340a:	1000                	addi	s0,sp,32
    8000340c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000340e:	00014517          	auipc	a0,0x14
    80003412:	3aa50513          	addi	a0,a0,938 # 800177b8 <bcache>
    80003416:	ffffd097          	auipc	ra,0xffffd
    8000341a:	7c0080e7          	jalr	1984(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000341e:	40bc                	lw	a5,64(s1)
    80003420:	37fd                	addiw	a5,a5,-1
    80003422:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003424:	00014517          	auipc	a0,0x14
    80003428:	39450513          	addi	a0,a0,916 # 800177b8 <bcache>
    8000342c:	ffffe097          	auipc	ra,0xffffe
    80003430:	85e080e7          	jalr	-1954(ra) # 80000c8a <release>
}
    80003434:	60e2                	ld	ra,24(sp)
    80003436:	6442                	ld	s0,16(sp)
    80003438:	64a2                	ld	s1,8(sp)
    8000343a:	6105                	addi	sp,sp,32
    8000343c:	8082                	ret

000000008000343e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000343e:	1101                	addi	sp,sp,-32
    80003440:	ec06                	sd	ra,24(sp)
    80003442:	e822                	sd	s0,16(sp)
    80003444:	e426                	sd	s1,8(sp)
    80003446:	e04a                	sd	s2,0(sp)
    80003448:	1000                	addi	s0,sp,32
    8000344a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000344c:	00d5d59b          	srliw	a1,a1,0xd
    80003450:	0001d797          	auipc	a5,0x1d
    80003454:	a447a783          	lw	a5,-1468(a5) # 8001fe94 <sb+0x1c>
    80003458:	9dbd                	addw	a1,a1,a5
    8000345a:	00000097          	auipc	ra,0x0
    8000345e:	d9e080e7          	jalr	-610(ra) # 800031f8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003462:	0074f713          	andi	a4,s1,7
    80003466:	4785                	li	a5,1
    80003468:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000346c:	14ce                	slli	s1,s1,0x33
    8000346e:	90d9                	srli	s1,s1,0x36
    80003470:	00950733          	add	a4,a0,s1
    80003474:	05874703          	lbu	a4,88(a4)
    80003478:	00e7f6b3          	and	a3,a5,a4
    8000347c:	c69d                	beqz	a3,800034aa <bfree+0x6c>
    8000347e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003480:	94aa                	add	s1,s1,a0
    80003482:	fff7c793          	not	a5,a5
    80003486:	8f7d                	and	a4,a4,a5
    80003488:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000348c:	00001097          	auipc	ra,0x1
    80003490:	126080e7          	jalr	294(ra) # 800045b2 <log_write>
  brelse(bp);
    80003494:	854a                	mv	a0,s2
    80003496:	00000097          	auipc	ra,0x0
    8000349a:	e92080e7          	jalr	-366(ra) # 80003328 <brelse>
}
    8000349e:	60e2                	ld	ra,24(sp)
    800034a0:	6442                	ld	s0,16(sp)
    800034a2:	64a2                	ld	s1,8(sp)
    800034a4:	6902                	ld	s2,0(sp)
    800034a6:	6105                	addi	sp,sp,32
    800034a8:	8082                	ret
    panic("freeing free block");
    800034aa:	00005517          	auipc	a0,0x5
    800034ae:	0ae50513          	addi	a0,a0,174 # 80008558 <syscalls+0x108>
    800034b2:	ffffd097          	auipc	ra,0xffffd
    800034b6:	08e080e7          	jalr	142(ra) # 80000540 <panic>

00000000800034ba <balloc>:
{
    800034ba:	711d                	addi	sp,sp,-96
    800034bc:	ec86                	sd	ra,88(sp)
    800034be:	e8a2                	sd	s0,80(sp)
    800034c0:	e4a6                	sd	s1,72(sp)
    800034c2:	e0ca                	sd	s2,64(sp)
    800034c4:	fc4e                	sd	s3,56(sp)
    800034c6:	f852                	sd	s4,48(sp)
    800034c8:	f456                	sd	s5,40(sp)
    800034ca:	f05a                	sd	s6,32(sp)
    800034cc:	ec5e                	sd	s7,24(sp)
    800034ce:	e862                	sd	s8,16(sp)
    800034d0:	e466                	sd	s9,8(sp)
    800034d2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034d4:	0001d797          	auipc	a5,0x1d
    800034d8:	9a87a783          	lw	a5,-1624(a5) # 8001fe7c <sb+0x4>
    800034dc:	cff5                	beqz	a5,800035d8 <balloc+0x11e>
    800034de:	8baa                	mv	s7,a0
    800034e0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034e2:	0001db17          	auipc	s6,0x1d
    800034e6:	996b0b13          	addi	s6,s6,-1642 # 8001fe78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ea:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034ec:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ee:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034f0:	6c89                	lui	s9,0x2
    800034f2:	a061                	j	8000357a <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034f4:	97ca                	add	a5,a5,s2
    800034f6:	8e55                	or	a2,a2,a3
    800034f8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800034fc:	854a                	mv	a0,s2
    800034fe:	00001097          	auipc	ra,0x1
    80003502:	0b4080e7          	jalr	180(ra) # 800045b2 <log_write>
        brelse(bp);
    80003506:	854a                	mv	a0,s2
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	e20080e7          	jalr	-480(ra) # 80003328 <brelse>
  bp = bread(dev, bno);
    80003510:	85a6                	mv	a1,s1
    80003512:	855e                	mv	a0,s7
    80003514:	00000097          	auipc	ra,0x0
    80003518:	ce4080e7          	jalr	-796(ra) # 800031f8 <bread>
    8000351c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000351e:	40000613          	li	a2,1024
    80003522:	4581                	li	a1,0
    80003524:	05850513          	addi	a0,a0,88
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	7aa080e7          	jalr	1962(ra) # 80000cd2 <memset>
  log_write(bp);
    80003530:	854a                	mv	a0,s2
    80003532:	00001097          	auipc	ra,0x1
    80003536:	080080e7          	jalr	128(ra) # 800045b2 <log_write>
  brelse(bp);
    8000353a:	854a                	mv	a0,s2
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	dec080e7          	jalr	-532(ra) # 80003328 <brelse>
}
    80003544:	8526                	mv	a0,s1
    80003546:	60e6                	ld	ra,88(sp)
    80003548:	6446                	ld	s0,80(sp)
    8000354a:	64a6                	ld	s1,72(sp)
    8000354c:	6906                	ld	s2,64(sp)
    8000354e:	79e2                	ld	s3,56(sp)
    80003550:	7a42                	ld	s4,48(sp)
    80003552:	7aa2                	ld	s5,40(sp)
    80003554:	7b02                	ld	s6,32(sp)
    80003556:	6be2                	ld	s7,24(sp)
    80003558:	6c42                	ld	s8,16(sp)
    8000355a:	6ca2                	ld	s9,8(sp)
    8000355c:	6125                	addi	sp,sp,96
    8000355e:	8082                	ret
    brelse(bp);
    80003560:	854a                	mv	a0,s2
    80003562:	00000097          	auipc	ra,0x0
    80003566:	dc6080e7          	jalr	-570(ra) # 80003328 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000356a:	015c87bb          	addw	a5,s9,s5
    8000356e:	00078a9b          	sext.w	s5,a5
    80003572:	004b2703          	lw	a4,4(s6)
    80003576:	06eaf163          	bgeu	s5,a4,800035d8 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000357a:	41fad79b          	sraiw	a5,s5,0x1f
    8000357e:	0137d79b          	srliw	a5,a5,0x13
    80003582:	015787bb          	addw	a5,a5,s5
    80003586:	40d7d79b          	sraiw	a5,a5,0xd
    8000358a:	01cb2583          	lw	a1,28(s6)
    8000358e:	9dbd                	addw	a1,a1,a5
    80003590:	855e                	mv	a0,s7
    80003592:	00000097          	auipc	ra,0x0
    80003596:	c66080e7          	jalr	-922(ra) # 800031f8 <bread>
    8000359a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000359c:	004b2503          	lw	a0,4(s6)
    800035a0:	000a849b          	sext.w	s1,s5
    800035a4:	8762                	mv	a4,s8
    800035a6:	faa4fde3          	bgeu	s1,a0,80003560 <balloc+0xa6>
      m = 1 << (bi % 8);
    800035aa:	00777693          	andi	a3,a4,7
    800035ae:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035b2:	41f7579b          	sraiw	a5,a4,0x1f
    800035b6:	01d7d79b          	srliw	a5,a5,0x1d
    800035ba:	9fb9                	addw	a5,a5,a4
    800035bc:	4037d79b          	sraiw	a5,a5,0x3
    800035c0:	00f90633          	add	a2,s2,a5
    800035c4:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800035c8:	00c6f5b3          	and	a1,a3,a2
    800035cc:	d585                	beqz	a1,800034f4 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035ce:	2705                	addiw	a4,a4,1
    800035d0:	2485                	addiw	s1,s1,1
    800035d2:	fd471ae3          	bne	a4,s4,800035a6 <balloc+0xec>
    800035d6:	b769                	j	80003560 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800035d8:	00005517          	auipc	a0,0x5
    800035dc:	f9850513          	addi	a0,a0,-104 # 80008570 <syscalls+0x120>
    800035e0:	ffffd097          	auipc	ra,0xffffd
    800035e4:	faa080e7          	jalr	-86(ra) # 8000058a <printf>
  return 0;
    800035e8:	4481                	li	s1,0
    800035ea:	bfa9                	j	80003544 <balloc+0x8a>

00000000800035ec <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800035ec:	7179                	addi	sp,sp,-48
    800035ee:	f406                	sd	ra,40(sp)
    800035f0:	f022                	sd	s0,32(sp)
    800035f2:	ec26                	sd	s1,24(sp)
    800035f4:	e84a                	sd	s2,16(sp)
    800035f6:	e44e                	sd	s3,8(sp)
    800035f8:	e052                	sd	s4,0(sp)
    800035fa:	1800                	addi	s0,sp,48
    800035fc:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035fe:	47ad                	li	a5,11
    80003600:	02b7e863          	bltu	a5,a1,80003630 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003604:	02059793          	slli	a5,a1,0x20
    80003608:	01e7d593          	srli	a1,a5,0x1e
    8000360c:	00b504b3          	add	s1,a0,a1
    80003610:	0504a903          	lw	s2,80(s1)
    80003614:	06091e63          	bnez	s2,80003690 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003618:	4108                	lw	a0,0(a0)
    8000361a:	00000097          	auipc	ra,0x0
    8000361e:	ea0080e7          	jalr	-352(ra) # 800034ba <balloc>
    80003622:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003626:	06090563          	beqz	s2,80003690 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000362a:	0524a823          	sw	s2,80(s1)
    8000362e:	a08d                	j	80003690 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003630:	ff45849b          	addiw	s1,a1,-12
    80003634:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003638:	0ff00793          	li	a5,255
    8000363c:	08e7e563          	bltu	a5,a4,800036c6 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003640:	08052903          	lw	s2,128(a0)
    80003644:	00091d63          	bnez	s2,8000365e <bmap+0x72>
      addr = balloc(ip->dev);
    80003648:	4108                	lw	a0,0(a0)
    8000364a:	00000097          	auipc	ra,0x0
    8000364e:	e70080e7          	jalr	-400(ra) # 800034ba <balloc>
    80003652:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003656:	02090d63          	beqz	s2,80003690 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000365a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000365e:	85ca                	mv	a1,s2
    80003660:	0009a503          	lw	a0,0(s3)
    80003664:	00000097          	auipc	ra,0x0
    80003668:	b94080e7          	jalr	-1132(ra) # 800031f8 <bread>
    8000366c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000366e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003672:	02049713          	slli	a4,s1,0x20
    80003676:	01e75593          	srli	a1,a4,0x1e
    8000367a:	00b784b3          	add	s1,a5,a1
    8000367e:	0004a903          	lw	s2,0(s1)
    80003682:	02090063          	beqz	s2,800036a2 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003686:	8552                	mv	a0,s4
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	ca0080e7          	jalr	-864(ra) # 80003328 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003690:	854a                	mv	a0,s2
    80003692:	70a2                	ld	ra,40(sp)
    80003694:	7402                	ld	s0,32(sp)
    80003696:	64e2                	ld	s1,24(sp)
    80003698:	6942                	ld	s2,16(sp)
    8000369a:	69a2                	ld	s3,8(sp)
    8000369c:	6a02                	ld	s4,0(sp)
    8000369e:	6145                	addi	sp,sp,48
    800036a0:	8082                	ret
      addr = balloc(ip->dev);
    800036a2:	0009a503          	lw	a0,0(s3)
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	e14080e7          	jalr	-492(ra) # 800034ba <balloc>
    800036ae:	0005091b          	sext.w	s2,a0
      if(addr){
    800036b2:	fc090ae3          	beqz	s2,80003686 <bmap+0x9a>
        a[bn] = addr;
    800036b6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800036ba:	8552                	mv	a0,s4
    800036bc:	00001097          	auipc	ra,0x1
    800036c0:	ef6080e7          	jalr	-266(ra) # 800045b2 <log_write>
    800036c4:	b7c9                	j	80003686 <bmap+0x9a>
  panic("bmap: out of range");
    800036c6:	00005517          	auipc	a0,0x5
    800036ca:	ec250513          	addi	a0,a0,-318 # 80008588 <syscalls+0x138>
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	e72080e7          	jalr	-398(ra) # 80000540 <panic>

00000000800036d6 <iget>:
{
    800036d6:	7179                	addi	sp,sp,-48
    800036d8:	f406                	sd	ra,40(sp)
    800036da:	f022                	sd	s0,32(sp)
    800036dc:	ec26                	sd	s1,24(sp)
    800036de:	e84a                	sd	s2,16(sp)
    800036e0:	e44e                	sd	s3,8(sp)
    800036e2:	e052                	sd	s4,0(sp)
    800036e4:	1800                	addi	s0,sp,48
    800036e6:	89aa                	mv	s3,a0
    800036e8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036ea:	0001c517          	auipc	a0,0x1c
    800036ee:	7ae50513          	addi	a0,a0,1966 # 8001fe98 <itable>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	4e4080e7          	jalr	1252(ra) # 80000bd6 <acquire>
  empty = 0;
    800036fa:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036fc:	0001c497          	auipc	s1,0x1c
    80003700:	7b448493          	addi	s1,s1,1972 # 8001feb0 <itable+0x18>
    80003704:	0001e697          	auipc	a3,0x1e
    80003708:	23c68693          	addi	a3,a3,572 # 80021940 <log>
    8000370c:	a039                	j	8000371a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000370e:	02090b63          	beqz	s2,80003744 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003712:	08848493          	addi	s1,s1,136
    80003716:	02d48a63          	beq	s1,a3,8000374a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000371a:	449c                	lw	a5,8(s1)
    8000371c:	fef059e3          	blez	a5,8000370e <iget+0x38>
    80003720:	4098                	lw	a4,0(s1)
    80003722:	ff3716e3          	bne	a4,s3,8000370e <iget+0x38>
    80003726:	40d8                	lw	a4,4(s1)
    80003728:	ff4713e3          	bne	a4,s4,8000370e <iget+0x38>
      ip->ref++;
    8000372c:	2785                	addiw	a5,a5,1
    8000372e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003730:	0001c517          	auipc	a0,0x1c
    80003734:	76850513          	addi	a0,a0,1896 # 8001fe98 <itable>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	552080e7          	jalr	1362(ra) # 80000c8a <release>
      return ip;
    80003740:	8926                	mv	s2,s1
    80003742:	a03d                	j	80003770 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003744:	f7f9                	bnez	a5,80003712 <iget+0x3c>
    80003746:	8926                	mv	s2,s1
    80003748:	b7e9                	j	80003712 <iget+0x3c>
  if(empty == 0)
    8000374a:	02090c63          	beqz	s2,80003782 <iget+0xac>
  ip->dev = dev;
    8000374e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003752:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003756:	4785                	li	a5,1
    80003758:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000375c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003760:	0001c517          	auipc	a0,0x1c
    80003764:	73850513          	addi	a0,a0,1848 # 8001fe98 <itable>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	522080e7          	jalr	1314(ra) # 80000c8a <release>
}
    80003770:	854a                	mv	a0,s2
    80003772:	70a2                	ld	ra,40(sp)
    80003774:	7402                	ld	s0,32(sp)
    80003776:	64e2                	ld	s1,24(sp)
    80003778:	6942                	ld	s2,16(sp)
    8000377a:	69a2                	ld	s3,8(sp)
    8000377c:	6a02                	ld	s4,0(sp)
    8000377e:	6145                	addi	sp,sp,48
    80003780:	8082                	ret
    panic("iget: no inodes");
    80003782:	00005517          	auipc	a0,0x5
    80003786:	e1e50513          	addi	a0,a0,-482 # 800085a0 <syscalls+0x150>
    8000378a:	ffffd097          	auipc	ra,0xffffd
    8000378e:	db6080e7          	jalr	-586(ra) # 80000540 <panic>

0000000080003792 <fsinit>:
fsinit(int dev) {
    80003792:	7179                	addi	sp,sp,-48
    80003794:	f406                	sd	ra,40(sp)
    80003796:	f022                	sd	s0,32(sp)
    80003798:	ec26                	sd	s1,24(sp)
    8000379a:	e84a                	sd	s2,16(sp)
    8000379c:	e44e                	sd	s3,8(sp)
    8000379e:	1800                	addi	s0,sp,48
    800037a0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037a2:	4585                	li	a1,1
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	a54080e7          	jalr	-1452(ra) # 800031f8 <bread>
    800037ac:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037ae:	0001c997          	auipc	s3,0x1c
    800037b2:	6ca98993          	addi	s3,s3,1738 # 8001fe78 <sb>
    800037b6:	02000613          	li	a2,32
    800037ba:	05850593          	addi	a1,a0,88
    800037be:	854e                	mv	a0,s3
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	56e080e7          	jalr	1390(ra) # 80000d2e <memmove>
  brelse(bp);
    800037c8:	8526                	mv	a0,s1
    800037ca:	00000097          	auipc	ra,0x0
    800037ce:	b5e080e7          	jalr	-1186(ra) # 80003328 <brelse>
  if(sb.magic != FSMAGIC)
    800037d2:	0009a703          	lw	a4,0(s3)
    800037d6:	102037b7          	lui	a5,0x10203
    800037da:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037de:	02f71263          	bne	a4,a5,80003802 <fsinit+0x70>
  initlog(dev, &sb);
    800037e2:	0001c597          	auipc	a1,0x1c
    800037e6:	69658593          	addi	a1,a1,1686 # 8001fe78 <sb>
    800037ea:	854a                	mv	a0,s2
    800037ec:	00001097          	auipc	ra,0x1
    800037f0:	b4a080e7          	jalr	-1206(ra) # 80004336 <initlog>
}
    800037f4:	70a2                	ld	ra,40(sp)
    800037f6:	7402                	ld	s0,32(sp)
    800037f8:	64e2                	ld	s1,24(sp)
    800037fa:	6942                	ld	s2,16(sp)
    800037fc:	69a2                	ld	s3,8(sp)
    800037fe:	6145                	addi	sp,sp,48
    80003800:	8082                	ret
    panic("invalid file system");
    80003802:	00005517          	auipc	a0,0x5
    80003806:	dae50513          	addi	a0,a0,-594 # 800085b0 <syscalls+0x160>
    8000380a:	ffffd097          	auipc	ra,0xffffd
    8000380e:	d36080e7          	jalr	-714(ra) # 80000540 <panic>

0000000080003812 <iinit>:
{
    80003812:	7179                	addi	sp,sp,-48
    80003814:	f406                	sd	ra,40(sp)
    80003816:	f022                	sd	s0,32(sp)
    80003818:	ec26                	sd	s1,24(sp)
    8000381a:	e84a                	sd	s2,16(sp)
    8000381c:	e44e                	sd	s3,8(sp)
    8000381e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003820:	00005597          	auipc	a1,0x5
    80003824:	da858593          	addi	a1,a1,-600 # 800085c8 <syscalls+0x178>
    80003828:	0001c517          	auipc	a0,0x1c
    8000382c:	67050513          	addi	a0,a0,1648 # 8001fe98 <itable>
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	316080e7          	jalr	790(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003838:	0001c497          	auipc	s1,0x1c
    8000383c:	68848493          	addi	s1,s1,1672 # 8001fec0 <itable+0x28>
    80003840:	0001e997          	auipc	s3,0x1e
    80003844:	11098993          	addi	s3,s3,272 # 80021950 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003848:	00005917          	auipc	s2,0x5
    8000384c:	d8890913          	addi	s2,s2,-632 # 800085d0 <syscalls+0x180>
    80003850:	85ca                	mv	a1,s2
    80003852:	8526                	mv	a0,s1
    80003854:	00001097          	auipc	ra,0x1
    80003858:	e42080e7          	jalr	-446(ra) # 80004696 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000385c:	08848493          	addi	s1,s1,136
    80003860:	ff3498e3          	bne	s1,s3,80003850 <iinit+0x3e>
}
    80003864:	70a2                	ld	ra,40(sp)
    80003866:	7402                	ld	s0,32(sp)
    80003868:	64e2                	ld	s1,24(sp)
    8000386a:	6942                	ld	s2,16(sp)
    8000386c:	69a2                	ld	s3,8(sp)
    8000386e:	6145                	addi	sp,sp,48
    80003870:	8082                	ret

0000000080003872 <ialloc>:
{
    80003872:	715d                	addi	sp,sp,-80
    80003874:	e486                	sd	ra,72(sp)
    80003876:	e0a2                	sd	s0,64(sp)
    80003878:	fc26                	sd	s1,56(sp)
    8000387a:	f84a                	sd	s2,48(sp)
    8000387c:	f44e                	sd	s3,40(sp)
    8000387e:	f052                	sd	s4,32(sp)
    80003880:	ec56                	sd	s5,24(sp)
    80003882:	e85a                	sd	s6,16(sp)
    80003884:	e45e                	sd	s7,8(sp)
    80003886:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003888:	0001c717          	auipc	a4,0x1c
    8000388c:	5fc72703          	lw	a4,1532(a4) # 8001fe84 <sb+0xc>
    80003890:	4785                	li	a5,1
    80003892:	04e7fa63          	bgeu	a5,a4,800038e6 <ialloc+0x74>
    80003896:	8aaa                	mv	s5,a0
    80003898:	8bae                	mv	s7,a1
    8000389a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000389c:	0001ca17          	auipc	s4,0x1c
    800038a0:	5dca0a13          	addi	s4,s4,1500 # 8001fe78 <sb>
    800038a4:	00048b1b          	sext.w	s6,s1
    800038a8:	0044d593          	srli	a1,s1,0x4
    800038ac:	018a2783          	lw	a5,24(s4)
    800038b0:	9dbd                	addw	a1,a1,a5
    800038b2:	8556                	mv	a0,s5
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	944080e7          	jalr	-1724(ra) # 800031f8 <bread>
    800038bc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038be:	05850993          	addi	s3,a0,88
    800038c2:	00f4f793          	andi	a5,s1,15
    800038c6:	079a                	slli	a5,a5,0x6
    800038c8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038ca:	00099783          	lh	a5,0(s3)
    800038ce:	c3a1                	beqz	a5,8000390e <ialloc+0x9c>
    brelse(bp);
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	a58080e7          	jalr	-1448(ra) # 80003328 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038d8:	0485                	addi	s1,s1,1
    800038da:	00ca2703          	lw	a4,12(s4)
    800038de:	0004879b          	sext.w	a5,s1
    800038e2:	fce7e1e3          	bltu	a5,a4,800038a4 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800038e6:	00005517          	auipc	a0,0x5
    800038ea:	cf250513          	addi	a0,a0,-782 # 800085d8 <syscalls+0x188>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	c9c080e7          	jalr	-868(ra) # 8000058a <printf>
  return 0;
    800038f6:	4501                	li	a0,0
}
    800038f8:	60a6                	ld	ra,72(sp)
    800038fa:	6406                	ld	s0,64(sp)
    800038fc:	74e2                	ld	s1,56(sp)
    800038fe:	7942                	ld	s2,48(sp)
    80003900:	79a2                	ld	s3,40(sp)
    80003902:	7a02                	ld	s4,32(sp)
    80003904:	6ae2                	ld	s5,24(sp)
    80003906:	6b42                	ld	s6,16(sp)
    80003908:	6ba2                	ld	s7,8(sp)
    8000390a:	6161                	addi	sp,sp,80
    8000390c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000390e:	04000613          	li	a2,64
    80003912:	4581                	li	a1,0
    80003914:	854e                	mv	a0,s3
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	3bc080e7          	jalr	956(ra) # 80000cd2 <memset>
      dip->type = type;
    8000391e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003922:	854a                	mv	a0,s2
    80003924:	00001097          	auipc	ra,0x1
    80003928:	c8e080e7          	jalr	-882(ra) # 800045b2 <log_write>
      brelse(bp);
    8000392c:	854a                	mv	a0,s2
    8000392e:	00000097          	auipc	ra,0x0
    80003932:	9fa080e7          	jalr	-1542(ra) # 80003328 <brelse>
      return iget(dev, inum);
    80003936:	85da                	mv	a1,s6
    80003938:	8556                	mv	a0,s5
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	d9c080e7          	jalr	-612(ra) # 800036d6 <iget>
    80003942:	bf5d                	j	800038f8 <ialloc+0x86>

0000000080003944 <iupdate>:
{
    80003944:	1101                	addi	sp,sp,-32
    80003946:	ec06                	sd	ra,24(sp)
    80003948:	e822                	sd	s0,16(sp)
    8000394a:	e426                	sd	s1,8(sp)
    8000394c:	e04a                	sd	s2,0(sp)
    8000394e:	1000                	addi	s0,sp,32
    80003950:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003952:	415c                	lw	a5,4(a0)
    80003954:	0047d79b          	srliw	a5,a5,0x4
    80003958:	0001c597          	auipc	a1,0x1c
    8000395c:	5385a583          	lw	a1,1336(a1) # 8001fe90 <sb+0x18>
    80003960:	9dbd                	addw	a1,a1,a5
    80003962:	4108                	lw	a0,0(a0)
    80003964:	00000097          	auipc	ra,0x0
    80003968:	894080e7          	jalr	-1900(ra) # 800031f8 <bread>
    8000396c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000396e:	05850793          	addi	a5,a0,88
    80003972:	40d8                	lw	a4,4(s1)
    80003974:	8b3d                	andi	a4,a4,15
    80003976:	071a                	slli	a4,a4,0x6
    80003978:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000397a:	04449703          	lh	a4,68(s1)
    8000397e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003982:	04649703          	lh	a4,70(s1)
    80003986:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000398a:	04849703          	lh	a4,72(s1)
    8000398e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003992:	04a49703          	lh	a4,74(s1)
    80003996:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000399a:	44f8                	lw	a4,76(s1)
    8000399c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000399e:	03400613          	li	a2,52
    800039a2:	05048593          	addi	a1,s1,80
    800039a6:	00c78513          	addi	a0,a5,12
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	384080e7          	jalr	900(ra) # 80000d2e <memmove>
  log_write(bp);
    800039b2:	854a                	mv	a0,s2
    800039b4:	00001097          	auipc	ra,0x1
    800039b8:	bfe080e7          	jalr	-1026(ra) # 800045b2 <log_write>
  brelse(bp);
    800039bc:	854a                	mv	a0,s2
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	96a080e7          	jalr	-1686(ra) # 80003328 <brelse>
}
    800039c6:	60e2                	ld	ra,24(sp)
    800039c8:	6442                	ld	s0,16(sp)
    800039ca:	64a2                	ld	s1,8(sp)
    800039cc:	6902                	ld	s2,0(sp)
    800039ce:	6105                	addi	sp,sp,32
    800039d0:	8082                	ret

00000000800039d2 <idup>:
{
    800039d2:	1101                	addi	sp,sp,-32
    800039d4:	ec06                	sd	ra,24(sp)
    800039d6:	e822                	sd	s0,16(sp)
    800039d8:	e426                	sd	s1,8(sp)
    800039da:	1000                	addi	s0,sp,32
    800039dc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039de:	0001c517          	auipc	a0,0x1c
    800039e2:	4ba50513          	addi	a0,a0,1210 # 8001fe98 <itable>
    800039e6:	ffffd097          	auipc	ra,0xffffd
    800039ea:	1f0080e7          	jalr	496(ra) # 80000bd6 <acquire>
  ip->ref++;
    800039ee:	449c                	lw	a5,8(s1)
    800039f0:	2785                	addiw	a5,a5,1
    800039f2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039f4:	0001c517          	auipc	a0,0x1c
    800039f8:	4a450513          	addi	a0,a0,1188 # 8001fe98 <itable>
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	28e080e7          	jalr	654(ra) # 80000c8a <release>
}
    80003a04:	8526                	mv	a0,s1
    80003a06:	60e2                	ld	ra,24(sp)
    80003a08:	6442                	ld	s0,16(sp)
    80003a0a:	64a2                	ld	s1,8(sp)
    80003a0c:	6105                	addi	sp,sp,32
    80003a0e:	8082                	ret

0000000080003a10 <ilock>:
{
    80003a10:	1101                	addi	sp,sp,-32
    80003a12:	ec06                	sd	ra,24(sp)
    80003a14:	e822                	sd	s0,16(sp)
    80003a16:	e426                	sd	s1,8(sp)
    80003a18:	e04a                	sd	s2,0(sp)
    80003a1a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a1c:	c115                	beqz	a0,80003a40 <ilock+0x30>
    80003a1e:	84aa                	mv	s1,a0
    80003a20:	451c                	lw	a5,8(a0)
    80003a22:	00f05f63          	blez	a5,80003a40 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a26:	0541                	addi	a0,a0,16
    80003a28:	00001097          	auipc	ra,0x1
    80003a2c:	ca8080e7          	jalr	-856(ra) # 800046d0 <acquiresleep>
  if(ip->valid == 0){
    80003a30:	40bc                	lw	a5,64(s1)
    80003a32:	cf99                	beqz	a5,80003a50 <ilock+0x40>
}
    80003a34:	60e2                	ld	ra,24(sp)
    80003a36:	6442                	ld	s0,16(sp)
    80003a38:	64a2                	ld	s1,8(sp)
    80003a3a:	6902                	ld	s2,0(sp)
    80003a3c:	6105                	addi	sp,sp,32
    80003a3e:	8082                	ret
    panic("ilock");
    80003a40:	00005517          	auipc	a0,0x5
    80003a44:	bb050513          	addi	a0,a0,-1104 # 800085f0 <syscalls+0x1a0>
    80003a48:	ffffd097          	auipc	ra,0xffffd
    80003a4c:	af8080e7          	jalr	-1288(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a50:	40dc                	lw	a5,4(s1)
    80003a52:	0047d79b          	srliw	a5,a5,0x4
    80003a56:	0001c597          	auipc	a1,0x1c
    80003a5a:	43a5a583          	lw	a1,1082(a1) # 8001fe90 <sb+0x18>
    80003a5e:	9dbd                	addw	a1,a1,a5
    80003a60:	4088                	lw	a0,0(s1)
    80003a62:	fffff097          	auipc	ra,0xfffff
    80003a66:	796080e7          	jalr	1942(ra) # 800031f8 <bread>
    80003a6a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a6c:	05850593          	addi	a1,a0,88
    80003a70:	40dc                	lw	a5,4(s1)
    80003a72:	8bbd                	andi	a5,a5,15
    80003a74:	079a                	slli	a5,a5,0x6
    80003a76:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a78:	00059783          	lh	a5,0(a1)
    80003a7c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a80:	00259783          	lh	a5,2(a1)
    80003a84:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a88:	00459783          	lh	a5,4(a1)
    80003a8c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a90:	00659783          	lh	a5,6(a1)
    80003a94:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a98:	459c                	lw	a5,8(a1)
    80003a9a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a9c:	03400613          	li	a2,52
    80003aa0:	05b1                	addi	a1,a1,12
    80003aa2:	05048513          	addi	a0,s1,80
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	288080e7          	jalr	648(ra) # 80000d2e <memmove>
    brelse(bp);
    80003aae:	854a                	mv	a0,s2
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	878080e7          	jalr	-1928(ra) # 80003328 <brelse>
    ip->valid = 1;
    80003ab8:	4785                	li	a5,1
    80003aba:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003abc:	04449783          	lh	a5,68(s1)
    80003ac0:	fbb5                	bnez	a5,80003a34 <ilock+0x24>
      panic("ilock: no type");
    80003ac2:	00005517          	auipc	a0,0x5
    80003ac6:	b3650513          	addi	a0,a0,-1226 # 800085f8 <syscalls+0x1a8>
    80003aca:	ffffd097          	auipc	ra,0xffffd
    80003ace:	a76080e7          	jalr	-1418(ra) # 80000540 <panic>

0000000080003ad2 <iunlock>:
{
    80003ad2:	1101                	addi	sp,sp,-32
    80003ad4:	ec06                	sd	ra,24(sp)
    80003ad6:	e822                	sd	s0,16(sp)
    80003ad8:	e426                	sd	s1,8(sp)
    80003ada:	e04a                	sd	s2,0(sp)
    80003adc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ade:	c905                	beqz	a0,80003b0e <iunlock+0x3c>
    80003ae0:	84aa                	mv	s1,a0
    80003ae2:	01050913          	addi	s2,a0,16
    80003ae6:	854a                	mv	a0,s2
    80003ae8:	00001097          	auipc	ra,0x1
    80003aec:	c82080e7          	jalr	-894(ra) # 8000476a <holdingsleep>
    80003af0:	cd19                	beqz	a0,80003b0e <iunlock+0x3c>
    80003af2:	449c                	lw	a5,8(s1)
    80003af4:	00f05d63          	blez	a5,80003b0e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003af8:	854a                	mv	a0,s2
    80003afa:	00001097          	auipc	ra,0x1
    80003afe:	c2c080e7          	jalr	-980(ra) # 80004726 <releasesleep>
}
    80003b02:	60e2                	ld	ra,24(sp)
    80003b04:	6442                	ld	s0,16(sp)
    80003b06:	64a2                	ld	s1,8(sp)
    80003b08:	6902                	ld	s2,0(sp)
    80003b0a:	6105                	addi	sp,sp,32
    80003b0c:	8082                	ret
    panic("iunlock");
    80003b0e:	00005517          	auipc	a0,0x5
    80003b12:	afa50513          	addi	a0,a0,-1286 # 80008608 <syscalls+0x1b8>
    80003b16:	ffffd097          	auipc	ra,0xffffd
    80003b1a:	a2a080e7          	jalr	-1494(ra) # 80000540 <panic>

0000000080003b1e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b1e:	7179                	addi	sp,sp,-48
    80003b20:	f406                	sd	ra,40(sp)
    80003b22:	f022                	sd	s0,32(sp)
    80003b24:	ec26                	sd	s1,24(sp)
    80003b26:	e84a                	sd	s2,16(sp)
    80003b28:	e44e                	sd	s3,8(sp)
    80003b2a:	e052                	sd	s4,0(sp)
    80003b2c:	1800                	addi	s0,sp,48
    80003b2e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b30:	05050493          	addi	s1,a0,80
    80003b34:	08050913          	addi	s2,a0,128
    80003b38:	a021                	j	80003b40 <itrunc+0x22>
    80003b3a:	0491                	addi	s1,s1,4
    80003b3c:	01248d63          	beq	s1,s2,80003b56 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b40:	408c                	lw	a1,0(s1)
    80003b42:	dde5                	beqz	a1,80003b3a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b44:	0009a503          	lw	a0,0(s3)
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	8f6080e7          	jalr	-1802(ra) # 8000343e <bfree>
      ip->addrs[i] = 0;
    80003b50:	0004a023          	sw	zero,0(s1)
    80003b54:	b7dd                	j	80003b3a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b56:	0809a583          	lw	a1,128(s3)
    80003b5a:	e185                	bnez	a1,80003b7a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b5c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b60:	854e                	mv	a0,s3
    80003b62:	00000097          	auipc	ra,0x0
    80003b66:	de2080e7          	jalr	-542(ra) # 80003944 <iupdate>
}
    80003b6a:	70a2                	ld	ra,40(sp)
    80003b6c:	7402                	ld	s0,32(sp)
    80003b6e:	64e2                	ld	s1,24(sp)
    80003b70:	6942                	ld	s2,16(sp)
    80003b72:	69a2                	ld	s3,8(sp)
    80003b74:	6a02                	ld	s4,0(sp)
    80003b76:	6145                	addi	sp,sp,48
    80003b78:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b7a:	0009a503          	lw	a0,0(s3)
    80003b7e:	fffff097          	auipc	ra,0xfffff
    80003b82:	67a080e7          	jalr	1658(ra) # 800031f8 <bread>
    80003b86:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b88:	05850493          	addi	s1,a0,88
    80003b8c:	45850913          	addi	s2,a0,1112
    80003b90:	a021                	j	80003b98 <itrunc+0x7a>
    80003b92:	0491                	addi	s1,s1,4
    80003b94:	01248b63          	beq	s1,s2,80003baa <itrunc+0x8c>
      if(a[j])
    80003b98:	408c                	lw	a1,0(s1)
    80003b9a:	dde5                	beqz	a1,80003b92 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b9c:	0009a503          	lw	a0,0(s3)
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	89e080e7          	jalr	-1890(ra) # 8000343e <bfree>
    80003ba8:	b7ed                	j	80003b92 <itrunc+0x74>
    brelse(bp);
    80003baa:	8552                	mv	a0,s4
    80003bac:	fffff097          	auipc	ra,0xfffff
    80003bb0:	77c080e7          	jalr	1916(ra) # 80003328 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bb4:	0809a583          	lw	a1,128(s3)
    80003bb8:	0009a503          	lw	a0,0(s3)
    80003bbc:	00000097          	auipc	ra,0x0
    80003bc0:	882080e7          	jalr	-1918(ra) # 8000343e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003bc4:	0809a023          	sw	zero,128(s3)
    80003bc8:	bf51                	j	80003b5c <itrunc+0x3e>

0000000080003bca <iput>:
{
    80003bca:	1101                	addi	sp,sp,-32
    80003bcc:	ec06                	sd	ra,24(sp)
    80003bce:	e822                	sd	s0,16(sp)
    80003bd0:	e426                	sd	s1,8(sp)
    80003bd2:	e04a                	sd	s2,0(sp)
    80003bd4:	1000                	addi	s0,sp,32
    80003bd6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bd8:	0001c517          	auipc	a0,0x1c
    80003bdc:	2c050513          	addi	a0,a0,704 # 8001fe98 <itable>
    80003be0:	ffffd097          	auipc	ra,0xffffd
    80003be4:	ff6080e7          	jalr	-10(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003be8:	4498                	lw	a4,8(s1)
    80003bea:	4785                	li	a5,1
    80003bec:	02f70363          	beq	a4,a5,80003c12 <iput+0x48>
  ip->ref--;
    80003bf0:	449c                	lw	a5,8(s1)
    80003bf2:	37fd                	addiw	a5,a5,-1
    80003bf4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bf6:	0001c517          	auipc	a0,0x1c
    80003bfa:	2a250513          	addi	a0,a0,674 # 8001fe98 <itable>
    80003bfe:	ffffd097          	auipc	ra,0xffffd
    80003c02:	08c080e7          	jalr	140(ra) # 80000c8a <release>
}
    80003c06:	60e2                	ld	ra,24(sp)
    80003c08:	6442                	ld	s0,16(sp)
    80003c0a:	64a2                	ld	s1,8(sp)
    80003c0c:	6902                	ld	s2,0(sp)
    80003c0e:	6105                	addi	sp,sp,32
    80003c10:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c12:	40bc                	lw	a5,64(s1)
    80003c14:	dff1                	beqz	a5,80003bf0 <iput+0x26>
    80003c16:	04a49783          	lh	a5,74(s1)
    80003c1a:	fbf9                	bnez	a5,80003bf0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c1c:	01048913          	addi	s2,s1,16
    80003c20:	854a                	mv	a0,s2
    80003c22:	00001097          	auipc	ra,0x1
    80003c26:	aae080e7          	jalr	-1362(ra) # 800046d0 <acquiresleep>
    release(&itable.lock);
    80003c2a:	0001c517          	auipc	a0,0x1c
    80003c2e:	26e50513          	addi	a0,a0,622 # 8001fe98 <itable>
    80003c32:	ffffd097          	auipc	ra,0xffffd
    80003c36:	058080e7          	jalr	88(ra) # 80000c8a <release>
    itrunc(ip);
    80003c3a:	8526                	mv	a0,s1
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	ee2080e7          	jalr	-286(ra) # 80003b1e <itrunc>
    ip->type = 0;
    80003c44:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c48:	8526                	mv	a0,s1
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	cfa080e7          	jalr	-774(ra) # 80003944 <iupdate>
    ip->valid = 0;
    80003c52:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c56:	854a                	mv	a0,s2
    80003c58:	00001097          	auipc	ra,0x1
    80003c5c:	ace080e7          	jalr	-1330(ra) # 80004726 <releasesleep>
    acquire(&itable.lock);
    80003c60:	0001c517          	auipc	a0,0x1c
    80003c64:	23850513          	addi	a0,a0,568 # 8001fe98 <itable>
    80003c68:	ffffd097          	auipc	ra,0xffffd
    80003c6c:	f6e080e7          	jalr	-146(ra) # 80000bd6 <acquire>
    80003c70:	b741                	j	80003bf0 <iput+0x26>

0000000080003c72 <iunlockput>:
{
    80003c72:	1101                	addi	sp,sp,-32
    80003c74:	ec06                	sd	ra,24(sp)
    80003c76:	e822                	sd	s0,16(sp)
    80003c78:	e426                	sd	s1,8(sp)
    80003c7a:	1000                	addi	s0,sp,32
    80003c7c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	e54080e7          	jalr	-428(ra) # 80003ad2 <iunlock>
  iput(ip);
    80003c86:	8526                	mv	a0,s1
    80003c88:	00000097          	auipc	ra,0x0
    80003c8c:	f42080e7          	jalr	-190(ra) # 80003bca <iput>
}
    80003c90:	60e2                	ld	ra,24(sp)
    80003c92:	6442                	ld	s0,16(sp)
    80003c94:	64a2                	ld	s1,8(sp)
    80003c96:	6105                	addi	sp,sp,32
    80003c98:	8082                	ret

0000000080003c9a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c9a:	1141                	addi	sp,sp,-16
    80003c9c:	e422                	sd	s0,8(sp)
    80003c9e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ca0:	411c                	lw	a5,0(a0)
    80003ca2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ca4:	415c                	lw	a5,4(a0)
    80003ca6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ca8:	04451783          	lh	a5,68(a0)
    80003cac:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cb0:	04a51783          	lh	a5,74(a0)
    80003cb4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cb8:	04c56783          	lwu	a5,76(a0)
    80003cbc:	e99c                	sd	a5,16(a1)
}
    80003cbe:	6422                	ld	s0,8(sp)
    80003cc0:	0141                	addi	sp,sp,16
    80003cc2:	8082                	ret

0000000080003cc4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cc4:	457c                	lw	a5,76(a0)
    80003cc6:	0ed7e963          	bltu	a5,a3,80003db8 <readi+0xf4>
{
    80003cca:	7159                	addi	sp,sp,-112
    80003ccc:	f486                	sd	ra,104(sp)
    80003cce:	f0a2                	sd	s0,96(sp)
    80003cd0:	eca6                	sd	s1,88(sp)
    80003cd2:	e8ca                	sd	s2,80(sp)
    80003cd4:	e4ce                	sd	s3,72(sp)
    80003cd6:	e0d2                	sd	s4,64(sp)
    80003cd8:	fc56                	sd	s5,56(sp)
    80003cda:	f85a                	sd	s6,48(sp)
    80003cdc:	f45e                	sd	s7,40(sp)
    80003cde:	f062                	sd	s8,32(sp)
    80003ce0:	ec66                	sd	s9,24(sp)
    80003ce2:	e86a                	sd	s10,16(sp)
    80003ce4:	e46e                	sd	s11,8(sp)
    80003ce6:	1880                	addi	s0,sp,112
    80003ce8:	8b2a                	mv	s6,a0
    80003cea:	8bae                	mv	s7,a1
    80003cec:	8a32                	mv	s4,a2
    80003cee:	84b6                	mv	s1,a3
    80003cf0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003cf2:	9f35                	addw	a4,a4,a3
    return 0;
    80003cf4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cf6:	0ad76063          	bltu	a4,a3,80003d96 <readi+0xd2>
  if(off + n > ip->size)
    80003cfa:	00e7f463          	bgeu	a5,a4,80003d02 <readi+0x3e>
    n = ip->size - off;
    80003cfe:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d02:	0a0a8963          	beqz	s5,80003db4 <readi+0xf0>
    80003d06:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d08:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d0c:	5c7d                	li	s8,-1
    80003d0e:	a82d                	j	80003d48 <readi+0x84>
    80003d10:	020d1d93          	slli	s11,s10,0x20
    80003d14:	020ddd93          	srli	s11,s11,0x20
    80003d18:	05890613          	addi	a2,s2,88
    80003d1c:	86ee                	mv	a3,s11
    80003d1e:	963a                	add	a2,a2,a4
    80003d20:	85d2                	mv	a1,s4
    80003d22:	855e                	mv	a0,s7
    80003d24:	ffffe097          	auipc	ra,0xffffe
    80003d28:	7ac080e7          	jalr	1964(ra) # 800024d0 <either_copyout>
    80003d2c:	05850d63          	beq	a0,s8,80003d86 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d30:	854a                	mv	a0,s2
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	5f6080e7          	jalr	1526(ra) # 80003328 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d3a:	013d09bb          	addw	s3,s10,s3
    80003d3e:	009d04bb          	addw	s1,s10,s1
    80003d42:	9a6e                	add	s4,s4,s11
    80003d44:	0559f763          	bgeu	s3,s5,80003d92 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d48:	00a4d59b          	srliw	a1,s1,0xa
    80003d4c:	855a                	mv	a0,s6
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	89e080e7          	jalr	-1890(ra) # 800035ec <bmap>
    80003d56:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d5a:	cd85                	beqz	a1,80003d92 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d5c:	000b2503          	lw	a0,0(s6)
    80003d60:	fffff097          	auipc	ra,0xfffff
    80003d64:	498080e7          	jalr	1176(ra) # 800031f8 <bread>
    80003d68:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d6a:	3ff4f713          	andi	a4,s1,1023
    80003d6e:	40ec87bb          	subw	a5,s9,a4
    80003d72:	413a86bb          	subw	a3,s5,s3
    80003d76:	8d3e                	mv	s10,a5
    80003d78:	2781                	sext.w	a5,a5
    80003d7a:	0006861b          	sext.w	a2,a3
    80003d7e:	f8f679e3          	bgeu	a2,a5,80003d10 <readi+0x4c>
    80003d82:	8d36                	mv	s10,a3
    80003d84:	b771                	j	80003d10 <readi+0x4c>
      brelse(bp);
    80003d86:	854a                	mv	a0,s2
    80003d88:	fffff097          	auipc	ra,0xfffff
    80003d8c:	5a0080e7          	jalr	1440(ra) # 80003328 <brelse>
      tot = -1;
    80003d90:	59fd                	li	s3,-1
  }
  return tot;
    80003d92:	0009851b          	sext.w	a0,s3
}
    80003d96:	70a6                	ld	ra,104(sp)
    80003d98:	7406                	ld	s0,96(sp)
    80003d9a:	64e6                	ld	s1,88(sp)
    80003d9c:	6946                	ld	s2,80(sp)
    80003d9e:	69a6                	ld	s3,72(sp)
    80003da0:	6a06                	ld	s4,64(sp)
    80003da2:	7ae2                	ld	s5,56(sp)
    80003da4:	7b42                	ld	s6,48(sp)
    80003da6:	7ba2                	ld	s7,40(sp)
    80003da8:	7c02                	ld	s8,32(sp)
    80003daa:	6ce2                	ld	s9,24(sp)
    80003dac:	6d42                	ld	s10,16(sp)
    80003dae:	6da2                	ld	s11,8(sp)
    80003db0:	6165                	addi	sp,sp,112
    80003db2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003db4:	89d6                	mv	s3,s5
    80003db6:	bff1                	j	80003d92 <readi+0xce>
    return 0;
    80003db8:	4501                	li	a0,0
}
    80003dba:	8082                	ret

0000000080003dbc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dbc:	457c                	lw	a5,76(a0)
    80003dbe:	10d7e863          	bltu	a5,a3,80003ece <writei+0x112>
{
    80003dc2:	7159                	addi	sp,sp,-112
    80003dc4:	f486                	sd	ra,104(sp)
    80003dc6:	f0a2                	sd	s0,96(sp)
    80003dc8:	eca6                	sd	s1,88(sp)
    80003dca:	e8ca                	sd	s2,80(sp)
    80003dcc:	e4ce                	sd	s3,72(sp)
    80003dce:	e0d2                	sd	s4,64(sp)
    80003dd0:	fc56                	sd	s5,56(sp)
    80003dd2:	f85a                	sd	s6,48(sp)
    80003dd4:	f45e                	sd	s7,40(sp)
    80003dd6:	f062                	sd	s8,32(sp)
    80003dd8:	ec66                	sd	s9,24(sp)
    80003dda:	e86a                	sd	s10,16(sp)
    80003ddc:	e46e                	sd	s11,8(sp)
    80003dde:	1880                	addi	s0,sp,112
    80003de0:	8aaa                	mv	s5,a0
    80003de2:	8bae                	mv	s7,a1
    80003de4:	8a32                	mv	s4,a2
    80003de6:	8936                	mv	s2,a3
    80003de8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dea:	00e687bb          	addw	a5,a3,a4
    80003dee:	0ed7e263          	bltu	a5,a3,80003ed2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003df2:	00043737          	lui	a4,0x43
    80003df6:	0ef76063          	bltu	a4,a5,80003ed6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dfa:	0c0b0863          	beqz	s6,80003eca <writei+0x10e>
    80003dfe:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e00:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e04:	5c7d                	li	s8,-1
    80003e06:	a091                	j	80003e4a <writei+0x8e>
    80003e08:	020d1d93          	slli	s11,s10,0x20
    80003e0c:	020ddd93          	srli	s11,s11,0x20
    80003e10:	05848513          	addi	a0,s1,88
    80003e14:	86ee                	mv	a3,s11
    80003e16:	8652                	mv	a2,s4
    80003e18:	85de                	mv	a1,s7
    80003e1a:	953a                	add	a0,a0,a4
    80003e1c:	ffffe097          	auipc	ra,0xffffe
    80003e20:	70a080e7          	jalr	1802(ra) # 80002526 <either_copyin>
    80003e24:	07850263          	beq	a0,s8,80003e88 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e28:	8526                	mv	a0,s1
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	788080e7          	jalr	1928(ra) # 800045b2 <log_write>
    brelse(bp);
    80003e32:	8526                	mv	a0,s1
    80003e34:	fffff097          	auipc	ra,0xfffff
    80003e38:	4f4080e7          	jalr	1268(ra) # 80003328 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e3c:	013d09bb          	addw	s3,s10,s3
    80003e40:	012d093b          	addw	s2,s10,s2
    80003e44:	9a6e                	add	s4,s4,s11
    80003e46:	0569f663          	bgeu	s3,s6,80003e92 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e4a:	00a9559b          	srliw	a1,s2,0xa
    80003e4e:	8556                	mv	a0,s5
    80003e50:	fffff097          	auipc	ra,0xfffff
    80003e54:	79c080e7          	jalr	1948(ra) # 800035ec <bmap>
    80003e58:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e5c:	c99d                	beqz	a1,80003e92 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e5e:	000aa503          	lw	a0,0(s5)
    80003e62:	fffff097          	auipc	ra,0xfffff
    80003e66:	396080e7          	jalr	918(ra) # 800031f8 <bread>
    80003e6a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e6c:	3ff97713          	andi	a4,s2,1023
    80003e70:	40ec87bb          	subw	a5,s9,a4
    80003e74:	413b06bb          	subw	a3,s6,s3
    80003e78:	8d3e                	mv	s10,a5
    80003e7a:	2781                	sext.w	a5,a5
    80003e7c:	0006861b          	sext.w	a2,a3
    80003e80:	f8f674e3          	bgeu	a2,a5,80003e08 <writei+0x4c>
    80003e84:	8d36                	mv	s10,a3
    80003e86:	b749                	j	80003e08 <writei+0x4c>
      brelse(bp);
    80003e88:	8526                	mv	a0,s1
    80003e8a:	fffff097          	auipc	ra,0xfffff
    80003e8e:	49e080e7          	jalr	1182(ra) # 80003328 <brelse>
  }

  if(off > ip->size)
    80003e92:	04caa783          	lw	a5,76(s5)
    80003e96:	0127f463          	bgeu	a5,s2,80003e9e <writei+0xe2>
    ip->size = off;
    80003e9a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e9e:	8556                	mv	a0,s5
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	aa4080e7          	jalr	-1372(ra) # 80003944 <iupdate>

  return tot;
    80003ea8:	0009851b          	sext.w	a0,s3
}
    80003eac:	70a6                	ld	ra,104(sp)
    80003eae:	7406                	ld	s0,96(sp)
    80003eb0:	64e6                	ld	s1,88(sp)
    80003eb2:	6946                	ld	s2,80(sp)
    80003eb4:	69a6                	ld	s3,72(sp)
    80003eb6:	6a06                	ld	s4,64(sp)
    80003eb8:	7ae2                	ld	s5,56(sp)
    80003eba:	7b42                	ld	s6,48(sp)
    80003ebc:	7ba2                	ld	s7,40(sp)
    80003ebe:	7c02                	ld	s8,32(sp)
    80003ec0:	6ce2                	ld	s9,24(sp)
    80003ec2:	6d42                	ld	s10,16(sp)
    80003ec4:	6da2                	ld	s11,8(sp)
    80003ec6:	6165                	addi	sp,sp,112
    80003ec8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eca:	89da                	mv	s3,s6
    80003ecc:	bfc9                	j	80003e9e <writei+0xe2>
    return -1;
    80003ece:	557d                	li	a0,-1
}
    80003ed0:	8082                	ret
    return -1;
    80003ed2:	557d                	li	a0,-1
    80003ed4:	bfe1                	j	80003eac <writei+0xf0>
    return -1;
    80003ed6:	557d                	li	a0,-1
    80003ed8:	bfd1                	j	80003eac <writei+0xf0>

0000000080003eda <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003eda:	1141                	addi	sp,sp,-16
    80003edc:	e406                	sd	ra,8(sp)
    80003ede:	e022                	sd	s0,0(sp)
    80003ee0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ee2:	4639                	li	a2,14
    80003ee4:	ffffd097          	auipc	ra,0xffffd
    80003ee8:	ebe080e7          	jalr	-322(ra) # 80000da2 <strncmp>
}
    80003eec:	60a2                	ld	ra,8(sp)
    80003eee:	6402                	ld	s0,0(sp)
    80003ef0:	0141                	addi	sp,sp,16
    80003ef2:	8082                	ret

0000000080003ef4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ef4:	7139                	addi	sp,sp,-64
    80003ef6:	fc06                	sd	ra,56(sp)
    80003ef8:	f822                	sd	s0,48(sp)
    80003efa:	f426                	sd	s1,40(sp)
    80003efc:	f04a                	sd	s2,32(sp)
    80003efe:	ec4e                	sd	s3,24(sp)
    80003f00:	e852                	sd	s4,16(sp)
    80003f02:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f04:	04451703          	lh	a4,68(a0)
    80003f08:	4785                	li	a5,1
    80003f0a:	00f71a63          	bne	a4,a5,80003f1e <dirlookup+0x2a>
    80003f0e:	892a                	mv	s2,a0
    80003f10:	89ae                	mv	s3,a1
    80003f12:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f14:	457c                	lw	a5,76(a0)
    80003f16:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f18:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f1a:	e79d                	bnez	a5,80003f48 <dirlookup+0x54>
    80003f1c:	a8a5                	j	80003f94 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f1e:	00004517          	auipc	a0,0x4
    80003f22:	6f250513          	addi	a0,a0,1778 # 80008610 <syscalls+0x1c0>
    80003f26:	ffffc097          	auipc	ra,0xffffc
    80003f2a:	61a080e7          	jalr	1562(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003f2e:	00004517          	auipc	a0,0x4
    80003f32:	6fa50513          	addi	a0,a0,1786 # 80008628 <syscalls+0x1d8>
    80003f36:	ffffc097          	auipc	ra,0xffffc
    80003f3a:	60a080e7          	jalr	1546(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f3e:	24c1                	addiw	s1,s1,16
    80003f40:	04c92783          	lw	a5,76(s2)
    80003f44:	04f4f763          	bgeu	s1,a5,80003f92 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f48:	4741                	li	a4,16
    80003f4a:	86a6                	mv	a3,s1
    80003f4c:	fc040613          	addi	a2,s0,-64
    80003f50:	4581                	li	a1,0
    80003f52:	854a                	mv	a0,s2
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	d70080e7          	jalr	-656(ra) # 80003cc4 <readi>
    80003f5c:	47c1                	li	a5,16
    80003f5e:	fcf518e3          	bne	a0,a5,80003f2e <dirlookup+0x3a>
    if(de.inum == 0)
    80003f62:	fc045783          	lhu	a5,-64(s0)
    80003f66:	dfe1                	beqz	a5,80003f3e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f68:	fc240593          	addi	a1,s0,-62
    80003f6c:	854e                	mv	a0,s3
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	f6c080e7          	jalr	-148(ra) # 80003eda <namecmp>
    80003f76:	f561                	bnez	a0,80003f3e <dirlookup+0x4a>
      if(poff)
    80003f78:	000a0463          	beqz	s4,80003f80 <dirlookup+0x8c>
        *poff = off;
    80003f7c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f80:	fc045583          	lhu	a1,-64(s0)
    80003f84:	00092503          	lw	a0,0(s2)
    80003f88:	fffff097          	auipc	ra,0xfffff
    80003f8c:	74e080e7          	jalr	1870(ra) # 800036d6 <iget>
    80003f90:	a011                	j	80003f94 <dirlookup+0xa0>
  return 0;
    80003f92:	4501                	li	a0,0
}
    80003f94:	70e2                	ld	ra,56(sp)
    80003f96:	7442                	ld	s0,48(sp)
    80003f98:	74a2                	ld	s1,40(sp)
    80003f9a:	7902                	ld	s2,32(sp)
    80003f9c:	69e2                	ld	s3,24(sp)
    80003f9e:	6a42                	ld	s4,16(sp)
    80003fa0:	6121                	addi	sp,sp,64
    80003fa2:	8082                	ret

0000000080003fa4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fa4:	711d                	addi	sp,sp,-96
    80003fa6:	ec86                	sd	ra,88(sp)
    80003fa8:	e8a2                	sd	s0,80(sp)
    80003faa:	e4a6                	sd	s1,72(sp)
    80003fac:	e0ca                	sd	s2,64(sp)
    80003fae:	fc4e                	sd	s3,56(sp)
    80003fb0:	f852                	sd	s4,48(sp)
    80003fb2:	f456                	sd	s5,40(sp)
    80003fb4:	f05a                	sd	s6,32(sp)
    80003fb6:	ec5e                	sd	s7,24(sp)
    80003fb8:	e862                	sd	s8,16(sp)
    80003fba:	e466                	sd	s9,8(sp)
    80003fbc:	e06a                	sd	s10,0(sp)
    80003fbe:	1080                	addi	s0,sp,96
    80003fc0:	84aa                	mv	s1,a0
    80003fc2:	8b2e                	mv	s6,a1
    80003fc4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fc6:	00054703          	lbu	a4,0(a0)
    80003fca:	02f00793          	li	a5,47
    80003fce:	02f70363          	beq	a4,a5,80003ff4 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003fd2:	ffffe097          	auipc	ra,0xffffe
    80003fd6:	9da080e7          	jalr	-1574(ra) # 800019ac <myproc>
    80003fda:	15053503          	ld	a0,336(a0)
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	9f4080e7          	jalr	-1548(ra) # 800039d2 <idup>
    80003fe6:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003fe8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003fec:	4cb5                	li	s9,13
  len = path - s;
    80003fee:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ff0:	4c05                	li	s8,1
    80003ff2:	a87d                	j	800040b0 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003ff4:	4585                	li	a1,1
    80003ff6:	4505                	li	a0,1
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	6de080e7          	jalr	1758(ra) # 800036d6 <iget>
    80004000:	8a2a                	mv	s4,a0
    80004002:	b7dd                	j	80003fe8 <namex+0x44>
      iunlockput(ip);
    80004004:	8552                	mv	a0,s4
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	c6c080e7          	jalr	-916(ra) # 80003c72 <iunlockput>
      return 0;
    8000400e:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004010:	8552                	mv	a0,s4
    80004012:	60e6                	ld	ra,88(sp)
    80004014:	6446                	ld	s0,80(sp)
    80004016:	64a6                	ld	s1,72(sp)
    80004018:	6906                	ld	s2,64(sp)
    8000401a:	79e2                	ld	s3,56(sp)
    8000401c:	7a42                	ld	s4,48(sp)
    8000401e:	7aa2                	ld	s5,40(sp)
    80004020:	7b02                	ld	s6,32(sp)
    80004022:	6be2                	ld	s7,24(sp)
    80004024:	6c42                	ld	s8,16(sp)
    80004026:	6ca2                	ld	s9,8(sp)
    80004028:	6d02                	ld	s10,0(sp)
    8000402a:	6125                	addi	sp,sp,96
    8000402c:	8082                	ret
      iunlock(ip);
    8000402e:	8552                	mv	a0,s4
    80004030:	00000097          	auipc	ra,0x0
    80004034:	aa2080e7          	jalr	-1374(ra) # 80003ad2 <iunlock>
      return ip;
    80004038:	bfe1                	j	80004010 <namex+0x6c>
      iunlockput(ip);
    8000403a:	8552                	mv	a0,s4
    8000403c:	00000097          	auipc	ra,0x0
    80004040:	c36080e7          	jalr	-970(ra) # 80003c72 <iunlockput>
      return 0;
    80004044:	8a4e                	mv	s4,s3
    80004046:	b7e9                	j	80004010 <namex+0x6c>
  len = path - s;
    80004048:	40998633          	sub	a2,s3,s1
    8000404c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004050:	09acd863          	bge	s9,s10,800040e0 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004054:	4639                	li	a2,14
    80004056:	85a6                	mv	a1,s1
    80004058:	8556                	mv	a0,s5
    8000405a:	ffffd097          	auipc	ra,0xffffd
    8000405e:	cd4080e7          	jalr	-812(ra) # 80000d2e <memmove>
    80004062:	84ce                	mv	s1,s3
  while(*path == '/')
    80004064:	0004c783          	lbu	a5,0(s1)
    80004068:	01279763          	bne	a5,s2,80004076 <namex+0xd2>
    path++;
    8000406c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000406e:	0004c783          	lbu	a5,0(s1)
    80004072:	ff278de3          	beq	a5,s2,8000406c <namex+0xc8>
    ilock(ip);
    80004076:	8552                	mv	a0,s4
    80004078:	00000097          	auipc	ra,0x0
    8000407c:	998080e7          	jalr	-1640(ra) # 80003a10 <ilock>
    if(ip->type != T_DIR){
    80004080:	044a1783          	lh	a5,68(s4)
    80004084:	f98790e3          	bne	a5,s8,80004004 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004088:	000b0563          	beqz	s6,80004092 <namex+0xee>
    8000408c:	0004c783          	lbu	a5,0(s1)
    80004090:	dfd9                	beqz	a5,8000402e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004092:	865e                	mv	a2,s7
    80004094:	85d6                	mv	a1,s5
    80004096:	8552                	mv	a0,s4
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	e5c080e7          	jalr	-420(ra) # 80003ef4 <dirlookup>
    800040a0:	89aa                	mv	s3,a0
    800040a2:	dd41                	beqz	a0,8000403a <namex+0x96>
    iunlockput(ip);
    800040a4:	8552                	mv	a0,s4
    800040a6:	00000097          	auipc	ra,0x0
    800040aa:	bcc080e7          	jalr	-1076(ra) # 80003c72 <iunlockput>
    ip = next;
    800040ae:	8a4e                	mv	s4,s3
  while(*path == '/')
    800040b0:	0004c783          	lbu	a5,0(s1)
    800040b4:	01279763          	bne	a5,s2,800040c2 <namex+0x11e>
    path++;
    800040b8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040ba:	0004c783          	lbu	a5,0(s1)
    800040be:	ff278de3          	beq	a5,s2,800040b8 <namex+0x114>
  if(*path == 0)
    800040c2:	cb9d                	beqz	a5,800040f8 <namex+0x154>
  while(*path != '/' && *path != 0)
    800040c4:	0004c783          	lbu	a5,0(s1)
    800040c8:	89a6                	mv	s3,s1
  len = path - s;
    800040ca:	8d5e                	mv	s10,s7
    800040cc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800040ce:	01278963          	beq	a5,s2,800040e0 <namex+0x13c>
    800040d2:	dbbd                	beqz	a5,80004048 <namex+0xa4>
    path++;
    800040d4:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800040d6:	0009c783          	lbu	a5,0(s3)
    800040da:	ff279ce3          	bne	a5,s2,800040d2 <namex+0x12e>
    800040de:	b7ad                	j	80004048 <namex+0xa4>
    memmove(name, s, len);
    800040e0:	2601                	sext.w	a2,a2
    800040e2:	85a6                	mv	a1,s1
    800040e4:	8556                	mv	a0,s5
    800040e6:	ffffd097          	auipc	ra,0xffffd
    800040ea:	c48080e7          	jalr	-952(ra) # 80000d2e <memmove>
    name[len] = 0;
    800040ee:	9d56                	add	s10,s10,s5
    800040f0:	000d0023          	sb	zero,0(s10)
    800040f4:	84ce                	mv	s1,s3
    800040f6:	b7bd                	j	80004064 <namex+0xc0>
  if(nameiparent){
    800040f8:	f00b0ce3          	beqz	s6,80004010 <namex+0x6c>
    iput(ip);
    800040fc:	8552                	mv	a0,s4
    800040fe:	00000097          	auipc	ra,0x0
    80004102:	acc080e7          	jalr	-1332(ra) # 80003bca <iput>
    return 0;
    80004106:	4a01                	li	s4,0
    80004108:	b721                	j	80004010 <namex+0x6c>

000000008000410a <dirlink>:
{
    8000410a:	7139                	addi	sp,sp,-64
    8000410c:	fc06                	sd	ra,56(sp)
    8000410e:	f822                	sd	s0,48(sp)
    80004110:	f426                	sd	s1,40(sp)
    80004112:	f04a                	sd	s2,32(sp)
    80004114:	ec4e                	sd	s3,24(sp)
    80004116:	e852                	sd	s4,16(sp)
    80004118:	0080                	addi	s0,sp,64
    8000411a:	892a                	mv	s2,a0
    8000411c:	8a2e                	mv	s4,a1
    8000411e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004120:	4601                	li	a2,0
    80004122:	00000097          	auipc	ra,0x0
    80004126:	dd2080e7          	jalr	-558(ra) # 80003ef4 <dirlookup>
    8000412a:	e93d                	bnez	a0,800041a0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000412c:	04c92483          	lw	s1,76(s2)
    80004130:	c49d                	beqz	s1,8000415e <dirlink+0x54>
    80004132:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004134:	4741                	li	a4,16
    80004136:	86a6                	mv	a3,s1
    80004138:	fc040613          	addi	a2,s0,-64
    8000413c:	4581                	li	a1,0
    8000413e:	854a                	mv	a0,s2
    80004140:	00000097          	auipc	ra,0x0
    80004144:	b84080e7          	jalr	-1148(ra) # 80003cc4 <readi>
    80004148:	47c1                	li	a5,16
    8000414a:	06f51163          	bne	a0,a5,800041ac <dirlink+0xa2>
    if(de.inum == 0)
    8000414e:	fc045783          	lhu	a5,-64(s0)
    80004152:	c791                	beqz	a5,8000415e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004154:	24c1                	addiw	s1,s1,16
    80004156:	04c92783          	lw	a5,76(s2)
    8000415a:	fcf4ede3          	bltu	s1,a5,80004134 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000415e:	4639                	li	a2,14
    80004160:	85d2                	mv	a1,s4
    80004162:	fc240513          	addi	a0,s0,-62
    80004166:	ffffd097          	auipc	ra,0xffffd
    8000416a:	c78080e7          	jalr	-904(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000416e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004172:	4741                	li	a4,16
    80004174:	86a6                	mv	a3,s1
    80004176:	fc040613          	addi	a2,s0,-64
    8000417a:	4581                	li	a1,0
    8000417c:	854a                	mv	a0,s2
    8000417e:	00000097          	auipc	ra,0x0
    80004182:	c3e080e7          	jalr	-962(ra) # 80003dbc <writei>
    80004186:	1541                	addi	a0,a0,-16
    80004188:	00a03533          	snez	a0,a0
    8000418c:	40a00533          	neg	a0,a0
}
    80004190:	70e2                	ld	ra,56(sp)
    80004192:	7442                	ld	s0,48(sp)
    80004194:	74a2                	ld	s1,40(sp)
    80004196:	7902                	ld	s2,32(sp)
    80004198:	69e2                	ld	s3,24(sp)
    8000419a:	6a42                	ld	s4,16(sp)
    8000419c:	6121                	addi	sp,sp,64
    8000419e:	8082                	ret
    iput(ip);
    800041a0:	00000097          	auipc	ra,0x0
    800041a4:	a2a080e7          	jalr	-1494(ra) # 80003bca <iput>
    return -1;
    800041a8:	557d                	li	a0,-1
    800041aa:	b7dd                	j	80004190 <dirlink+0x86>
      panic("dirlink read");
    800041ac:	00004517          	auipc	a0,0x4
    800041b0:	48c50513          	addi	a0,a0,1164 # 80008638 <syscalls+0x1e8>
    800041b4:	ffffc097          	auipc	ra,0xffffc
    800041b8:	38c080e7          	jalr	908(ra) # 80000540 <panic>

00000000800041bc <namei>:

struct inode*
namei(char *path)
{
    800041bc:	1101                	addi	sp,sp,-32
    800041be:	ec06                	sd	ra,24(sp)
    800041c0:	e822                	sd	s0,16(sp)
    800041c2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041c4:	fe040613          	addi	a2,s0,-32
    800041c8:	4581                	li	a1,0
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	dda080e7          	jalr	-550(ra) # 80003fa4 <namex>
}
    800041d2:	60e2                	ld	ra,24(sp)
    800041d4:	6442                	ld	s0,16(sp)
    800041d6:	6105                	addi	sp,sp,32
    800041d8:	8082                	ret

00000000800041da <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041da:	1141                	addi	sp,sp,-16
    800041dc:	e406                	sd	ra,8(sp)
    800041de:	e022                	sd	s0,0(sp)
    800041e0:	0800                	addi	s0,sp,16
    800041e2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041e4:	4585                	li	a1,1
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	dbe080e7          	jalr	-578(ra) # 80003fa4 <namex>
}
    800041ee:	60a2                	ld	ra,8(sp)
    800041f0:	6402                	ld	s0,0(sp)
    800041f2:	0141                	addi	sp,sp,16
    800041f4:	8082                	ret

00000000800041f6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041f6:	1101                	addi	sp,sp,-32
    800041f8:	ec06                	sd	ra,24(sp)
    800041fa:	e822                	sd	s0,16(sp)
    800041fc:	e426                	sd	s1,8(sp)
    800041fe:	e04a                	sd	s2,0(sp)
    80004200:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004202:	0001d917          	auipc	s2,0x1d
    80004206:	73e90913          	addi	s2,s2,1854 # 80021940 <log>
    8000420a:	01892583          	lw	a1,24(s2)
    8000420e:	02892503          	lw	a0,40(s2)
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	fe6080e7          	jalr	-26(ra) # 800031f8 <bread>
    8000421a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000421c:	02c92683          	lw	a3,44(s2)
    80004220:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004222:	02d05863          	blez	a3,80004252 <write_head+0x5c>
    80004226:	0001d797          	auipc	a5,0x1d
    8000422a:	74a78793          	addi	a5,a5,1866 # 80021970 <log+0x30>
    8000422e:	05c50713          	addi	a4,a0,92
    80004232:	36fd                	addiw	a3,a3,-1
    80004234:	02069613          	slli	a2,a3,0x20
    80004238:	01e65693          	srli	a3,a2,0x1e
    8000423c:	0001d617          	auipc	a2,0x1d
    80004240:	73860613          	addi	a2,a2,1848 # 80021974 <log+0x34>
    80004244:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004246:	4390                	lw	a2,0(a5)
    80004248:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000424a:	0791                	addi	a5,a5,4
    8000424c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000424e:	fed79ce3          	bne	a5,a3,80004246 <write_head+0x50>
  }
  bwrite(buf);
    80004252:	8526                	mv	a0,s1
    80004254:	fffff097          	auipc	ra,0xfffff
    80004258:	096080e7          	jalr	150(ra) # 800032ea <bwrite>
  brelse(buf);
    8000425c:	8526                	mv	a0,s1
    8000425e:	fffff097          	auipc	ra,0xfffff
    80004262:	0ca080e7          	jalr	202(ra) # 80003328 <brelse>
}
    80004266:	60e2                	ld	ra,24(sp)
    80004268:	6442                	ld	s0,16(sp)
    8000426a:	64a2                	ld	s1,8(sp)
    8000426c:	6902                	ld	s2,0(sp)
    8000426e:	6105                	addi	sp,sp,32
    80004270:	8082                	ret

0000000080004272 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004272:	0001d797          	auipc	a5,0x1d
    80004276:	6fa7a783          	lw	a5,1786(a5) # 8002196c <log+0x2c>
    8000427a:	0af05d63          	blez	a5,80004334 <install_trans+0xc2>
{
    8000427e:	7139                	addi	sp,sp,-64
    80004280:	fc06                	sd	ra,56(sp)
    80004282:	f822                	sd	s0,48(sp)
    80004284:	f426                	sd	s1,40(sp)
    80004286:	f04a                	sd	s2,32(sp)
    80004288:	ec4e                	sd	s3,24(sp)
    8000428a:	e852                	sd	s4,16(sp)
    8000428c:	e456                	sd	s5,8(sp)
    8000428e:	e05a                	sd	s6,0(sp)
    80004290:	0080                	addi	s0,sp,64
    80004292:	8b2a                	mv	s6,a0
    80004294:	0001da97          	auipc	s5,0x1d
    80004298:	6dca8a93          	addi	s5,s5,1756 # 80021970 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000429c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000429e:	0001d997          	auipc	s3,0x1d
    800042a2:	6a298993          	addi	s3,s3,1698 # 80021940 <log>
    800042a6:	a00d                	j	800042c8 <install_trans+0x56>
    brelse(lbuf);
    800042a8:	854a                	mv	a0,s2
    800042aa:	fffff097          	auipc	ra,0xfffff
    800042ae:	07e080e7          	jalr	126(ra) # 80003328 <brelse>
    brelse(dbuf);
    800042b2:	8526                	mv	a0,s1
    800042b4:	fffff097          	auipc	ra,0xfffff
    800042b8:	074080e7          	jalr	116(ra) # 80003328 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042bc:	2a05                	addiw	s4,s4,1
    800042be:	0a91                	addi	s5,s5,4
    800042c0:	02c9a783          	lw	a5,44(s3)
    800042c4:	04fa5e63          	bge	s4,a5,80004320 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042c8:	0189a583          	lw	a1,24(s3)
    800042cc:	014585bb          	addw	a1,a1,s4
    800042d0:	2585                	addiw	a1,a1,1
    800042d2:	0289a503          	lw	a0,40(s3)
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	f22080e7          	jalr	-222(ra) # 800031f8 <bread>
    800042de:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042e0:	000aa583          	lw	a1,0(s5)
    800042e4:	0289a503          	lw	a0,40(s3)
    800042e8:	fffff097          	auipc	ra,0xfffff
    800042ec:	f10080e7          	jalr	-240(ra) # 800031f8 <bread>
    800042f0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042f2:	40000613          	li	a2,1024
    800042f6:	05890593          	addi	a1,s2,88
    800042fa:	05850513          	addi	a0,a0,88
    800042fe:	ffffd097          	auipc	ra,0xffffd
    80004302:	a30080e7          	jalr	-1488(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004306:	8526                	mv	a0,s1
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	fe2080e7          	jalr	-30(ra) # 800032ea <bwrite>
    if(recovering == 0)
    80004310:	f80b1ce3          	bnez	s6,800042a8 <install_trans+0x36>
      bunpin(dbuf);
    80004314:	8526                	mv	a0,s1
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	0ec080e7          	jalr	236(ra) # 80003402 <bunpin>
    8000431e:	b769                	j	800042a8 <install_trans+0x36>
}
    80004320:	70e2                	ld	ra,56(sp)
    80004322:	7442                	ld	s0,48(sp)
    80004324:	74a2                	ld	s1,40(sp)
    80004326:	7902                	ld	s2,32(sp)
    80004328:	69e2                	ld	s3,24(sp)
    8000432a:	6a42                	ld	s4,16(sp)
    8000432c:	6aa2                	ld	s5,8(sp)
    8000432e:	6b02                	ld	s6,0(sp)
    80004330:	6121                	addi	sp,sp,64
    80004332:	8082                	ret
    80004334:	8082                	ret

0000000080004336 <initlog>:
{
    80004336:	7179                	addi	sp,sp,-48
    80004338:	f406                	sd	ra,40(sp)
    8000433a:	f022                	sd	s0,32(sp)
    8000433c:	ec26                	sd	s1,24(sp)
    8000433e:	e84a                	sd	s2,16(sp)
    80004340:	e44e                	sd	s3,8(sp)
    80004342:	1800                	addi	s0,sp,48
    80004344:	892a                	mv	s2,a0
    80004346:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004348:	0001d497          	auipc	s1,0x1d
    8000434c:	5f848493          	addi	s1,s1,1528 # 80021940 <log>
    80004350:	00004597          	auipc	a1,0x4
    80004354:	2f858593          	addi	a1,a1,760 # 80008648 <syscalls+0x1f8>
    80004358:	8526                	mv	a0,s1
    8000435a:	ffffc097          	auipc	ra,0xffffc
    8000435e:	7ec080e7          	jalr	2028(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004362:	0149a583          	lw	a1,20(s3)
    80004366:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004368:	0109a783          	lw	a5,16(s3)
    8000436c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000436e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004372:	854a                	mv	a0,s2
    80004374:	fffff097          	auipc	ra,0xfffff
    80004378:	e84080e7          	jalr	-380(ra) # 800031f8 <bread>
  log.lh.n = lh->n;
    8000437c:	4d34                	lw	a3,88(a0)
    8000437e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004380:	02d05663          	blez	a3,800043ac <initlog+0x76>
    80004384:	05c50793          	addi	a5,a0,92
    80004388:	0001d717          	auipc	a4,0x1d
    8000438c:	5e870713          	addi	a4,a4,1512 # 80021970 <log+0x30>
    80004390:	36fd                	addiw	a3,a3,-1
    80004392:	02069613          	slli	a2,a3,0x20
    80004396:	01e65693          	srli	a3,a2,0x1e
    8000439a:	06050613          	addi	a2,a0,96
    8000439e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800043a0:	4390                	lw	a2,0(a5)
    800043a2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043a4:	0791                	addi	a5,a5,4
    800043a6:	0711                	addi	a4,a4,4
    800043a8:	fed79ce3          	bne	a5,a3,800043a0 <initlog+0x6a>
  brelse(buf);
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	f7c080e7          	jalr	-132(ra) # 80003328 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043b4:	4505                	li	a0,1
    800043b6:	00000097          	auipc	ra,0x0
    800043ba:	ebc080e7          	jalr	-324(ra) # 80004272 <install_trans>
  log.lh.n = 0;
    800043be:	0001d797          	auipc	a5,0x1d
    800043c2:	5a07a723          	sw	zero,1454(a5) # 8002196c <log+0x2c>
  write_head(); // clear the log
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	e30080e7          	jalr	-464(ra) # 800041f6 <write_head>
}
    800043ce:	70a2                	ld	ra,40(sp)
    800043d0:	7402                	ld	s0,32(sp)
    800043d2:	64e2                	ld	s1,24(sp)
    800043d4:	6942                	ld	s2,16(sp)
    800043d6:	69a2                	ld	s3,8(sp)
    800043d8:	6145                	addi	sp,sp,48
    800043da:	8082                	ret

00000000800043dc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043dc:	1101                	addi	sp,sp,-32
    800043de:	ec06                	sd	ra,24(sp)
    800043e0:	e822                	sd	s0,16(sp)
    800043e2:	e426                	sd	s1,8(sp)
    800043e4:	e04a                	sd	s2,0(sp)
    800043e6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043e8:	0001d517          	auipc	a0,0x1d
    800043ec:	55850513          	addi	a0,a0,1368 # 80021940 <log>
    800043f0:	ffffc097          	auipc	ra,0xffffc
    800043f4:	7e6080e7          	jalr	2022(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800043f8:	0001d497          	auipc	s1,0x1d
    800043fc:	54848493          	addi	s1,s1,1352 # 80021940 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004400:	4979                	li	s2,30
    80004402:	a039                	j	80004410 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004404:	85a6                	mv	a1,s1
    80004406:	8526                	mv	a0,s1
    80004408:	ffffe097          	auipc	ra,0xffffe
    8000440c:	cb4080e7          	jalr	-844(ra) # 800020bc <sleep>
    if(log.committing){
    80004410:	50dc                	lw	a5,36(s1)
    80004412:	fbed                	bnez	a5,80004404 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004414:	5098                	lw	a4,32(s1)
    80004416:	2705                	addiw	a4,a4,1
    80004418:	0007069b          	sext.w	a3,a4
    8000441c:	0027179b          	slliw	a5,a4,0x2
    80004420:	9fb9                	addw	a5,a5,a4
    80004422:	0017979b          	slliw	a5,a5,0x1
    80004426:	54d8                	lw	a4,44(s1)
    80004428:	9fb9                	addw	a5,a5,a4
    8000442a:	00f95963          	bge	s2,a5,8000443c <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000442e:	85a6                	mv	a1,s1
    80004430:	8526                	mv	a0,s1
    80004432:	ffffe097          	auipc	ra,0xffffe
    80004436:	c8a080e7          	jalr	-886(ra) # 800020bc <sleep>
    8000443a:	bfd9                	j	80004410 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000443c:	0001d517          	auipc	a0,0x1d
    80004440:	50450513          	addi	a0,a0,1284 # 80021940 <log>
    80004444:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	844080e7          	jalr	-1980(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000444e:	60e2                	ld	ra,24(sp)
    80004450:	6442                	ld	s0,16(sp)
    80004452:	64a2                	ld	s1,8(sp)
    80004454:	6902                	ld	s2,0(sp)
    80004456:	6105                	addi	sp,sp,32
    80004458:	8082                	ret

000000008000445a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000445a:	7139                	addi	sp,sp,-64
    8000445c:	fc06                	sd	ra,56(sp)
    8000445e:	f822                	sd	s0,48(sp)
    80004460:	f426                	sd	s1,40(sp)
    80004462:	f04a                	sd	s2,32(sp)
    80004464:	ec4e                	sd	s3,24(sp)
    80004466:	e852                	sd	s4,16(sp)
    80004468:	e456                	sd	s5,8(sp)
    8000446a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000446c:	0001d497          	auipc	s1,0x1d
    80004470:	4d448493          	addi	s1,s1,1236 # 80021940 <log>
    80004474:	8526                	mv	a0,s1
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	760080e7          	jalr	1888(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000447e:	509c                	lw	a5,32(s1)
    80004480:	37fd                	addiw	a5,a5,-1
    80004482:	0007891b          	sext.w	s2,a5
    80004486:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004488:	50dc                	lw	a5,36(s1)
    8000448a:	e7b9                	bnez	a5,800044d8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000448c:	04091e63          	bnez	s2,800044e8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004490:	0001d497          	auipc	s1,0x1d
    80004494:	4b048493          	addi	s1,s1,1200 # 80021940 <log>
    80004498:	4785                	li	a5,1
    8000449a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000449c:	8526                	mv	a0,s1
    8000449e:	ffffc097          	auipc	ra,0xffffc
    800044a2:	7ec080e7          	jalr	2028(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044a6:	54dc                	lw	a5,44(s1)
    800044a8:	06f04763          	bgtz	a5,80004516 <end_op+0xbc>
    acquire(&log.lock);
    800044ac:	0001d497          	auipc	s1,0x1d
    800044b0:	49448493          	addi	s1,s1,1172 # 80021940 <log>
    800044b4:	8526                	mv	a0,s1
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	720080e7          	jalr	1824(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800044be:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044c2:	8526                	mv	a0,s1
    800044c4:	ffffe097          	auipc	ra,0xffffe
    800044c8:	c5c080e7          	jalr	-932(ra) # 80002120 <wakeup>
    release(&log.lock);
    800044cc:	8526                	mv	a0,s1
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	7bc080e7          	jalr	1980(ra) # 80000c8a <release>
}
    800044d6:	a03d                	j	80004504 <end_op+0xaa>
    panic("log.committing");
    800044d8:	00004517          	auipc	a0,0x4
    800044dc:	17850513          	addi	a0,a0,376 # 80008650 <syscalls+0x200>
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	060080e7          	jalr	96(ra) # 80000540 <panic>
    wakeup(&log);
    800044e8:	0001d497          	auipc	s1,0x1d
    800044ec:	45848493          	addi	s1,s1,1112 # 80021940 <log>
    800044f0:	8526                	mv	a0,s1
    800044f2:	ffffe097          	auipc	ra,0xffffe
    800044f6:	c2e080e7          	jalr	-978(ra) # 80002120 <wakeup>
  release(&log.lock);
    800044fa:	8526                	mv	a0,s1
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	78e080e7          	jalr	1934(ra) # 80000c8a <release>
}
    80004504:	70e2                	ld	ra,56(sp)
    80004506:	7442                	ld	s0,48(sp)
    80004508:	74a2                	ld	s1,40(sp)
    8000450a:	7902                	ld	s2,32(sp)
    8000450c:	69e2                	ld	s3,24(sp)
    8000450e:	6a42                	ld	s4,16(sp)
    80004510:	6aa2                	ld	s5,8(sp)
    80004512:	6121                	addi	sp,sp,64
    80004514:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004516:	0001da97          	auipc	s5,0x1d
    8000451a:	45aa8a93          	addi	s5,s5,1114 # 80021970 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000451e:	0001da17          	auipc	s4,0x1d
    80004522:	422a0a13          	addi	s4,s4,1058 # 80021940 <log>
    80004526:	018a2583          	lw	a1,24(s4)
    8000452a:	012585bb          	addw	a1,a1,s2
    8000452e:	2585                	addiw	a1,a1,1
    80004530:	028a2503          	lw	a0,40(s4)
    80004534:	fffff097          	auipc	ra,0xfffff
    80004538:	cc4080e7          	jalr	-828(ra) # 800031f8 <bread>
    8000453c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000453e:	000aa583          	lw	a1,0(s5)
    80004542:	028a2503          	lw	a0,40(s4)
    80004546:	fffff097          	auipc	ra,0xfffff
    8000454a:	cb2080e7          	jalr	-846(ra) # 800031f8 <bread>
    8000454e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004550:	40000613          	li	a2,1024
    80004554:	05850593          	addi	a1,a0,88
    80004558:	05848513          	addi	a0,s1,88
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	7d2080e7          	jalr	2002(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004564:	8526                	mv	a0,s1
    80004566:	fffff097          	auipc	ra,0xfffff
    8000456a:	d84080e7          	jalr	-636(ra) # 800032ea <bwrite>
    brelse(from);
    8000456e:	854e                	mv	a0,s3
    80004570:	fffff097          	auipc	ra,0xfffff
    80004574:	db8080e7          	jalr	-584(ra) # 80003328 <brelse>
    brelse(to);
    80004578:	8526                	mv	a0,s1
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	dae080e7          	jalr	-594(ra) # 80003328 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004582:	2905                	addiw	s2,s2,1
    80004584:	0a91                	addi	s5,s5,4
    80004586:	02ca2783          	lw	a5,44(s4)
    8000458a:	f8f94ee3          	blt	s2,a5,80004526 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000458e:	00000097          	auipc	ra,0x0
    80004592:	c68080e7          	jalr	-920(ra) # 800041f6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004596:	4501                	li	a0,0
    80004598:	00000097          	auipc	ra,0x0
    8000459c:	cda080e7          	jalr	-806(ra) # 80004272 <install_trans>
    log.lh.n = 0;
    800045a0:	0001d797          	auipc	a5,0x1d
    800045a4:	3c07a623          	sw	zero,972(a5) # 8002196c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045a8:	00000097          	auipc	ra,0x0
    800045ac:	c4e080e7          	jalr	-946(ra) # 800041f6 <write_head>
    800045b0:	bdf5                	j	800044ac <end_op+0x52>

00000000800045b2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045b2:	1101                	addi	sp,sp,-32
    800045b4:	ec06                	sd	ra,24(sp)
    800045b6:	e822                	sd	s0,16(sp)
    800045b8:	e426                	sd	s1,8(sp)
    800045ba:	e04a                	sd	s2,0(sp)
    800045bc:	1000                	addi	s0,sp,32
    800045be:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045c0:	0001d917          	auipc	s2,0x1d
    800045c4:	38090913          	addi	s2,s2,896 # 80021940 <log>
    800045c8:	854a                	mv	a0,s2
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	60c080e7          	jalr	1548(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045d2:	02c92603          	lw	a2,44(s2)
    800045d6:	47f5                	li	a5,29
    800045d8:	06c7c563          	blt	a5,a2,80004642 <log_write+0x90>
    800045dc:	0001d797          	auipc	a5,0x1d
    800045e0:	3807a783          	lw	a5,896(a5) # 8002195c <log+0x1c>
    800045e4:	37fd                	addiw	a5,a5,-1
    800045e6:	04f65e63          	bge	a2,a5,80004642 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045ea:	0001d797          	auipc	a5,0x1d
    800045ee:	3767a783          	lw	a5,886(a5) # 80021960 <log+0x20>
    800045f2:	06f05063          	blez	a5,80004652 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045f6:	4781                	li	a5,0
    800045f8:	06c05563          	blez	a2,80004662 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045fc:	44cc                	lw	a1,12(s1)
    800045fe:	0001d717          	auipc	a4,0x1d
    80004602:	37270713          	addi	a4,a4,882 # 80021970 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004606:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004608:	4314                	lw	a3,0(a4)
    8000460a:	04b68c63          	beq	a3,a1,80004662 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000460e:	2785                	addiw	a5,a5,1
    80004610:	0711                	addi	a4,a4,4
    80004612:	fef61be3          	bne	a2,a5,80004608 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004616:	0621                	addi	a2,a2,8
    80004618:	060a                	slli	a2,a2,0x2
    8000461a:	0001d797          	auipc	a5,0x1d
    8000461e:	32678793          	addi	a5,a5,806 # 80021940 <log>
    80004622:	97b2                	add	a5,a5,a2
    80004624:	44d8                	lw	a4,12(s1)
    80004626:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004628:	8526                	mv	a0,s1
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	d9c080e7          	jalr	-612(ra) # 800033c6 <bpin>
    log.lh.n++;
    80004632:	0001d717          	auipc	a4,0x1d
    80004636:	30e70713          	addi	a4,a4,782 # 80021940 <log>
    8000463a:	575c                	lw	a5,44(a4)
    8000463c:	2785                	addiw	a5,a5,1
    8000463e:	d75c                	sw	a5,44(a4)
    80004640:	a82d                	j	8000467a <log_write+0xc8>
    panic("too big a transaction");
    80004642:	00004517          	auipc	a0,0x4
    80004646:	01e50513          	addi	a0,a0,30 # 80008660 <syscalls+0x210>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	ef6080e7          	jalr	-266(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004652:	00004517          	auipc	a0,0x4
    80004656:	02650513          	addi	a0,a0,38 # 80008678 <syscalls+0x228>
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	ee6080e7          	jalr	-282(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004662:	00878693          	addi	a3,a5,8
    80004666:	068a                	slli	a3,a3,0x2
    80004668:	0001d717          	auipc	a4,0x1d
    8000466c:	2d870713          	addi	a4,a4,728 # 80021940 <log>
    80004670:	9736                	add	a4,a4,a3
    80004672:	44d4                	lw	a3,12(s1)
    80004674:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004676:	faf609e3          	beq	a2,a5,80004628 <log_write+0x76>
  }
  release(&log.lock);
    8000467a:	0001d517          	auipc	a0,0x1d
    8000467e:	2c650513          	addi	a0,a0,710 # 80021940 <log>
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	608080e7          	jalr	1544(ra) # 80000c8a <release>
}
    8000468a:	60e2                	ld	ra,24(sp)
    8000468c:	6442                	ld	s0,16(sp)
    8000468e:	64a2                	ld	s1,8(sp)
    80004690:	6902                	ld	s2,0(sp)
    80004692:	6105                	addi	sp,sp,32
    80004694:	8082                	ret

0000000080004696 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004696:	1101                	addi	sp,sp,-32
    80004698:	ec06                	sd	ra,24(sp)
    8000469a:	e822                	sd	s0,16(sp)
    8000469c:	e426                	sd	s1,8(sp)
    8000469e:	e04a                	sd	s2,0(sp)
    800046a0:	1000                	addi	s0,sp,32
    800046a2:	84aa                	mv	s1,a0
    800046a4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046a6:	00004597          	auipc	a1,0x4
    800046aa:	ff258593          	addi	a1,a1,-14 # 80008698 <syscalls+0x248>
    800046ae:	0521                	addi	a0,a0,8
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	496080e7          	jalr	1174(ra) # 80000b46 <initlock>
  lk->name = name;
    800046b8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046bc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046c0:	0204a423          	sw	zero,40(s1)
}
    800046c4:	60e2                	ld	ra,24(sp)
    800046c6:	6442                	ld	s0,16(sp)
    800046c8:	64a2                	ld	s1,8(sp)
    800046ca:	6902                	ld	s2,0(sp)
    800046cc:	6105                	addi	sp,sp,32
    800046ce:	8082                	ret

00000000800046d0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046d0:	1101                	addi	sp,sp,-32
    800046d2:	ec06                	sd	ra,24(sp)
    800046d4:	e822                	sd	s0,16(sp)
    800046d6:	e426                	sd	s1,8(sp)
    800046d8:	e04a                	sd	s2,0(sp)
    800046da:	1000                	addi	s0,sp,32
    800046dc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046de:	00850913          	addi	s2,a0,8
    800046e2:	854a                	mv	a0,s2
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	4f2080e7          	jalr	1266(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800046ec:	409c                	lw	a5,0(s1)
    800046ee:	cb89                	beqz	a5,80004700 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046f0:	85ca                	mv	a1,s2
    800046f2:	8526                	mv	a0,s1
    800046f4:	ffffe097          	auipc	ra,0xffffe
    800046f8:	9c8080e7          	jalr	-1592(ra) # 800020bc <sleep>
  while (lk->locked) {
    800046fc:	409c                	lw	a5,0(s1)
    800046fe:	fbed                	bnez	a5,800046f0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004700:	4785                	li	a5,1
    80004702:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004704:	ffffd097          	auipc	ra,0xffffd
    80004708:	2a8080e7          	jalr	680(ra) # 800019ac <myproc>
    8000470c:	591c                	lw	a5,48(a0)
    8000470e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004710:	854a                	mv	a0,s2
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	578080e7          	jalr	1400(ra) # 80000c8a <release>
}
    8000471a:	60e2                	ld	ra,24(sp)
    8000471c:	6442                	ld	s0,16(sp)
    8000471e:	64a2                	ld	s1,8(sp)
    80004720:	6902                	ld	s2,0(sp)
    80004722:	6105                	addi	sp,sp,32
    80004724:	8082                	ret

0000000080004726 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004726:	1101                	addi	sp,sp,-32
    80004728:	ec06                	sd	ra,24(sp)
    8000472a:	e822                	sd	s0,16(sp)
    8000472c:	e426                	sd	s1,8(sp)
    8000472e:	e04a                	sd	s2,0(sp)
    80004730:	1000                	addi	s0,sp,32
    80004732:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004734:	00850913          	addi	s2,a0,8
    80004738:	854a                	mv	a0,s2
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	49c080e7          	jalr	1180(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004742:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004746:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000474a:	8526                	mv	a0,s1
    8000474c:	ffffe097          	auipc	ra,0xffffe
    80004750:	9d4080e7          	jalr	-1580(ra) # 80002120 <wakeup>
  release(&lk->lk);
    80004754:	854a                	mv	a0,s2
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	534080e7          	jalr	1332(ra) # 80000c8a <release>
}
    8000475e:	60e2                	ld	ra,24(sp)
    80004760:	6442                	ld	s0,16(sp)
    80004762:	64a2                	ld	s1,8(sp)
    80004764:	6902                	ld	s2,0(sp)
    80004766:	6105                	addi	sp,sp,32
    80004768:	8082                	ret

000000008000476a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000476a:	7179                	addi	sp,sp,-48
    8000476c:	f406                	sd	ra,40(sp)
    8000476e:	f022                	sd	s0,32(sp)
    80004770:	ec26                	sd	s1,24(sp)
    80004772:	e84a                	sd	s2,16(sp)
    80004774:	e44e                	sd	s3,8(sp)
    80004776:	1800                	addi	s0,sp,48
    80004778:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000477a:	00850913          	addi	s2,a0,8
    8000477e:	854a                	mv	a0,s2
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	456080e7          	jalr	1110(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004788:	409c                	lw	a5,0(s1)
    8000478a:	ef99                	bnez	a5,800047a8 <holdingsleep+0x3e>
    8000478c:	4481                	li	s1,0
  release(&lk->lk);
    8000478e:	854a                	mv	a0,s2
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	4fa080e7          	jalr	1274(ra) # 80000c8a <release>
  return r;
}
    80004798:	8526                	mv	a0,s1
    8000479a:	70a2                	ld	ra,40(sp)
    8000479c:	7402                	ld	s0,32(sp)
    8000479e:	64e2                	ld	s1,24(sp)
    800047a0:	6942                	ld	s2,16(sp)
    800047a2:	69a2                	ld	s3,8(sp)
    800047a4:	6145                	addi	sp,sp,48
    800047a6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047a8:	0284a983          	lw	s3,40(s1)
    800047ac:	ffffd097          	auipc	ra,0xffffd
    800047b0:	200080e7          	jalr	512(ra) # 800019ac <myproc>
    800047b4:	5904                	lw	s1,48(a0)
    800047b6:	413484b3          	sub	s1,s1,s3
    800047ba:	0014b493          	seqz	s1,s1
    800047be:	bfc1                	j	8000478e <holdingsleep+0x24>

00000000800047c0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047c0:	1141                	addi	sp,sp,-16
    800047c2:	e406                	sd	ra,8(sp)
    800047c4:	e022                	sd	s0,0(sp)
    800047c6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047c8:	00004597          	auipc	a1,0x4
    800047cc:	ee058593          	addi	a1,a1,-288 # 800086a8 <syscalls+0x258>
    800047d0:	0001d517          	auipc	a0,0x1d
    800047d4:	2b850513          	addi	a0,a0,696 # 80021a88 <ftable>
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	36e080e7          	jalr	878(ra) # 80000b46 <initlock>
}
    800047e0:	60a2                	ld	ra,8(sp)
    800047e2:	6402                	ld	s0,0(sp)
    800047e4:	0141                	addi	sp,sp,16
    800047e6:	8082                	ret

00000000800047e8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047e8:	1101                	addi	sp,sp,-32
    800047ea:	ec06                	sd	ra,24(sp)
    800047ec:	e822                	sd	s0,16(sp)
    800047ee:	e426                	sd	s1,8(sp)
    800047f0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047f2:	0001d517          	auipc	a0,0x1d
    800047f6:	29650513          	addi	a0,a0,662 # 80021a88 <ftable>
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	3dc080e7          	jalr	988(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004802:	0001d497          	auipc	s1,0x1d
    80004806:	29e48493          	addi	s1,s1,670 # 80021aa0 <ftable+0x18>
    8000480a:	0001e717          	auipc	a4,0x1e
    8000480e:	23670713          	addi	a4,a4,566 # 80022a40 <disk>
    if(f->ref == 0){
    80004812:	40dc                	lw	a5,4(s1)
    80004814:	cf99                	beqz	a5,80004832 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004816:	02848493          	addi	s1,s1,40
    8000481a:	fee49ce3          	bne	s1,a4,80004812 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000481e:	0001d517          	auipc	a0,0x1d
    80004822:	26a50513          	addi	a0,a0,618 # 80021a88 <ftable>
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	464080e7          	jalr	1124(ra) # 80000c8a <release>
  return 0;
    8000482e:	4481                	li	s1,0
    80004830:	a819                	j	80004846 <filealloc+0x5e>
      f->ref = 1;
    80004832:	4785                	li	a5,1
    80004834:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004836:	0001d517          	auipc	a0,0x1d
    8000483a:	25250513          	addi	a0,a0,594 # 80021a88 <ftable>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	44c080e7          	jalr	1100(ra) # 80000c8a <release>
}
    80004846:	8526                	mv	a0,s1
    80004848:	60e2                	ld	ra,24(sp)
    8000484a:	6442                	ld	s0,16(sp)
    8000484c:	64a2                	ld	s1,8(sp)
    8000484e:	6105                	addi	sp,sp,32
    80004850:	8082                	ret

0000000080004852 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004852:	1101                	addi	sp,sp,-32
    80004854:	ec06                	sd	ra,24(sp)
    80004856:	e822                	sd	s0,16(sp)
    80004858:	e426                	sd	s1,8(sp)
    8000485a:	1000                	addi	s0,sp,32
    8000485c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000485e:	0001d517          	auipc	a0,0x1d
    80004862:	22a50513          	addi	a0,a0,554 # 80021a88 <ftable>
    80004866:	ffffc097          	auipc	ra,0xffffc
    8000486a:	370080e7          	jalr	880(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000486e:	40dc                	lw	a5,4(s1)
    80004870:	02f05263          	blez	a5,80004894 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004874:	2785                	addiw	a5,a5,1
    80004876:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004878:	0001d517          	auipc	a0,0x1d
    8000487c:	21050513          	addi	a0,a0,528 # 80021a88 <ftable>
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	40a080e7          	jalr	1034(ra) # 80000c8a <release>
  return f;
}
    80004888:	8526                	mv	a0,s1
    8000488a:	60e2                	ld	ra,24(sp)
    8000488c:	6442                	ld	s0,16(sp)
    8000488e:	64a2                	ld	s1,8(sp)
    80004890:	6105                	addi	sp,sp,32
    80004892:	8082                	ret
    panic("filedup");
    80004894:	00004517          	auipc	a0,0x4
    80004898:	e1c50513          	addi	a0,a0,-484 # 800086b0 <syscalls+0x260>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	ca4080e7          	jalr	-860(ra) # 80000540 <panic>

00000000800048a4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048a4:	7139                	addi	sp,sp,-64
    800048a6:	fc06                	sd	ra,56(sp)
    800048a8:	f822                	sd	s0,48(sp)
    800048aa:	f426                	sd	s1,40(sp)
    800048ac:	f04a                	sd	s2,32(sp)
    800048ae:	ec4e                	sd	s3,24(sp)
    800048b0:	e852                	sd	s4,16(sp)
    800048b2:	e456                	sd	s5,8(sp)
    800048b4:	0080                	addi	s0,sp,64
    800048b6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048b8:	0001d517          	auipc	a0,0x1d
    800048bc:	1d050513          	addi	a0,a0,464 # 80021a88 <ftable>
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	316080e7          	jalr	790(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800048c8:	40dc                	lw	a5,4(s1)
    800048ca:	06f05163          	blez	a5,8000492c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048ce:	37fd                	addiw	a5,a5,-1
    800048d0:	0007871b          	sext.w	a4,a5
    800048d4:	c0dc                	sw	a5,4(s1)
    800048d6:	06e04363          	bgtz	a4,8000493c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048da:	0004a903          	lw	s2,0(s1)
    800048de:	0094ca83          	lbu	s5,9(s1)
    800048e2:	0104ba03          	ld	s4,16(s1)
    800048e6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048ea:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048ee:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048f2:	0001d517          	auipc	a0,0x1d
    800048f6:	19650513          	addi	a0,a0,406 # 80021a88 <ftable>
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	390080e7          	jalr	912(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004902:	4785                	li	a5,1
    80004904:	04f90d63          	beq	s2,a5,8000495e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004908:	3979                	addiw	s2,s2,-2
    8000490a:	4785                	li	a5,1
    8000490c:	0527e063          	bltu	a5,s2,8000494c <fileclose+0xa8>
    begin_op();
    80004910:	00000097          	auipc	ra,0x0
    80004914:	acc080e7          	jalr	-1332(ra) # 800043dc <begin_op>
    iput(ff.ip);
    80004918:	854e                	mv	a0,s3
    8000491a:	fffff097          	auipc	ra,0xfffff
    8000491e:	2b0080e7          	jalr	688(ra) # 80003bca <iput>
    end_op();
    80004922:	00000097          	auipc	ra,0x0
    80004926:	b38080e7          	jalr	-1224(ra) # 8000445a <end_op>
    8000492a:	a00d                	j	8000494c <fileclose+0xa8>
    panic("fileclose");
    8000492c:	00004517          	auipc	a0,0x4
    80004930:	d8c50513          	addi	a0,a0,-628 # 800086b8 <syscalls+0x268>
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	c0c080e7          	jalr	-1012(ra) # 80000540 <panic>
    release(&ftable.lock);
    8000493c:	0001d517          	auipc	a0,0x1d
    80004940:	14c50513          	addi	a0,a0,332 # 80021a88 <ftable>
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	346080e7          	jalr	838(ra) # 80000c8a <release>
  }
}
    8000494c:	70e2                	ld	ra,56(sp)
    8000494e:	7442                	ld	s0,48(sp)
    80004950:	74a2                	ld	s1,40(sp)
    80004952:	7902                	ld	s2,32(sp)
    80004954:	69e2                	ld	s3,24(sp)
    80004956:	6a42                	ld	s4,16(sp)
    80004958:	6aa2                	ld	s5,8(sp)
    8000495a:	6121                	addi	sp,sp,64
    8000495c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000495e:	85d6                	mv	a1,s5
    80004960:	8552                	mv	a0,s4
    80004962:	00000097          	auipc	ra,0x0
    80004966:	34c080e7          	jalr	844(ra) # 80004cae <pipeclose>
    8000496a:	b7cd                	j	8000494c <fileclose+0xa8>

000000008000496c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000496c:	715d                	addi	sp,sp,-80
    8000496e:	e486                	sd	ra,72(sp)
    80004970:	e0a2                	sd	s0,64(sp)
    80004972:	fc26                	sd	s1,56(sp)
    80004974:	f84a                	sd	s2,48(sp)
    80004976:	f44e                	sd	s3,40(sp)
    80004978:	0880                	addi	s0,sp,80
    8000497a:	84aa                	mv	s1,a0
    8000497c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000497e:	ffffd097          	auipc	ra,0xffffd
    80004982:	02e080e7          	jalr	46(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004986:	409c                	lw	a5,0(s1)
    80004988:	37f9                	addiw	a5,a5,-2
    8000498a:	4705                	li	a4,1
    8000498c:	04f76763          	bltu	a4,a5,800049da <filestat+0x6e>
    80004990:	892a                	mv	s2,a0
    ilock(f->ip);
    80004992:	6c88                	ld	a0,24(s1)
    80004994:	fffff097          	auipc	ra,0xfffff
    80004998:	07c080e7          	jalr	124(ra) # 80003a10 <ilock>
    stati(f->ip, &st);
    8000499c:	fb840593          	addi	a1,s0,-72
    800049a0:	6c88                	ld	a0,24(s1)
    800049a2:	fffff097          	auipc	ra,0xfffff
    800049a6:	2f8080e7          	jalr	760(ra) # 80003c9a <stati>
    iunlock(f->ip);
    800049aa:	6c88                	ld	a0,24(s1)
    800049ac:	fffff097          	auipc	ra,0xfffff
    800049b0:	126080e7          	jalr	294(ra) # 80003ad2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049b4:	46e1                	li	a3,24
    800049b6:	fb840613          	addi	a2,s0,-72
    800049ba:	85ce                	mv	a1,s3
    800049bc:	05093503          	ld	a0,80(s2)
    800049c0:	ffffd097          	auipc	ra,0xffffd
    800049c4:	cac080e7          	jalr	-852(ra) # 8000166c <copyout>
    800049c8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049cc:	60a6                	ld	ra,72(sp)
    800049ce:	6406                	ld	s0,64(sp)
    800049d0:	74e2                	ld	s1,56(sp)
    800049d2:	7942                	ld	s2,48(sp)
    800049d4:	79a2                	ld	s3,40(sp)
    800049d6:	6161                	addi	sp,sp,80
    800049d8:	8082                	ret
  return -1;
    800049da:	557d                	li	a0,-1
    800049dc:	bfc5                	j	800049cc <filestat+0x60>

00000000800049de <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049de:	7179                	addi	sp,sp,-48
    800049e0:	f406                	sd	ra,40(sp)
    800049e2:	f022                	sd	s0,32(sp)
    800049e4:	ec26                	sd	s1,24(sp)
    800049e6:	e84a                	sd	s2,16(sp)
    800049e8:	e44e                	sd	s3,8(sp)
    800049ea:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049ec:	00854783          	lbu	a5,8(a0)
    800049f0:	c3d5                	beqz	a5,80004a94 <fileread+0xb6>
    800049f2:	84aa                	mv	s1,a0
    800049f4:	89ae                	mv	s3,a1
    800049f6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049f8:	411c                	lw	a5,0(a0)
    800049fa:	4705                	li	a4,1
    800049fc:	04e78963          	beq	a5,a4,80004a4e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a00:	470d                	li	a4,3
    80004a02:	04e78d63          	beq	a5,a4,80004a5c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a06:	4709                	li	a4,2
    80004a08:	06e79e63          	bne	a5,a4,80004a84 <fileread+0xa6>
    ilock(f->ip);
    80004a0c:	6d08                	ld	a0,24(a0)
    80004a0e:	fffff097          	auipc	ra,0xfffff
    80004a12:	002080e7          	jalr	2(ra) # 80003a10 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a16:	874a                	mv	a4,s2
    80004a18:	5094                	lw	a3,32(s1)
    80004a1a:	864e                	mv	a2,s3
    80004a1c:	4585                	li	a1,1
    80004a1e:	6c88                	ld	a0,24(s1)
    80004a20:	fffff097          	auipc	ra,0xfffff
    80004a24:	2a4080e7          	jalr	676(ra) # 80003cc4 <readi>
    80004a28:	892a                	mv	s2,a0
    80004a2a:	00a05563          	blez	a0,80004a34 <fileread+0x56>
      f->off += r;
    80004a2e:	509c                	lw	a5,32(s1)
    80004a30:	9fa9                	addw	a5,a5,a0
    80004a32:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a34:	6c88                	ld	a0,24(s1)
    80004a36:	fffff097          	auipc	ra,0xfffff
    80004a3a:	09c080e7          	jalr	156(ra) # 80003ad2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a3e:	854a                	mv	a0,s2
    80004a40:	70a2                	ld	ra,40(sp)
    80004a42:	7402                	ld	s0,32(sp)
    80004a44:	64e2                	ld	s1,24(sp)
    80004a46:	6942                	ld	s2,16(sp)
    80004a48:	69a2                	ld	s3,8(sp)
    80004a4a:	6145                	addi	sp,sp,48
    80004a4c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a4e:	6908                	ld	a0,16(a0)
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	3c6080e7          	jalr	966(ra) # 80004e16 <piperead>
    80004a58:	892a                	mv	s2,a0
    80004a5a:	b7d5                	j	80004a3e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a5c:	02451783          	lh	a5,36(a0)
    80004a60:	03079693          	slli	a3,a5,0x30
    80004a64:	92c1                	srli	a3,a3,0x30
    80004a66:	4725                	li	a4,9
    80004a68:	02d76863          	bltu	a4,a3,80004a98 <fileread+0xba>
    80004a6c:	0792                	slli	a5,a5,0x4
    80004a6e:	0001d717          	auipc	a4,0x1d
    80004a72:	f7a70713          	addi	a4,a4,-134 # 800219e8 <devsw>
    80004a76:	97ba                	add	a5,a5,a4
    80004a78:	639c                	ld	a5,0(a5)
    80004a7a:	c38d                	beqz	a5,80004a9c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a7c:	4505                	li	a0,1
    80004a7e:	9782                	jalr	a5
    80004a80:	892a                	mv	s2,a0
    80004a82:	bf75                	j	80004a3e <fileread+0x60>
    panic("fileread");
    80004a84:	00004517          	auipc	a0,0x4
    80004a88:	c4450513          	addi	a0,a0,-956 # 800086c8 <syscalls+0x278>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	ab4080e7          	jalr	-1356(ra) # 80000540 <panic>
    return -1;
    80004a94:	597d                	li	s2,-1
    80004a96:	b765                	j	80004a3e <fileread+0x60>
      return -1;
    80004a98:	597d                	li	s2,-1
    80004a9a:	b755                	j	80004a3e <fileread+0x60>
    80004a9c:	597d                	li	s2,-1
    80004a9e:	b745                	j	80004a3e <fileread+0x60>

0000000080004aa0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004aa0:	715d                	addi	sp,sp,-80
    80004aa2:	e486                	sd	ra,72(sp)
    80004aa4:	e0a2                	sd	s0,64(sp)
    80004aa6:	fc26                	sd	s1,56(sp)
    80004aa8:	f84a                	sd	s2,48(sp)
    80004aaa:	f44e                	sd	s3,40(sp)
    80004aac:	f052                	sd	s4,32(sp)
    80004aae:	ec56                	sd	s5,24(sp)
    80004ab0:	e85a                	sd	s6,16(sp)
    80004ab2:	e45e                	sd	s7,8(sp)
    80004ab4:	e062                	sd	s8,0(sp)
    80004ab6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ab8:	00954783          	lbu	a5,9(a0)
    80004abc:	10078663          	beqz	a5,80004bc8 <filewrite+0x128>
    80004ac0:	892a                	mv	s2,a0
    80004ac2:	8b2e                	mv	s6,a1
    80004ac4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ac6:	411c                	lw	a5,0(a0)
    80004ac8:	4705                	li	a4,1
    80004aca:	02e78263          	beq	a5,a4,80004aee <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ace:	470d                	li	a4,3
    80004ad0:	02e78663          	beq	a5,a4,80004afc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ad4:	4709                	li	a4,2
    80004ad6:	0ee79163          	bne	a5,a4,80004bb8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ada:	0ac05d63          	blez	a2,80004b94 <filewrite+0xf4>
    int i = 0;
    80004ade:	4981                	li	s3,0
    80004ae0:	6b85                	lui	s7,0x1
    80004ae2:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ae6:	6c05                	lui	s8,0x1
    80004ae8:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004aec:	a861                	j	80004b84 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004aee:	6908                	ld	a0,16(a0)
    80004af0:	00000097          	auipc	ra,0x0
    80004af4:	22e080e7          	jalr	558(ra) # 80004d1e <pipewrite>
    80004af8:	8a2a                	mv	s4,a0
    80004afa:	a045                	j	80004b9a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004afc:	02451783          	lh	a5,36(a0)
    80004b00:	03079693          	slli	a3,a5,0x30
    80004b04:	92c1                	srli	a3,a3,0x30
    80004b06:	4725                	li	a4,9
    80004b08:	0cd76263          	bltu	a4,a3,80004bcc <filewrite+0x12c>
    80004b0c:	0792                	slli	a5,a5,0x4
    80004b0e:	0001d717          	auipc	a4,0x1d
    80004b12:	eda70713          	addi	a4,a4,-294 # 800219e8 <devsw>
    80004b16:	97ba                	add	a5,a5,a4
    80004b18:	679c                	ld	a5,8(a5)
    80004b1a:	cbdd                	beqz	a5,80004bd0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b1c:	4505                	li	a0,1
    80004b1e:	9782                	jalr	a5
    80004b20:	8a2a                	mv	s4,a0
    80004b22:	a8a5                	j	80004b9a <filewrite+0xfa>
    80004b24:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b28:	00000097          	auipc	ra,0x0
    80004b2c:	8b4080e7          	jalr	-1868(ra) # 800043dc <begin_op>
      ilock(f->ip);
    80004b30:	01893503          	ld	a0,24(s2)
    80004b34:	fffff097          	auipc	ra,0xfffff
    80004b38:	edc080e7          	jalr	-292(ra) # 80003a10 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b3c:	8756                	mv	a4,s5
    80004b3e:	02092683          	lw	a3,32(s2)
    80004b42:	01698633          	add	a2,s3,s6
    80004b46:	4585                	li	a1,1
    80004b48:	01893503          	ld	a0,24(s2)
    80004b4c:	fffff097          	auipc	ra,0xfffff
    80004b50:	270080e7          	jalr	624(ra) # 80003dbc <writei>
    80004b54:	84aa                	mv	s1,a0
    80004b56:	00a05763          	blez	a0,80004b64 <filewrite+0xc4>
        f->off += r;
    80004b5a:	02092783          	lw	a5,32(s2)
    80004b5e:	9fa9                	addw	a5,a5,a0
    80004b60:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b64:	01893503          	ld	a0,24(s2)
    80004b68:	fffff097          	auipc	ra,0xfffff
    80004b6c:	f6a080e7          	jalr	-150(ra) # 80003ad2 <iunlock>
      end_op();
    80004b70:	00000097          	auipc	ra,0x0
    80004b74:	8ea080e7          	jalr	-1814(ra) # 8000445a <end_op>

      if(r != n1){
    80004b78:	009a9f63          	bne	s5,s1,80004b96 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b7c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b80:	0149db63          	bge	s3,s4,80004b96 <filewrite+0xf6>
      int n1 = n - i;
    80004b84:	413a04bb          	subw	s1,s4,s3
    80004b88:	0004879b          	sext.w	a5,s1
    80004b8c:	f8fbdce3          	bge	s7,a5,80004b24 <filewrite+0x84>
    80004b90:	84e2                	mv	s1,s8
    80004b92:	bf49                	j	80004b24 <filewrite+0x84>
    int i = 0;
    80004b94:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b96:	013a1f63          	bne	s4,s3,80004bb4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b9a:	8552                	mv	a0,s4
    80004b9c:	60a6                	ld	ra,72(sp)
    80004b9e:	6406                	ld	s0,64(sp)
    80004ba0:	74e2                	ld	s1,56(sp)
    80004ba2:	7942                	ld	s2,48(sp)
    80004ba4:	79a2                	ld	s3,40(sp)
    80004ba6:	7a02                	ld	s4,32(sp)
    80004ba8:	6ae2                	ld	s5,24(sp)
    80004baa:	6b42                	ld	s6,16(sp)
    80004bac:	6ba2                	ld	s7,8(sp)
    80004bae:	6c02                	ld	s8,0(sp)
    80004bb0:	6161                	addi	sp,sp,80
    80004bb2:	8082                	ret
    ret = (i == n ? n : -1);
    80004bb4:	5a7d                	li	s4,-1
    80004bb6:	b7d5                	j	80004b9a <filewrite+0xfa>
    panic("filewrite");
    80004bb8:	00004517          	auipc	a0,0x4
    80004bbc:	b2050513          	addi	a0,a0,-1248 # 800086d8 <syscalls+0x288>
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	980080e7          	jalr	-1664(ra) # 80000540 <panic>
    return -1;
    80004bc8:	5a7d                	li	s4,-1
    80004bca:	bfc1                	j	80004b9a <filewrite+0xfa>
      return -1;
    80004bcc:	5a7d                	li	s4,-1
    80004bce:	b7f1                	j	80004b9a <filewrite+0xfa>
    80004bd0:	5a7d                	li	s4,-1
    80004bd2:	b7e1                	j	80004b9a <filewrite+0xfa>

0000000080004bd4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bd4:	7179                	addi	sp,sp,-48
    80004bd6:	f406                	sd	ra,40(sp)
    80004bd8:	f022                	sd	s0,32(sp)
    80004bda:	ec26                	sd	s1,24(sp)
    80004bdc:	e84a                	sd	s2,16(sp)
    80004bde:	e44e                	sd	s3,8(sp)
    80004be0:	e052                	sd	s4,0(sp)
    80004be2:	1800                	addi	s0,sp,48
    80004be4:	84aa                	mv	s1,a0
    80004be6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004be8:	0005b023          	sd	zero,0(a1)
    80004bec:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bf0:	00000097          	auipc	ra,0x0
    80004bf4:	bf8080e7          	jalr	-1032(ra) # 800047e8 <filealloc>
    80004bf8:	e088                	sd	a0,0(s1)
    80004bfa:	c551                	beqz	a0,80004c86 <pipealloc+0xb2>
    80004bfc:	00000097          	auipc	ra,0x0
    80004c00:	bec080e7          	jalr	-1044(ra) # 800047e8 <filealloc>
    80004c04:	00aa3023          	sd	a0,0(s4)
    80004c08:	c92d                	beqz	a0,80004c7a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	edc080e7          	jalr	-292(ra) # 80000ae6 <kalloc>
    80004c12:	892a                	mv	s2,a0
    80004c14:	c125                	beqz	a0,80004c74 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c16:	4985                	li	s3,1
    80004c18:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c1c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c20:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c24:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c28:	00004597          	auipc	a1,0x4
    80004c2c:	ac058593          	addi	a1,a1,-1344 # 800086e8 <syscalls+0x298>
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	f16080e7          	jalr	-234(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004c38:	609c                	ld	a5,0(s1)
    80004c3a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c3e:	609c                	ld	a5,0(s1)
    80004c40:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c44:	609c                	ld	a5,0(s1)
    80004c46:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c4a:	609c                	ld	a5,0(s1)
    80004c4c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c50:	000a3783          	ld	a5,0(s4)
    80004c54:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c58:	000a3783          	ld	a5,0(s4)
    80004c5c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c60:	000a3783          	ld	a5,0(s4)
    80004c64:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c68:	000a3783          	ld	a5,0(s4)
    80004c6c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c70:	4501                	li	a0,0
    80004c72:	a025                	j	80004c9a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c74:	6088                	ld	a0,0(s1)
    80004c76:	e501                	bnez	a0,80004c7e <pipealloc+0xaa>
    80004c78:	a039                	j	80004c86 <pipealloc+0xb2>
    80004c7a:	6088                	ld	a0,0(s1)
    80004c7c:	c51d                	beqz	a0,80004caa <pipealloc+0xd6>
    fileclose(*f0);
    80004c7e:	00000097          	auipc	ra,0x0
    80004c82:	c26080e7          	jalr	-986(ra) # 800048a4 <fileclose>
  if(*f1)
    80004c86:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c8a:	557d                	li	a0,-1
  if(*f1)
    80004c8c:	c799                	beqz	a5,80004c9a <pipealloc+0xc6>
    fileclose(*f1);
    80004c8e:	853e                	mv	a0,a5
    80004c90:	00000097          	auipc	ra,0x0
    80004c94:	c14080e7          	jalr	-1004(ra) # 800048a4 <fileclose>
  return -1;
    80004c98:	557d                	li	a0,-1
}
    80004c9a:	70a2                	ld	ra,40(sp)
    80004c9c:	7402                	ld	s0,32(sp)
    80004c9e:	64e2                	ld	s1,24(sp)
    80004ca0:	6942                	ld	s2,16(sp)
    80004ca2:	69a2                	ld	s3,8(sp)
    80004ca4:	6a02                	ld	s4,0(sp)
    80004ca6:	6145                	addi	sp,sp,48
    80004ca8:	8082                	ret
  return -1;
    80004caa:	557d                	li	a0,-1
    80004cac:	b7fd                	j	80004c9a <pipealloc+0xc6>

0000000080004cae <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004cae:	1101                	addi	sp,sp,-32
    80004cb0:	ec06                	sd	ra,24(sp)
    80004cb2:	e822                	sd	s0,16(sp)
    80004cb4:	e426                	sd	s1,8(sp)
    80004cb6:	e04a                	sd	s2,0(sp)
    80004cb8:	1000                	addi	s0,sp,32
    80004cba:	84aa                	mv	s1,a0
    80004cbc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	f18080e7          	jalr	-232(ra) # 80000bd6 <acquire>
  if(writable){
    80004cc6:	02090d63          	beqz	s2,80004d00 <pipeclose+0x52>
    pi->writeopen = 0;
    80004cca:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cce:	21848513          	addi	a0,s1,536
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	44e080e7          	jalr	1102(ra) # 80002120 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cda:	2204b783          	ld	a5,544(s1)
    80004cde:	eb95                	bnez	a5,80004d12 <pipeclose+0x64>
    release(&pi->lock);
    80004ce0:	8526                	mv	a0,s1
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	fa8080e7          	jalr	-88(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004cea:	8526                	mv	a0,s1
    80004cec:	ffffc097          	auipc	ra,0xffffc
    80004cf0:	cfc080e7          	jalr	-772(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004cf4:	60e2                	ld	ra,24(sp)
    80004cf6:	6442                	ld	s0,16(sp)
    80004cf8:	64a2                	ld	s1,8(sp)
    80004cfa:	6902                	ld	s2,0(sp)
    80004cfc:	6105                	addi	sp,sp,32
    80004cfe:	8082                	ret
    pi->readopen = 0;
    80004d00:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d04:	21c48513          	addi	a0,s1,540
    80004d08:	ffffd097          	auipc	ra,0xffffd
    80004d0c:	418080e7          	jalr	1048(ra) # 80002120 <wakeup>
    80004d10:	b7e9                	j	80004cda <pipeclose+0x2c>
    release(&pi->lock);
    80004d12:	8526                	mv	a0,s1
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	f76080e7          	jalr	-138(ra) # 80000c8a <release>
}
    80004d1c:	bfe1                	j	80004cf4 <pipeclose+0x46>

0000000080004d1e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d1e:	711d                	addi	sp,sp,-96
    80004d20:	ec86                	sd	ra,88(sp)
    80004d22:	e8a2                	sd	s0,80(sp)
    80004d24:	e4a6                	sd	s1,72(sp)
    80004d26:	e0ca                	sd	s2,64(sp)
    80004d28:	fc4e                	sd	s3,56(sp)
    80004d2a:	f852                	sd	s4,48(sp)
    80004d2c:	f456                	sd	s5,40(sp)
    80004d2e:	f05a                	sd	s6,32(sp)
    80004d30:	ec5e                	sd	s7,24(sp)
    80004d32:	e862                	sd	s8,16(sp)
    80004d34:	1080                	addi	s0,sp,96
    80004d36:	84aa                	mv	s1,a0
    80004d38:	8aae                	mv	s5,a1
    80004d3a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	c70080e7          	jalr	-912(ra) # 800019ac <myproc>
    80004d44:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d46:	8526                	mv	a0,s1
    80004d48:	ffffc097          	auipc	ra,0xffffc
    80004d4c:	e8e080e7          	jalr	-370(ra) # 80000bd6 <acquire>
  while(i < n){
    80004d50:	0b405663          	blez	s4,80004dfc <pipewrite+0xde>
  int i = 0;
    80004d54:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d56:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d58:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d5c:	21c48b93          	addi	s7,s1,540
    80004d60:	a089                	j	80004da2 <pipewrite+0x84>
      release(&pi->lock);
    80004d62:	8526                	mv	a0,s1
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	f26080e7          	jalr	-218(ra) # 80000c8a <release>
      return -1;
    80004d6c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d6e:	854a                	mv	a0,s2
    80004d70:	60e6                	ld	ra,88(sp)
    80004d72:	6446                	ld	s0,80(sp)
    80004d74:	64a6                	ld	s1,72(sp)
    80004d76:	6906                	ld	s2,64(sp)
    80004d78:	79e2                	ld	s3,56(sp)
    80004d7a:	7a42                	ld	s4,48(sp)
    80004d7c:	7aa2                	ld	s5,40(sp)
    80004d7e:	7b02                	ld	s6,32(sp)
    80004d80:	6be2                	ld	s7,24(sp)
    80004d82:	6c42                	ld	s8,16(sp)
    80004d84:	6125                	addi	sp,sp,96
    80004d86:	8082                	ret
      wakeup(&pi->nread);
    80004d88:	8562                	mv	a0,s8
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	396080e7          	jalr	918(ra) # 80002120 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d92:	85a6                	mv	a1,s1
    80004d94:	855e                	mv	a0,s7
    80004d96:	ffffd097          	auipc	ra,0xffffd
    80004d9a:	326080e7          	jalr	806(ra) # 800020bc <sleep>
  while(i < n){
    80004d9e:	07495063          	bge	s2,s4,80004dfe <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004da2:	2204a783          	lw	a5,544(s1)
    80004da6:	dfd5                	beqz	a5,80004d62 <pipewrite+0x44>
    80004da8:	854e                	mv	a0,s3
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	5c6080e7          	jalr	1478(ra) # 80002370 <killed>
    80004db2:	f945                	bnez	a0,80004d62 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004db4:	2184a783          	lw	a5,536(s1)
    80004db8:	21c4a703          	lw	a4,540(s1)
    80004dbc:	2007879b          	addiw	a5,a5,512
    80004dc0:	fcf704e3          	beq	a4,a5,80004d88 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dc4:	4685                	li	a3,1
    80004dc6:	01590633          	add	a2,s2,s5
    80004dca:	faf40593          	addi	a1,s0,-81
    80004dce:	0509b503          	ld	a0,80(s3)
    80004dd2:	ffffd097          	auipc	ra,0xffffd
    80004dd6:	926080e7          	jalr	-1754(ra) # 800016f8 <copyin>
    80004dda:	03650263          	beq	a0,s6,80004dfe <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dde:	21c4a783          	lw	a5,540(s1)
    80004de2:	0017871b          	addiw	a4,a5,1
    80004de6:	20e4ae23          	sw	a4,540(s1)
    80004dea:	1ff7f793          	andi	a5,a5,511
    80004dee:	97a6                	add	a5,a5,s1
    80004df0:	faf44703          	lbu	a4,-81(s0)
    80004df4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004df8:	2905                	addiw	s2,s2,1
    80004dfa:	b755                	j	80004d9e <pipewrite+0x80>
  int i = 0;
    80004dfc:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004dfe:	21848513          	addi	a0,s1,536
    80004e02:	ffffd097          	auipc	ra,0xffffd
    80004e06:	31e080e7          	jalr	798(ra) # 80002120 <wakeup>
  release(&pi->lock);
    80004e0a:	8526                	mv	a0,s1
    80004e0c:	ffffc097          	auipc	ra,0xffffc
    80004e10:	e7e080e7          	jalr	-386(ra) # 80000c8a <release>
  return i;
    80004e14:	bfa9                	j	80004d6e <pipewrite+0x50>

0000000080004e16 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e16:	715d                	addi	sp,sp,-80
    80004e18:	e486                	sd	ra,72(sp)
    80004e1a:	e0a2                	sd	s0,64(sp)
    80004e1c:	fc26                	sd	s1,56(sp)
    80004e1e:	f84a                	sd	s2,48(sp)
    80004e20:	f44e                	sd	s3,40(sp)
    80004e22:	f052                	sd	s4,32(sp)
    80004e24:	ec56                	sd	s5,24(sp)
    80004e26:	e85a                	sd	s6,16(sp)
    80004e28:	0880                	addi	s0,sp,80
    80004e2a:	84aa                	mv	s1,a0
    80004e2c:	892e                	mv	s2,a1
    80004e2e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e30:	ffffd097          	auipc	ra,0xffffd
    80004e34:	b7c080e7          	jalr	-1156(ra) # 800019ac <myproc>
    80004e38:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e3a:	8526                	mv	a0,s1
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	d9a080e7          	jalr	-614(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e44:	2184a703          	lw	a4,536(s1)
    80004e48:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e4c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e50:	02f71763          	bne	a4,a5,80004e7e <piperead+0x68>
    80004e54:	2244a783          	lw	a5,548(s1)
    80004e58:	c39d                	beqz	a5,80004e7e <piperead+0x68>
    if(killed(pr)){
    80004e5a:	8552                	mv	a0,s4
    80004e5c:	ffffd097          	auipc	ra,0xffffd
    80004e60:	514080e7          	jalr	1300(ra) # 80002370 <killed>
    80004e64:	e949                	bnez	a0,80004ef6 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e66:	85a6                	mv	a1,s1
    80004e68:	854e                	mv	a0,s3
    80004e6a:	ffffd097          	auipc	ra,0xffffd
    80004e6e:	252080e7          	jalr	594(ra) # 800020bc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e72:	2184a703          	lw	a4,536(s1)
    80004e76:	21c4a783          	lw	a5,540(s1)
    80004e7a:	fcf70de3          	beq	a4,a5,80004e54 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e7e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e80:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e82:	05505463          	blez	s5,80004eca <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004e86:	2184a783          	lw	a5,536(s1)
    80004e8a:	21c4a703          	lw	a4,540(s1)
    80004e8e:	02f70e63          	beq	a4,a5,80004eca <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e92:	0017871b          	addiw	a4,a5,1
    80004e96:	20e4ac23          	sw	a4,536(s1)
    80004e9a:	1ff7f793          	andi	a5,a5,511
    80004e9e:	97a6                	add	a5,a5,s1
    80004ea0:	0187c783          	lbu	a5,24(a5)
    80004ea4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ea8:	4685                	li	a3,1
    80004eaa:	fbf40613          	addi	a2,s0,-65
    80004eae:	85ca                	mv	a1,s2
    80004eb0:	050a3503          	ld	a0,80(s4)
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	7b8080e7          	jalr	1976(ra) # 8000166c <copyout>
    80004ebc:	01650763          	beq	a0,s6,80004eca <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ec0:	2985                	addiw	s3,s3,1
    80004ec2:	0905                	addi	s2,s2,1
    80004ec4:	fd3a91e3          	bne	s5,s3,80004e86 <piperead+0x70>
    80004ec8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004eca:	21c48513          	addi	a0,s1,540
    80004ece:	ffffd097          	auipc	ra,0xffffd
    80004ed2:	252080e7          	jalr	594(ra) # 80002120 <wakeup>
  release(&pi->lock);
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	db2080e7          	jalr	-590(ra) # 80000c8a <release>
  return i;
}
    80004ee0:	854e                	mv	a0,s3
    80004ee2:	60a6                	ld	ra,72(sp)
    80004ee4:	6406                	ld	s0,64(sp)
    80004ee6:	74e2                	ld	s1,56(sp)
    80004ee8:	7942                	ld	s2,48(sp)
    80004eea:	79a2                	ld	s3,40(sp)
    80004eec:	7a02                	ld	s4,32(sp)
    80004eee:	6ae2                	ld	s5,24(sp)
    80004ef0:	6b42                	ld	s6,16(sp)
    80004ef2:	6161                	addi	sp,sp,80
    80004ef4:	8082                	ret
      release(&pi->lock);
    80004ef6:	8526                	mv	a0,s1
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	d92080e7          	jalr	-622(ra) # 80000c8a <release>
      return -1;
    80004f00:	59fd                	li	s3,-1
    80004f02:	bff9                	j	80004ee0 <piperead+0xca>

0000000080004f04 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f04:	1141                	addi	sp,sp,-16
    80004f06:	e422                	sd	s0,8(sp)
    80004f08:	0800                	addi	s0,sp,16
    80004f0a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f0c:	8905                	andi	a0,a0,1
    80004f0e:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004f10:	8b89                	andi	a5,a5,2
    80004f12:	c399                	beqz	a5,80004f18 <flags2perm+0x14>
      perm |= PTE_W;
    80004f14:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f18:	6422                	ld	s0,8(sp)
    80004f1a:	0141                	addi	sp,sp,16
    80004f1c:	8082                	ret

0000000080004f1e <exec>:

int
exec(char *path, char **argv)
{
    80004f1e:	de010113          	addi	sp,sp,-544
    80004f22:	20113c23          	sd	ra,536(sp)
    80004f26:	20813823          	sd	s0,528(sp)
    80004f2a:	20913423          	sd	s1,520(sp)
    80004f2e:	21213023          	sd	s2,512(sp)
    80004f32:	ffce                	sd	s3,504(sp)
    80004f34:	fbd2                	sd	s4,496(sp)
    80004f36:	f7d6                	sd	s5,488(sp)
    80004f38:	f3da                	sd	s6,480(sp)
    80004f3a:	efde                	sd	s7,472(sp)
    80004f3c:	ebe2                	sd	s8,464(sp)
    80004f3e:	e7e6                	sd	s9,456(sp)
    80004f40:	e3ea                	sd	s10,448(sp)
    80004f42:	ff6e                	sd	s11,440(sp)
    80004f44:	1400                	addi	s0,sp,544
    80004f46:	892a                	mv	s2,a0
    80004f48:	dea43423          	sd	a0,-536(s0)
    80004f4c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f50:	ffffd097          	auipc	ra,0xffffd
    80004f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80004f58:	84aa                	mv	s1,a0

  begin_op();
    80004f5a:	fffff097          	auipc	ra,0xfffff
    80004f5e:	482080e7          	jalr	1154(ra) # 800043dc <begin_op>

  if((ip = namei(path)) == 0){
    80004f62:	854a                	mv	a0,s2
    80004f64:	fffff097          	auipc	ra,0xfffff
    80004f68:	258080e7          	jalr	600(ra) # 800041bc <namei>
    80004f6c:	c93d                	beqz	a0,80004fe2 <exec+0xc4>
    80004f6e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f70:	fffff097          	auipc	ra,0xfffff
    80004f74:	aa0080e7          	jalr	-1376(ra) # 80003a10 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f78:	04000713          	li	a4,64
    80004f7c:	4681                	li	a3,0
    80004f7e:	e5040613          	addi	a2,s0,-432
    80004f82:	4581                	li	a1,0
    80004f84:	8556                	mv	a0,s5
    80004f86:	fffff097          	auipc	ra,0xfffff
    80004f8a:	d3e080e7          	jalr	-706(ra) # 80003cc4 <readi>
    80004f8e:	04000793          	li	a5,64
    80004f92:	00f51a63          	bne	a0,a5,80004fa6 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f96:	e5042703          	lw	a4,-432(s0)
    80004f9a:	464c47b7          	lui	a5,0x464c4
    80004f9e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fa2:	04f70663          	beq	a4,a5,80004fee <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fa6:	8556                	mv	a0,s5
    80004fa8:	fffff097          	auipc	ra,0xfffff
    80004fac:	cca080e7          	jalr	-822(ra) # 80003c72 <iunlockput>
    end_op();
    80004fb0:	fffff097          	auipc	ra,0xfffff
    80004fb4:	4aa080e7          	jalr	1194(ra) # 8000445a <end_op>
  }
  return -1;
    80004fb8:	557d                	li	a0,-1
}
    80004fba:	21813083          	ld	ra,536(sp)
    80004fbe:	21013403          	ld	s0,528(sp)
    80004fc2:	20813483          	ld	s1,520(sp)
    80004fc6:	20013903          	ld	s2,512(sp)
    80004fca:	79fe                	ld	s3,504(sp)
    80004fcc:	7a5e                	ld	s4,496(sp)
    80004fce:	7abe                	ld	s5,488(sp)
    80004fd0:	7b1e                	ld	s6,480(sp)
    80004fd2:	6bfe                	ld	s7,472(sp)
    80004fd4:	6c5e                	ld	s8,464(sp)
    80004fd6:	6cbe                	ld	s9,456(sp)
    80004fd8:	6d1e                	ld	s10,448(sp)
    80004fda:	7dfa                	ld	s11,440(sp)
    80004fdc:	22010113          	addi	sp,sp,544
    80004fe0:	8082                	ret
    end_op();
    80004fe2:	fffff097          	auipc	ra,0xfffff
    80004fe6:	478080e7          	jalr	1144(ra) # 8000445a <end_op>
    return -1;
    80004fea:	557d                	li	a0,-1
    80004fec:	b7f9                	j	80004fba <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fee:	8526                	mv	a0,s1
    80004ff0:	ffffd097          	auipc	ra,0xffffd
    80004ff4:	a80080e7          	jalr	-1408(ra) # 80001a70 <proc_pagetable>
    80004ff8:	8b2a                	mv	s6,a0
    80004ffa:	d555                	beqz	a0,80004fa6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ffc:	e7042783          	lw	a5,-400(s0)
    80005000:	e8845703          	lhu	a4,-376(s0)
    80005004:	c735                	beqz	a4,80005070 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005006:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005008:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000500c:	6a05                	lui	s4,0x1
    8000500e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005012:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005016:	6d85                	lui	s11,0x1
    80005018:	7d7d                	lui	s10,0xfffff
    8000501a:	ac3d                	j	80005258 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000501c:	00003517          	auipc	a0,0x3
    80005020:	6d450513          	addi	a0,a0,1748 # 800086f0 <syscalls+0x2a0>
    80005024:	ffffb097          	auipc	ra,0xffffb
    80005028:	51c080e7          	jalr	1308(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000502c:	874a                	mv	a4,s2
    8000502e:	009c86bb          	addw	a3,s9,s1
    80005032:	4581                	li	a1,0
    80005034:	8556                	mv	a0,s5
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	c8e080e7          	jalr	-882(ra) # 80003cc4 <readi>
    8000503e:	2501                	sext.w	a0,a0
    80005040:	1aa91963          	bne	s2,a0,800051f2 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005044:	009d84bb          	addw	s1,s11,s1
    80005048:	013d09bb          	addw	s3,s10,s3
    8000504c:	1f74f663          	bgeu	s1,s7,80005238 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005050:	02049593          	slli	a1,s1,0x20
    80005054:	9181                	srli	a1,a1,0x20
    80005056:	95e2                	add	a1,a1,s8
    80005058:	855a                	mv	a0,s6
    8000505a:	ffffc097          	auipc	ra,0xffffc
    8000505e:	002080e7          	jalr	2(ra) # 8000105c <walkaddr>
    80005062:	862a                	mv	a2,a0
    if(pa == 0)
    80005064:	dd45                	beqz	a0,8000501c <exec+0xfe>
      n = PGSIZE;
    80005066:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005068:	fd49f2e3          	bgeu	s3,s4,8000502c <exec+0x10e>
      n = sz - i;
    8000506c:	894e                	mv	s2,s3
    8000506e:	bf7d                	j	8000502c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005070:	4901                	li	s2,0
  iunlockput(ip);
    80005072:	8556                	mv	a0,s5
    80005074:	fffff097          	auipc	ra,0xfffff
    80005078:	bfe080e7          	jalr	-1026(ra) # 80003c72 <iunlockput>
  end_op();
    8000507c:	fffff097          	auipc	ra,0xfffff
    80005080:	3de080e7          	jalr	990(ra) # 8000445a <end_op>
  p = myproc();
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	928080e7          	jalr	-1752(ra) # 800019ac <myproc>
    8000508c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000508e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005092:	6785                	lui	a5,0x1
    80005094:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005096:	97ca                	add	a5,a5,s2
    80005098:	777d                	lui	a4,0xfffff
    8000509a:	8ff9                	and	a5,a5,a4
    8000509c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050a0:	4691                	li	a3,4
    800050a2:	6609                	lui	a2,0x2
    800050a4:	963e                	add	a2,a2,a5
    800050a6:	85be                	mv	a1,a5
    800050a8:	855a                	mv	a0,s6
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	366080e7          	jalr	870(ra) # 80001410 <uvmalloc>
    800050b2:	8c2a                	mv	s8,a0
  ip = 0;
    800050b4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050b6:	12050e63          	beqz	a0,800051f2 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050ba:	75f9                	lui	a1,0xffffe
    800050bc:	95aa                	add	a1,a1,a0
    800050be:	855a                	mv	a0,s6
    800050c0:	ffffc097          	auipc	ra,0xffffc
    800050c4:	57a080e7          	jalr	1402(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800050c8:	7afd                	lui	s5,0xfffff
    800050ca:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800050cc:	df043783          	ld	a5,-528(s0)
    800050d0:	6388                	ld	a0,0(a5)
    800050d2:	c925                	beqz	a0,80005142 <exec+0x224>
    800050d4:	e9040993          	addi	s3,s0,-368
    800050d8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800050dc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050de:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	d6e080e7          	jalr	-658(ra) # 80000e4e <strlen>
    800050e8:	0015079b          	addiw	a5,a0,1
    800050ec:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050f0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800050f4:	13596663          	bltu	s2,s5,80005220 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050f8:	df043d83          	ld	s11,-528(s0)
    800050fc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005100:	8552                	mv	a0,s4
    80005102:	ffffc097          	auipc	ra,0xffffc
    80005106:	d4c080e7          	jalr	-692(ra) # 80000e4e <strlen>
    8000510a:	0015069b          	addiw	a3,a0,1
    8000510e:	8652                	mv	a2,s4
    80005110:	85ca                	mv	a1,s2
    80005112:	855a                	mv	a0,s6
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	558080e7          	jalr	1368(ra) # 8000166c <copyout>
    8000511c:	10054663          	bltz	a0,80005228 <exec+0x30a>
    ustack[argc] = sp;
    80005120:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005124:	0485                	addi	s1,s1,1
    80005126:	008d8793          	addi	a5,s11,8
    8000512a:	def43823          	sd	a5,-528(s0)
    8000512e:	008db503          	ld	a0,8(s11)
    80005132:	c911                	beqz	a0,80005146 <exec+0x228>
    if(argc >= MAXARG)
    80005134:	09a1                	addi	s3,s3,8
    80005136:	fb3c95e3          	bne	s9,s3,800050e0 <exec+0x1c2>
  sz = sz1;
    8000513a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000513e:	4a81                	li	s5,0
    80005140:	a84d                	j	800051f2 <exec+0x2d4>
  sp = sz;
    80005142:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005144:	4481                	li	s1,0
  ustack[argc] = 0;
    80005146:	00349793          	slli	a5,s1,0x3
    8000514a:	f9078793          	addi	a5,a5,-112
    8000514e:	97a2                	add	a5,a5,s0
    80005150:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005154:	00148693          	addi	a3,s1,1
    80005158:	068e                	slli	a3,a3,0x3
    8000515a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000515e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005162:	01597663          	bgeu	s2,s5,8000516e <exec+0x250>
  sz = sz1;
    80005166:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000516a:	4a81                	li	s5,0
    8000516c:	a059                	j	800051f2 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000516e:	e9040613          	addi	a2,s0,-368
    80005172:	85ca                	mv	a1,s2
    80005174:	855a                	mv	a0,s6
    80005176:	ffffc097          	auipc	ra,0xffffc
    8000517a:	4f6080e7          	jalr	1270(ra) # 8000166c <copyout>
    8000517e:	0a054963          	bltz	a0,80005230 <exec+0x312>
  p->trapframe->a1 = sp;
    80005182:	058bb783          	ld	a5,88(s7)
    80005186:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000518a:	de843783          	ld	a5,-536(s0)
    8000518e:	0007c703          	lbu	a4,0(a5)
    80005192:	cf11                	beqz	a4,800051ae <exec+0x290>
    80005194:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005196:	02f00693          	li	a3,47
    8000519a:	a039                	j	800051a8 <exec+0x28a>
      last = s+1;
    8000519c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800051a0:	0785                	addi	a5,a5,1
    800051a2:	fff7c703          	lbu	a4,-1(a5)
    800051a6:	c701                	beqz	a4,800051ae <exec+0x290>
    if(*s == '/')
    800051a8:	fed71ce3          	bne	a4,a3,800051a0 <exec+0x282>
    800051ac:	bfc5                	j	8000519c <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800051ae:	4641                	li	a2,16
    800051b0:	de843583          	ld	a1,-536(s0)
    800051b4:	158b8513          	addi	a0,s7,344
    800051b8:	ffffc097          	auipc	ra,0xffffc
    800051bc:	c64080e7          	jalr	-924(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800051c0:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800051c4:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800051c8:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051cc:	058bb783          	ld	a5,88(s7)
    800051d0:	e6843703          	ld	a4,-408(s0)
    800051d4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051d6:	058bb783          	ld	a5,88(s7)
    800051da:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051de:	85ea                	mv	a1,s10
    800051e0:	ffffd097          	auipc	ra,0xffffd
    800051e4:	92c080e7          	jalr	-1748(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051e8:	0004851b          	sext.w	a0,s1
    800051ec:	b3f9                	j	80004fba <exec+0x9c>
    800051ee:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051f2:	df843583          	ld	a1,-520(s0)
    800051f6:	855a                	mv	a0,s6
    800051f8:	ffffd097          	auipc	ra,0xffffd
    800051fc:	914080e7          	jalr	-1772(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80005200:	da0a93e3          	bnez	s5,80004fa6 <exec+0x88>
  return -1;
    80005204:	557d                	li	a0,-1
    80005206:	bb55                	j	80004fba <exec+0x9c>
    80005208:	df243c23          	sd	s2,-520(s0)
    8000520c:	b7dd                	j	800051f2 <exec+0x2d4>
    8000520e:	df243c23          	sd	s2,-520(s0)
    80005212:	b7c5                	j	800051f2 <exec+0x2d4>
    80005214:	df243c23          	sd	s2,-520(s0)
    80005218:	bfe9                	j	800051f2 <exec+0x2d4>
    8000521a:	df243c23          	sd	s2,-520(s0)
    8000521e:	bfd1                	j	800051f2 <exec+0x2d4>
  sz = sz1;
    80005220:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005224:	4a81                	li	s5,0
    80005226:	b7f1                	j	800051f2 <exec+0x2d4>
  sz = sz1;
    80005228:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000522c:	4a81                	li	s5,0
    8000522e:	b7d1                	j	800051f2 <exec+0x2d4>
  sz = sz1;
    80005230:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005234:	4a81                	li	s5,0
    80005236:	bf75                	j	800051f2 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005238:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000523c:	e0843783          	ld	a5,-504(s0)
    80005240:	0017869b          	addiw	a3,a5,1
    80005244:	e0d43423          	sd	a3,-504(s0)
    80005248:	e0043783          	ld	a5,-512(s0)
    8000524c:	0387879b          	addiw	a5,a5,56
    80005250:	e8845703          	lhu	a4,-376(s0)
    80005254:	e0e6dfe3          	bge	a3,a4,80005072 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005258:	2781                	sext.w	a5,a5
    8000525a:	e0f43023          	sd	a5,-512(s0)
    8000525e:	03800713          	li	a4,56
    80005262:	86be                	mv	a3,a5
    80005264:	e1840613          	addi	a2,s0,-488
    80005268:	4581                	li	a1,0
    8000526a:	8556                	mv	a0,s5
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	a58080e7          	jalr	-1448(ra) # 80003cc4 <readi>
    80005274:	03800793          	li	a5,56
    80005278:	f6f51be3          	bne	a0,a5,800051ee <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000527c:	e1842783          	lw	a5,-488(s0)
    80005280:	4705                	li	a4,1
    80005282:	fae79de3          	bne	a5,a4,8000523c <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005286:	e4043483          	ld	s1,-448(s0)
    8000528a:	e3843783          	ld	a5,-456(s0)
    8000528e:	f6f4ede3          	bltu	s1,a5,80005208 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005292:	e2843783          	ld	a5,-472(s0)
    80005296:	94be                	add	s1,s1,a5
    80005298:	f6f4ebe3          	bltu	s1,a5,8000520e <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000529c:	de043703          	ld	a4,-544(s0)
    800052a0:	8ff9                	and	a5,a5,a4
    800052a2:	fbad                	bnez	a5,80005214 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052a4:	e1c42503          	lw	a0,-484(s0)
    800052a8:	00000097          	auipc	ra,0x0
    800052ac:	c5c080e7          	jalr	-932(ra) # 80004f04 <flags2perm>
    800052b0:	86aa                	mv	a3,a0
    800052b2:	8626                	mv	a2,s1
    800052b4:	85ca                	mv	a1,s2
    800052b6:	855a                	mv	a0,s6
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	158080e7          	jalr	344(ra) # 80001410 <uvmalloc>
    800052c0:	dea43c23          	sd	a0,-520(s0)
    800052c4:	d939                	beqz	a0,8000521a <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052c6:	e2843c03          	ld	s8,-472(s0)
    800052ca:	e2042c83          	lw	s9,-480(s0)
    800052ce:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052d2:	f60b83e3          	beqz	s7,80005238 <exec+0x31a>
    800052d6:	89de                	mv	s3,s7
    800052d8:	4481                	li	s1,0
    800052da:	bb9d                	j	80005050 <exec+0x132>

00000000800052dc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052dc:	7179                	addi	sp,sp,-48
    800052de:	f406                	sd	ra,40(sp)
    800052e0:	f022                	sd	s0,32(sp)
    800052e2:	ec26                	sd	s1,24(sp)
    800052e4:	e84a                	sd	s2,16(sp)
    800052e6:	1800                	addi	s0,sp,48
    800052e8:	892e                	mv	s2,a1
    800052ea:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800052ec:	fdc40593          	addi	a1,s0,-36
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	a56080e7          	jalr	-1450(ra) # 80002d46 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052f8:	fdc42703          	lw	a4,-36(s0)
    800052fc:	47bd                	li	a5,15
    800052fe:	02e7eb63          	bltu	a5,a4,80005334 <argfd+0x58>
    80005302:	ffffc097          	auipc	ra,0xffffc
    80005306:	6aa080e7          	jalr	1706(ra) # 800019ac <myproc>
    8000530a:	fdc42703          	lw	a4,-36(s0)
    8000530e:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdc49a>
    80005312:	078e                	slli	a5,a5,0x3
    80005314:	953e                	add	a0,a0,a5
    80005316:	611c                	ld	a5,0(a0)
    80005318:	c385                	beqz	a5,80005338 <argfd+0x5c>
    return -1;
  if(pfd)
    8000531a:	00090463          	beqz	s2,80005322 <argfd+0x46>
    *pfd = fd;
    8000531e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005322:	4501                	li	a0,0
  if(pf)
    80005324:	c091                	beqz	s1,80005328 <argfd+0x4c>
    *pf = f;
    80005326:	e09c                	sd	a5,0(s1)
}
    80005328:	70a2                	ld	ra,40(sp)
    8000532a:	7402                	ld	s0,32(sp)
    8000532c:	64e2                	ld	s1,24(sp)
    8000532e:	6942                	ld	s2,16(sp)
    80005330:	6145                	addi	sp,sp,48
    80005332:	8082                	ret
    return -1;
    80005334:	557d                	li	a0,-1
    80005336:	bfcd                	j	80005328 <argfd+0x4c>
    80005338:	557d                	li	a0,-1
    8000533a:	b7fd                	j	80005328 <argfd+0x4c>

000000008000533c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000533c:	1101                	addi	sp,sp,-32
    8000533e:	ec06                	sd	ra,24(sp)
    80005340:	e822                	sd	s0,16(sp)
    80005342:	e426                	sd	s1,8(sp)
    80005344:	1000                	addi	s0,sp,32
    80005346:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005348:	ffffc097          	auipc	ra,0xffffc
    8000534c:	664080e7          	jalr	1636(ra) # 800019ac <myproc>
    80005350:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005352:	0d050793          	addi	a5,a0,208
    80005356:	4501                	li	a0,0
    80005358:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000535a:	6398                	ld	a4,0(a5)
    8000535c:	cb19                	beqz	a4,80005372 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000535e:	2505                	addiw	a0,a0,1
    80005360:	07a1                	addi	a5,a5,8
    80005362:	fed51ce3          	bne	a0,a3,8000535a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005366:	557d                	li	a0,-1
}
    80005368:	60e2                	ld	ra,24(sp)
    8000536a:	6442                	ld	s0,16(sp)
    8000536c:	64a2                	ld	s1,8(sp)
    8000536e:	6105                	addi	sp,sp,32
    80005370:	8082                	ret
      p->ofile[fd] = f;
    80005372:	01a50793          	addi	a5,a0,26
    80005376:	078e                	slli	a5,a5,0x3
    80005378:	963e                	add	a2,a2,a5
    8000537a:	e204                	sd	s1,0(a2)
      return fd;
    8000537c:	b7f5                	j	80005368 <fdalloc+0x2c>

000000008000537e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000537e:	715d                	addi	sp,sp,-80
    80005380:	e486                	sd	ra,72(sp)
    80005382:	e0a2                	sd	s0,64(sp)
    80005384:	fc26                	sd	s1,56(sp)
    80005386:	f84a                	sd	s2,48(sp)
    80005388:	f44e                	sd	s3,40(sp)
    8000538a:	f052                	sd	s4,32(sp)
    8000538c:	ec56                	sd	s5,24(sp)
    8000538e:	e85a                	sd	s6,16(sp)
    80005390:	0880                	addi	s0,sp,80
    80005392:	8b2e                	mv	s6,a1
    80005394:	89b2                	mv	s3,a2
    80005396:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005398:	fb040593          	addi	a1,s0,-80
    8000539c:	fffff097          	auipc	ra,0xfffff
    800053a0:	e3e080e7          	jalr	-450(ra) # 800041da <nameiparent>
    800053a4:	84aa                	mv	s1,a0
    800053a6:	14050f63          	beqz	a0,80005504 <create+0x186>
    return 0;

  ilock(dp);
    800053aa:	ffffe097          	auipc	ra,0xffffe
    800053ae:	666080e7          	jalr	1638(ra) # 80003a10 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053b2:	4601                	li	a2,0
    800053b4:	fb040593          	addi	a1,s0,-80
    800053b8:	8526                	mv	a0,s1
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	b3a080e7          	jalr	-1222(ra) # 80003ef4 <dirlookup>
    800053c2:	8aaa                	mv	s5,a0
    800053c4:	c931                	beqz	a0,80005418 <create+0x9a>
    iunlockput(dp);
    800053c6:	8526                	mv	a0,s1
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	8aa080e7          	jalr	-1878(ra) # 80003c72 <iunlockput>
    ilock(ip);
    800053d0:	8556                	mv	a0,s5
    800053d2:	ffffe097          	auipc	ra,0xffffe
    800053d6:	63e080e7          	jalr	1598(ra) # 80003a10 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053da:	000b059b          	sext.w	a1,s6
    800053de:	4789                	li	a5,2
    800053e0:	02f59563          	bne	a1,a5,8000540a <create+0x8c>
    800053e4:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc4c4>
    800053e8:	37f9                	addiw	a5,a5,-2
    800053ea:	17c2                	slli	a5,a5,0x30
    800053ec:	93c1                	srli	a5,a5,0x30
    800053ee:	4705                	li	a4,1
    800053f0:	00f76d63          	bltu	a4,a5,8000540a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053f4:	8556                	mv	a0,s5
    800053f6:	60a6                	ld	ra,72(sp)
    800053f8:	6406                	ld	s0,64(sp)
    800053fa:	74e2                	ld	s1,56(sp)
    800053fc:	7942                	ld	s2,48(sp)
    800053fe:	79a2                	ld	s3,40(sp)
    80005400:	7a02                	ld	s4,32(sp)
    80005402:	6ae2                	ld	s5,24(sp)
    80005404:	6b42                	ld	s6,16(sp)
    80005406:	6161                	addi	sp,sp,80
    80005408:	8082                	ret
    iunlockput(ip);
    8000540a:	8556                	mv	a0,s5
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	866080e7          	jalr	-1946(ra) # 80003c72 <iunlockput>
    return 0;
    80005414:	4a81                	li	s5,0
    80005416:	bff9                	j	800053f4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005418:	85da                	mv	a1,s6
    8000541a:	4088                	lw	a0,0(s1)
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	456080e7          	jalr	1110(ra) # 80003872 <ialloc>
    80005424:	8a2a                	mv	s4,a0
    80005426:	c539                	beqz	a0,80005474 <create+0xf6>
  ilock(ip);
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	5e8080e7          	jalr	1512(ra) # 80003a10 <ilock>
  ip->major = major;
    80005430:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005434:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005438:	4905                	li	s2,1
    8000543a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000543e:	8552                	mv	a0,s4
    80005440:	ffffe097          	auipc	ra,0xffffe
    80005444:	504080e7          	jalr	1284(ra) # 80003944 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005448:	000b059b          	sext.w	a1,s6
    8000544c:	03258b63          	beq	a1,s2,80005482 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005450:	004a2603          	lw	a2,4(s4)
    80005454:	fb040593          	addi	a1,s0,-80
    80005458:	8526                	mv	a0,s1
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	cb0080e7          	jalr	-848(ra) # 8000410a <dirlink>
    80005462:	06054f63          	bltz	a0,800054e0 <create+0x162>
  iunlockput(dp);
    80005466:	8526                	mv	a0,s1
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	80a080e7          	jalr	-2038(ra) # 80003c72 <iunlockput>
  return ip;
    80005470:	8ad2                	mv	s5,s4
    80005472:	b749                	j	800053f4 <create+0x76>
    iunlockput(dp);
    80005474:	8526                	mv	a0,s1
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	7fc080e7          	jalr	2044(ra) # 80003c72 <iunlockput>
    return 0;
    8000547e:	8ad2                	mv	s5,s4
    80005480:	bf95                	j	800053f4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005482:	004a2603          	lw	a2,4(s4)
    80005486:	00003597          	auipc	a1,0x3
    8000548a:	28a58593          	addi	a1,a1,650 # 80008710 <syscalls+0x2c0>
    8000548e:	8552                	mv	a0,s4
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	c7a080e7          	jalr	-902(ra) # 8000410a <dirlink>
    80005498:	04054463          	bltz	a0,800054e0 <create+0x162>
    8000549c:	40d0                	lw	a2,4(s1)
    8000549e:	00003597          	auipc	a1,0x3
    800054a2:	27a58593          	addi	a1,a1,634 # 80008718 <syscalls+0x2c8>
    800054a6:	8552                	mv	a0,s4
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	c62080e7          	jalr	-926(ra) # 8000410a <dirlink>
    800054b0:	02054863          	bltz	a0,800054e0 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800054b4:	004a2603          	lw	a2,4(s4)
    800054b8:	fb040593          	addi	a1,s0,-80
    800054bc:	8526                	mv	a0,s1
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	c4c080e7          	jalr	-948(ra) # 8000410a <dirlink>
    800054c6:	00054d63          	bltz	a0,800054e0 <create+0x162>
    dp->nlink++;  // for ".."
    800054ca:	04a4d783          	lhu	a5,74(s1)
    800054ce:	2785                	addiw	a5,a5,1
    800054d0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054d4:	8526                	mv	a0,s1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	46e080e7          	jalr	1134(ra) # 80003944 <iupdate>
    800054de:	b761                	j	80005466 <create+0xe8>
  ip->nlink = 0;
    800054e0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800054e4:	8552                	mv	a0,s4
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	45e080e7          	jalr	1118(ra) # 80003944 <iupdate>
  iunlockput(ip);
    800054ee:	8552                	mv	a0,s4
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	782080e7          	jalr	1922(ra) # 80003c72 <iunlockput>
  iunlockput(dp);
    800054f8:	8526                	mv	a0,s1
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	778080e7          	jalr	1912(ra) # 80003c72 <iunlockput>
  return 0;
    80005502:	bdcd                	j	800053f4 <create+0x76>
    return 0;
    80005504:	8aaa                	mv	s5,a0
    80005506:	b5fd                	j	800053f4 <create+0x76>

0000000080005508 <sys_dup>:
{
    80005508:	7179                	addi	sp,sp,-48
    8000550a:	f406                	sd	ra,40(sp)
    8000550c:	f022                	sd	s0,32(sp)
    8000550e:	ec26                	sd	s1,24(sp)
    80005510:	e84a                	sd	s2,16(sp)
    80005512:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005514:	fd840613          	addi	a2,s0,-40
    80005518:	4581                	li	a1,0
    8000551a:	4501                	li	a0,0
    8000551c:	00000097          	auipc	ra,0x0
    80005520:	dc0080e7          	jalr	-576(ra) # 800052dc <argfd>
    return -1;
    80005524:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005526:	02054363          	bltz	a0,8000554c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000552a:	fd843903          	ld	s2,-40(s0)
    8000552e:	854a                	mv	a0,s2
    80005530:	00000097          	auipc	ra,0x0
    80005534:	e0c080e7          	jalr	-500(ra) # 8000533c <fdalloc>
    80005538:	84aa                	mv	s1,a0
    return -1;
    8000553a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000553c:	00054863          	bltz	a0,8000554c <sys_dup+0x44>
  filedup(f);
    80005540:	854a                	mv	a0,s2
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	310080e7          	jalr	784(ra) # 80004852 <filedup>
  return fd;
    8000554a:	87a6                	mv	a5,s1
}
    8000554c:	853e                	mv	a0,a5
    8000554e:	70a2                	ld	ra,40(sp)
    80005550:	7402                	ld	s0,32(sp)
    80005552:	64e2                	ld	s1,24(sp)
    80005554:	6942                	ld	s2,16(sp)
    80005556:	6145                	addi	sp,sp,48
    80005558:	8082                	ret

000000008000555a <sys_read>:
{
    8000555a:	7179                	addi	sp,sp,-48
    8000555c:	f406                	sd	ra,40(sp)
    8000555e:	f022                	sd	s0,32(sp)
    80005560:	1800                	addi	s0,sp,48
myproc()->read_count++;
    80005562:	ffffc097          	auipc	ra,0xffffc
    80005566:	44a080e7          	jalr	1098(ra) # 800019ac <myproc>
    8000556a:	17852783          	lw	a5,376(a0)
    8000556e:	2785                	addiw	a5,a5,1
    80005570:	16f52c23          	sw	a5,376(a0)
  argaddr(1, &p);
    80005574:	fd840593          	addi	a1,s0,-40
    80005578:	4505                	li	a0,1
    8000557a:	ffffd097          	auipc	ra,0xffffd
    8000557e:	7ec080e7          	jalr	2028(ra) # 80002d66 <argaddr>
  argint(2, &n);
    80005582:	fe440593          	addi	a1,s0,-28
    80005586:	4509                	li	a0,2
    80005588:	ffffd097          	auipc	ra,0xffffd
    8000558c:	7be080e7          	jalr	1982(ra) # 80002d46 <argint>
  if(argfd(0, 0, &f) < 0)
    80005590:	fe840613          	addi	a2,s0,-24
    80005594:	4581                	li	a1,0
    80005596:	4501                	li	a0,0
    80005598:	00000097          	auipc	ra,0x0
    8000559c:	d44080e7          	jalr	-700(ra) # 800052dc <argfd>
    800055a0:	87aa                	mv	a5,a0
    return -1;
    800055a2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055a4:	0007cc63          	bltz	a5,800055bc <sys_read+0x62>
  return fileread(f, p, n);
    800055a8:	fe442603          	lw	a2,-28(s0)
    800055ac:	fd843583          	ld	a1,-40(s0)
    800055b0:	fe843503          	ld	a0,-24(s0)
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	42a080e7          	jalr	1066(ra) # 800049de <fileread>
}
    800055bc:	70a2                	ld	ra,40(sp)
    800055be:	7402                	ld	s0,32(sp)
    800055c0:	6145                	addi	sp,sp,48
    800055c2:	8082                	ret

00000000800055c4 <sys_write>:
{
    800055c4:	7179                	addi	sp,sp,-48
    800055c6:	f406                	sd	ra,40(sp)
    800055c8:	f022                	sd	s0,32(sp)
    800055ca:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800055cc:	fd840593          	addi	a1,s0,-40
    800055d0:	4505                	li	a0,1
    800055d2:	ffffd097          	auipc	ra,0xffffd
    800055d6:	794080e7          	jalr	1940(ra) # 80002d66 <argaddr>
  argint(2, &n);
    800055da:	fe440593          	addi	a1,s0,-28
    800055de:	4509                	li	a0,2
    800055e0:	ffffd097          	auipc	ra,0xffffd
    800055e4:	766080e7          	jalr	1894(ra) # 80002d46 <argint>
  if(argfd(0, 0, &f) < 0)
    800055e8:	fe840613          	addi	a2,s0,-24
    800055ec:	4581                	li	a1,0
    800055ee:	4501                	li	a0,0
    800055f0:	00000097          	auipc	ra,0x0
    800055f4:	cec080e7          	jalr	-788(ra) # 800052dc <argfd>
    800055f8:	87aa                	mv	a5,a0
    return -1;
    800055fa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055fc:	0007cc63          	bltz	a5,80005614 <sys_write+0x50>
  return filewrite(f, p, n);
    80005600:	fe442603          	lw	a2,-28(s0)
    80005604:	fd843583          	ld	a1,-40(s0)
    80005608:	fe843503          	ld	a0,-24(s0)
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	494080e7          	jalr	1172(ra) # 80004aa0 <filewrite>
}
    80005614:	70a2                	ld	ra,40(sp)
    80005616:	7402                	ld	s0,32(sp)
    80005618:	6145                	addi	sp,sp,48
    8000561a:	8082                	ret

000000008000561c <sys_close>:
{
    8000561c:	1101                	addi	sp,sp,-32
    8000561e:	ec06                	sd	ra,24(sp)
    80005620:	e822                	sd	s0,16(sp)
    80005622:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005624:	fe040613          	addi	a2,s0,-32
    80005628:	fec40593          	addi	a1,s0,-20
    8000562c:	4501                	li	a0,0
    8000562e:	00000097          	auipc	ra,0x0
    80005632:	cae080e7          	jalr	-850(ra) # 800052dc <argfd>
    return -1;
    80005636:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005638:	02054463          	bltz	a0,80005660 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000563c:	ffffc097          	auipc	ra,0xffffc
    80005640:	370080e7          	jalr	880(ra) # 800019ac <myproc>
    80005644:	fec42783          	lw	a5,-20(s0)
    80005648:	07e9                	addi	a5,a5,26
    8000564a:	078e                	slli	a5,a5,0x3
    8000564c:	953e                	add	a0,a0,a5
    8000564e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005652:	fe043503          	ld	a0,-32(s0)
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	24e080e7          	jalr	590(ra) # 800048a4 <fileclose>
  return 0;
    8000565e:	4781                	li	a5,0
}
    80005660:	853e                	mv	a0,a5
    80005662:	60e2                	ld	ra,24(sp)
    80005664:	6442                	ld	s0,16(sp)
    80005666:	6105                	addi	sp,sp,32
    80005668:	8082                	ret

000000008000566a <sys_fstat>:
{
    8000566a:	1101                	addi	sp,sp,-32
    8000566c:	ec06                	sd	ra,24(sp)
    8000566e:	e822                	sd	s0,16(sp)
    80005670:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005672:	fe040593          	addi	a1,s0,-32
    80005676:	4505                	li	a0,1
    80005678:	ffffd097          	auipc	ra,0xffffd
    8000567c:	6ee080e7          	jalr	1774(ra) # 80002d66 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005680:	fe840613          	addi	a2,s0,-24
    80005684:	4581                	li	a1,0
    80005686:	4501                	li	a0,0
    80005688:	00000097          	auipc	ra,0x0
    8000568c:	c54080e7          	jalr	-940(ra) # 800052dc <argfd>
    80005690:	87aa                	mv	a5,a0
    return -1;
    80005692:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005694:	0007ca63          	bltz	a5,800056a8 <sys_fstat+0x3e>
  return filestat(f, st);
    80005698:	fe043583          	ld	a1,-32(s0)
    8000569c:	fe843503          	ld	a0,-24(s0)
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	2cc080e7          	jalr	716(ra) # 8000496c <filestat>
}
    800056a8:	60e2                	ld	ra,24(sp)
    800056aa:	6442                	ld	s0,16(sp)
    800056ac:	6105                	addi	sp,sp,32
    800056ae:	8082                	ret

00000000800056b0 <sys_link>:
{
    800056b0:	7169                	addi	sp,sp,-304
    800056b2:	f606                	sd	ra,296(sp)
    800056b4:	f222                	sd	s0,288(sp)
    800056b6:	ee26                	sd	s1,280(sp)
    800056b8:	ea4a                	sd	s2,272(sp)
    800056ba:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056bc:	08000613          	li	a2,128
    800056c0:	ed040593          	addi	a1,s0,-304
    800056c4:	4501                	li	a0,0
    800056c6:	ffffd097          	auipc	ra,0xffffd
    800056ca:	6c0080e7          	jalr	1728(ra) # 80002d86 <argstr>
    return -1;
    800056ce:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056d0:	10054e63          	bltz	a0,800057ec <sys_link+0x13c>
    800056d4:	08000613          	li	a2,128
    800056d8:	f5040593          	addi	a1,s0,-176
    800056dc:	4505                	li	a0,1
    800056de:	ffffd097          	auipc	ra,0xffffd
    800056e2:	6a8080e7          	jalr	1704(ra) # 80002d86 <argstr>
    return -1;
    800056e6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056e8:	10054263          	bltz	a0,800057ec <sys_link+0x13c>
  begin_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	cf0080e7          	jalr	-784(ra) # 800043dc <begin_op>
  if((ip = namei(old)) == 0){
    800056f4:	ed040513          	addi	a0,s0,-304
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	ac4080e7          	jalr	-1340(ra) # 800041bc <namei>
    80005700:	84aa                	mv	s1,a0
    80005702:	c551                	beqz	a0,8000578e <sys_link+0xde>
  ilock(ip);
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	30c080e7          	jalr	780(ra) # 80003a10 <ilock>
  if(ip->type == T_DIR){
    8000570c:	04449703          	lh	a4,68(s1)
    80005710:	4785                	li	a5,1
    80005712:	08f70463          	beq	a4,a5,8000579a <sys_link+0xea>
  ip->nlink++;
    80005716:	04a4d783          	lhu	a5,74(s1)
    8000571a:	2785                	addiw	a5,a5,1
    8000571c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005720:	8526                	mv	a0,s1
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	222080e7          	jalr	546(ra) # 80003944 <iupdate>
  iunlock(ip);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	3a6080e7          	jalr	934(ra) # 80003ad2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005734:	fd040593          	addi	a1,s0,-48
    80005738:	f5040513          	addi	a0,s0,-176
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	a9e080e7          	jalr	-1378(ra) # 800041da <nameiparent>
    80005744:	892a                	mv	s2,a0
    80005746:	c935                	beqz	a0,800057ba <sys_link+0x10a>
  ilock(dp);
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	2c8080e7          	jalr	712(ra) # 80003a10 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005750:	00092703          	lw	a4,0(s2)
    80005754:	409c                	lw	a5,0(s1)
    80005756:	04f71d63          	bne	a4,a5,800057b0 <sys_link+0x100>
    8000575a:	40d0                	lw	a2,4(s1)
    8000575c:	fd040593          	addi	a1,s0,-48
    80005760:	854a                	mv	a0,s2
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	9a8080e7          	jalr	-1624(ra) # 8000410a <dirlink>
    8000576a:	04054363          	bltz	a0,800057b0 <sys_link+0x100>
  iunlockput(dp);
    8000576e:	854a                	mv	a0,s2
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	502080e7          	jalr	1282(ra) # 80003c72 <iunlockput>
  iput(ip);
    80005778:	8526                	mv	a0,s1
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	450080e7          	jalr	1104(ra) # 80003bca <iput>
  end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	cd8080e7          	jalr	-808(ra) # 8000445a <end_op>
  return 0;
    8000578a:	4781                	li	a5,0
    8000578c:	a085                	j	800057ec <sys_link+0x13c>
    end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	ccc080e7          	jalr	-820(ra) # 8000445a <end_op>
    return -1;
    80005796:	57fd                	li	a5,-1
    80005798:	a891                	j	800057ec <sys_link+0x13c>
    iunlockput(ip);
    8000579a:	8526                	mv	a0,s1
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	4d6080e7          	jalr	1238(ra) # 80003c72 <iunlockput>
    end_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	cb6080e7          	jalr	-842(ra) # 8000445a <end_op>
    return -1;
    800057ac:	57fd                	li	a5,-1
    800057ae:	a83d                	j	800057ec <sys_link+0x13c>
    iunlockput(dp);
    800057b0:	854a                	mv	a0,s2
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	4c0080e7          	jalr	1216(ra) # 80003c72 <iunlockput>
  ilock(ip);
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	254080e7          	jalr	596(ra) # 80003a10 <ilock>
  ip->nlink--;
    800057c4:	04a4d783          	lhu	a5,74(s1)
    800057c8:	37fd                	addiw	a5,a5,-1
    800057ca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057ce:	8526                	mv	a0,s1
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	174080e7          	jalr	372(ra) # 80003944 <iupdate>
  iunlockput(ip);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	498080e7          	jalr	1176(ra) # 80003c72 <iunlockput>
  end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	c78080e7          	jalr	-904(ra) # 8000445a <end_op>
  return -1;
    800057ea:	57fd                	li	a5,-1
}
    800057ec:	853e                	mv	a0,a5
    800057ee:	70b2                	ld	ra,296(sp)
    800057f0:	7412                	ld	s0,288(sp)
    800057f2:	64f2                	ld	s1,280(sp)
    800057f4:	6952                	ld	s2,272(sp)
    800057f6:	6155                	addi	sp,sp,304
    800057f8:	8082                	ret

00000000800057fa <sys_unlink>:
{
    800057fa:	7151                	addi	sp,sp,-240
    800057fc:	f586                	sd	ra,232(sp)
    800057fe:	f1a2                	sd	s0,224(sp)
    80005800:	eda6                	sd	s1,216(sp)
    80005802:	e9ca                	sd	s2,208(sp)
    80005804:	e5ce                	sd	s3,200(sp)
    80005806:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005808:	08000613          	li	a2,128
    8000580c:	f3040593          	addi	a1,s0,-208
    80005810:	4501                	li	a0,0
    80005812:	ffffd097          	auipc	ra,0xffffd
    80005816:	574080e7          	jalr	1396(ra) # 80002d86 <argstr>
    8000581a:	18054163          	bltz	a0,8000599c <sys_unlink+0x1a2>
  begin_op();
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	bbe080e7          	jalr	-1090(ra) # 800043dc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005826:	fb040593          	addi	a1,s0,-80
    8000582a:	f3040513          	addi	a0,s0,-208
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	9ac080e7          	jalr	-1620(ra) # 800041da <nameiparent>
    80005836:	84aa                	mv	s1,a0
    80005838:	c979                	beqz	a0,8000590e <sys_unlink+0x114>
  ilock(dp);
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	1d6080e7          	jalr	470(ra) # 80003a10 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005842:	00003597          	auipc	a1,0x3
    80005846:	ece58593          	addi	a1,a1,-306 # 80008710 <syscalls+0x2c0>
    8000584a:	fb040513          	addi	a0,s0,-80
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	68c080e7          	jalr	1676(ra) # 80003eda <namecmp>
    80005856:	14050a63          	beqz	a0,800059aa <sys_unlink+0x1b0>
    8000585a:	00003597          	auipc	a1,0x3
    8000585e:	ebe58593          	addi	a1,a1,-322 # 80008718 <syscalls+0x2c8>
    80005862:	fb040513          	addi	a0,s0,-80
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	674080e7          	jalr	1652(ra) # 80003eda <namecmp>
    8000586e:	12050e63          	beqz	a0,800059aa <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005872:	f2c40613          	addi	a2,s0,-212
    80005876:	fb040593          	addi	a1,s0,-80
    8000587a:	8526                	mv	a0,s1
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	678080e7          	jalr	1656(ra) # 80003ef4 <dirlookup>
    80005884:	892a                	mv	s2,a0
    80005886:	12050263          	beqz	a0,800059aa <sys_unlink+0x1b0>
  ilock(ip);
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	186080e7          	jalr	390(ra) # 80003a10 <ilock>
  if(ip->nlink < 1)
    80005892:	04a91783          	lh	a5,74(s2)
    80005896:	08f05263          	blez	a5,8000591a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000589a:	04491703          	lh	a4,68(s2)
    8000589e:	4785                	li	a5,1
    800058a0:	08f70563          	beq	a4,a5,8000592a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058a4:	4641                	li	a2,16
    800058a6:	4581                	li	a1,0
    800058a8:	fc040513          	addi	a0,s0,-64
    800058ac:	ffffb097          	auipc	ra,0xffffb
    800058b0:	426080e7          	jalr	1062(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058b4:	4741                	li	a4,16
    800058b6:	f2c42683          	lw	a3,-212(s0)
    800058ba:	fc040613          	addi	a2,s0,-64
    800058be:	4581                	li	a1,0
    800058c0:	8526                	mv	a0,s1
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	4fa080e7          	jalr	1274(ra) # 80003dbc <writei>
    800058ca:	47c1                	li	a5,16
    800058cc:	0af51563          	bne	a0,a5,80005976 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058d0:	04491703          	lh	a4,68(s2)
    800058d4:	4785                	li	a5,1
    800058d6:	0af70863          	beq	a4,a5,80005986 <sys_unlink+0x18c>
  iunlockput(dp);
    800058da:	8526                	mv	a0,s1
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	396080e7          	jalr	918(ra) # 80003c72 <iunlockput>
  ip->nlink--;
    800058e4:	04a95783          	lhu	a5,74(s2)
    800058e8:	37fd                	addiw	a5,a5,-1
    800058ea:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058ee:	854a                	mv	a0,s2
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	054080e7          	jalr	84(ra) # 80003944 <iupdate>
  iunlockput(ip);
    800058f8:	854a                	mv	a0,s2
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	378080e7          	jalr	888(ra) # 80003c72 <iunlockput>
  end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	b58080e7          	jalr	-1192(ra) # 8000445a <end_op>
  return 0;
    8000590a:	4501                	li	a0,0
    8000590c:	a84d                	j	800059be <sys_unlink+0x1c4>
    end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	b4c080e7          	jalr	-1204(ra) # 8000445a <end_op>
    return -1;
    80005916:	557d                	li	a0,-1
    80005918:	a05d                	j	800059be <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000591a:	00003517          	auipc	a0,0x3
    8000591e:	e0650513          	addi	a0,a0,-506 # 80008720 <syscalls+0x2d0>
    80005922:	ffffb097          	auipc	ra,0xffffb
    80005926:	c1e080e7          	jalr	-994(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000592a:	04c92703          	lw	a4,76(s2)
    8000592e:	02000793          	li	a5,32
    80005932:	f6e7f9e3          	bgeu	a5,a4,800058a4 <sys_unlink+0xaa>
    80005936:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000593a:	4741                	li	a4,16
    8000593c:	86ce                	mv	a3,s3
    8000593e:	f1840613          	addi	a2,s0,-232
    80005942:	4581                	li	a1,0
    80005944:	854a                	mv	a0,s2
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	37e080e7          	jalr	894(ra) # 80003cc4 <readi>
    8000594e:	47c1                	li	a5,16
    80005950:	00f51b63          	bne	a0,a5,80005966 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005954:	f1845783          	lhu	a5,-232(s0)
    80005958:	e7a1                	bnez	a5,800059a0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000595a:	29c1                	addiw	s3,s3,16
    8000595c:	04c92783          	lw	a5,76(s2)
    80005960:	fcf9ede3          	bltu	s3,a5,8000593a <sys_unlink+0x140>
    80005964:	b781                	j	800058a4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005966:	00003517          	auipc	a0,0x3
    8000596a:	dd250513          	addi	a0,a0,-558 # 80008738 <syscalls+0x2e8>
    8000596e:	ffffb097          	auipc	ra,0xffffb
    80005972:	bd2080e7          	jalr	-1070(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005976:	00003517          	auipc	a0,0x3
    8000597a:	dda50513          	addi	a0,a0,-550 # 80008750 <syscalls+0x300>
    8000597e:	ffffb097          	auipc	ra,0xffffb
    80005982:	bc2080e7          	jalr	-1086(ra) # 80000540 <panic>
    dp->nlink--;
    80005986:	04a4d783          	lhu	a5,74(s1)
    8000598a:	37fd                	addiw	a5,a5,-1
    8000598c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005990:	8526                	mv	a0,s1
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	fb2080e7          	jalr	-78(ra) # 80003944 <iupdate>
    8000599a:	b781                	j	800058da <sys_unlink+0xe0>
    return -1;
    8000599c:	557d                	li	a0,-1
    8000599e:	a005                	j	800059be <sys_unlink+0x1c4>
    iunlockput(ip);
    800059a0:	854a                	mv	a0,s2
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	2d0080e7          	jalr	720(ra) # 80003c72 <iunlockput>
  iunlockput(dp);
    800059aa:	8526                	mv	a0,s1
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	2c6080e7          	jalr	710(ra) # 80003c72 <iunlockput>
  end_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	aa6080e7          	jalr	-1370(ra) # 8000445a <end_op>
  return -1;
    800059bc:	557d                	li	a0,-1
}
    800059be:	70ae                	ld	ra,232(sp)
    800059c0:	740e                	ld	s0,224(sp)
    800059c2:	64ee                	ld	s1,216(sp)
    800059c4:	694e                	ld	s2,208(sp)
    800059c6:	69ae                	ld	s3,200(sp)
    800059c8:	616d                	addi	sp,sp,240
    800059ca:	8082                	ret

00000000800059cc <sys_open>:

uint64
sys_open(void)
{
    800059cc:	7131                	addi	sp,sp,-192
    800059ce:	fd06                	sd	ra,184(sp)
    800059d0:	f922                	sd	s0,176(sp)
    800059d2:	f526                	sd	s1,168(sp)
    800059d4:	f14a                	sd	s2,160(sp)
    800059d6:	ed4e                	sd	s3,152(sp)
    800059d8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059da:	f4c40593          	addi	a1,s0,-180
    800059de:	4505                	li	a0,1
    800059e0:	ffffd097          	auipc	ra,0xffffd
    800059e4:	366080e7          	jalr	870(ra) # 80002d46 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059e8:	08000613          	li	a2,128
    800059ec:	f5040593          	addi	a1,s0,-176
    800059f0:	4501                	li	a0,0
    800059f2:	ffffd097          	auipc	ra,0xffffd
    800059f6:	394080e7          	jalr	916(ra) # 80002d86 <argstr>
    800059fa:	87aa                	mv	a5,a0
    return -1;
    800059fc:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059fe:	0a07c963          	bltz	a5,80005ab0 <sys_open+0xe4>

  begin_op();
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	9da080e7          	jalr	-1574(ra) # 800043dc <begin_op>

  if(omode & O_CREATE){
    80005a0a:	f4c42783          	lw	a5,-180(s0)
    80005a0e:	2007f793          	andi	a5,a5,512
    80005a12:	cfc5                	beqz	a5,80005aca <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a14:	4681                	li	a3,0
    80005a16:	4601                	li	a2,0
    80005a18:	4589                	li	a1,2
    80005a1a:	f5040513          	addi	a0,s0,-176
    80005a1e:	00000097          	auipc	ra,0x0
    80005a22:	960080e7          	jalr	-1696(ra) # 8000537e <create>
    80005a26:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a28:	c959                	beqz	a0,80005abe <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a2a:	04449703          	lh	a4,68(s1)
    80005a2e:	478d                	li	a5,3
    80005a30:	00f71763          	bne	a4,a5,80005a3e <sys_open+0x72>
    80005a34:	0464d703          	lhu	a4,70(s1)
    80005a38:	47a5                	li	a5,9
    80005a3a:	0ce7ed63          	bltu	a5,a4,80005b14 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	daa080e7          	jalr	-598(ra) # 800047e8 <filealloc>
    80005a46:	89aa                	mv	s3,a0
    80005a48:	10050363          	beqz	a0,80005b4e <sys_open+0x182>
    80005a4c:	00000097          	auipc	ra,0x0
    80005a50:	8f0080e7          	jalr	-1808(ra) # 8000533c <fdalloc>
    80005a54:	892a                	mv	s2,a0
    80005a56:	0e054763          	bltz	a0,80005b44 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a5a:	04449703          	lh	a4,68(s1)
    80005a5e:	478d                	li	a5,3
    80005a60:	0cf70563          	beq	a4,a5,80005b2a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a64:	4789                	li	a5,2
    80005a66:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a6a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a6e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a72:	f4c42783          	lw	a5,-180(s0)
    80005a76:	0017c713          	xori	a4,a5,1
    80005a7a:	8b05                	andi	a4,a4,1
    80005a7c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a80:	0037f713          	andi	a4,a5,3
    80005a84:	00e03733          	snez	a4,a4
    80005a88:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a8c:	4007f793          	andi	a5,a5,1024
    80005a90:	c791                	beqz	a5,80005a9c <sys_open+0xd0>
    80005a92:	04449703          	lh	a4,68(s1)
    80005a96:	4789                	li	a5,2
    80005a98:	0af70063          	beq	a4,a5,80005b38 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	034080e7          	jalr	52(ra) # 80003ad2 <iunlock>
  end_op();
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	9b4080e7          	jalr	-1612(ra) # 8000445a <end_op>

  return fd;
    80005aae:	854a                	mv	a0,s2
}
    80005ab0:	70ea                	ld	ra,184(sp)
    80005ab2:	744a                	ld	s0,176(sp)
    80005ab4:	74aa                	ld	s1,168(sp)
    80005ab6:	790a                	ld	s2,160(sp)
    80005ab8:	69ea                	ld	s3,152(sp)
    80005aba:	6129                	addi	sp,sp,192
    80005abc:	8082                	ret
      end_op();
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	99c080e7          	jalr	-1636(ra) # 8000445a <end_op>
      return -1;
    80005ac6:	557d                	li	a0,-1
    80005ac8:	b7e5                	j	80005ab0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005aca:	f5040513          	addi	a0,s0,-176
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	6ee080e7          	jalr	1774(ra) # 800041bc <namei>
    80005ad6:	84aa                	mv	s1,a0
    80005ad8:	c905                	beqz	a0,80005b08 <sys_open+0x13c>
    ilock(ip);
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	f36080e7          	jalr	-202(ra) # 80003a10 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ae2:	04449703          	lh	a4,68(s1)
    80005ae6:	4785                	li	a5,1
    80005ae8:	f4f711e3          	bne	a4,a5,80005a2a <sys_open+0x5e>
    80005aec:	f4c42783          	lw	a5,-180(s0)
    80005af0:	d7b9                	beqz	a5,80005a3e <sys_open+0x72>
      iunlockput(ip);
    80005af2:	8526                	mv	a0,s1
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	17e080e7          	jalr	382(ra) # 80003c72 <iunlockput>
      end_op();
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	95e080e7          	jalr	-1698(ra) # 8000445a <end_op>
      return -1;
    80005b04:	557d                	li	a0,-1
    80005b06:	b76d                	j	80005ab0 <sys_open+0xe4>
      end_op();
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	952080e7          	jalr	-1710(ra) # 8000445a <end_op>
      return -1;
    80005b10:	557d                	li	a0,-1
    80005b12:	bf79                	j	80005ab0 <sys_open+0xe4>
    iunlockput(ip);
    80005b14:	8526                	mv	a0,s1
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	15c080e7          	jalr	348(ra) # 80003c72 <iunlockput>
    end_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	93c080e7          	jalr	-1732(ra) # 8000445a <end_op>
    return -1;
    80005b26:	557d                	li	a0,-1
    80005b28:	b761                	j	80005ab0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b2a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b2e:	04649783          	lh	a5,70(s1)
    80005b32:	02f99223          	sh	a5,36(s3)
    80005b36:	bf25                	j	80005a6e <sys_open+0xa2>
    itrunc(ip);
    80005b38:	8526                	mv	a0,s1
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	fe4080e7          	jalr	-28(ra) # 80003b1e <itrunc>
    80005b42:	bfa9                	j	80005a9c <sys_open+0xd0>
      fileclose(f);
    80005b44:	854e                	mv	a0,s3
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	d5e080e7          	jalr	-674(ra) # 800048a4 <fileclose>
    iunlockput(ip);
    80005b4e:	8526                	mv	a0,s1
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	122080e7          	jalr	290(ra) # 80003c72 <iunlockput>
    end_op();
    80005b58:	fffff097          	auipc	ra,0xfffff
    80005b5c:	902080e7          	jalr	-1790(ra) # 8000445a <end_op>
    return -1;
    80005b60:	557d                	li	a0,-1
    80005b62:	b7b9                	j	80005ab0 <sys_open+0xe4>

0000000080005b64 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b64:	7175                	addi	sp,sp,-144
    80005b66:	e506                	sd	ra,136(sp)
    80005b68:	e122                	sd	s0,128(sp)
    80005b6a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	870080e7          	jalr	-1936(ra) # 800043dc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b74:	08000613          	li	a2,128
    80005b78:	f7040593          	addi	a1,s0,-144
    80005b7c:	4501                	li	a0,0
    80005b7e:	ffffd097          	auipc	ra,0xffffd
    80005b82:	208080e7          	jalr	520(ra) # 80002d86 <argstr>
    80005b86:	02054963          	bltz	a0,80005bb8 <sys_mkdir+0x54>
    80005b8a:	4681                	li	a3,0
    80005b8c:	4601                	li	a2,0
    80005b8e:	4585                	li	a1,1
    80005b90:	f7040513          	addi	a0,s0,-144
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	7ea080e7          	jalr	2026(ra) # 8000537e <create>
    80005b9c:	cd11                	beqz	a0,80005bb8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b9e:	ffffe097          	auipc	ra,0xffffe
    80005ba2:	0d4080e7          	jalr	212(ra) # 80003c72 <iunlockput>
  end_op();
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	8b4080e7          	jalr	-1868(ra) # 8000445a <end_op>
  return 0;
    80005bae:	4501                	li	a0,0
}
    80005bb0:	60aa                	ld	ra,136(sp)
    80005bb2:	640a                	ld	s0,128(sp)
    80005bb4:	6149                	addi	sp,sp,144
    80005bb6:	8082                	ret
    end_op();
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	8a2080e7          	jalr	-1886(ra) # 8000445a <end_op>
    return -1;
    80005bc0:	557d                	li	a0,-1
    80005bc2:	b7fd                	j	80005bb0 <sys_mkdir+0x4c>

0000000080005bc4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005bc4:	7135                	addi	sp,sp,-160
    80005bc6:	ed06                	sd	ra,152(sp)
    80005bc8:	e922                	sd	s0,144(sp)
    80005bca:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	810080e7          	jalr	-2032(ra) # 800043dc <begin_op>
  argint(1, &major);
    80005bd4:	f6c40593          	addi	a1,s0,-148
    80005bd8:	4505                	li	a0,1
    80005bda:	ffffd097          	auipc	ra,0xffffd
    80005bde:	16c080e7          	jalr	364(ra) # 80002d46 <argint>
  argint(2, &minor);
    80005be2:	f6840593          	addi	a1,s0,-152
    80005be6:	4509                	li	a0,2
    80005be8:	ffffd097          	auipc	ra,0xffffd
    80005bec:	15e080e7          	jalr	350(ra) # 80002d46 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bf0:	08000613          	li	a2,128
    80005bf4:	f7040593          	addi	a1,s0,-144
    80005bf8:	4501                	li	a0,0
    80005bfa:	ffffd097          	auipc	ra,0xffffd
    80005bfe:	18c080e7          	jalr	396(ra) # 80002d86 <argstr>
    80005c02:	02054b63          	bltz	a0,80005c38 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c06:	f6841683          	lh	a3,-152(s0)
    80005c0a:	f6c41603          	lh	a2,-148(s0)
    80005c0e:	458d                	li	a1,3
    80005c10:	f7040513          	addi	a0,s0,-144
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	76a080e7          	jalr	1898(ra) # 8000537e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c1c:	cd11                	beqz	a0,80005c38 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	054080e7          	jalr	84(ra) # 80003c72 <iunlockput>
  end_op();
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	834080e7          	jalr	-1996(ra) # 8000445a <end_op>
  return 0;
    80005c2e:	4501                	li	a0,0
}
    80005c30:	60ea                	ld	ra,152(sp)
    80005c32:	644a                	ld	s0,144(sp)
    80005c34:	610d                	addi	sp,sp,160
    80005c36:	8082                	ret
    end_op();
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	822080e7          	jalr	-2014(ra) # 8000445a <end_op>
    return -1;
    80005c40:	557d                	li	a0,-1
    80005c42:	b7fd                	j	80005c30 <sys_mknod+0x6c>

0000000080005c44 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c44:	7135                	addi	sp,sp,-160
    80005c46:	ed06                	sd	ra,152(sp)
    80005c48:	e922                	sd	s0,144(sp)
    80005c4a:	e526                	sd	s1,136(sp)
    80005c4c:	e14a                	sd	s2,128(sp)
    80005c4e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c50:	ffffc097          	auipc	ra,0xffffc
    80005c54:	d5c080e7          	jalr	-676(ra) # 800019ac <myproc>
    80005c58:	892a                	mv	s2,a0
  
  begin_op();
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	782080e7          	jalr	1922(ra) # 800043dc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c62:	08000613          	li	a2,128
    80005c66:	f6040593          	addi	a1,s0,-160
    80005c6a:	4501                	li	a0,0
    80005c6c:	ffffd097          	auipc	ra,0xffffd
    80005c70:	11a080e7          	jalr	282(ra) # 80002d86 <argstr>
    80005c74:	04054b63          	bltz	a0,80005cca <sys_chdir+0x86>
    80005c78:	f6040513          	addi	a0,s0,-160
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	540080e7          	jalr	1344(ra) # 800041bc <namei>
    80005c84:	84aa                	mv	s1,a0
    80005c86:	c131                	beqz	a0,80005cca <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c88:	ffffe097          	auipc	ra,0xffffe
    80005c8c:	d88080e7          	jalr	-632(ra) # 80003a10 <ilock>
  if(ip->type != T_DIR){
    80005c90:	04449703          	lh	a4,68(s1)
    80005c94:	4785                	li	a5,1
    80005c96:	04f71063          	bne	a4,a5,80005cd6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c9a:	8526                	mv	a0,s1
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	e36080e7          	jalr	-458(ra) # 80003ad2 <iunlock>
  iput(p->cwd);
    80005ca4:	15093503          	ld	a0,336(s2)
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	f22080e7          	jalr	-222(ra) # 80003bca <iput>
  end_op();
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	7aa080e7          	jalr	1962(ra) # 8000445a <end_op>
  p->cwd = ip;
    80005cb8:	14993823          	sd	s1,336(s2)
  return 0;
    80005cbc:	4501                	li	a0,0
}
    80005cbe:	60ea                	ld	ra,152(sp)
    80005cc0:	644a                	ld	s0,144(sp)
    80005cc2:	64aa                	ld	s1,136(sp)
    80005cc4:	690a                	ld	s2,128(sp)
    80005cc6:	610d                	addi	sp,sp,160
    80005cc8:	8082                	ret
    end_op();
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	790080e7          	jalr	1936(ra) # 8000445a <end_op>
    return -1;
    80005cd2:	557d                	li	a0,-1
    80005cd4:	b7ed                	j	80005cbe <sys_chdir+0x7a>
    iunlockput(ip);
    80005cd6:	8526                	mv	a0,s1
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	f9a080e7          	jalr	-102(ra) # 80003c72 <iunlockput>
    end_op();
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	77a080e7          	jalr	1914(ra) # 8000445a <end_op>
    return -1;
    80005ce8:	557d                	li	a0,-1
    80005cea:	bfd1                	j	80005cbe <sys_chdir+0x7a>

0000000080005cec <sys_exec>:

uint64
sys_exec(void)
{
    80005cec:	7145                	addi	sp,sp,-464
    80005cee:	e786                	sd	ra,456(sp)
    80005cf0:	e3a2                	sd	s0,448(sp)
    80005cf2:	ff26                	sd	s1,440(sp)
    80005cf4:	fb4a                	sd	s2,432(sp)
    80005cf6:	f74e                	sd	s3,424(sp)
    80005cf8:	f352                	sd	s4,416(sp)
    80005cfa:	ef56                	sd	s5,408(sp)
    80005cfc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005cfe:	e3840593          	addi	a1,s0,-456
    80005d02:	4505                	li	a0,1
    80005d04:	ffffd097          	auipc	ra,0xffffd
    80005d08:	062080e7          	jalr	98(ra) # 80002d66 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005d0c:	08000613          	li	a2,128
    80005d10:	f4040593          	addi	a1,s0,-192
    80005d14:	4501                	li	a0,0
    80005d16:	ffffd097          	auipc	ra,0xffffd
    80005d1a:	070080e7          	jalr	112(ra) # 80002d86 <argstr>
    80005d1e:	87aa                	mv	a5,a0
    return -1;
    80005d20:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005d22:	0c07c363          	bltz	a5,80005de8 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005d26:	10000613          	li	a2,256
    80005d2a:	4581                	li	a1,0
    80005d2c:	e4040513          	addi	a0,s0,-448
    80005d30:	ffffb097          	auipc	ra,0xffffb
    80005d34:	fa2080e7          	jalr	-94(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d38:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d3c:	89a6                	mv	s3,s1
    80005d3e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d40:	02000a13          	li	s4,32
    80005d44:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d48:	00391513          	slli	a0,s2,0x3
    80005d4c:	e3040593          	addi	a1,s0,-464
    80005d50:	e3843783          	ld	a5,-456(s0)
    80005d54:	953e                	add	a0,a0,a5
    80005d56:	ffffd097          	auipc	ra,0xffffd
    80005d5a:	f52080e7          	jalr	-174(ra) # 80002ca8 <fetchaddr>
    80005d5e:	02054a63          	bltz	a0,80005d92 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005d62:	e3043783          	ld	a5,-464(s0)
    80005d66:	c3b9                	beqz	a5,80005dac <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d68:	ffffb097          	auipc	ra,0xffffb
    80005d6c:	d7e080e7          	jalr	-642(ra) # 80000ae6 <kalloc>
    80005d70:	85aa                	mv	a1,a0
    80005d72:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d76:	cd11                	beqz	a0,80005d92 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d78:	6605                	lui	a2,0x1
    80005d7a:	e3043503          	ld	a0,-464(s0)
    80005d7e:	ffffd097          	auipc	ra,0xffffd
    80005d82:	f7c080e7          	jalr	-132(ra) # 80002cfa <fetchstr>
    80005d86:	00054663          	bltz	a0,80005d92 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d8a:	0905                	addi	s2,s2,1
    80005d8c:	09a1                	addi	s3,s3,8
    80005d8e:	fb491be3          	bne	s2,s4,80005d44 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d92:	f4040913          	addi	s2,s0,-192
    80005d96:	6088                	ld	a0,0(s1)
    80005d98:	c539                	beqz	a0,80005de6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d9a:	ffffb097          	auipc	ra,0xffffb
    80005d9e:	c4e080e7          	jalr	-946(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005da2:	04a1                	addi	s1,s1,8
    80005da4:	ff2499e3          	bne	s1,s2,80005d96 <sys_exec+0xaa>
  return -1;
    80005da8:	557d                	li	a0,-1
    80005daa:	a83d                	j	80005de8 <sys_exec+0xfc>
      argv[i] = 0;
    80005dac:	0a8e                	slli	s5,s5,0x3
    80005dae:	fc0a8793          	addi	a5,s5,-64
    80005db2:	00878ab3          	add	s5,a5,s0
    80005db6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005dba:	e4040593          	addi	a1,s0,-448
    80005dbe:	f4040513          	addi	a0,s0,-192
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	15c080e7          	jalr	348(ra) # 80004f1e <exec>
    80005dca:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dcc:	f4040993          	addi	s3,s0,-192
    80005dd0:	6088                	ld	a0,0(s1)
    80005dd2:	c901                	beqz	a0,80005de2 <sys_exec+0xf6>
    kfree(argv[i]);
    80005dd4:	ffffb097          	auipc	ra,0xffffb
    80005dd8:	c14080e7          	jalr	-1004(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ddc:	04a1                	addi	s1,s1,8
    80005dde:	ff3499e3          	bne	s1,s3,80005dd0 <sys_exec+0xe4>
  return ret;
    80005de2:	854a                	mv	a0,s2
    80005de4:	a011                	j	80005de8 <sys_exec+0xfc>
  return -1;
    80005de6:	557d                	li	a0,-1
}
    80005de8:	60be                	ld	ra,456(sp)
    80005dea:	641e                	ld	s0,448(sp)
    80005dec:	74fa                	ld	s1,440(sp)
    80005dee:	795a                	ld	s2,432(sp)
    80005df0:	79ba                	ld	s3,424(sp)
    80005df2:	7a1a                	ld	s4,416(sp)
    80005df4:	6afa                	ld	s5,408(sp)
    80005df6:	6179                	addi	sp,sp,464
    80005df8:	8082                	ret

0000000080005dfa <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dfa:	7139                	addi	sp,sp,-64
    80005dfc:	fc06                	sd	ra,56(sp)
    80005dfe:	f822                	sd	s0,48(sp)
    80005e00:	f426                	sd	s1,40(sp)
    80005e02:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e04:	ffffc097          	auipc	ra,0xffffc
    80005e08:	ba8080e7          	jalr	-1112(ra) # 800019ac <myproc>
    80005e0c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005e0e:	fd840593          	addi	a1,s0,-40
    80005e12:	4501                	li	a0,0
    80005e14:	ffffd097          	auipc	ra,0xffffd
    80005e18:	f52080e7          	jalr	-174(ra) # 80002d66 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005e1c:	fc840593          	addi	a1,s0,-56
    80005e20:	fd040513          	addi	a0,s0,-48
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	db0080e7          	jalr	-592(ra) # 80004bd4 <pipealloc>
    return -1;
    80005e2c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e2e:	0c054463          	bltz	a0,80005ef6 <sys_pipe+0xfc>
  fd0 = -1;
    80005e32:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e36:	fd043503          	ld	a0,-48(s0)
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	502080e7          	jalr	1282(ra) # 8000533c <fdalloc>
    80005e42:	fca42223          	sw	a0,-60(s0)
    80005e46:	08054b63          	bltz	a0,80005edc <sys_pipe+0xe2>
    80005e4a:	fc843503          	ld	a0,-56(s0)
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	4ee080e7          	jalr	1262(ra) # 8000533c <fdalloc>
    80005e56:	fca42023          	sw	a0,-64(s0)
    80005e5a:	06054863          	bltz	a0,80005eca <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e5e:	4691                	li	a3,4
    80005e60:	fc440613          	addi	a2,s0,-60
    80005e64:	fd843583          	ld	a1,-40(s0)
    80005e68:	68a8                	ld	a0,80(s1)
    80005e6a:	ffffc097          	auipc	ra,0xffffc
    80005e6e:	802080e7          	jalr	-2046(ra) # 8000166c <copyout>
    80005e72:	02054063          	bltz	a0,80005e92 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e76:	4691                	li	a3,4
    80005e78:	fc040613          	addi	a2,s0,-64
    80005e7c:	fd843583          	ld	a1,-40(s0)
    80005e80:	0591                	addi	a1,a1,4
    80005e82:	68a8                	ld	a0,80(s1)
    80005e84:	ffffb097          	auipc	ra,0xffffb
    80005e88:	7e8080e7          	jalr	2024(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e8c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e8e:	06055463          	bgez	a0,80005ef6 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e92:	fc442783          	lw	a5,-60(s0)
    80005e96:	07e9                	addi	a5,a5,26
    80005e98:	078e                	slli	a5,a5,0x3
    80005e9a:	97a6                	add	a5,a5,s1
    80005e9c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ea0:	fc042783          	lw	a5,-64(s0)
    80005ea4:	07e9                	addi	a5,a5,26
    80005ea6:	078e                	slli	a5,a5,0x3
    80005ea8:	94be                	add	s1,s1,a5
    80005eaa:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005eae:	fd043503          	ld	a0,-48(s0)
    80005eb2:	fffff097          	auipc	ra,0xfffff
    80005eb6:	9f2080e7          	jalr	-1550(ra) # 800048a4 <fileclose>
    fileclose(wf);
    80005eba:	fc843503          	ld	a0,-56(s0)
    80005ebe:	fffff097          	auipc	ra,0xfffff
    80005ec2:	9e6080e7          	jalr	-1562(ra) # 800048a4 <fileclose>
    return -1;
    80005ec6:	57fd                	li	a5,-1
    80005ec8:	a03d                	j	80005ef6 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005eca:	fc442783          	lw	a5,-60(s0)
    80005ece:	0007c763          	bltz	a5,80005edc <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ed2:	07e9                	addi	a5,a5,26
    80005ed4:	078e                	slli	a5,a5,0x3
    80005ed6:	97a6                	add	a5,a5,s1
    80005ed8:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005edc:	fd043503          	ld	a0,-48(s0)
    80005ee0:	fffff097          	auipc	ra,0xfffff
    80005ee4:	9c4080e7          	jalr	-1596(ra) # 800048a4 <fileclose>
    fileclose(wf);
    80005ee8:	fc843503          	ld	a0,-56(s0)
    80005eec:	fffff097          	auipc	ra,0xfffff
    80005ef0:	9b8080e7          	jalr	-1608(ra) # 800048a4 <fileclose>
    return -1;
    80005ef4:	57fd                	li	a5,-1
}
    80005ef6:	853e                	mv	a0,a5
    80005ef8:	70e2                	ld	ra,56(sp)
    80005efa:	7442                	ld	s0,48(sp)
    80005efc:	74a2                	ld	s1,40(sp)
    80005efe:	6121                	addi	sp,sp,64
    80005f00:	8082                	ret
	...

0000000080005f10 <kernelvec>:
    80005f10:	7111                	addi	sp,sp,-256
    80005f12:	e006                	sd	ra,0(sp)
    80005f14:	e40a                	sd	sp,8(sp)
    80005f16:	e80e                	sd	gp,16(sp)
    80005f18:	ec12                	sd	tp,24(sp)
    80005f1a:	f016                	sd	t0,32(sp)
    80005f1c:	f41a                	sd	t1,40(sp)
    80005f1e:	f81e                	sd	t2,48(sp)
    80005f20:	fc22                	sd	s0,56(sp)
    80005f22:	e0a6                	sd	s1,64(sp)
    80005f24:	e4aa                	sd	a0,72(sp)
    80005f26:	e8ae                	sd	a1,80(sp)
    80005f28:	ecb2                	sd	a2,88(sp)
    80005f2a:	f0b6                	sd	a3,96(sp)
    80005f2c:	f4ba                	sd	a4,104(sp)
    80005f2e:	f8be                	sd	a5,112(sp)
    80005f30:	fcc2                	sd	a6,120(sp)
    80005f32:	e146                	sd	a7,128(sp)
    80005f34:	e54a                	sd	s2,136(sp)
    80005f36:	e94e                	sd	s3,144(sp)
    80005f38:	ed52                	sd	s4,152(sp)
    80005f3a:	f156                	sd	s5,160(sp)
    80005f3c:	f55a                	sd	s6,168(sp)
    80005f3e:	f95e                	sd	s7,176(sp)
    80005f40:	fd62                	sd	s8,184(sp)
    80005f42:	e1e6                	sd	s9,192(sp)
    80005f44:	e5ea                	sd	s10,200(sp)
    80005f46:	e9ee                	sd	s11,208(sp)
    80005f48:	edf2                	sd	t3,216(sp)
    80005f4a:	f1f6                	sd	t4,224(sp)
    80005f4c:	f5fa                	sd	t5,232(sp)
    80005f4e:	f9fe                	sd	t6,240(sp)
    80005f50:	c25fc0ef          	jal	ra,80002b74 <kerneltrap>
    80005f54:	6082                	ld	ra,0(sp)
    80005f56:	6122                	ld	sp,8(sp)
    80005f58:	61c2                	ld	gp,16(sp)
    80005f5a:	7282                	ld	t0,32(sp)
    80005f5c:	7322                	ld	t1,40(sp)
    80005f5e:	73c2                	ld	t2,48(sp)
    80005f60:	7462                	ld	s0,56(sp)
    80005f62:	6486                	ld	s1,64(sp)
    80005f64:	6526                	ld	a0,72(sp)
    80005f66:	65c6                	ld	a1,80(sp)
    80005f68:	6666                	ld	a2,88(sp)
    80005f6a:	7686                	ld	a3,96(sp)
    80005f6c:	7726                	ld	a4,104(sp)
    80005f6e:	77c6                	ld	a5,112(sp)
    80005f70:	7866                	ld	a6,120(sp)
    80005f72:	688a                	ld	a7,128(sp)
    80005f74:	692a                	ld	s2,136(sp)
    80005f76:	69ca                	ld	s3,144(sp)
    80005f78:	6a6a                	ld	s4,152(sp)
    80005f7a:	7a8a                	ld	s5,160(sp)
    80005f7c:	7b2a                	ld	s6,168(sp)
    80005f7e:	7bca                	ld	s7,176(sp)
    80005f80:	7c6a                	ld	s8,184(sp)
    80005f82:	6c8e                	ld	s9,192(sp)
    80005f84:	6d2e                	ld	s10,200(sp)
    80005f86:	6dce                	ld	s11,208(sp)
    80005f88:	6e6e                	ld	t3,216(sp)
    80005f8a:	7e8e                	ld	t4,224(sp)
    80005f8c:	7f2e                	ld	t5,232(sp)
    80005f8e:	7fce                	ld	t6,240(sp)
    80005f90:	6111                	addi	sp,sp,256
    80005f92:	10200073          	sret
    80005f96:	00000013          	nop
    80005f9a:	00000013          	nop
    80005f9e:	0001                	nop

0000000080005fa0 <timervec>:
    80005fa0:	34051573          	csrrw	a0,mscratch,a0
    80005fa4:	e10c                	sd	a1,0(a0)
    80005fa6:	e510                	sd	a2,8(a0)
    80005fa8:	e914                	sd	a3,16(a0)
    80005faa:	6d0c                	ld	a1,24(a0)
    80005fac:	7110                	ld	a2,32(a0)
    80005fae:	6194                	ld	a3,0(a1)
    80005fb0:	96b2                	add	a3,a3,a2
    80005fb2:	e194                	sd	a3,0(a1)
    80005fb4:	4589                	li	a1,2
    80005fb6:	14459073          	csrw	sip,a1
    80005fba:	6914                	ld	a3,16(a0)
    80005fbc:	6510                	ld	a2,8(a0)
    80005fbe:	610c                	ld	a1,0(a0)
    80005fc0:	34051573          	csrrw	a0,mscratch,a0
    80005fc4:	30200073          	mret
	...

0000000080005fca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fca:	1141                	addi	sp,sp,-16
    80005fcc:	e422                	sd	s0,8(sp)
    80005fce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fd0:	0c0007b7          	lui	a5,0xc000
    80005fd4:	4705                	li	a4,1
    80005fd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fd8:	c3d8                	sw	a4,4(a5)
}
    80005fda:	6422                	ld	s0,8(sp)
    80005fdc:	0141                	addi	sp,sp,16
    80005fde:	8082                	ret

0000000080005fe0 <plicinithart>:

void
plicinithart(void)
{
    80005fe0:	1141                	addi	sp,sp,-16
    80005fe2:	e406                	sd	ra,8(sp)
    80005fe4:	e022                	sd	s0,0(sp)
    80005fe6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fe8:	ffffc097          	auipc	ra,0xffffc
    80005fec:	998080e7          	jalr	-1640(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ff0:	0085171b          	slliw	a4,a0,0x8
    80005ff4:	0c0027b7          	lui	a5,0xc002
    80005ff8:	97ba                	add	a5,a5,a4
    80005ffa:	40200713          	li	a4,1026
    80005ffe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006002:	00d5151b          	slliw	a0,a0,0xd
    80006006:	0c2017b7          	lui	a5,0xc201
    8000600a:	97aa                	add	a5,a5,a0
    8000600c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006010:	60a2                	ld	ra,8(sp)
    80006012:	6402                	ld	s0,0(sp)
    80006014:	0141                	addi	sp,sp,16
    80006016:	8082                	ret

0000000080006018 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006018:	1141                	addi	sp,sp,-16
    8000601a:	e406                	sd	ra,8(sp)
    8000601c:	e022                	sd	s0,0(sp)
    8000601e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006020:	ffffc097          	auipc	ra,0xffffc
    80006024:	960080e7          	jalr	-1696(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006028:	00d5151b          	slliw	a0,a0,0xd
    8000602c:	0c2017b7          	lui	a5,0xc201
    80006030:	97aa                	add	a5,a5,a0
  return irq;
}
    80006032:	43c8                	lw	a0,4(a5)
    80006034:	60a2                	ld	ra,8(sp)
    80006036:	6402                	ld	s0,0(sp)
    80006038:	0141                	addi	sp,sp,16
    8000603a:	8082                	ret

000000008000603c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000603c:	1101                	addi	sp,sp,-32
    8000603e:	ec06                	sd	ra,24(sp)
    80006040:	e822                	sd	s0,16(sp)
    80006042:	e426                	sd	s1,8(sp)
    80006044:	1000                	addi	s0,sp,32
    80006046:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006048:	ffffc097          	auipc	ra,0xffffc
    8000604c:	938080e7          	jalr	-1736(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006050:	00d5151b          	slliw	a0,a0,0xd
    80006054:	0c2017b7          	lui	a5,0xc201
    80006058:	97aa                	add	a5,a5,a0
    8000605a:	c3c4                	sw	s1,4(a5)
}
    8000605c:	60e2                	ld	ra,24(sp)
    8000605e:	6442                	ld	s0,16(sp)
    80006060:	64a2                	ld	s1,8(sp)
    80006062:	6105                	addi	sp,sp,32
    80006064:	8082                	ret

0000000080006066 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006066:	1141                	addi	sp,sp,-16
    80006068:	e406                	sd	ra,8(sp)
    8000606a:	e022                	sd	s0,0(sp)
    8000606c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000606e:	479d                	li	a5,7
    80006070:	04a7cc63          	blt	a5,a0,800060c8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006074:	0001d797          	auipc	a5,0x1d
    80006078:	9cc78793          	addi	a5,a5,-1588 # 80022a40 <disk>
    8000607c:	97aa                	add	a5,a5,a0
    8000607e:	0187c783          	lbu	a5,24(a5)
    80006082:	ebb9                	bnez	a5,800060d8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006084:	00451693          	slli	a3,a0,0x4
    80006088:	0001d797          	auipc	a5,0x1d
    8000608c:	9b878793          	addi	a5,a5,-1608 # 80022a40 <disk>
    80006090:	6398                	ld	a4,0(a5)
    80006092:	9736                	add	a4,a4,a3
    80006094:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006098:	6398                	ld	a4,0(a5)
    8000609a:	9736                	add	a4,a4,a3
    8000609c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800060a0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800060a4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800060a8:	97aa                	add	a5,a5,a0
    800060aa:	4705                	li	a4,1
    800060ac:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800060b0:	0001d517          	auipc	a0,0x1d
    800060b4:	9a850513          	addi	a0,a0,-1624 # 80022a58 <disk+0x18>
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	068080e7          	jalr	104(ra) # 80002120 <wakeup>
}
    800060c0:	60a2                	ld	ra,8(sp)
    800060c2:	6402                	ld	s0,0(sp)
    800060c4:	0141                	addi	sp,sp,16
    800060c6:	8082                	ret
    panic("free_desc 1");
    800060c8:	00002517          	auipc	a0,0x2
    800060cc:	69850513          	addi	a0,a0,1688 # 80008760 <syscalls+0x310>
    800060d0:	ffffa097          	auipc	ra,0xffffa
    800060d4:	470080e7          	jalr	1136(ra) # 80000540 <panic>
    panic("free_desc 2");
    800060d8:	00002517          	auipc	a0,0x2
    800060dc:	69850513          	addi	a0,a0,1688 # 80008770 <syscalls+0x320>
    800060e0:	ffffa097          	auipc	ra,0xffffa
    800060e4:	460080e7          	jalr	1120(ra) # 80000540 <panic>

00000000800060e8 <virtio_disk_init>:
{
    800060e8:	1101                	addi	sp,sp,-32
    800060ea:	ec06                	sd	ra,24(sp)
    800060ec:	e822                	sd	s0,16(sp)
    800060ee:	e426                	sd	s1,8(sp)
    800060f0:	e04a                	sd	s2,0(sp)
    800060f2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060f4:	00002597          	auipc	a1,0x2
    800060f8:	68c58593          	addi	a1,a1,1676 # 80008780 <syscalls+0x330>
    800060fc:	0001d517          	auipc	a0,0x1d
    80006100:	a6c50513          	addi	a0,a0,-1428 # 80022b68 <disk+0x128>
    80006104:	ffffb097          	auipc	ra,0xffffb
    80006108:	a42080e7          	jalr	-1470(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000610c:	100017b7          	lui	a5,0x10001
    80006110:	4398                	lw	a4,0(a5)
    80006112:	2701                	sext.w	a4,a4
    80006114:	747277b7          	lui	a5,0x74727
    80006118:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000611c:	14f71b63          	bne	a4,a5,80006272 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006120:	100017b7          	lui	a5,0x10001
    80006124:	43dc                	lw	a5,4(a5)
    80006126:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006128:	4709                	li	a4,2
    8000612a:	14e79463          	bne	a5,a4,80006272 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000612e:	100017b7          	lui	a5,0x10001
    80006132:	479c                	lw	a5,8(a5)
    80006134:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006136:	12e79e63          	bne	a5,a4,80006272 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000613a:	100017b7          	lui	a5,0x10001
    8000613e:	47d8                	lw	a4,12(a5)
    80006140:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006142:	554d47b7          	lui	a5,0x554d4
    80006146:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000614a:	12f71463          	bne	a4,a5,80006272 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000614e:	100017b7          	lui	a5,0x10001
    80006152:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006156:	4705                	li	a4,1
    80006158:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000615a:	470d                	li	a4,3
    8000615c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000615e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006160:	c7ffe6b7          	lui	a3,0xc7ffe
    80006164:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbbdf>
    80006168:	8f75                	and	a4,a4,a3
    8000616a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000616c:	472d                	li	a4,11
    8000616e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006170:	5bbc                	lw	a5,112(a5)
    80006172:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006176:	8ba1                	andi	a5,a5,8
    80006178:	10078563          	beqz	a5,80006282 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000617c:	100017b7          	lui	a5,0x10001
    80006180:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006184:	43fc                	lw	a5,68(a5)
    80006186:	2781                	sext.w	a5,a5
    80006188:	10079563          	bnez	a5,80006292 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000618c:	100017b7          	lui	a5,0x10001
    80006190:	5bdc                	lw	a5,52(a5)
    80006192:	2781                	sext.w	a5,a5
  if(max == 0)
    80006194:	10078763          	beqz	a5,800062a2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006198:	471d                	li	a4,7
    8000619a:	10f77c63          	bgeu	a4,a5,800062b2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000619e:	ffffb097          	auipc	ra,0xffffb
    800061a2:	948080e7          	jalr	-1720(ra) # 80000ae6 <kalloc>
    800061a6:	0001d497          	auipc	s1,0x1d
    800061aa:	89a48493          	addi	s1,s1,-1894 # 80022a40 <disk>
    800061ae:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800061b0:	ffffb097          	auipc	ra,0xffffb
    800061b4:	936080e7          	jalr	-1738(ra) # 80000ae6 <kalloc>
    800061b8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800061ba:	ffffb097          	auipc	ra,0xffffb
    800061be:	92c080e7          	jalr	-1748(ra) # 80000ae6 <kalloc>
    800061c2:	87aa                	mv	a5,a0
    800061c4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800061c6:	6088                	ld	a0,0(s1)
    800061c8:	cd6d                	beqz	a0,800062c2 <virtio_disk_init+0x1da>
    800061ca:	0001d717          	auipc	a4,0x1d
    800061ce:	87e73703          	ld	a4,-1922(a4) # 80022a48 <disk+0x8>
    800061d2:	cb65                	beqz	a4,800062c2 <virtio_disk_init+0x1da>
    800061d4:	c7fd                	beqz	a5,800062c2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800061d6:	6605                	lui	a2,0x1
    800061d8:	4581                	li	a1,0
    800061da:	ffffb097          	auipc	ra,0xffffb
    800061de:	af8080e7          	jalr	-1288(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800061e2:	0001d497          	auipc	s1,0x1d
    800061e6:	85e48493          	addi	s1,s1,-1954 # 80022a40 <disk>
    800061ea:	6605                	lui	a2,0x1
    800061ec:	4581                	li	a1,0
    800061ee:	6488                	ld	a0,8(s1)
    800061f0:	ffffb097          	auipc	ra,0xffffb
    800061f4:	ae2080e7          	jalr	-1310(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800061f8:	6605                	lui	a2,0x1
    800061fa:	4581                	li	a1,0
    800061fc:	6888                	ld	a0,16(s1)
    800061fe:	ffffb097          	auipc	ra,0xffffb
    80006202:	ad4080e7          	jalr	-1324(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006206:	100017b7          	lui	a5,0x10001
    8000620a:	4721                	li	a4,8
    8000620c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000620e:	4098                	lw	a4,0(s1)
    80006210:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006214:	40d8                	lw	a4,4(s1)
    80006216:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000621a:	6498                	ld	a4,8(s1)
    8000621c:	0007069b          	sext.w	a3,a4
    80006220:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006224:	9701                	srai	a4,a4,0x20
    80006226:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000622a:	6898                	ld	a4,16(s1)
    8000622c:	0007069b          	sext.w	a3,a4
    80006230:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006234:	9701                	srai	a4,a4,0x20
    80006236:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000623a:	4705                	li	a4,1
    8000623c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000623e:	00e48c23          	sb	a4,24(s1)
    80006242:	00e48ca3          	sb	a4,25(s1)
    80006246:	00e48d23          	sb	a4,26(s1)
    8000624a:	00e48da3          	sb	a4,27(s1)
    8000624e:	00e48e23          	sb	a4,28(s1)
    80006252:	00e48ea3          	sb	a4,29(s1)
    80006256:	00e48f23          	sb	a4,30(s1)
    8000625a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000625e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006262:	0727a823          	sw	s2,112(a5)
}
    80006266:	60e2                	ld	ra,24(sp)
    80006268:	6442                	ld	s0,16(sp)
    8000626a:	64a2                	ld	s1,8(sp)
    8000626c:	6902                	ld	s2,0(sp)
    8000626e:	6105                	addi	sp,sp,32
    80006270:	8082                	ret
    panic("could not find virtio disk");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	51e50513          	addi	a0,a0,1310 # 80008790 <syscalls+0x340>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c6080e7          	jalr	710(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	52e50513          	addi	a0,a0,1326 # 800087b0 <syscalls+0x360>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b6080e7          	jalr	694(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	53e50513          	addi	a0,a0,1342 # 800087d0 <syscalls+0x380>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2a6080e7          	jalr	678(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800062a2:	00002517          	auipc	a0,0x2
    800062a6:	54e50513          	addi	a0,a0,1358 # 800087f0 <syscalls+0x3a0>
    800062aa:	ffffa097          	auipc	ra,0xffffa
    800062ae:	296080e7          	jalr	662(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800062b2:	00002517          	auipc	a0,0x2
    800062b6:	55e50513          	addi	a0,a0,1374 # 80008810 <syscalls+0x3c0>
    800062ba:	ffffa097          	auipc	ra,0xffffa
    800062be:	286080e7          	jalr	646(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800062c2:	00002517          	auipc	a0,0x2
    800062c6:	56e50513          	addi	a0,a0,1390 # 80008830 <syscalls+0x3e0>
    800062ca:	ffffa097          	auipc	ra,0xffffa
    800062ce:	276080e7          	jalr	630(ra) # 80000540 <panic>

00000000800062d2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062d2:	7119                	addi	sp,sp,-128
    800062d4:	fc86                	sd	ra,120(sp)
    800062d6:	f8a2                	sd	s0,112(sp)
    800062d8:	f4a6                	sd	s1,104(sp)
    800062da:	f0ca                	sd	s2,96(sp)
    800062dc:	ecce                	sd	s3,88(sp)
    800062de:	e8d2                	sd	s4,80(sp)
    800062e0:	e4d6                	sd	s5,72(sp)
    800062e2:	e0da                	sd	s6,64(sp)
    800062e4:	fc5e                	sd	s7,56(sp)
    800062e6:	f862                	sd	s8,48(sp)
    800062e8:	f466                	sd	s9,40(sp)
    800062ea:	f06a                	sd	s10,32(sp)
    800062ec:	ec6e                	sd	s11,24(sp)
    800062ee:	0100                	addi	s0,sp,128
    800062f0:	8aaa                	mv	s5,a0
    800062f2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062f4:	00c52d03          	lw	s10,12(a0)
    800062f8:	001d1d1b          	slliw	s10,s10,0x1
    800062fc:	1d02                	slli	s10,s10,0x20
    800062fe:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006302:	0001d517          	auipc	a0,0x1d
    80006306:	86650513          	addi	a0,a0,-1946 # 80022b68 <disk+0x128>
    8000630a:	ffffb097          	auipc	ra,0xffffb
    8000630e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006312:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006314:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006316:	0001cb97          	auipc	s7,0x1c
    8000631a:	72ab8b93          	addi	s7,s7,1834 # 80022a40 <disk>
  for(int i = 0; i < 3; i++){
    8000631e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006320:	0001dc97          	auipc	s9,0x1d
    80006324:	848c8c93          	addi	s9,s9,-1976 # 80022b68 <disk+0x128>
    80006328:	a08d                	j	8000638a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000632a:	00fb8733          	add	a4,s7,a5
    8000632e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006332:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006334:	0207c563          	bltz	a5,8000635e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006338:	2905                	addiw	s2,s2,1
    8000633a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000633c:	05690c63          	beq	s2,s6,80006394 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006340:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006342:	0001c717          	auipc	a4,0x1c
    80006346:	6fe70713          	addi	a4,a4,1790 # 80022a40 <disk>
    8000634a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000634c:	01874683          	lbu	a3,24(a4)
    80006350:	fee9                	bnez	a3,8000632a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006352:	2785                	addiw	a5,a5,1
    80006354:	0705                	addi	a4,a4,1
    80006356:	fe979be3          	bne	a5,s1,8000634c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000635a:	57fd                	li	a5,-1
    8000635c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000635e:	01205d63          	blez	s2,80006378 <virtio_disk_rw+0xa6>
    80006362:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006364:	000a2503          	lw	a0,0(s4)
    80006368:	00000097          	auipc	ra,0x0
    8000636c:	cfe080e7          	jalr	-770(ra) # 80006066 <free_desc>
      for(int j = 0; j < i; j++)
    80006370:	2d85                	addiw	s11,s11,1
    80006372:	0a11                	addi	s4,s4,4
    80006374:	ff2d98e3          	bne	s11,s2,80006364 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006378:	85e6                	mv	a1,s9
    8000637a:	0001c517          	auipc	a0,0x1c
    8000637e:	6de50513          	addi	a0,a0,1758 # 80022a58 <disk+0x18>
    80006382:	ffffc097          	auipc	ra,0xffffc
    80006386:	d3a080e7          	jalr	-710(ra) # 800020bc <sleep>
  for(int i = 0; i < 3; i++){
    8000638a:	f8040a13          	addi	s4,s0,-128
{
    8000638e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006390:	894e                	mv	s2,s3
    80006392:	b77d                	j	80006340 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006394:	f8042503          	lw	a0,-128(s0)
    80006398:	00a50713          	addi	a4,a0,10
    8000639c:	0712                	slli	a4,a4,0x4

  if(write)
    8000639e:	0001c797          	auipc	a5,0x1c
    800063a2:	6a278793          	addi	a5,a5,1698 # 80022a40 <disk>
    800063a6:	00e786b3          	add	a3,a5,a4
    800063aa:	01803633          	snez	a2,s8
    800063ae:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063b0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800063b4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063b8:	f6070613          	addi	a2,a4,-160
    800063bc:	6394                	ld	a3,0(a5)
    800063be:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063c0:	00870593          	addi	a1,a4,8
    800063c4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063c6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063c8:	0007b803          	ld	a6,0(a5)
    800063cc:	9642                	add	a2,a2,a6
    800063ce:	46c1                	li	a3,16
    800063d0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063d2:	4585                	li	a1,1
    800063d4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800063d8:	f8442683          	lw	a3,-124(s0)
    800063dc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063e0:	0692                	slli	a3,a3,0x4
    800063e2:	9836                	add	a6,a6,a3
    800063e4:	058a8613          	addi	a2,s5,88
    800063e8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800063ec:	0007b803          	ld	a6,0(a5)
    800063f0:	96c2                	add	a3,a3,a6
    800063f2:	40000613          	li	a2,1024
    800063f6:	c690                	sw	a2,8(a3)
  if(write)
    800063f8:	001c3613          	seqz	a2,s8
    800063fc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006400:	00166613          	ori	a2,a2,1
    80006404:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006408:	f8842603          	lw	a2,-120(s0)
    8000640c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006410:	00250693          	addi	a3,a0,2
    80006414:	0692                	slli	a3,a3,0x4
    80006416:	96be                	add	a3,a3,a5
    80006418:	58fd                	li	a7,-1
    8000641a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000641e:	0612                	slli	a2,a2,0x4
    80006420:	9832                	add	a6,a6,a2
    80006422:	f9070713          	addi	a4,a4,-112
    80006426:	973e                	add	a4,a4,a5
    80006428:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000642c:	6398                	ld	a4,0(a5)
    8000642e:	9732                	add	a4,a4,a2
    80006430:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006432:	4609                	li	a2,2
    80006434:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006438:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000643c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006440:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006444:	6794                	ld	a3,8(a5)
    80006446:	0026d703          	lhu	a4,2(a3)
    8000644a:	8b1d                	andi	a4,a4,7
    8000644c:	0706                	slli	a4,a4,0x1
    8000644e:	96ba                	add	a3,a3,a4
    80006450:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006454:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006458:	6798                	ld	a4,8(a5)
    8000645a:	00275783          	lhu	a5,2(a4)
    8000645e:	2785                	addiw	a5,a5,1
    80006460:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006464:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006468:	100017b7          	lui	a5,0x10001
    8000646c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006470:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006474:	0001c917          	auipc	s2,0x1c
    80006478:	6f490913          	addi	s2,s2,1780 # 80022b68 <disk+0x128>
  while(b->disk == 1) {
    8000647c:	4485                	li	s1,1
    8000647e:	00b79c63          	bne	a5,a1,80006496 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006482:	85ca                	mv	a1,s2
    80006484:	8556                	mv	a0,s5
    80006486:	ffffc097          	auipc	ra,0xffffc
    8000648a:	c36080e7          	jalr	-970(ra) # 800020bc <sleep>
  while(b->disk == 1) {
    8000648e:	004aa783          	lw	a5,4(s5)
    80006492:	fe9788e3          	beq	a5,s1,80006482 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006496:	f8042903          	lw	s2,-128(s0)
    8000649a:	00290713          	addi	a4,s2,2
    8000649e:	0712                	slli	a4,a4,0x4
    800064a0:	0001c797          	auipc	a5,0x1c
    800064a4:	5a078793          	addi	a5,a5,1440 # 80022a40 <disk>
    800064a8:	97ba                	add	a5,a5,a4
    800064aa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800064ae:	0001c997          	auipc	s3,0x1c
    800064b2:	59298993          	addi	s3,s3,1426 # 80022a40 <disk>
    800064b6:	00491713          	slli	a4,s2,0x4
    800064ba:	0009b783          	ld	a5,0(s3)
    800064be:	97ba                	add	a5,a5,a4
    800064c0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064c4:	854a                	mv	a0,s2
    800064c6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064ca:	00000097          	auipc	ra,0x0
    800064ce:	b9c080e7          	jalr	-1124(ra) # 80006066 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064d2:	8885                	andi	s1,s1,1
    800064d4:	f0ed                	bnez	s1,800064b6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064d6:	0001c517          	auipc	a0,0x1c
    800064da:	69250513          	addi	a0,a0,1682 # 80022b68 <disk+0x128>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	7ac080e7          	jalr	1964(ra) # 80000c8a <release>
}
    800064e6:	70e6                	ld	ra,120(sp)
    800064e8:	7446                	ld	s0,112(sp)
    800064ea:	74a6                	ld	s1,104(sp)
    800064ec:	7906                	ld	s2,96(sp)
    800064ee:	69e6                	ld	s3,88(sp)
    800064f0:	6a46                	ld	s4,80(sp)
    800064f2:	6aa6                	ld	s5,72(sp)
    800064f4:	6b06                	ld	s6,64(sp)
    800064f6:	7be2                	ld	s7,56(sp)
    800064f8:	7c42                	ld	s8,48(sp)
    800064fa:	7ca2                	ld	s9,40(sp)
    800064fc:	7d02                	ld	s10,32(sp)
    800064fe:	6de2                	ld	s11,24(sp)
    80006500:	6109                	addi	sp,sp,128
    80006502:	8082                	ret

0000000080006504 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006504:	1101                	addi	sp,sp,-32
    80006506:	ec06                	sd	ra,24(sp)
    80006508:	e822                	sd	s0,16(sp)
    8000650a:	e426                	sd	s1,8(sp)
    8000650c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000650e:	0001c497          	auipc	s1,0x1c
    80006512:	53248493          	addi	s1,s1,1330 # 80022a40 <disk>
    80006516:	0001c517          	auipc	a0,0x1c
    8000651a:	65250513          	addi	a0,a0,1618 # 80022b68 <disk+0x128>
    8000651e:	ffffa097          	auipc	ra,0xffffa
    80006522:	6b8080e7          	jalr	1720(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006526:	10001737          	lui	a4,0x10001
    8000652a:	533c                	lw	a5,96(a4)
    8000652c:	8b8d                	andi	a5,a5,3
    8000652e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006530:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006534:	689c                	ld	a5,16(s1)
    80006536:	0204d703          	lhu	a4,32(s1)
    8000653a:	0027d783          	lhu	a5,2(a5)
    8000653e:	04f70863          	beq	a4,a5,8000658e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006542:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006546:	6898                	ld	a4,16(s1)
    80006548:	0204d783          	lhu	a5,32(s1)
    8000654c:	8b9d                	andi	a5,a5,7
    8000654e:	078e                	slli	a5,a5,0x3
    80006550:	97ba                	add	a5,a5,a4
    80006552:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006554:	00278713          	addi	a4,a5,2
    80006558:	0712                	slli	a4,a4,0x4
    8000655a:	9726                	add	a4,a4,s1
    8000655c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006560:	e721                	bnez	a4,800065a8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006562:	0789                	addi	a5,a5,2
    80006564:	0792                	slli	a5,a5,0x4
    80006566:	97a6                	add	a5,a5,s1
    80006568:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000656a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000656e:	ffffc097          	auipc	ra,0xffffc
    80006572:	bb2080e7          	jalr	-1102(ra) # 80002120 <wakeup>

    disk.used_idx += 1;
    80006576:	0204d783          	lhu	a5,32(s1)
    8000657a:	2785                	addiw	a5,a5,1
    8000657c:	17c2                	slli	a5,a5,0x30
    8000657e:	93c1                	srli	a5,a5,0x30
    80006580:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006584:	6898                	ld	a4,16(s1)
    80006586:	00275703          	lhu	a4,2(a4)
    8000658a:	faf71ce3          	bne	a4,a5,80006542 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000658e:	0001c517          	auipc	a0,0x1c
    80006592:	5da50513          	addi	a0,a0,1498 # 80022b68 <disk+0x128>
    80006596:	ffffa097          	auipc	ra,0xffffa
    8000659a:	6f4080e7          	jalr	1780(ra) # 80000c8a <release>
}
    8000659e:	60e2                	ld	ra,24(sp)
    800065a0:	6442                	ld	s0,16(sp)
    800065a2:	64a2                	ld	s1,8(sp)
    800065a4:	6105                	addi	sp,sp,32
    800065a6:	8082                	ret
      panic("virtio_disk_intr status");
    800065a8:	00002517          	auipc	a0,0x2
    800065ac:	2a050513          	addi	a0,a0,672 # 80008848 <syscalls+0x3f8>
    800065b0:	ffffa097          	auipc	ra,0xffffa
    800065b4:	f90080e7          	jalr	-112(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
