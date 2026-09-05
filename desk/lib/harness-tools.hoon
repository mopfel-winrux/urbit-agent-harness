::  Capability catalog and executor safeguards. Pure data/functions only.
::  Schemas advertise tools; +tool-granted remains the dispatch authority.
::  The JavaScript guard is an executor limitation, not head logic.
/-  h=harness
|%
::  +js-loop-guard: reject the canonical unbounded-loop spellings.
::  the wasm runtime has no preemption, so a tight infinite loop wedges
::  the whole ship for the duration of its (single, blocking) event. a
::  behn watchdog catches loops that YIELD; this catches the ones that
::  don't, before any thread is spawned. coarse but cheap, and the model
::  gets a clear error to correct against
::
++  js-loop-guard
  |=  code=@t
  ^-  (unit @t)
  =/  flat  (normalize code)
  =/  bad=(list @t)
    :~  'while(true)'  'while(1)'  'while(!0)'
        'for(;;)'  'do{'
    ==
  ?:  (lien bad |=(pat=@t (find-sub pat flat)))
    :-  ~
    %+  rap  3
    :~  'rejected: unbounded loop construct detected. this runtime '
        'cannot be interrupted, so infinite loops are not allowed. '
        'use a loop with an explicit bound instead.'
    ==
  ~
::  +normalize: lowercase and strip ascii whitespace, for pattern search
::
++  normalize
  |=  t=@t
  ^-  @t
  %-  crip
  %+  murn  (trip t)
  |=  c=@t
  ^-  (unit @t)
  ?:  ?|(=(' ' c) =('\09' c) =('\0a' c) =('\0d' c))  ~
  `?:(&((gte c 'A') (lte c 'Z')) (add c 32) c)
::  +find-sub: does needle occur in haystack?
::
++  find-sub
  |=  [needle=@t haystack=@t]
  ^-  ?
  =/  nl  (met 3 needle)
  =/  hl  (met 3 haystack)
  ?:  (gth nl hl)  |
  =/  i  0
  |-  ^-  ?
  ?:  (gth i (sub hl nl))  |
  ?:  =(needle (cut 3 [i nl] haystack))  &
  $(i +(i))
::  +clip: cap a cord's byte length, marking truncation
::
++  clip
  |=  [t=@t cap=@ud]
  ^-  @t
  ?:  (lte (met 3 t) cap)  t
  (cat 3 (end [3 cap] t) ' ...(truncated)')
::  +all-tools: the available catalog, not a default grant. Bootstrap policy
::  lives in harness-defaults; existing explicit grants remain independent.
::
++  all-tools
  ^-  (list term)
  :~  %clay  %web  %skills  %skill-write
      %author  %subagents  %peers  %mcp
  ==
::  Rehearsals may inspect inherited source material, never dispatch effects
::  or publish instructions. An allowlist keeps future families out by default.
++  rehearsal-tools
  |=  tools=(list tool-grant:h)
  ^-  (list tool-grant:h)
  (skim tools |=(tool=tool-grant:h ?=(?(%clay %skills) tool)))
::  Used once when loading pre-scope policy, never when admitting new grants.
::  Snapshot registered IDs so adding a server later cannot widen authority.
++  scope-mcp
  |=  [tools=(list tool-grant:h) servers=(list @t)]
  ^-  (list tool-grant:h)
  %-  zing
  %+  turn  tools
  |=  tool=tool-grant:h
  ^-  (list tool-grant:h)
  ?.  =(%mcp tool)  ~[tool]
  (turn servers |=(server=@t `tool-grant:h`[%mcp server]))
++  mcp-granted
  |=  [server=@t tools=(list tool-grant:h)]
  ^-  ?
  (lien tools |=(tool=tool-grant:h =(tool [%mcp server])))
::  Collapse server grants to one schema family, retaining catalog order and
::  avoiding duplicate MCP function definitions when several servers are granted.
++  tool-families
  |=  tools=(list tool-grant:h)
  ^-  (list term)
  =/  granted=(set term)
    %+  roll  tools
    |=  [tool=tool-grant:h out=(set term)]
    ?:  ?=(^ tool)  (~(put in out) %mcp)
    ?:  =(%mcp tool)  out
    (~(put in out) tool)
  (skim (snoc all-tools %code) |=(family=term (~(has in granted) family)))
::  Resolve provider-returned function names to the capability family that
::  authorizes execution. This mapping is also checked at dispatch time;
::  provider schemas are discovery, never authority.
::
++  tool-family
  |=  name=@t
  ^-  (unit term)
  ?+  name  ~
    %'read_desk_file'   `%clay
    %'list_desk_files'  `%clay
    %'http_fetch'       `%web
    %'web_search'       `%web
    %'read_skill'       `%skills
    %'write_skill'      `%skill-write
    %'delete_skill'     `%skill-write
    %'propose_skill'    `%author
    %'rehearse_skill'   `%author
    %'commit_skill'     `%author
    %'discard_skill'    `%author
    %'run_js'           `%code
    %'run_subagent'     `%subagents
    %'ask_peer'         `%peers
    %'list_mcp_tools'   `%mcp
    %'list_mcp_servers'  `%mcp
    %'call_mcp_tool'    `%mcp
  ==
++  tool-granted
  |=  [name=@t tools=(list tool-grant:h)]
  ^-  ?
  =/  family  (tool-family name)
  ?~  family  |
  (lien (tool-families tools) |=(candidate=term =(candidate u.family)))
::  Schema visibility is not execution authority: MCP calls also name a server.
++  call-granted
  |=  [call=tool-call:h tools=(list tool-grant:h)]
  ^-  ?
  ?.  (tool-granted name.call tools)  |
  ?.  |(=('list_mcp_tools' name.call) =('call_mcp_tool' name.call))  &
  =/  jon  (de:json:html args.call)
  ?.  ?=([~ %o *] jon)  |
  =/  server  (~(get by p.u.jon) 'server')
  ?.  ?=([~ %s *] server)  |
  (mcp-granted p.u.server tools)
::  +tool-defs: schemas for granted tool families
::
++  tool-defs
  |=  tools=(list tool-grant:h)
  ^-  json
  :-  %a
  %-  zing
  %+  turn  (tool-families tools)
  |=  t=term
  ^-  (list json)
  ?+  t  ~
      %clay
    :~  %^    fun-json
            'read_desk_file'
          %-  crip
          %+  weld
            "Read a file from the ship's filesystem (clay). "
          "Path is /desk/spur, e.g. /harness/lib/harness/hoon"
        ~[['path' 'the file path, as /desk/spur/file/ext']]
      ::
        %^    fun-json
            'list_desk_files'
          'List files under a clay directory. Path is /desk or /desk/spur'
        ~[['path' 'the directory path, as /desk/spur']]
    ==
  ::
      %web
    :-  (fun-json 'web_search' 'Search the web with the configured search provider. Returns up to five titles, URLs and excerpts. Use http_fetch to read a result.' ~[['query' 'search query, up to 400 characters']])
    :_  ~
    %^    fun-json
        'http_fetch'
      %-  crip
      %+  weld
        "Fetch a url over http(s). Optional method (GET or POST) "
      "and body (sent as json when present)."
    :~  ['url' 'the url to fetch']
        ['method' 'GET or POST; defaults to GET']
        ['body' 'optional request body']
    ==
  ::
      %skills
    :_  ~
    %^    fun-json
        'read_skill'
      %-  crip
      %+  weld
        "Read the full body of a named skill from your skill library. "
      "The catalog of available skills is in your context."
    ~[['name' 'the skill name']]
  ::
      %skill-write
    :~  %^    fun-json
            'write_skill'
          %-  crip
          %+  weld
            "Create or update a named skill in your persistent skill "
          "library. Skills survive across sessions."
        :~  ['name' 'the skill name']
            ['description' 'one line shown in the skill catalog']
            ['body' 'the full skill text']
        ==
      ::
        %^    fun-json
            'delete_skill'
          'Delete a named skill from your skill library'
        ~[['name' 'the skill name']]
    ==
  ::
      %author
    :~  %^    fun-json
            'propose_skill'
          %-  crip
          %-  zing
          ^-  (list tape)
          :~  "Stage a new or revised skill WITHOUT making it live. Use "
              "this to author a skill, then rehearse_skill to test it, "
              "then commit_skill only if the test succeeds."
          ==
        :~  ['name' 'the skill name']
            ['description' 'one line for the skill catalog']
            ['body' 'the full skill text']
        ==
      ::
        %^    fun-json
            'rehearse_skill'
          %-  crip
          %-  zing
          ^-  (list tape)
          :~  "Try a staged skill on a sample task in a fresh read-only "
              "session. It may only read inherited Clay files and skills; "
              "web, MCP, code execution and other effects are unavailable. "
              "The rehearsal creates a transcript and incurs inference usage. "
              "Its answer is evidence for review, not proof that the skill "
              "is safe or correct. It does not publish the skill."
          ==
        :~  ['name' 'the staged skill to test']
            ['input' 'a sample task to try the skill on']
        ==
      ::
        %^    fun-json
            'commit_skill'
          %-  crip
          %+  weld
            "Publish a staged skill to the shared live library for future conversations. "
          "Requires explicit authorization to change shared instructions; a rehearsal answer does not supply that authorization."
        ~[['name' 'the staged skill to commit']]
      ::
        %^    fun-json
            'discard_skill'
          'Drop a staged skill without committing it'
        ~[['name' 'the staged skill to discard']]
    ==
  ::
      %code
    :_  ~
    %^    fun-json
        'run_js'
      %-  crip
      %-  zing
      ^-  (list tape)
      :~  "Run a JavaScript snippet on the ship and get its result. "
          "The code MUST assign a function to module.exports; its return "
          "value (JSON.stringify objects) is the result. Available: "
          "console.*, fetch_sync(url), require('urbit_thread') for file "
          "i/o. No unbounded loops (while(true), for(;;)): the runtime "
          "cannot be preempted, so use a bounded loop or you are rejected."
      ==
    :~  ['code' 'the javascript source; must set module.exports to a function']
    ==
  ::
      %peers
    :_  ~
    %^    fun-json
        'ask_peer'
      %-  crip
      %+  weld
        "Ask another ship's agent a question over the urbit network. "
      "Their agent answers from their own knowledge; expect a delay."
    :~  ['ship' 'the ship to ask, e.g. ~sampel-palnet']
        ['prompt' 'the question or task']
    ==
  ::
      %subagents
    :_  ~
    %^    fun-json
        'run_subagent'
      %-  crip
      %+  weld
        "Delegate a task to a fresh subagent session with no history. "
      "It runs until done and its final answer is returned to you."
    :~  ['prompt' 'the task for the subagent']
        ['system' 'optional system prompt for the subagent']
    ==
  ::
      %mcp
    :-  (fun-json 'list_mcp_servers' 'Discover enabled MCP servers granted to this conversation. Call this first; you do not need the user to supply a server ID.' ~)
    :~  %^    fun-json
            'list_mcp_tools'
          'List tools on a server discovered with list_mcp_servers'
        ~[['server' 'the configured MCP server id']]
      ::
        %^    fun-json
            'call_mcp_tool'
          'Call a tool on a configured MCP server'
        :~  ['server' 'the configured MCP server id']
            ['name' 'the MCP tool name']
            ['arguments' 'tool arguments as a JSON object string; use {} when empty']
        ==
    ==
  ==
::  +fun-json: an openai function schema; first param is required
::
++  fun-json
  |=  [name=@t desc=@t params=(list [@t @t])]
  ^-  json
  %-  pairs:enjs:format
  :~  ['type' %s 'function']
      :-  'function'
      %-  pairs:enjs:format
      :~  ['name' %s name]
          ['description' %s desc]
          :-  'parameters'
          =/  props=json
            :-  %o
            %-  ~(gas by *(map @t json))
            %+  turn  params
            |=  [pn=@t pd=@t]
            ^-  [@t json]
            :-  pn
            (pairs:enjs:format ~[['type' %s 'string'] ['description' %s pd]])
          =/  req=json
            :-  %a
            ?~  params  ~
            ~[`json`[%s -.i.params]]
          %-  pairs:enjs:format
          :~  ['type' %s 'object']
              ['properties' props]
              ['required' req]
          ==
      ==
  ==
--
