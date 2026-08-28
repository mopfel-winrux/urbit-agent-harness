# JS script documentation

`thread-builder-js.hoon` library allows to run scripts written in JS. This document describes the API for it.

## Imports and exports

The interaction with the host environment is done in CommonJS style: import Urbit JS library by calling `require("urbit_thread")`. No other packages are available in the JS environment on Urbit: bundle dependencies into a single file with JS bundlers if necessary.

`thread-builder-js.hoon` expects that the provided JS code will export a function to call to `module.exports`. Here is an example of a JS script that prints to console:

```js
const urbit = require("urbit_thread");

module.exports = () => {
    console.log("Hello world!");
}
```

Importing `urbit` library is not strictly necessary if you will not call functions from it. The exported function will be called with no arguments.

## Built-in functions

### `fetch_sync`, `fetch`

In addition to usual printing functions in `console` object, the JS script execution environment comes with `fetch_sync` function for synchronous HTTP requests:

```js
/**
 * @typedef {{
 *      status: number,
 *      statusText: string,
 *      headers: Record<string, string>,
 *      body?: string
 * }} Response
 * 
 * @typedef {(url: string | URL, options: {
 *      method?: string,
 *      headers?: [string, string][] | Record<string, string>,
 *      body?: string
 * }) => Response} fetch_sync
 * @description Performs HTTP request synchronously
 */
```

It is also aliased with `fetch` function that wraps the return of `fetch_sync` with a `Promise` for ease of code portability:

```js
/**
 * @typedef {(url: string | URL, options: {
 *      method?: string,
 *      headers?: [string, string][] | Record<string, string>,
 *      body?: string
 * }) => Promise(Response)} fetch
 * @description Performs HTTP request synchronously, wraps result in Promise
 */
```

## `urbit_thread` library

These functions are defined in the root of the importable object and are used to interact with the JS script host.

### urbit_thread.load_txt_file

```js
/**
 * @typedef {(path: string) => string} load_txt_file
 * @description Returns contents of a .txt file at a given path. The first
 * element of the path is the desk, the rest is the path in the desk.
 */
```

### urbit_thread.store_txt_file

```js
/**
 * @typedef {(path: string, text: string) => void} store_txt_file
 * @description Stores contents of a .txt file at a given path.
 */
```

### urbit_thread.sleep

```js
/**
 * @typedef {(seconds: number) => void} sleep
 * @description Sleep for a given amount of seconds, rounded down
 */
```

### urbit_thread.restart

```js
/**
 * @typedef {() => never} restart
 * @description Restart the script, discarding all state. Useful for scripts
 * that run for a very long time and would otherwise spend all memory on urwasm
 * event log
 */
```
### Tlon Messenger API

These functions are used for interacting with Tlon Messenger app suite. `id: string` in DM-related functions is either a `@p` like `~sampel-palnet` or a groupchat ID which can be found in the URL of the groupchat. `Nest` string is the unique identifier of a group chat and can be derived from the chat's URL, e.g. in `https://example.com/apps/groups/group/~halbex-palheb%2Fuf-public/channel/diary%2F~sicdev-pilnup%2Fvipr7b5` the `Nest` is `diary/~sicdev-pilnup/vipr7b5` (`%2F` stands for `/` in URL encoding).

`Flag` is a unique identifier of a group, which consists of a group host and a group name, and in the above case it's `~halbex-palheb/uf-public`.

#### Type definitions

```js
/**
 * @typedef {
 *      string
 *      | {italics: Inline[]}
 *      | {bold: Inline[]}
 *      | {strike: Inline[]}
 *      | {blockquote: Inline[]}
 *      | {ship: string}
 *      | {"inline-code": string}
 *      | {code: string}
 *      | {tag: string}
 *      | {break: null}
 *      | {block: {index: number, text: string}}
 *      | {link: {href: string, content: string}}
 *      | {task: {checked: boolean, content: Inline[]}}
 * } Inline
 */

/**
 * @typedef {
 *      {list: {type: string, items: Listing[], contents: Inline[]}}
 *      | {item: Inline[]}
 * } Listing
 */

/**
 * @typedef {
 *      {group: string}
 *      | {desk: {flag: string, where: string}}
 *      | {chan: {nest: string, where: string}}
 *      | {bait: {group: string, graph: string, where: string}}
 * } Cite
 */

/**
 * @typedef {
 *      {rule: null}
 *      | {cite: Cite}
 *      | {listing: Listing}
 *      | {code: {code: string, lang: string}}
 *      | {header: {tag: string, content: Inline[]}}
 *      | {image: {src: string, height: number, width: number, alt: string}}
 * } Block
 */

/**
 * @typedef {{block: Block} | {inline: Inline[]}} Verse
 */

/**
 * @typedef {Verse[]} Story
 */

/**
 * @typedef {string} Nest
 * @description Unique identifier of a TM channel
 */

/**
 * @typedef {string} Flag
 * @description Unique identifier of a TM group
 */

/**
 * @typedef {content: Story, author: string, sent: number} Memo
 * @description Post contents with an author and a timestamp
 */
```

#### tlon.get_channels

```js
/**
 * @typedef {() => Nest[]} tlon.get_channels
 * @description Returns a list of all TM channels' identifiers you are currently
 * in
 */

```

#### tlon.get_groups

```js

/**
 * @typedef {() => Flag[]} tlon.get_groups
 * @description Returns a list of all TM channels' identifiers you are currently
 * in
 */
```

#### tlon.get_channel_messages

```js
/**
 * @typedef {(nest: Nest, n: number) => {key: string, message: Memo}[]} tlon.get_channel_messages
 * @description Returns a list of N last messages in a given channel with their
 * unique keys
 */
```

#### tlon.get_dm_messages

```js
/**
 * @typedef {(id: string, n: number) => {key: string, message: Memo}[]} tlon.get_dm_messages
 * @description Returns a list of N last messages in a given chat with their
 * unique keys
 */
```

#### tlon.get_dm_replies

```js
/**
 * @typedef {(id: string, key: string) => Memo[]} tlon.get_dm_replies
 * @description Returns a list of replies to a DM message
 */
```

#### tlon.get_channel_replies


```js
/**
 * @typedef {(nest: Nest, key: string) => Memo[]} tlon.get_channel_replies
 * @description Returns a list of replies to a channel post
 */
```

#### tlon.get_channel_members

```js
/**
 * @typedef {(nest: Nest) => string[]} tlon.get_channel_members
 * @description Returns a list of members in a channel
 */
```

#### tlon.get_groupchat_members

```js
/**
 * @typedef {(id: string) => string[]} tlon.get_groupchat_members
 * @description Returns a list of members in a groupchat
 */
```

#### tlon.get_roles

```js
/**
 * @typedef {(nest: Nest, ship: string) => string[]} tlon.get_roles
 * @description Returns a list of roles of a user in the group of a channel
 */
```

#### tlon.invite_user_channel

```js
/**
 * @typedef {(nest: Nest, ship: string) => ()} tlon.invite_user_channel
 * @description Invite user to the group of a channel
 */
```

#### tlon.invite_user_groupchat

```js
/**
 * @typedef {(id: string, ship: string) => ()} tlon.invite_user_groupchat
 * @description Invite user to a groupchat
 */
```

#### tlon.kick_user_channel

```js
/**
 * @typedef {(nest: Nest, ship: string) => ()} tlon.kick_user_channel
 * @description Remove user from the group of a channel
 */
```

#### tlon.give_role

```js
/**
 * @typedef {(nest: Nest, ship: string, role: string) => ()} tlon.give_role
 * @description Give role to a user in the group of a channel. The role has to
 * already exist to be given. It can be created in Tlon app UI.
 */
```

#### tlon.remove_role

```js
/**
 * @typedef {(nest: Nest, ship: string, role: string) => ()} tlon.remove_role
 * @description Remove role from a user in the group of a channel
 */
```

#### tlon.post_channel

```js
/**
 * @typedef {(nest: Nest, post: string) => ()} tlon.post_channel
 * @description Post a simple message in the channel, no formatting
 */
```

#### tlon.send_dm

```js
/**
 * @typedef {(id: string, post: string) => ()} tlon.send_dm
 * @description Send a simple DM in the channel, no formatting
 */
```

#### tlon.reply_channel

```js
/**
 * @typedef {(nest: Nest, key: string, post: string) => ()} tlon.reply_channel
 * @description Reply to a message in a channel, no formatting
 */
```
### Pals API

These functions are used to interact with `%pals` agent.

#### pals.get_leeches

```js
/**
 * @typedef {() => string[]} pals.get_leeches
 * @description Get a list of incoming pals requests
 */
```

#### pals.get_targets

```js
/**
 * @typedef {(?tag: string) => string[]} pals.get_targets
 * @description Get a list of outgoing pals requests, filtered with an optional
 * tag
 */
```