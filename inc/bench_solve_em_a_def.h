#ifdef BENCH
   INTEGER, EXTERNAL :: rsl_internal_microclock
   INTEGER btimex, solve_tim
#define SOLVE_START     solve_tim = rsl_internal_microclock()
#define SOLVE_END       solve_tim = rsl_internal_microclock() - solve_tim
#define BENCH_DECL(A)   integer A
#define BENCH_INIT(A)   A=0
#define BENCH_START(A)  btimex=rsl_internal_microclock()
#define BENCH_END(A)    A=A+rsl_internal_microclock()-btimex
!#define BENCH_START(A)    A=A+rsl_internal_microclock()-btimex
!#define BENCH_END(A)  btimex=rsl_internal_microclock()
#define INVERT_TIMING_START(A)  BENCH_END(A)
#define INVERT_TIMING_END(A)  BENCH_START(A)
#define BENCH_REPORT(A) write(0,*)'A= ',A
BENCH_DECL(exch1)
BENCH_DECL(exch2)
BENCH_DECL(exch3)
BENCH_DECL(exch4)
BENCH_DECL(exch5)
BENCH_DECL(exch6)
BENCH_DECL(exch7)
BENCH_DECL(exch8)
BENCH_DECL(exch9)
BENCH_DECL(exch10)
BENCH_DECL(exch11)
BENCH_DECL(exch12)
BENCH_DECL(exch13)
BENCH_DECL(exch14)
BENCH_DECL(exch15)
BENCH_DECL(exch16)
BENCH_DECL(exch17)
BENCH_DECL(exch18)
BENCH_DECL(exch19)
BENCH_DECL(exch20)
BENCH_DECL(exch21)
BENCH_DECL(exch22)
BENCH_DECL(exch23)
BENCH_DECL(exch24)
BENCH_DECL(exch25)
BENCH_DECL(exch26)
BENCH_DECL(exch23)
BENCH_DECL(exch24)
BENCH_DECL(exch25)
BENCH_DECL(exch26)
BENCH_DECL(exch27)
BENCH_DECL(exch28)
BENCH_DECL(exch29)
BENCH_DECL(exch30)
BENCH_DECL(exch31)
BENCH_DECL(exch32)
BENCH_DECL(exch33)
BENCH_DECL(exch34)
BENCH_DECL(exch35)
BENCH_DECL(exch36)
BENCH_DECL(exch37)
BENCH_DECL(exch38)
BENCH_DECL(exch39)
BENCH_DECL(exch40)
BENCH_DECL(exch41)
BENCH_DECL(exch42)
BENCH_DECL(exch43)
BENCH_DECL(exch44)
BENCH_DECL(exch45)
BENCH_DECL(exch46)
BENCH_DECL(exch47)
BENCH_DECL(exch48)
BENCH_DECL(exch49)
BENCH_DECL(exch50)
BENCH_DECL(exch51)
BENCH_DECL(exch52)
BENCH_DECL(exch53)
BENCH_DECL(exch54)
BENCH_DECL(exch55)
BENCH_DECL(exch56)
BENCH_DECL(exch57)
BENCH_DECL(exch58)
BENCH_DECL(exch59)
BENCH_DECL(exch60)
BENCH_DECL(exch61)
BENCH_DECL(exch62)
BENCH_DECL(exch63)
BENCH_DECL(exch64)
BENCH_DECL(exch65)
BENCH_DECL(exch66)
BENCH_DECL(exch67)
BENCH_DECL(exch68)
BENCH_DECL(exch69)
BENCH_DECL(exch70)
BENCH_DECL(exch71)
BENCH_DECL(exch72)
BENCH_DECL(exch73)
BENCH_DECL(exch74)
BENCH_DECL(exch75)
BENCH_DECL(exch76)
BENCH_DECL(exch77)
BENCH_DECL(exch78)
BENCH_DECL(exch79)
BENCH_DECL(exch80)
BENCH_DECL(exch81)
BENCH_DECL(exch82)
BENCH_DECL(exch83)
BENCH_DECL(exch84)
BENCH_DECL(exch85)
BENCH_DECL(exch86)
BENCH_DECL(exch87)
BENCH_DECL(exch88)
BENCH_DECL(exch89)
BENCH_DECL(exch90)
BENCH_DECL(exch91)
BENCH_DECL(exch92)
BENCH_DECL(exch93)
BENCH_DECL(exch94)
BENCH_DECL(exch95)
BENCH_DECL(exch96)
BENCH_DECL(exch97)
BENCH_DECL(exch98)
BENCH_DECL(exch99)
BENCH_DECL(exch100)
BENCH_DECL(exch101)
BENCH_DECL(exch102)
BENCH_DECL(exch103)
BENCH_DECL(exch104)
BENCH_DECL(exch105)
BENCH_DECL(exch106)
BENCH_DECL(exch107)
BENCH_DECL(exch108)
BENCH_DECL(exch109)
BENCH_DECL(exch110)
BENCH_DECL(exch111)
BENCH_DECL(exch112)
BENCH_DECL(exch113)
BENCH_DECL(exch114)

BENCH_DECL(comp1)
BENCH_DECL(comp2)
BENCH_DECL(comp3)
BENCH_DECL(comp4)
BENCH_DECL(comp5)
BENCH_DECL(comp6)
BENCH_DECL(comp7)
BENCH_DECL(comp8)
BENCH_DECL(comp9)
BENCH_DECL(comp10)
BENCH_DECL(comp11)
BENCH_DECL(comp12)
BENCH_DECL(comp13)
BENCH_DECL(comp14)
BENCH_DECL(comp15)
BENCH_DECL(comp16)
BENCH_DECL(comp17)
BENCH_DECL(comp18)
BENCH_DECL(comp19)
BENCH_DECL(comp20)
BENCH_DECL(comp21)
BENCH_DECL(comp22)
BENCH_DECL(comp23)
BENCH_DECL(comp24)
BENCH_DECL(comp25)
BENCH_DECL(comp26)
BENCH_DECL(comp27)
BENCH_DECL(comp28)
BENCH_DECL(comp29)
BENCH_DECL(comp30)
BENCH_DECL(comp31)
BENCH_DECL(comp32)
BENCH_DECL(comp33)
BENCH_DECL(comp34)
BENCH_DECL(comp35)
BENCH_DECL(comp36)
BENCH_DECL(comp37)
BENCH_DECL(comp38)
BENCH_DECL(comp39)
BENCH_DECL(comp40)
BENCH_DECL(comp41)
BENCH_DECL(comp42)
BENCH_DECL(comp43)
BENCH_DECL(comp44)
BENCH_DECL(comp45)
BENCH_DECL(comp46)
BENCH_DECL(comp47)
BENCH_DECL(comp48)
BENCH_DECL(comp49)
BENCH_DECL(comp50)
BENCH_DECL(comp51)
BENCH_DECL(comp52)
BENCH_DECL(comp53)
BENCH_DECL(comp54)
BENCH_DECL(comp55)
BENCH_DECL(comp56)
BENCH_DECL(comp57)
BENCH_DECL(comp58)
BENCH_DECL(comp59)
BENCH_DECL(comp60)
BENCH_DECL(comp61)
BENCH_DECL(comp62)
BENCH_DECL(comp63)
BENCH_DECL(comp64)
BENCH_DECL(comp65)
BENCH_DECL(comp66)
BENCH_DECL(comp67)
BENCH_DECL(comp68)
BENCH_DECL(comp69)
BENCH_DECL(comp70)
BENCH_DECL(comp71)
BENCH_DECL(comp72)
BENCH_DECL(comp73)
BENCH_DECL(comp74)
BENCH_DECL(comp75)
BENCH_DECL(comp76)
BENCH_DECL(comp77)
BENCH_DECL(comp78)
BENCH_DECL(comp79)
BENCH_DECL(comp80)
BENCH_DECL(comp81)
BENCH_DECL(comp82)
BENCH_DECL(comp83)
BENCH_DECL(comp84)
BENCH_DECL(comp85)
BENCH_DECL(comp86)
BENCH_DECL(comp87)
BENCH_DECL(comp88)
BENCH_DECL(comp89)
BENCH_DECL(comp90)
BENCH_DECL(comp91)
BENCH_DECL(comp92)
BENCH_DECL(comp93)
BENCH_DECL(comp94)
BENCH_DECL(comp95)
BENCH_DECL(comp96)
BENCH_DECL(comp97)
BENCH_DECL(comp98)
BENCH_DECL(comp99)
BENCH_DECL(comp100)
BENCH_DECL(comp101)
BENCH_DECL(comp102)
BENCH_DECL(comp103)
BENCH_DECL(comp104)
BENCH_DECL(comp105)
BENCH_DECL(comp106)
BENCH_DECL(comp107)
BENCH_DECL(comp108)
BENCH_DECL(comp109)
BENCH_DECL(comp110)
BENCH_DECL(comp111)
BENCH_DECL(comp112)
BENCH_DECL(comp113)
BENCH_DECL(comp114)
BENCH_DECL(comp115)
BENCH_DECL(comp116)
BENCH_DECL(comp117)
BENCH_DECL(comp118)

BENCH_DECL(moist_physics_prep_tim)
BENCH_DECL(a_moist_physics_finish_tim)
BENCH_DECL(a_lscond_tim)
BENCH_DECL(a_moist_physics_prep_tim)

BENCH_DECL(store1)
BENCH_DECL(restore1)
#else
#define SOLVE_START
#define SOLVE_END
#define BENCH_INIT(A)
#define BENCH_START(A)
#define BENCH_END(A)
#define BENCH_REPORT(A)
#endif
