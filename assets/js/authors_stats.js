document.addEventListener("DOMContentLoaded", () => {
  const table = document.getElementById("authors-stats-table");
  const tbody = table.querySelector("tbody");

  let rows = Array.from(tbody.querySelectorAll("tr"));
  let currentSort = { column: null, asc: true };

  function render(rowsToRender) {
    tbody.innerHTML = "";
    rowsToRender.forEach(row => tbody.appendChild(row));
  }

  function sortByColumn(columnIndex, type = "string") {
    let asc = !(currentSort.column === columnIndex && currentSort.asc);

    let sorted = [...rows].sort((a, b) => {
      let aText = a.children[columnIndex].textContent.trim();
      let bText = b.children[columnIndex].textContent.trim();

      if (type === "number") {
        let aVal = parseFloat(aText) || 0;
        let bVal = parseFloat(bText) || 0;
        return asc ? aVal - bVal : bVal - aVal;
      } else {
        return asc ? aText.localeCompare(bText) : bText.localeCompare(aText);
      }
    });

    currentSort = { column: columnIndex, asc };

    document.querySelectorAll("#authors-stats-table th").forEach((th, idx) => {
      const arrowSpan = th.querySelector("span");
      if (idx === columnIndex) {
        arrowSpan.textContent = asc ? "▲" : "▼";
      } else {
        arrowSpan.textContent = "▲";
      }
    });

    render(sorted);
  }

  function filterRows() {
    const authorFilter = document.getElementById("filter-author").value.toLowerCase();
    const booksFilter = parseInt(document.getElementById("filter-books").value, 10);
    const scoreFilter = parseFloat(document.getElementById("filter-score").value);
    const salesFilter = parseInt(document.getElementById("filter-sales").value, 10);

    let filtered = rows.filter(row => {
      let author = row.children[0].textContent.toLowerCase();
      let books = parseInt(row.children[1].textContent, 10);
      let scoreText = row.children[2].textContent.trim();
      let score = parseFloat(scoreText) || 0;
      let sales = parseInt(row.children[3].textContent, 10);

      let matchAuthor = author.includes(authorFilter);
      let matchBooks = isNaN(booksFilter) ? true : books >= booksFilter;
      let matchScore = isNaN(scoreFilter) ? true : score >= scoreFilter;
      let matchSales = isNaN(salesFilter) ? true : sales >= salesFilter;

      return matchAuthor && matchBooks && matchScore && matchSales;
    });

    render(filtered);
  }

  document.getElementById("th-author").addEventListener("click", (e) => {
    if (e.target.tagName.toLowerCase() !== 'input') {
      sortByColumn(0, "string");
    }
  });
  document.getElementById("th-books").addEventListener("click", (e) => {
    if (e.target.tagName.toLowerCase() !== 'input') {
      sortByColumn(1, "number");
    }
  });
  document.getElementById("th-avg-score").addEventListener("click", (e) => {
    if (e.target.tagName.toLowerCase() !== 'input') {
      sortByColumn(2, "number");
    }
  });
  document.getElementById("th-total-sales").addEventListener("click", (e) => {
    if (e.target.tagName.toLowerCase() !== 'input') {
      sortByColumn(3, "number");
    }
  });

  document.getElementById("filter-author").addEventListener("input", filterRows);
  document.getElementById("filter-books").addEventListener("input", filterRows);
  document.getElementById("filter-score").addEventListener("input", filterRows);
  document.getElementById("filter-sales").addEventListener("input", filterRows);
});
