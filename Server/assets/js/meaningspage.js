// What the names mean, on the page at `/meanings`.
//
// **Everything it draws is in `meanings.js`**, which the block on every area
// page is drawn from too; this file is only the page's own opening. Kept apart,
// as each area's page script is kept apart from the module that draws its plot,
// so that an area page importing the table does not also import a page.
//
// **It arrives at a row.** Every area page links to `/meanings#<theme>`, and
// the rows are written after the language is settled, so when the browser
// looked for the fragment on load there was nothing yet to scroll to. It is
// looked for again once, after the first drawing — and only once, so changing
// the chooser does not throw the reader back to a row they have scrolled away
// from.
import { whenSettled } from './plain.js';
import { showMeanings } from './meanings.js';

let arrived = false;

// A fragment changed without a reload — the back button, or an address edited
// in place — moves the ring to the row it now names. The browser does the
// scrolling itself here, because by now the row exists.
addEventListener('hashchange', () => {
  for (const row of document.querySelectorAll('.meanings-row--here')) {
    row.classList.remove('meanings-row--here');
  }
  const id = decodeURIComponent(location.hash.slice(1));
  const row = id ? document.getElementById(id) : null;
  if (row && row.parentElement?.id === 'themes-body') row.classList.add('meanings-row--here');
});

whenSettled((strings) => {
  showMeanings(strings);
  if (arrived) return;
  arrived = true;
  const id = decodeURIComponent(location.hash.slice(1));
  const row = id ? document.getElementById(id) : null;
  if (row) row.scrollIntoView({ block: 'center' });
});
