      PROGRAM DRIVER
      IMPLICIT NONE
      INTEGER I, K, NCASE
      DOUBLE PRECISION RJD(4), X(4), Y(4), UT1(4)
      DOUBLE PRECISION T, XL, YL, UL, XO, YO, UO, LO, XG, YG
      READ (*,*) NCASE
      DO K = 1, NCASE
        READ (*,*) T
        DO I = 1, 4
          READ (*,*) RJD(I), X(I), Y(I), UT1(I)
        ENDDO
        CALL LAGINT (RJD, X, 4, T, XL)
        CALL LAGINT (RJD, Y, 4, T, YL)
        CALL LAGINT (RJD, UT1, 4, T, UL)
        CALL PMUT1_OCEANS (T, XO, YO, UO, LO)
        CALL PM_GRAVI (T, XG, YG)
        WRITE (*,'(9ES26.17)') T, XL, YL, UL, XO, YO, UO, XG, YG
      ENDDO
      END
