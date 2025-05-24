#let teamproject(subject, project_name, topic, members, deadline) = {[7
  = #subject
  == #assignment | #topic

  #line(length: 100%, stroke: rgb("#97981a"))
  _Taiwan-Paraguay Polytechnic University_\
  _Students_: #(members.join(", "))\
  _ID_: 6219490\
  _Career_: Information Engineering\
  _Deadline_:  #deadline\
  #line(length: 100%, stroke: rgb("#97981a"))
  
]}

#let formatted_text(body, font: "New Computer Modern", size: 11pt, justify: true) = {
  set text(font: font, size: size)
  set par(justify: justify)
    
  body
}

#let section(title) = [
  = #title
  #line(length: 20%, stroke: rgb("#458588"))
]

#let subsection(title) = [
  == #title
  #line(length: 10%, stroke: rgb("#689d6a"))
]

#show raw.where(block: true): block.with(
    fill: luma(240),
    inset:10pt,
    radius: 8pt,
  )
