const ring = (cx, cy, r) => `M${cx - r} ${cy}a${r} ${r} 0 1 0 ${2 * r} 0a${r} ${r} 0 1 0 ${-2 * r} 0`;
const dot = (x, y) => `M${x} ${y}h0`;
const bed = (x) => `M${x} 3h2.5a.7 .7 0 0 1 .7 .7v12.6a.7 .7 0 0 1 -.7 .7h-2.5a.7 .7 0 0 1 -.7 -.7v-12.6a.7 .7 0 0 1 .7 -.7Z`;
const box = (x0, y0, x1, y1, r) => `M${x0 + r} ${y0}H${x1 - r}A${r} ${r} 0 0 1 ${x1} ${y0 + r}V${y1 - r}A${r} ${r} 0 0 1 ${x1 - r} ${y1}H${x0 + r}A${r} ${r} 0 0 1 ${x0} ${y1 - r}V${y0 + r}A${r} ${r} 0 0 1 ${x0 + r} ${y0}Z`;

const today = {
  waiting: "M2.5 16H17.5M4.5 16V12.5M15.5 16V8.2M15.8 7.4L4 9.8M10 16V13.4M10 14.2c1.3-.2 2-.9 2.2-2",
  ground: `${bed(2.5)}${bed(8.75)}${bed(15)}M3.75 5.4V7M3.75 9.2V10.8M3.75 13V14.6M9.55 6.2H10.45M9.55 10H10.45M9.55 13.8H10.45${dot(16.25, 5.6)}${dot(16.25, 8.4)}${dot(16.25, 11.2)}${dot(16.25, 14)}`,
  beginnings: "M7.5 6H17M7.5 10H17M7.5 14H17M4 16.5V8.5M2.6 8.9L4.9 5.6",
  renewal: "M6 16.5H14M10 16.5V3.5M10 16.5L5.8 5M10 16.5L14.2 5M8 16.5L3.5 9M12 16.5L16.5 9",
  travel: "M3 17.5L8.7 2.5M17 17.5L11.3 2.5",
  peace: `M5.5 3.5H14.5A2 2 0 0 1 16.5 5.5V14.5A2 2 0 0 1 14.5 16.5H5.5A2 2 0 0 1 3.5 14.5V5.5A2 2 0 0 1 5.5 3.5Z${ring(7.8, 7.8, 1.8)}M11 13.2H13.8`,
  kinship: `${ring(5, 5, 1.7)}${ring(15, 5, 1.7)}${ring(10, 10, 1.7)}${ring(5, 15, 1.7)}${ring(15, 15, 1.7)}`,
  pattern: "M5 5H15V15H5ZM10 2.5L17.5 10L10 17.5L2.5 10Z",
  light: "M2.5 16.5H17.5M3.5 16.5V9L10 3.5L16.5 9V16.5M10 3.5V16.5M6.7 6.3V16.5M13.3 6.3V16.5",
  meeting: `${ring(10, 10, 2.8)}M10 2.5V7.2M10 12.8V17.5M2.5 10H7.2M12.8 10H17.5`,
};

const plan = {
  // The tank down the middle, a run of lights either side of it, each light's
  // glazing bars across it.
  waiting: `M5.2 8.4H14.8A1.6 1.6 0 0 1 14.8 11.6H5.2A1.6 1.6 0 0 1 5.2 8.4Z${box(2.5, 2.5, 17.5, 6, 0.6)}M7.5 2.5V6M12.5 2.5V6${box(2.5, 14, 17.5, 17.5, 0.6)}M7.5 14V17.5M12.5 14V17.5`,
  ground: today.ground,
  // The bed, and three drills drawn along it by hand, each stopping short
  // of the end where its label stands.
  beginnings: `${box(2.5, 3, 17.5, 17, 2.4)}M5.5 7.2c2.2-.5 4.4.4 6.6 0s2.4-.3 2.9 0M5.5 10.2c2.3.4 4.5-.4 6.8 0s2 .2 2.7 0M5.5 13.2c2.1-.3 4.2.5 6.4 0s2.5-.2 3.1.1`,
  // Two rides across, and the stools in their rows between them, each a ring
  // round its cut.
  renewal: `M2.5 7H17.5M2.5 13H17.5${ring(4.5, 3.8, 1.2)}${ring(10, 3.8, 1.2)}${ring(15.5, 3.8, 1.2)}${ring(7.25, 10, 1.2)}${ring(12.75, 10, 1.2)}${ring(4.5, 16.2, 1.2)}${ring(10, 16.2, 1.2)}${ring(15.5, 16.2, 1.2)}`,
  // Looking down on the walk: the clipped hedge along the back in scallops,
  // the planting in front of it, and the grass path's wandering verges.
  travel: `M2.5 4.8q1.25-2.2 2.5 0t2.5 0 2.5 0 2.5 0 2.5 0 2.5 0${dot(4, 8.3)}${dot(7.4, 7.8)}${dot(10.6, 8.6)}${dot(14.2, 7.9)}${dot(5.8, 10.8)}${dot(9, 11.2)}${dot(12.4, 10.7)}${dot(16.2, 11.1)}M2.5 13.8c3-.7 5.2.5 7.6 0s5-.4 7.4.2M2.5 17c2.6.5 5.1-.4 7.6 0s4.9.3 7.4-.2`,
  // The hedge round, open where it is entered, the pool lying to one side
  // of the middle, and the bench across from it.
  peace: `M8 16.5H5.5A2 2 0 0 1 3.5 14.5V5.5A2 2 0 0 1 5.5 3.5H14.5A2 2 0 0 1 16.5 5.5V14.5A2 2 0 0 1 14.5 16.5H12M11.6 6.4H14M8.2 8c2.4-.2 3.7 1 3.6 2.7s-1.6 2.9-3.8 2.8-3.1-1.4-3-2.9 1-2.4 3.2-2.6Z`,
  kinship: today.kinship,
  // This knot: the edging, two runs each way crossing four times, and the
  // four inner stretches bowed in round the empty middle.
  pattern: `${box(2.5, 2.5, 17.5, 17.5, 1)}M7 2.5V7M13 2.5V7M7 13V17.5M13 13V17.5M2.5 7H7M2.5 13H7M13 7H17.5M13 13H17.5M7 7Q10 9.2 13 7Q10.8 10 13 13Q10 10.8 7 13Q9.2 10 7 7Z`,
  // The house from above: its walls with the door gap at one end, the ridge
  // along the middle, and the glazing bars running down from it to the eaves
  // on the near side only, so it reads as a roof of glass and not a grid.
  light: `M5.5 4H16A1.5 1.5 0 0 1 17.5 5.5V14.5A1.5 1.5 0 0 1 16 16H5.5M2.5 7.2V5.5A1.5 1.5 0 0 1 4 4M2.5 12.8V14.5A1.5 1.5 0 0 0 4 16M2.5 10H17.5M6.5 10V16M10 10V16M13.5 10V16`,
  meeting: today.meeting,
};

const areas = [
  ["waiting", "Cold Frame", "#968b78"], ["peace", "Quiet Garden", "#56654a"],
  ["ground", "Home Ground", "#4d3b2c"], ["kinship", "Orchard", "#66704a"],
  ["beginnings", "Seedbed", "#6a5641"], ["pattern", "Knot Garden", "#968b78"],
  ["renewal", "Coppice", "#5e4a33"], ["light", "Glasshouse", "#8a5a43"],
  ["travel", "Long Walk", "#5b6648"], ["meeting", "Crossing", "#5b6648"],
];

const SVG = "http://www.w3.org/2000/svg";
function glyph(d, px) {
  const svg = document.createElementNS(SVG, "svg");
  svg.setAttribute("width", px);
  svg.setAttribute("height", px);
  svg.setAttribute("viewBox", "0 0 20 20");
  const path = document.createElementNS(SVG, "path");
  path.setAttribute("d", d);
  svg.append(path);
  return svg;
}
function cell(d, px, ground, sep) {
  const td = document.createElement("td");
  if (sep) td.className = "sep";
  const span = document.createElement("span");
  span.className = "cell";
  span.style.background = ground;
  span.style.width = span.style.height = `${px * 1.5}px`;
  span.append(glyph(d, px));
  td.append(span);
  return td;
}
const table = document.getElementById("t");
for (const [key, name, ground] of areas) {
  const row = document.createElement("tr");
  const label = document.createElement("td");
  label.className = "name";
  const b = document.createElement("b");
  b.textContent = name;
  const small = document.createElement("span");
  small.textContent = key;
  label.append(b, small);
  row.append(label, cell(today[key], 20, ground), cell(today[key], 40, ground));
  if (plan[key] === today[key]) {
    const td = document.createElement("td");
    td.className = "sep same";
    td.colSpan = 3;
    td.textContent = "already a plan — unchanged";
    row.append(td);
  } else {
    row.append(cell(plan[key], 20, ground, true), cell(plan[key], 40, ground), cell(plan[key], 96, ground));
  }
  table.append(row);
}
