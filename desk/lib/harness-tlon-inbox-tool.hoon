::  Explicit inbox reads: native mentions, replies and unread summaries.
/-  a=tlon-activity-ver
/+  spec=harness-tlon-tool, hp=harness-tlon-history-page, story=harness-tlon-story
|_  bowl=bowl:gall
++  flag
  |=  value=[@p @tas]
  (rap 3 (scot %p -.value) '/' +.value ~)
++  nest
  |=  value=[@tas @p @tas]
  (rap 3 -.value '/' (flag +.value) ~)
++  source
  |=  value=source:v8:a
  ^-  json
  %-  pairs:enjs:format
  :-  ['kind' %s -.value]
  ?-  -.value
    %base  ~
    %contact  ~[['ship' %s (scot %p who.value)]]
    %group  ~[['group' %s (flag flag.value)]]
    %channel  ~[['channel' %s (nest nest.value)] ['group' %s (flag group.value)]]
    %thread  ~[['channel' %s (nest channel.value)] ['group' %s (flag group.value)] ['parent' %s (scot %da time.key.value)]]
    %dm  ~[?:(?=(%ship -.whom.value) ['ship' %s (scot %p p.whom.value)] ['club' %s (scot %uv p.whom.value)])]
    %dm-thread
      :~  ?:(?=(%ship -.whom.value) ['ship' %s (scot %p p.whom.value)] ['club' %s (scot %uv p.whom.value)])
          ['parent' %s (rap 3 (scot %p p.id.key.value) '/' (scot %da q.id.key.value) ~)]
      ==
  ==
++  event
  |=  row=time-event:v8:a
  ^-  json
  =/  ev=incoming-event:v8:a  -.event.row
  =/  fields=(list [@t json])
    :~  ['type' %s -.ev]  ['at' %s (scot %da time.row)]  ==
  =/  details=(list [@t json])
    ?+  -.ev  ~
      %post  ~[['message_id' %s (scot %da time.key.ev)] ['text' %s (clip-text:hp (story-to-text:story content.ev) 300)] ['mention' %b mention.ev]]
      %reply  ~[['message_id' %s (scot %da time.key.ev)] ['text' %s (clip-text:hp (story-to-text:story content.ev) 300)] ['mention' %b mention.ev]]
      %dm-post  ~[['message_id' %s (rap 3 (scot %p p.id.key.ev) '/' (scot %da q.id.key.ev) ~)] ['text' %s (clip-text:hp (story-to-text:story content.ev) 300)] ['mention' %b mention.ev]]
      %dm-reply  ~[['message_id' %s (rap 3 (scot %p p.id.key.ev) '/' (scot %da q.id.key.ev) ~)] ['text' %s (clip-text:hp (story-to-text:story content.ev) 300)] ['mention' %b mention.ev]]
    ==
  =/  fields  (weld fields details)
  (pairs:enjs:format fields)
++  read
  |=  args=json
  ^-  json
  ?>  .^(? %gu /(scot %p our.bowl)/activity/(scot %da now.bowl)/$)
  =/  filter  (string:spec args 'filter' 'all' 16)
  ?>  ?=(?(%all %mentions %replies %unreads) filter)
  ?:  =('unreads' filter)
    =/  rows=(list [source=source:v8:a summary=activity-summary:v8:a])
      .^((list [source:v8:a activity-summary:v8:a]) %gx /(scot %p our.bowl)/activity/(scot %da now.bowl)/v4/activity/unreads/noun)
    =/  items
      %+  turn  rows
      |=  row=[source=source:v8:a summary=activity-summary:v8:a]
      (pairs:enjs:format ~[['source' (source source.row)] ['count' (numb:enjs:format count.summary.row)] ['notify_count' (numb:enjs:format notify-count.summary.row)]])
    (directory:spec args items)
  =/  scope  (sham [%tlon-inbox our.bowl filter])
  =/  before  (position:hp scope (string:spec args 'cursor' '' 256))
  =/  start  ?~(before now.bowl u.before)
  =/  feed=feed:v8:a
    .^(feed:v8:a %gx /(scot %p our.bowl)/activity/(scot %da now.bowl)/v5/feed/[filter]/11/(scot %ud start)/noun)
  =/  rows  (scag 10 feed.feed)
  =/  items
    %+  turn  rows
    |=  row=activity-bundle:v8:a
    (pairs:enjs:format ~[['source' (source source.row)] ['latest' %s (scot %da latest.row)] ['events' %a (turn (scag 3 events.row) event)] ['events_truncated' %b (gth (lent events.row) 3)]])
  =/  more  (gth (lent feed.feed) 10)
  (pairs:enjs:format ~[['items' %a items] ['has_more' %b more] ['next_cursor' ?:(more [%s (cursor:hp scope latest:(snag 9 rows))] ~)]])
--
