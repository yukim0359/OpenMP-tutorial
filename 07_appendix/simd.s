	.arch armv8.5-a
	.build_version macos,  15, 0
	.text
	.align	2
_main._omp_fn.1:
LFB6:
	stp	x29, x30, [sp, -32]!
LCFI0:
	mov	x29, sp
LCFI1:
	stp	x19, x20, [sp, 16]
LCFI2:
	mov	x20, x0
	bl	_omp_get_num_threads
	mov	w19, w0
	bl	_omp_get_thread_num
	mov	w1, 57600
	movk	w1, 0x5f5, lsl 16
	sdiv	w4, w1, w19
	msub	w2, w4, w19, w1
	cmp	w0, w2
	cinc	w4, w4, lt
	csel	w2, w2, wzr, ge
	mul	w3, w4, w0
	add	w5, w2, w3
	add	w0, w4, w5
	cmp	w5, w0
	bge	L1
	ldp	x10, x9, [x20]
	mov	w8, w4
	sub	w0, w4, #1
	cmp	w0, 2
	bls	L11
	sxtw	x0, w3
	add	x0, x0, w2, sxtw
	add	x7, x10, x0, lsl 2
	add	x0, x9, x0, lsl 2
	lsr	w6, w4, 2
	lsl	x6, x6, 4
	mov	x1, 0
L5:
	ldr	q31, [x7, x1]
	add	v31.4s, v31.4s, v31.4s
	str	q31, [x0, x1]
	add	x1, x1, 16
	cmp	x1, x6
	bne	L5
	and	w4, w4, -4
	mov	w6, w4
	add	w5, w5, w4
	cmp	w8, w4
	beq	L1
L4:
	sub	w1, w8, w6
	cmp	w1, 1
	beq	L8
	sxtw	x0, w3
	add	x2, x0, w2, sxtw
	add	x6, x2, w6, uxtw
	lsl	x6, x6, 2
	ldr	d31, [x10, x6]
	add	v31.2s, v31.2s, v31.2s
	str	d31, [x9, x6]
	tbz	x1, 0, L1
	and	w1, w1, -2
	add	w5, w5, w1
L8:
	sbfiz	x5, x5, 2, 32
	ldr	w0, [x10, x5]
	lsl	w0, w0, 1
	str	w0, [x9, x5]
L1:
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 32
LCFI3:
	ret
L11:
LCFI4:
	mov	w6, 0
	b	L4
LFE6:
	.align	2
_main._omp_fn.0:
LFB5:
	stp	x29, x30, [sp, -32]!
LCFI5:
	mov	x29, sp
LCFI6:
	stp	x19, x20, [sp, 16]
LCFI7:
	mov	x20, x0
	bl	_omp_get_num_threads
	mov	w19, w0
	bl	_omp_get_thread_num
	mov	w1, 57600
	movk	w1, 0x5f5, lsl 16
	sdiv	w2, w1, w19
	msub	w1, w2, w19, w1
	cmp	w0, w1
	cinc	w2, w2, lt
	csel	w1, w1, wzr, ge
	madd	w1, w2, w0, w1
	add	w2, w2, w1
	cmp	w1, w2
	bge	L14
	ldr	x4, [x20]
	sxtw	x0, w1
	mov	w3, 100
L17:
	sdiv	w1, w0, w3
	msub	w1, w1, w3, w0
	str	w1, [x4, x0, lsl 2]
	add	x0, x0, 1
	cmp	w2, w0
	bgt	L17
L14:
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 32
LCFI8:
	ret
LFE5:
	.cstring
	.align	3
lC0:
	.ascii "Memory allocation failed\12\0"
	.align	3
lC1:
	.ascii "Dot product (SIMD): %.6f sec\12\0"
	.section __TEXT,__text_startup,regular,pure_instructions
	.align	2
	.globl _main
_main:
LFB4:
	sub	sp, sp, #96
LCFI9:
	stp	x29, x30, [sp, 16]
LCFI10:
	add	x29, sp, 16
LCFI11:
	stp	x19, x20, [sp, 32]
LCFI12:
	mov	x20, 33792
	movk	x20, 0x17d7, lsl 16
	mov	x0, x20
	bl	_malloc
	mov	x19, x0
	mov	x0, x20
	bl	_malloc
	cmp	x19, 0
	ccmp	x0, 0, 4, ne
	beq	L25
	str	d15, [x29, 32]
LCFI13:
	mov	x20, x0
	str	x19, [x29, 56]
	mov	w3, 0
	mov	w2, 0
	add	x1, x29, 56
	adrp	x0, _main._omp_fn.0@PAGE
	add	x0, x0, _main._omp_fn.0@PAGEOFF;
	bl	_GOMP_parallel
	bl	_omp_get_wtime
	fmov	d15, d0
	stp	x19, x20, [x29, 64]
	mov	w3, 0
	mov	w2, 0
	add	x1, x29, 64
	adrp	x0, _main._omp_fn.1@PAGE
	add	x0, x0, _main._omp_fn.1@PAGEOFF;
	bl	_GOMP_parallel
	bl	_omp_get_wtime
	fsub	d0, d0, d15
	str	d0, [sp]
	adrp	x0, lC1@PAGE
	add	x0, x0, lC1@PAGEOFF;
	bl	_printf
	mov	x0, x19
	bl	_free
	mov	x0, x20
	bl	_free
	mov	w0, 0
	ldr	d15, [x29, 32]
LCFI14:
L21:
	ldp	x29, x30, [sp, 16]
	ldp	x19, x20, [sp, 32]
	add	sp, sp, 96
LCFI15:
	ret
L25:
LCFI16:
	adrp	x0, ___stderrp@GOTPAGE
	ldr	x0, [x0, ___stderrp@GOTPAGEOFF]
	ldr	x3, [x0]
	mov	x2, 25
	mov	x1, 1
	adrp	x0, lC0@PAGE
	add	x0, x0, lC0@PAGEOFF;
	bl	_fwrite
	mov	w0, 1
	b	L21
LFE4:
	.section __TEXT,__eh_frame,coalesced,no_toc+strip_static_syms+live_support
EH_frame1:
	.set L$set$0,LECIE1-LSCIE1
	.long L$set$0
LSCIE1:
	.long	0
	.byte	0x3
	.ascii "zR\0"
	.uleb128 0x1
	.sleb128 -8
	.uleb128 0x1e
	.uleb128 0x1
	.byte	0x10
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.align	3
LECIE1:
LSFDE1:
	.set L$set$1,LEFDE1-LASFDE1
	.long L$set$1
LASFDE1:
	.long	LASFDE1-EH_frame1
	.quad	LFB6-.
	.set L$set$2,LFE6-LFB6
	.quad L$set$2
	.uleb128 0
	.byte	0x4
	.set L$set$3,LCFI0-LFB6
	.long L$set$3
	.byte	0xe
	.uleb128 0x20
	.byte	0x9d
	.uleb128 0x4
	.byte	0x9e
	.uleb128 0x3
	.byte	0x4
	.set L$set$4,LCFI1-LCFI0
	.long L$set$4
	.byte	0xd
	.uleb128 0x1d
	.byte	0x4
	.set L$set$5,LCFI2-LCFI1
	.long L$set$5
	.byte	0x93
	.uleb128 0x2
	.byte	0x94
	.uleb128 0x1
	.byte	0x4
	.set L$set$6,LCFI3-LCFI2
	.long L$set$6
	.byte	0xa
	.byte	0xde
	.byte	0xdd
	.byte	0xd3
	.byte	0xd4
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.byte	0x4
	.set L$set$7,LCFI4-LCFI3
	.long L$set$7
	.byte	0xb
	.align	3
LEFDE1:
LSFDE3:
	.set L$set$8,LEFDE3-LASFDE3
	.long L$set$8
LASFDE3:
	.long	LASFDE3-EH_frame1
	.quad	LFB5-.
	.set L$set$9,LFE5-LFB5
	.quad L$set$9
	.uleb128 0
	.byte	0x4
	.set L$set$10,LCFI5-LFB5
	.long L$set$10
	.byte	0xe
	.uleb128 0x20
	.byte	0x9d
	.uleb128 0x4
	.byte	0x9e
	.uleb128 0x3
	.byte	0x4
	.set L$set$11,LCFI6-LCFI5
	.long L$set$11
	.byte	0xd
	.uleb128 0x1d
	.byte	0x4
	.set L$set$12,LCFI7-LCFI6
	.long L$set$12
	.byte	0x93
	.uleb128 0x2
	.byte	0x94
	.uleb128 0x1
	.byte	0x4
	.set L$set$13,LCFI8-LCFI7
	.long L$set$13
	.byte	0xde
	.byte	0xdd
	.byte	0xd3
	.byte	0xd4
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.align	3
LEFDE3:
LSFDE5:
	.set L$set$14,LEFDE5-LASFDE5
	.long L$set$14
LASFDE5:
	.long	LASFDE5-EH_frame1
	.quad	LFB4-.
	.set L$set$15,LFE4-LFB4
	.quad L$set$15
	.uleb128 0
	.byte	0x4
	.set L$set$16,LCFI9-LFB4
	.long L$set$16
	.byte	0xe
	.uleb128 0x60
	.byte	0x4
	.set L$set$17,LCFI10-LCFI9
	.long L$set$17
	.byte	0x9d
	.uleb128 0xa
	.byte	0x9e
	.uleb128 0x9
	.byte	0x4
	.set L$set$18,LCFI11-LCFI10
	.long L$set$18
	.byte	0xc
	.uleb128 0x1d
	.uleb128 0x50
	.byte	0x4
	.set L$set$19,LCFI12-LCFI11
	.long L$set$19
	.byte	0x93
	.uleb128 0x8
	.byte	0x94
	.uleb128 0x7
	.byte	0x4
	.set L$set$20,LCFI13-LCFI12
	.long L$set$20
	.byte	0x5
	.uleb128 0x4f
	.uleb128 0x6
	.byte	0x4
	.set L$set$21,LCFI14-LCFI13
	.long L$set$21
	.byte	0x6
	.uleb128 0x4f
	.byte	0x4
	.set L$set$22,LCFI15-LCFI14
	.long L$set$22
	.byte	0xa
	.byte	0xd3
	.byte	0xd4
	.byte	0xdd
	.byte	0xde
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.byte	0x4
	.set L$set$23,LCFI16-LCFI15
	.long L$set$23
	.byte	0xb
	.align	3
LEFDE5:
	.ident	"GCC: (Homebrew GCC 15.1.0) 15.1.0"
	.subsections_via_symbols
