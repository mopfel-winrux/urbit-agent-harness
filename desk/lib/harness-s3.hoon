::  s3-client: reusable S3 upload client
::
::  provides AWS SigV4 signing and presigned PUT URL generation.
::  no agent dependencies — takes credentials as parameters.
::
|%
::
::  +s3-hmac-sha256: HMAC-SHA256 using shay
::
++  s3-hmac-sha256
  |=  [key=octs msg=octs]
  ^-  @
  =/  block-size=@ud  64
  =/  k=@
    ?:  (gth p.key block-size)
      (shay p.key q.key)
    q.key
  =/  ipad-key=@  (mix k (fil 3 block-size 0x36))
  =/  opad-key=@  (mix k (fil 3 block-size 0x5c))
  =/  inner-data=@  (can 3 ~[[64 ipad-key] [p.msg q.msg]])
  =/  inner-len=@ud  (add block-size p.msg)
  =/  inner-hash=@  (shay inner-len inner-data)
  =/  outer-data=@  (can 3 ~[[64 opad-key] [32 inner-hash]])
  =/  outer-len=@ud  (add block-size 32)
  (shay outer-len outer-data)
::
++  s3-hmac-sha256-cord
  |=  [key=@t msg=@t]
  ^-  @
  (s3-hmac-sha256 [(met 3 key) key] [(met 3 msg) msg])
::
::  +s3-signing-key: derive AWS4 signing key
::
++  s3-signing-key
  |=  [secret=@t date=@t region=@t service=@t]
  ^-  @
  =/  k-secret=@t  (rap 3 'AWS4' secret ~)
  =/  k-date=@  (s3-hmac-sha256-cord k-secret date)
  =/  k-region=@  (s3-hmac-sha256 [32 k-date] [(met 3 region) region])
  =/  k-service=@  (s3-hmac-sha256 [32 k-region] [(met 3 service) service])
  (s3-hmac-sha256 [32 k-service] [(met 3 'aws4_request') 'aws4_request'])
::
::  +s3-hex: convert 32-byte hash to hex cord
::
++  s3-hex
  |=  dat=@
  ^-  @t
  =/  out=tape
    =/  idx  0
    |-
    ?:  =(idx 32)  ~
    =/  byt=@  (cut 3 [idx 1] dat)
    =/  hi  (snag (rsh 0^4 byt) "0123456789abcdef")
    =/  lo  (snag (end 0^4 byt) "0123456789abcdef")
    [hi lo $(idx +(idx))]
  (crip out)
::
::  +s3-uri-encode: URI-encode a path for S3
::
++  s3-uri-encode
  |=  [cord=@t slash=?]
  ^-  @t
  %-  crip
  %-  zing
  %+  turn  (trip cord)
  |=  c=@t
  ^-  tape
  ?:  ?|  &((gte c 'a') (lte c 'z'))
          &((gte c 'A') (lte c 'Z'))
          &((gte c '0') (lte c '9'))
          =(c '-')  =(c '.')  =(c '_')  =(c '~')  &(slash =(c '/'))
      ==
    [c ~]
  =/  hi  (snag (rsh 0^4 c) "0123456789ABCDEF")
  =/  lo  (snag (end 0^4 c) "0123456789ABCDEF")
  ['%' hi lo ~]
::
::  SigV4 stays ship-side. Callers own dispatch, durable identity and retry policy.
+$  credentials
  [endpoint=@t access-key=@t secret-key=@t bucket=@t region=@t public-base=@t]
++  join
  |=  [base=@t key=@t]
  ^-  @t
  (rap 3 base ?:(=('/' (rsh [3 (dec (met 3 base))] base)) '' '/') key ~)
++  origin
  |=  raw=@t
  ^-  @t
  ?>  &((gth (met 3 raw) 0) (lte (met 3 raw) 2.048))
  ?>  !(lien (trip raw) |=(c=@t |((lte c 32) =(c '#') =(c '?') =(c '@'))))
  =/  url  ?:  |(=('https://' (end 3^8 raw)) =('http://' (end 3^7 raw)))  raw
    (cat 3 'https://' raw)
  =/  parsed  (need (de-purl:html url))
  ?>  &(=(~ r.parsed) =([~ ~] q.parsed))
  (crip (head:en-purl:html p.parsed))
++  decode
  |=  [cred=json conf=json]
  ^-  credentials
  =/  object  |=(val=json ?>(?=(%o -.val) p.val))
  =/  field
    |=  [val=json section=@t key=@t]
    ^-  @t
    =/  found
      %-  mole  |.
      =/  obj  (object val)
      =/  update  (object (~(got by obj) 'storage-update'))
      =/  values  (object (~(got by update) section))
      (so:dejs:format (~(got by values) key))
    (fall found '')
  =/  service  (field conf 'configuration' 'service')
  ?>  |(=('' service) =('credentials' service))
  =/  got=credentials
    :*  (field cred 'credentials' 'endpoint')
        (field cred 'credentials' 'accessKeyId')
        (field cred 'credentials' 'secretAccessKey')
        (field conf 'configuration' 'currentBucket')
        (field conf 'configuration' 'region')
        (field conf 'configuration' 'publicUrlBase')
    ==
  =?  region.got  =('' region.got)  'us-east-1'
  ?>  &(!=('' access-key.got) !=('' secret-key.got) !=('' bucket.got))
  ?>  &((gte (met 3 bucket.got) 3) (lte (met 3 bucket.got) 63) !=('.' bucket.got) !=('..' bucket.got))
  ?>  (levy (trip bucket.got) |=(c=@t |(&((gte c 'a') (lte c 'z')) &((gte c '0') (lte c '9')) =('-' c) =('.' c))))
  =.  endpoint.got  (origin ?:(=('' endpoint.got) (rap 3 'https://s3.' region.got '.amazonaws.com' ~) endpoint.got))
  ?.  =('' public-base.got)
    ?>  &((lte (met 3 public-base.got) 2.048) !(lien (trip public-base.got) |=(c=@t |((lte c 32) =(c '#') =(c '?') =(c '@')))))
    =/  parsed  (need (de-purl:html public-base.got))
    ?>  =(~ r.parsed)
    got
  got
++  spaces
  |=  endpoint=@t
  ^-  ?
  =/  parsed  (need (de-purl:html (origin endpoint)))
  ?:  ?=(%| -.r.p.parsed)  |
  =/  labels  p.r.p.parsed
  ?.  ?=([@ @ ^] labels)  |
  &(=('com' i.labels) =('digitaloceanspaces' i.t.labels))
++  presign
  |=  [creds=credentials now=@da key=@t mime=@t acl=?]
  ^-  [url=@t public-url=@t headers=(list [@t @t])]
  =/  d=date  (yore now)
  =/  pad  |=(n=@ud ^-(tape ?:((lth n 10) "0{(a-co:co n)}" (a-co:co n))))
  =/  day=@t  (crip "{(a-co:co y.d)}{(pad m.d)}{(pad d.t.d)}")
  =/  stamp=@t  (crip "{(trip day)}T{(pad h.t.d)}{(pad m.t.d)}{(pad s.t.d)}Z")
  =/  base  (origin endpoint.creds)
  =/  host  (rsh [3 ?:(=('https://' (end 3^8 base)) 8 7)] base)
  =/  object-path  (s3-uri-encode (rap 3 '/' bucket.creds '/' key ~) &)
  =/  public-url  ?:(=('' public-base.creds) (cat 3 base object-path) (join public-base.creds (s3-uri-encode key &)))
  =/  scope  (rap 3 day '/' region.creds '/s3/aws4_request' ~)
  =/  credential  (s3-uri-encode (rap 3 access-key.creds '/' scope ~) |)
  ::  Spaces requires the ACL on the wire, not only in the presigned query.
  ::  Sign that header too. Other providers retain their query-only behavior.
  =/  wire-acl  &(acl (spaces base))
  =/  signed  (cat 3 'cache-control;content-type;host' ?:(wire-acl ';x-amz-acl' ''))
  =/  query
    (rap 3 'X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=' credential '&X-Amz-Date=' stamp '&X-Amz-Expires=300&X-Amz-SignedHeaders=' (s3-uri-encode signed |) ?:(acl '&x-amz-acl=public-read' '') ~)
  =/  canonical
    (rap 3 'PUT\0a' object-path '\0a' query '\0acache-control:public, max-age=3600\0acontent-type:' mime '\0ahost:' host '\0a' ?:(wire-acl 'x-amz-acl:public-read\0a' '') '\0a' signed '\0aUNSIGNED-PAYLOAD' ~)
  =/  digest  (s3-hex (shay (met 3 canonical) canonical))
  =/  to-sign  (rap 3 'AWS4-HMAC-SHA256\0a' stamp '\0a' scope '\0a' digest ~)
  =/  signing-key  (s3-signing-key secret-key.creds day region.creds 's3')
  =/  signature  (s3-hex (s3-hmac-sha256 [32 signing-key] [(met 3 to-sign) to-sign]))
  :*  (rap 3 base object-path '?' query '&X-Amz-Signature=' signature ~)
      public-url
      (weld ~[['Content-Type' mime] ['Cache-Control' 'public, max-age=3600']] ?:(wire-acl ~[['x-amz-acl' 'public-read']] ~))
  ==
--
