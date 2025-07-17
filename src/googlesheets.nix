{
  runCommandWith,
  cmark-gfm,
}: let
  index = "$out/index.html";
  title = "Title";
  style = "https://cdn.jsdelivr.net/npm/yorha@1.2.0/dist/yorha.min.css";
  alpine = "https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js";
  gsid = "1xoxr2ybDrL-uH1v4KaPdZhxgepAdDRAse__UH2C-3yI";
  footer = "footer";
in
  runCommandWith {
    name = "marky";
    derivationArgs.nativeBuildInputs = [cmark-gfm];
  }
  /*
  bash
  */
  ''
                   mkdir -p $out
                    echo '<!doctype html><html lang="en"><head><meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" /><title>"${title}"</title><link rel="stylesheet" href="${style}" type="text/css"><style type="text/css">
                #pageui
                {
                    max-width: 1200px;
                    margin: 0 auto;
                }
                #pageui-faq details summary
                {
                    display: list-item;
                    text-decoration: none;
                    cursor: pointer;
                }
                #pageui details summary:hover
                {
                    text-decoration: underline;
                }
                #pageui details p
                {
                    margin: 2px 0 2px 0;
                    padding: 2px 2px 10px 20px;
                    color: indigo;
                }
                </style></head><body>' >> ${index}
                echo '
    <div id="pageui" x-data="'"{ search: ''',recipes: [],

            get filteredItems() {
                return this.recipes[0].filter(
                    i => i.startsWith(this.search)
                )
            } }"'" x-init="recipes = await fetchrecipe().then((data) => data )">
        <input x-model="search" placeholder="Search...">

        <ul>
            <template x-for="item in filteredItems" :key="item">
        <template x-for="recipe in recipes">
            <details>

                <summary x-text="item"></summary>
                <h3>Ingredients</h3>
                <span x-text="recipe[1]"></span>
                <h3>Steps</h3>
                <span x-text="recipe[2]"></span>
                <h6>Notes/Tags<h6>
                <p x-text="recipe[3]"></p>

            </details>

        </template>
            </template>
        </ul>

    </div>

                <div x-data="{ count: 0 }">
            <button x-on:click="count++">Increment</button>

            <span x-text="count"></span>
        </div>
            <div x-data="{ open: false }">
                <button @click="open = ! open">Toggle</button>

                <div x-show="open" @click.outside="open = false">Contents...</div>
            </div>
                <script>
                // This is the SpreadSheet ID
                var id = "${gsid}";

                // This is the sheet ID - you can reference different sheets in the spreadsheet with this
                var gid = "0";

                var url = "https://docs.google.com/spreadsheets/d/"+id+"/gviz/tq?tqx=out:json&tq&gid="+gid;

                console.log(url);

                let fetchrecipe= async () =>
                {
                    return await new Promise((resolve, reject) =>
                    {
                        fetch(url)
                        .then((response) => response.text())
                        .then((data) =>
                        {
                            let json_string = data.substring(47).slice(0, -2);
                            let details = getrecipe(JSON.parse(json_string));
                            resolve(details);
                        });
                    });
                }

                function getrecipe(json)
                {
                    let recipeList = [];
                    let detail, ingredients, steps, notes;

                    json.table.rows.forEach((row, i) =>
                    {
                        if (i == 0) return; // The first row is the header

                        try { detail = row.c[0].f ? row.c[0].f : row.c[0].v }
                        catch(e){ detail = "" }

                        try { ingredients = row.c[1].f ? row.c[1].f : row.c[1].v }
                        catch(e){ ingredients= "" }

                        try { steps = row.c[2].f ? row.c[2].f : row.c[2].v }
                        catch(e){ steps = "" }

                        try { notes = row.c[3].f ? row.c[3].f : row.c[3].v }
                        catch(e){ notes = "" }

                        recipeList.push([detail, ingredients, steps, notes]);
                    });

                    return recipeList;
                }
                </script>

                <script src="${alpine}" defer></script>

                </body>
                </html>' >> ${index}

  ''
