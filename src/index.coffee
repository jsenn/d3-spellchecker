d3.json 'wordlist.json', (err, json) -> console.warn err if err?; window.NWORDS = json

alphabet = 'abcdefghijklmnopqrstuvwxyz'

# (Inefficiently) create a set from an array
unique = (xs) -> xs.filter (x, i) -> (xs.indexOf x) is i
cross = (xs, ys) ->
  pairs = []
  for x in xs
    for y in ys
      pairs.push [x, y]
  pairs

# Set of all distance-1 edits
edits1 = (word) ->
  splits   = ([word[...i], word[i...]] for i in [0..word.length])
  crossed  = cross splits, alphabet
  deletes  = (a + b[1..] for [a, b] in splits when b)
  inserts  = (sp[0] + letter + sp[1] for [sp, letter] in crossed)
  switches = (a + b[1] + b[0] + b[2..] for [a, b] in splits when b.length > 1)
  replaces = (sp[0] + letter + sp[1][1...] for [sp, letter] in crossed when letter)
  unique (deletes.concat switches.concat replaces.concat inserts)

# Words that can be found in the training set
known = (words) -> (word for word in words when word of NWORDS)

# Set of all distance-2 edits encountered in the training set
edits2 = (word) -> known ((edits1 e1) for e1 in edits1 word)

# Return a function that finds the most plausible correction (if one exists)
correct = (word) ->
  # Assume that small mistakes are more common than big ones
  e1 = known (edits1 word)
  if e1.length
    corrections = e1
  else
    e2 = edits2 word
    corrections = if e2.length then e2 else [word]

  [maxword, maxval] = [null, -Infinity]
  for w in corrections
    count = NWORDS[w]
    [maxword, maxval] = [w, count] if count > maxval

  (maxword or corrections[0]).split ''

width = 960
height = 250
duration = 750
data = []
setx = (d, i) -> i * 32

svg = d3.select('body')
        .append('svg')
        .attr('width', width)
        .attr('height', height)
        .append('g')
        .attr('transform', "translate(32, #{height/2})")

update = ->
  char = String.fromCharCode(d3.event.keyCode).toLowerCase()
  switch
    when char is '\b' then data.pop(); show()
    when char is '\r' then data = correct (data.join ''); correction()
    when char in alphabet then data.push char; show()

show = ->
  svg.selectAll('text').remove()
  text = svg.selectAll('text').data(data)
  text.attr('x', setx)
  text.enter().append('text')
      .attr('x', setx)
      .text((d) -> d)

correction = ->
  # Reuse any existing elements
  text = svg.selectAll('text').data(data, bindfunc)
  text.attr('class', 'update')
      # Shift if necessary
      .transition().duration(duration)
      .attr('x', setx)

  # Add new elements
  text.enter().append('text')
      .attr('class', 'enter')
      .attr('y', -60)
      .attr('x', setx)
      .style('fill-opacity', 0)
      .text((d) -> d)
      # Drop in
      .transition().duration(duration)
        .attr('y', 0)
        .style('fill-opacity', 1)

  # Remove old elements
  text.exit()
      .attr('class', 'exit')
      .attr('y', 0)
      # Drop out
      .transition().duration(duration)
        .attr('y', 60)
        .style('fill-opacity', 0)
        .remove()

bindfunc = (d, i) ->
  # Number of occurences of d in data
  count = (data.filter (letter) -> letter is d).length
  if count > 1 then d + i else d

d3.select('body')
  .on('keydown', ->
    d3.event.preventDefault() if d3.event.keyCode is 8
    update())

