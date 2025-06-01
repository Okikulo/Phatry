// Copy and Paste stuff
#show raw.where(block: true): block.with(
    fill: luma(240),
    inset:10pt,
    radius: 8pt,
  )

// TODO: Fix showybox
#let prob(title: "", color: green, ..body) = {
  let problem_counter = counter("1")
  [== Problem #problem_counter.step() #context {problem_counter.display()}]
    showybox(
      frame: (
        border-color: color.darken(10%),
        title-color: color.lighten(85%),
        body-color: color.lighten(90%)
      ),
      title-style: (
        color: black,
        weight: "bold",
      ),
      title: title,
      ..body
    )
}


// Utilities
#let section(title) = [
  = #title
  #line(length: 20%, stroke: rgb("#458588"))
]

#let subsection(title) = [
  == #title
  #line(length: 10%, stroke: rgb("#689d6a"))
]

#let uptpheader(subject, assignment, topic, deadline) = {[
  = #subject
  == #assignment | #topic

  #line(length: 100%, stroke: rgb("#97981a"))
  _Taiwan-Paraguay Polytechnic University_\
  _Student_: Fabrizio Diaz\
  _ID_: 6219490\
  _Career_: Information Engineering\
  _Deadline_:  #deadline\
  #line(length: 100%, stroke: rgb("#97981a"))
  
]}

#let ntustheader(subject, assignment, topic, deadline) = {[
  = #subject
  == #assignment | #topic
  
  #line(length: 100%, stroke: rgb("#97981a"))
  _National Taiwan University of Science and Technology_\
  _Student:_ Fabrizio Diaz\
  _ID:_ F11315107\
  _Career:_ Computer Science, Department of Computer Science and Information Engineering\
  _Deadline_:  #deadline\
  #line(length: 100%, stroke: rgb("#97981a"))

]}

#let database_hw(subject, assignment, topic, deadline) = {[
  = #subject
  == #assignment | #topic
  
  #line(length: 100%, stroke: rgb("#97981a"))
  _National Taiwan University of Science and Technology_\
  _Computer Science, Department of Computer Science and Information Engineering_\
  _Students:_ Aldo Acevedo, Fabrizio Diaz\
  _ID:_ F11315101, F11315107\
  _Deadline_:  #deadline\
  #line(length: 100%, stroke: rgb("#97981a"))

]}

#let ntust_final_paper(subject, project_name, topic, members, deadline) = {[
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

