# Generates redirects for Dredd docs.
#
# Purpose:
#   Thanks to this we can be sure no old links get broken.
#
# Usage:
#
#   Configure redirects.json, then run `coffee generate-redirects.coffee`


fs = require('fs')
path = require('path')
ect = require('ect')

redirects = require('./redirects.json')


docsDir = path.join(path.dirname(__filename), '..')
buildDir = path.join(docsDir, '_build')
redirectsDir = path.join(docsDir, '_redirects')
template = fs.readFileSync(path.join(redirectsDir, 'redirect-template.html'), {encoding: 'utf-8'})


writeRedirect = (filename, data) ->
  renderer = ect({root: {redirect: template}})
  rendered = renderer.render('redirect', data)
  fs.writeFileSync(filename, rendered, {encoding: 'utf-8'})


for src, dst of redirects
  srcDocname = src
  [dstDocname, dstAnchor] = dst.split('#')

  dstUrl = "#{dstDocname}/"
  dstUrl += "##{dstAnchor}" if dstAnchor

  data = {srcDocname, dstDocname, dstUrl}

  # redirect for /docname.html
  srcFilename = path.join(buildDir, "#{srcDocname}.html")
  writeRedirect(srcFilename, data)

  # redirect for /docname/
  try
    fs.mkdirSync(path.join(buildDir, srcDocname))
  catch e
    throw e if e.code isnt 'EEXIST'

  srcFilename = path.join(buildDir, srcDocname, 'index.html')
  writeRedirect(srcFilename, data)
