library(bookdown)

render_book("_docs_bookdown/", output_format = "gitbook", output_dir = "../docs")

browseURL("docs/index.html")
