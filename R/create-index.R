library(yaml)

read_front_matter = function(path) {
  lines = readLines(path, warn = FALSE, encoding = "UTF-8")

  if (length(lines) < 3 || trimws(lines[1]) != "---") {
    stop("Missing YAML front matter: ", path)
  }

  end = which(trimws(lines[-1]) == "---")[1] + 1

  if (is.na(end)) {
    stop("Unclosed YAML front matter: ", path)
  }

  yaml_text = paste(lines[2:(end - 1)], collapse = "\n")
  yaml::yaml.load(yaml_text)
}

create_area_index = function(area, content_dir) {
  area_id = as.character(area$id)
  area_name = as.character(area$name)
  area_path = as.character(area$path)

  dir = file.path(content_dir, area_path)

  if (!dir.exists(dir)) {
    stop("EDR area directory does not exist: ", dir)
  }

  files = list.files(
    dir,
    pattern = "^EDR-[0-9]{5}\\.qmd$",
    full.names = TRUE
  )

  records = lapply(files, function(path) {
    front_matter = read_front_matter(path)

    id = front_matter$id
    title = front_matter$title

    if (is.null(id) || !nzchar(as.character(id))) {
      stop("Missing 'id' in ", path)
    }

    if (is.null(title) || !nzchar(as.character(title))) {
      stop("Missing 'title' in ", path)
    }

    id = as.character(id)
    title = as.character(title)

    expected_prefix = paste0("EDR-", area_id)

    if (!startsWith(id, expected_prefix)) {
      stop(
        "EDR ", id,
        " is stored in area ", area_id,
        " but its identifier does not match that area."
      )
    }

    list(
      id = id,
      title = title,
      file = basename(path)
    )
  })

  if (length(records) > 0) {
    ids = vapply(records, `[[`, character(1), "id")

    if (anyDuplicated(ids)) {
      duplicated_ids = unique(ids[duplicated(ids)])
      stop("Duplicated EDR identifiers: ", paste(duplicated_ids, collapse = ", "))
    }

    records = records[order(ids)]
  }

  lines = c(
    "---",
    paste0('title: "', area_name, '"'),
    "---",
    "",
    paste0(
      "Esta sección reúne los Engineering Decision Records clasificados ",
      "en el área **", area_name, "** (`", area_id, "`)."
    ),
    ""
  )

  if (length(records) == 0) {
    lines = c(
      lines,
      "Actualmente no hay EDR registrados en esta área.",
      ""
    )
  } else {
    lines = c(
      lines,
      "| ID | Título |",
      "|---|---|"
    )

    rows = vapply(
      records,
      function(record) {
        paste0(
          "| [", record$id, "](", record$file, ")",
          " | ", record$title, " |"
        )
      },
      character(1)
    )

    lines = c(lines, rows, "")
  }

  writeLines(
    lines,
    file.path(dir, "index.qmd"),
    useBytes = TRUE
  )

  message(
    "Generated ",
    file.path(dir, "index.qmd"),
    " (", length(records), " EDR)"
  )
}

create_indexes = function(config = "_iasi.yml") {
  if (!file.exists(config)) {
    stop("Configuration file not found: ", config)
  }

  iasi = yaml::read_yaml(config)

  content_dir = iasi$publication$`content-dir`
  areas = iasi$edr$areas

  if (is.null(content_dir) || !nzchar(content_dir)) {
    stop("Missing publication.content-dir in ", config)
  }

  if (is.null(areas) || length(areas) == 0) {
    stop("Missing edr.areas in ", config)
  }

  invisible(lapply(
    areas,
    create_area_index,
    content_dir = content_dir
  ))
}

create_indexes()
