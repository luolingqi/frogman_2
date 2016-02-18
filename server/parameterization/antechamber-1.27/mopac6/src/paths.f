      SUBROUTINE PATHS
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      INCLUDE 'SIZES'
      COMMON /PATH  / LATOM,LPARAM,REACT(200)
      COMMON /GEOVAR/ NVAR, LOC(2,MAXPAR), IDUMY, XPARAM(MAXPAR)
      COMMON /KEYWRD/ KEYWRD
      COMMON /TIME  / TIME0
      COMMON /GEOM  / GEO(3,NUMATM)
      COMMON /ALPARM/ ALPARM(3,MAXPAR),X0, X1, X2, ILOOP
************************************************************************
*
*   PATH FOLLOWS A REACTION COORDINATE.   THE REACTION COORDINATE IS ON
*        ATOM LATOM, AND IS A DISTANCE IF LPARAM=1,
*                           AN ANGLE   IF LPARAM=2,
*                           AN DIHEDRALIF LPARAM=3.
*
************************************************************************
      DIMENSION GD(MAXPAR),XLAST(MAXPAR),MDFP(20),XDFP(20)
      CHARACTER*241 KEYWRD
      CHARACTER*10 TYPE(3)
      SAVE TYPE, GD, XLAST, MDFP, XDFP
      DATA TYPE / 'ANGSTROMS ','DEGREES   ','DEGREES   '/
      ILOOP=1
      IF(INDEX(KEYWRD,'RESTAR') .NE. 0) THEN
         MDFP(9)=0
         CALL DFPSAV(TOTIME,XPARAM,GD,XLAST,FUNCT1,MDFP,XDFP)
         WRITE(6,'(//10X,'' RESTARTING AT POINT'',I3)')ILOOP
      ENDIF
      IF(ILOOP.GT.1) GOTO 10
      WRITE(6,'(''  ABOUT TO ENTER FLEPO FROM PATH'')')
      TIME0=SECOND()
      CALL FLEPO(XPARAM,NVAR,FUNCT)
      WRITE(6,'(''  OPTIMIZED VALUES OF PARAMETERS, INITIAL POINT'')')
      CALL WRITMO(TIME0,FUNCT)
      TIME0=SECOND()
   10 CONTINUE
      IF(ILOOP.GT.2) GOTO 40
      GEO(LPARAM,LATOM)=REACT(2)
      IF(ILOOP.EQ.1) THEN
         X0=REACT(1)
         X1=X0
         X2=REACT(2)
         IF(X2.LT. -100.D0) STOP
         DO 20 I=1,NVAR
            ALPARM(2,I)=XPARAM(I)
   20    ALPARM(1,I)=XPARAM(I)
         ILOOP=2
      ENDIF
      CALL FLEPO(XPARAM,NVAR,FUNCT)
      RNORD=REACT(2)
      IF(LPARAM.GT.1) RNORD=RNORD*57.29577951D0
      WRITE(6,'(1X,16(''*****'')//17X,''REACTION COORDINATE = ''
     1,F12.4,2X,A10,19X//1X,16(''*****''))')RNORD,TYPE(LPARAM)
      CALL WRITMO(TIME0,FUNCT)
      TIME0=SECOND()
      DO 30 I=1,NVAR
   30 ALPARM(3,I)=XPARAM(I)
C
C   NOW FOR THE MAIN INTERPOLATION ROUTE
C
      IF(ILOOP.EQ.2)ILOOP=3
   40 CONTINUE
      LPR=ILOOP
      DO 110 ILOOP = LPR,100
C
         IF(REACT(ILOOP).LT. -100.D0) RETURN
C
         RNORD=REACT(ILOOP)
         IF(LPARAM.GT.1) RNORD=RNORD*57.29577951D0
         WRITE(6,'(1X,16(''*****'')//19X,''REACTION COORDINATE = ''
     1,F12.4,2X,A10,19X//1X,16(''*****''))')RNORD,TYPE(LPARAM)
C
         X3=REACT(ILOOP)
         C3=(X0**2-X1**2)*(X1-X2)-(X1**2-X2**2)*(X0-X1)
C      WRITE(6,'(''   C3:'',F13.7)')C3
         IF (ABS(C3) .LT. 1.D-8) THEN
C
C    WE USE A LINEAR INTERPOLATION
C
            CC1=0.D0
            CC2=0.D0
         ELSE
C    WE DO A QUADRATIC INTERPOLATION
C
            CC1=(X1-X2)/C3
            CC2=(X0-X1)/C3
         ENDIF
         CB1=1.D0/(X1-X2)
         CB2=(X1**2-X2**2)*CB1
C
C    NOW TO CALCULATE THE INTERPOLATED COORDINATES
C
         DO 50 I=1,NVAR
            DELF0=ALPARM(1,I)-ALPARM(2,I)
            DELF1=ALPARM(2,I)-ALPARM(3,I)
            ACONST = CC1*DELF0-CC2*DELF1
            BCONST = CB1*DELF1-ACONST*CB2
            CCONST = ALPARM(3,I) - BCONST*X2 - ACONST*X2**2
            XPARAM(I)=CCONST+BCONST*X3+ACONST*X3**2
            ALPARM(1,I)=ALPARM(2,I)
   50    ALPARM(2,I)=ALPARM(3,I)
C
C   NOW TO CHECK THAT THE GUESSED GEOMETRY IS NOT TOO ABSURD
C
         DO 60 I=1,NVAR
   60    IF(ABS(XPARAM(I)-ALPARM(3,I)) .GT. 0.2) GOTO 70
         GOTO 90
   70    WRITE(6,'('' GEOMETRY TOO UNSTABLE FOR EXTRAPOLATION TO BE USED
     1''/ ,'' - THE LAST GEOMETRY IS BEING USED TO START THE NEXT''
     2,'' CALCULATION'')')
         DO 80 I=1,NVAR
   80    XPARAM(I)=ALPARM(3,I)
   90    CONTINUE
         X0=X1
         X1=X2
         X2=X3
         GEO(LPARAM,LATOM)=REACT(ILOOP)
         CALL FLEPO(XPARAM,NVAR,FUNCT)
         CALL WRITMO(TIME0,FUNCT)
         TIME0=SECOND()
         DO 100 I=1,NVAR
  100    ALPARM(3,I)=XPARAM(I)
  110 CONTINUE
      END
