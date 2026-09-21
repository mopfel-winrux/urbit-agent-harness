// Match the index's term boundaries and ASCII-only case folding. Render text
// nodes, never source HTML; tool output can contain arbitrary markup.
export default function SearchText({ text = '', terms = [] }) {
  const lower = (value) => value.replace(/[A-Z]/g, (letter) => letter.toLowerCase())
  const matches = new Set(terms.map(lower))
  return text.split(/([a-zA-Z0-9_~\-\u0080-\uFFFF]+)/).map((part, index) =>
    matches.has(lower(part)) ? <mark className="search-match" key={index}>{part}</mark> : part)
}
