# BM25 Report Drafts

## To-do:

- [ ] Is there a place to add in a quick reminder on the difference between using the query builder vs the per-field query builder (also in the exec summary)?

## 2016-10-05 (Second Draft)

- [x] Make corrections based on feedback
    - [x] Deb's feedback
        - [x] Can you add in what BM25 is - something simple like: (BM stands for Best Matching) and then linking to the page early in the exec summary.
        - [x] The same with PaulScore. Just a quick link to the meaning of it. 
        - [x] Can you add in a link to enwiki here: Users who searched English Wikipedia (“EnWiki”) just to make it clear which wiki (first sentance under 'data')
        - [x] Also move up the link to Discernatron in the data area so that readers can view what it is - before you start reading about it.
        - [x] Give a reference or definition of what SERP is (under: SERP De-duplication)
    - [x] Trey's feedback
        - [x] The font is kinda small, and the font for the snippet is *really* small. I can easily enlarge it online, so it's not a huge issue.
        - [x] In the "Background" section, I was expecting a link to the definition of PaulScore (since it's something we made up); then I saw that there's a whole section on it (cool!). A note saying "see below" or "defined below" or "see PaulScore Definition" would let those who forgot to read the TOC first know a right proper definition is coming soon.
        - [x] Under Background|Query reformulation
            - [x] "the less times" --> "the fewer times"—though this is a lost cause; another 30 years or so and no one will use "fewer" anymore. ;)
            - [x] "the [fewer] times the user reformulated their query, the better our search engine performs": it's not clear what the causal relationship is here. Is the idea that poor performance increases the likelihood of reformulation? Also, this seems to contradict Figure 6, where query reformulation leads to much better engagement scores.
        - [x] Methods|Data: the link to the schema ends with a stray close paren.
        - [x] Methods|Data|Track typos in first 2 characters: "the benefit of such field" --> "the benefit of such a field".
        - [x] Methods|Data: I'm not sure how broad the intended audience is, but if you are going to define ZRR you should at least add a link to the first mention of the Discernatron ( https://www.mediawiki.org/wiki/Discernatron ). Thinking about it, the scores are really on "Discernatron data" not Discernatron itself. A minor quibble, but the current way it's described (written by David, right?) might make people think Discernatron scores data, which it does not.
            - [x] Ahh... there it is in the paragraph after the five buckets, along with nDCG, which needed a definition, too. Any way to move that paragraph up before the descriptions of the buckets?
        - [x] Software: don't footnotes go after punctuation? See [CMOS](http://www.chicagomanualofstyle.org/qanda/data/faq/topics/Punctuation.html?page=1) (last question) for an appeal to authority. ;)
        - [x] Query Reformulation Detection:
            - [x] "normalized via dividing by maximum of two search queries" --> "normalized via dividing by the maximum length(?) of the two search queries"? Is it length or result set size?
            - [x] "dividing by minimum size of the two result sets" --> "dividing by the minimum size of the two result sets"
            - [x] Also, "in unaffected" --> "is unaffected"
            - [x] In Table 1, it isn't immediately obvious what A, B, and C are. Maybe use "cluster A", etc.?
            - [x] In the TOC, "Query Reformulation Detection" wraps awkwardly. If that's easy to fix, you should.
        - [x] PaulScore Definition: 
            - [x] footnote [1] is not superscript like the others
            - [x] "Pick scoring factor 0<F<10<F<1." Should there be any comment on what this does? If you think it through, it's clear from the math, but not everyone is going to do that. Something like "Larger values of F increase the weight of clicks on lower-ranked results" or something like that.
        - [x] Results|Table 2 caption: "one-week-long" --> "ten-day-long"?
        - [x] Are the results in Figures 1 and 2 significant? It looks like blue is significantly outside the range of the others, but an explicit statement of the significance would help
        - [x] Why does query reformulation matter? (hey, that's a different kind of significance) I get the sense that it indicates people didn't like the results they got then they modify their query, but it isn't clear. It's implicit in the discussion, but if ZRR gets an explicit definition....
        - [x] A last few comments on color—Should figure 3 have the same color scheme as the rest? Also, would it be possible to include some indication of color in Methods|Data? Maybe just a solid block before the bucket names. I started off tracking the buckets by number (go #4!) but by the end I was tracking them by color; starting out that way wouldn't hurt (go purple!).
    - [x] Chelsy's feedback
        - [x] One typo in section 'query reformulation detection' -- last sentence of the first paragraph: "...or they user might reformulate their query to instead say “buffalo wings”

## 2016-09-30 (First Draft)

- [x] Fix string distance normalization
- [x] Re-run clustering code
- Asked Trey, Chelsy, and Deb to review

## 2016-09-27 (Pre-first Draft)

- [x] Use the Wikimedia Labs-hosted copy of MathJax
- [x] Deploy to https://wikimedia-research.github.io/Discovery-Search-Test-BM25/
- Emailed David and Erik with initial results
