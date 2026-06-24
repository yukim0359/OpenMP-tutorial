	.arch armv8.5-a
	.build_version macos,  15, 0
	.text
	.align	2
	.p2align 5,,15
	.globl _omp_atomic_double_add
_omp_atomic_double_add:
LFB0:
	fadd	d0, d0, d0
	ldr	x1, [x0]
L2:
	fmov	d31, x1
	mov	x2, x1
	fadd	d31, d0, d31
	fmov	x3, d31
	cas	x2, x3, [x0]
	cmp	x1, x2
	bne	L3
	ret
L3:
	mov	x1, x2
	b	L2
LFE0:
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
	.quad	LFB0-.
	.set L$set$2,LFE0-LFB0
	.quad L$set$2
	.uleb128 0
	.align	3
LEFDE1:
	.ident	"GCC: (Homebrew GCC 15.1.0) 15.1.0"
	.subsections_via_symbols
