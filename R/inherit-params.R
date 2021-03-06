process_inherit_params <- function(topics) {
  
  # Currently no topological sort, so @inheritParams will only traverse
  # one-level - you can't inherit params that have been inherited from
  # another function (and you can't currently use multiple inherit tags)
  inherit_index <- get_values(topics, "inheritParams")
  name_index <- get_values(topics, "name")
  
  for(topic_name in names(inherit_index)) {
    topic <- topics[[topic_name]]

    documented <- names(get_tag(topic, "arguments")$values)
    if (length(documented) > 0)
      documented <- unlist(strsplit(documented, ","))
    
    needed <- get_tag(topic, "formals")$values
    missing <- setdiff(needed, documented)
    if (length(missing) == 0) next
    
    for(inheritor in inherit_index[[topic_name]]) {
      inherited <- find_params(inheritor, topics, name_index)
      
      to_add <- intersect(missing, names(inherited))
      if (length(to_add) == 0) next
      missing <- setdiff(missing, names(inherited))
      
      add_tag(topic, new_tag("arguments", inherited[to_add]))
    }
  }
  
  topics 
}

find_params <- function(inheritor, topics, name_lookup) {
  has_colons <- grepl("::", inheritor, fixed = TRUE)
  
  if (has_colons) {
    # Reference to another package
    pieces <- strsplit(inheritor, "::", fixed = TRUE)[[1]]
    params <- rd_arguments(get_rd(pieces[2], pieces[1]))
    
  } else {
    # Reference within this package
    rd_name <- names(Filter(function(x) inheritor %in% x, name_lookup))
    
    if (length(rd_name) != 1) {
      warning("@inheritParams: can't find topic ", inheritor,
        call. = FALSE, immediate. = TRUE)
      return()
    }
    params <- get_tag(topics[[rd_name]], "arguments")$values
  }
  params <- unlist(params)
  
  param_names <- str_trim(names(params))
  param_names[param_names == "\\dots"] <- "..."
  
  # Split up compound names on , duplicating their contents
  individual_names <- strsplit(param_names, ",")
  reps <- vapply(individual_names, length, integer(1))
  
  setNames(rep.int(params, reps), unlist(individual_names))
}