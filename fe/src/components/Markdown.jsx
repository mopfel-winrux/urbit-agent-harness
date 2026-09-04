import { Children, isValidElement, memo, useEffect, useId, useRef, useState } from 'react'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import './markdown.css'

function textContent(children) {
  return Children.toArray(children).map((child) => isValidElement(child) ? textContent(child.props.children) : String(child)).join('')
}

function CodeBlock({ children }) {
  const [notice, setNotice] = useState('')
  const timer = useRef(null)
  useEffect(() => () => clearTimeout(timer.current), [])
  const code = Children.toArray(children).find(isValidElement)
  const language = code?.props.className?.match(/language-([^\s]+)/)?.[1]

  async function copy() {
    try { await navigator.clipboard.writeText(textContent(children)); setNotice('Copied') }
    catch { setNotice('Select code to copy') }
    clearTimeout(timer.current)
    timer.current = setTimeout(() => setNotice(''), 2500)
  }

  return <div className="code-block">
    <div className="code-block-header"><span>{language || 'Code'}</span>
      <button type="button" onClick={copy} aria-label="Copy code"><span role="status">{notice || 'Copy'}</span></button>
    </div>
    <pre tabIndex={0} aria-label={`${language || 'Code'} block`}>{children}</pre>
  </div>
}

function Link({ href, children, title, ...props }) {
  if (!href) return <span>{children}</span>
  // Footnotes scroll within the transcript without changing the app's hash route.
  if (href.startsWith('#')) return <a id={props.id} href={href} title={title} aria-label={props['aria-label']} onClick={(event) => {
    event.preventDefault()
    document.getElementById(href.slice(1))?.scrollIntoView({ block: 'nearest' })
  }}>{children}</a>
  return <a href={href} title={title} target="_blank" rel="noopener noreferrer">{children}</a>
}

const components = {
  a: Link,
  pre: CodeBlock,
  // Model-authored remote images must not make background requests from the
  // user's browser. They remain explicit links, just like other external media.
  img: ({ src, alt }) => <Link href={src}>Image: {alt || 'view image'}</Link>,
  table: ({ children }) => <div className="markdown-table" role="region" aria-label="Table" tabIndex={0}><table>{children}</table></div>,
}
const plugins = [remarkGfm]

export default memo(function Markdown({ text }) {
  const id = useId().replace(/[^a-zA-Z0-9_-]/g, '')
  return <div className="markdown">
    <ReactMarkdown remarkPlugins={plugins} remarkRehypeOptions={{ clobberPrefix: `md-${id}-` }} components={components} skipHtml>{text}</ReactMarkdown>
  </div>
})
