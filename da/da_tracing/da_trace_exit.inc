subroutine da_trace_exit( &
   Name, &               ! in
   Message, &            ! in, optional
   Messages, &           ! in, optional
   MaxNoCalls)           ! in, optional

   IMPLICIT NONE

   ! Arguments

   CHARACTER (LEN=*), INTENT(IN)           :: Name         ! subroutine name
   CHARACTER (LEN=*), OPTIONAL, INTENT(IN) :: Message      ! text to trace
   CHARACTER (LEN=*), OPTIONAL, INTENT(IN) :: Messages(:)  ! text to trace
   INTEGER, OPTIONAL, INTENT(IN)           :: MaxNoCalls   ! max no calls to show

   ! Local constants

   CHARACTER (LEN=*), PARAMETER :: pad = "                                                  "

   ! Local variables

   INTEGER                         :: IOStatus        ! I-O return code 
   INTEGER                         :: Loop            ! General loop counter
   INTEGER                         :: Count
   INTEGER                         :: TotalSpace
   INTEGER                         :: LocalMaxNoCalls
   INTEGER                         :: Caller
   REAL                            :: temp_CPUTime
   REAL                            :: temp1
   REAL                            :: temp2
   CHARACTER(LEN=25)               :: Change

   !======================================================================
   ! Start of code
   !======================================================================

   ! stop the clock

   call CPU_TIME(temp_CPUTime)

   call SYSTEM_CLOCK( &
      COUNT=Count)

   !======================================================================
   ! check whether trace active and whether depth exceeded
   !======================================================================

   IF (.NOT. TraceActive) THEN
      RETURN
   END IF

   IF (TraceActive) THEN
      ! was tracing enabled by this routine? If it was, disable it, to
      ! take affect after the trace line has been written
      IF (Name == TraceStartedBy(1:LEN(Name))) THEN
         TraceActive = .FALSE.
      END IF
   END IF

   temp1 = REAL(Count - BaseElapsedTime) - ElapsedTimeLocalStart
   temp2 = temp_CPUTime - CPUTimeLocalStart

   TraceDepth=TraceDepth-1

   IF (TraceDepth < 0) THEN
      TraceDepth = 0
   END IF

   !=======================================================================
   ! Check timing and maximum heap memory usage
   !=======================================================================

   ElapsedTimeLocal(Pointer)    = ElapsedTimeLocal(Pointer) + temp1
   ElapsedTimeThisCall(Pointer) = ElapsedTimeThisCall(Pointer) + temp1
   ElapsedTime(Pointer)         = ElapsedTime(Pointer) + &
      ElapsedTimeThisCall(Pointer)

   CPUTimeLocal(Pointer)        = CPUTimeLocal(Pointer) + temp2
   CPUTimeThisCall(Pointer)     = CPUTimeThisCall(Pointer) + temp2
   CPUTime(Pointer)             = CPUTime(Pointer) + CPUTimeThisCall(Pointer)

   Caller=CalledBy(Pointer)
   IF (Caller /= 0) THEN
      ElapsedTimeThisCall(Caller) = ElapsedTimeThisCall(Caller) + &
         ElapsedTimeThisCall(Pointer)
      CPUTimeThisCall(Caller) = CPUTimeThisCall(Caller) + CPUTimeThisCall(Pointer)
   END IF

   Change = ""

   IF (trace_memory) THEN
      call da_memory( &
         TotalSpace)
      IF (EntryHeap(Pointer) < TotalSpace) THEN
         WRITE(Change,"(A9,I12)")", BIGGER", TotalSpace - EntryHeap(Pointer)
      ELSE IF (EntryHeap(Pointer) > TotalSpace) THEN
         WRITE(Change,"(A9,I12)")", SMALLER", TotalSpace - EntryHeap(Pointer)
      END IF
      IF (MaxHeap(Pointer) < TotalSpace) THEN
         MaxHeap(Pointer) = TotalSpace
      END IF
   ELSE
      TotalSpace = 0
   END IF

   IF (trace_write .AND. TraceDepth <= trace_max_depth ) THEN

      IF (PRESENT(MaxNoCalls)) THEN
         LocalMaxNoCalls = MaxNoCalls
      ELSE
         LocalMaxNoCalls = trace_repeat_head
      END IF

      IOStatus=0

      IF (NoCalls(Pointer) <= LocalMaxNoCalls) THEN
         IF (trace_memory) THEN
            if (use_html) then
               WRITE (UNIT=trace_unit, &
                  FMT='(A, "&lt; <a href=",A,"/",A,".html>",A,"</a>",I11,A)', &
                  IOSTAT=IOStatus) &
                  pad(1:TraceDepth*TraceIndentAmount),TRIM(Documentation_url), &
                  TRIM(Name),TRIM(Name), TotalSpace, Change
            else
               WRITE (UNIT=trace_unit, &
                  FMT='(A, "<",A,I11,A)', &
                  IOSTAT=IOStatus) &
                  pad(1:TraceDepth*TraceIndentAmount),TRIM(Name), TotalSpace, Change
            end if
         ELSE
            if (use_html) then
               WRITE (UNIT=trace_unit, &
                  FMT='(A, "&lt; <a href=",A,"/",A,".html>",A,"</a>")', &
                  IOSTAT=IOStatus) &
                  pad(1:TraceDepth*TraceIndentAmount),TRIM(Documentation_url), &
                  TRIM(Name),TRIM(Name)
            else
               WRITE (UNIT=trace_unit, FMT='(A, "<",A)', IOSTAT=IOStatus) &
                  pad(1:TraceDepth*TraceIndentAmount),TRIM(Name)
            end if
         END IF

         IF (IOStatus /= 0) THEN
            call da_error(__FILE__,__LINE__, &
              (/"Cannot write to trace file for "//TRIM(Name)/))
         END IF

         IF (PRESENT(Message)) THEN
            WRITE (UNIT=trace_unit, FMT='(A," ",A)', IOSTAT=IOStatus) &
               pad(1:TraceDepth*TraceIndentAmount),TRIM(Message)
            IF (IOStatus .NE. 0) THEN
               call da_error(__FILE__,__LINE__, &
                  (/"Cannot write to trace file for "//TRIM(Name)/))
            END IF
         END IF

         IF (PRESENT(Messages)) THEN
            DO Loop = 1, SIZE(Messages)
               WRITE (UNIT=trace_unit, FMT='(A," ",A)', IOSTAT=IOStatus) &
                  pad(1:TraceDepth*TraceIndentAmount),TRIM(Messages(Loop))
               IF (IOStatus .NE. 0) THEN
                  call da_error(__FILE__,__LINE__, &
                     (/"Cannot write to trace file for "//TRIM(Name)/))
               END IF
            END DO ! Loop
         END IF
      END IF

      IF (NoCalls(Pointer) == trace_repeat_head) THEN
         WRITE(UNIT=trace_unit,FMT='(A,"  Called enough, going quiet")', &
            IOSTAT=IOStatus)&
            pad(1:TraceDepth*TraceIndentAmount)
         IF (IOStatus .NE. 0) THEN
            call da_error(__FILE__,__LINE__, &
               (/"Cannot write to trace file for "//TRIM(Name)/))
         END IF
      END IF
   END IF ! trace_write

   ! Restore pointer
   Pointer = CalledBy(Pointer)

   ! note local time

   call SYSTEM_CLOCK( &
     COUNT=Count)

   ElapsedTimeLocalStart = REAL(Count-BaseElapsedTime)
   call CPU_TIME(CPUTimeLocalStart)

   ! call FLUSH(trace_unit)

end subroutine da_trace_exit

