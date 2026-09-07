::  Reusable schedule data. A hand owns the binding and admission of each run.
/-  h=harness
|%
+$  pattern
  $:  minutes=(set @ud)
      hours=(set @ud)
      days=(set @ud)
      months=(set @ud)
      weekdays=(set @ud)
      any-day=?
      any-weekday=?
  ==
+$  job-0
  $:  sid=@t
      run-sid=@t
      expression=@t
      pattern=pattern
      prompt=@t
      tools=(list tool-grant:h)
      next=@da
      remaining=@ud
      state=?(%active %paused %cancelled %complete)
      reason=@t
      last=(unit @uv)
  ==
+$  job  [kind=?(%prompt %reminder) timezone=@t destination=@t job-0]
--
