// What the names mean, on the page at `/meanings`.
//
// **Everything it draws is in `meanings.js`**, which the block on every area
// page is drawn from too; this file is only the page's own opening. Kept apart,
// as each area's page script is kept apart from the module that draws its plot,
// so that an area page importing the table does not also import a page.
//
// **It arrives at an entry.** Every area page links to `/meanings#<theme>`,
// and the entries are written after the language is settled, so when the
// browser looked for the fragment on load there was nothing yet to scroll to.
// It is looked for again once, after the first drawing — and only once, so
// changing the chooser does not throw the reader back to an entry they have
// scrolled away from.
import { whenSettled } from './plain.js';
import { showMeanings } from './meanings.js';

let arrived = false;

// A fragment changed without a reload — a tile in the contents, the back
// button, or an address edited in place — moves the ring to the entry it now
// names. The browser does the scrolling itself here, because by now the entry
// exists.
addEventListener('hashchange', () => {
  for (const entry of document.querySelectorAll('.entry--here')) {
    entry.classList.remove('entry--here');
  }
  const id = decodeURIComponent(location.hash.slice(1));
  const entry = id ? document.getElementById(id) : null;
  if (entry && entry.parentElement?.id === 'lexicon') entry.classList.add('entry--here');
});

whenSettled((strings) => {
  showMeanings(strings);
  if (arrived) return;
  arrived = true;
  const id = decodeURIComponent(location.hash.slice(1));
  const entry = id ? document.getElementById(id) : null;
  if (entry) entry.scrollIntoView({ block: 'start' });
});
