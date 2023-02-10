find_matches <- function(pattern, subject, subject_index,
                         max.mismatch, with.indels = TRUE) {

  # pad subject sequence with dashes so there's no error subsetting matches
  # which overlap the beginning or end
  subject_paded <-
    Biostrings::xscat(stringr::str_dup("-", max.mismatch),
                      subject[[subject_index]],
                      stringr::str_dup("-", max.mismatch)) %>%
    # replace Ns inside the sequence with dashes so they
    # wouldn't match our pattern
    # this is especially an issue with long stretches of Ns
    Biostrings::chartr(old = "N", new = "-")

  # get the sequence ID
  # (everything up until the first whitespace of the sequence name)
  seqID <- strsplit(subject@ranges@NAMES[[subject_index]], " ")[[1]][1]

  # find matches on both strands of the subject
  match_fw <-
    Biostrings::matchPattern(pattern,
                             subject_paded,
                             max.mismatch,
                             with.indels = with.indels,
                             fixed = FALSE)

  match_rc <-
    Biostrings::matchPattern(pattern,
                             Biostrings::reverseComplement(subject_paded),
                             max.mismatch,
                             with.indels = with.indels,
                             fixed = FALSE)

  # create tibble combining the ranges of all matches found
  match_ranges <-
    tibble::tibble(start = c(match_fw@ranges@start,
                             match_rc@ranges@start),
                   width = c(match_fw@ranges@width,
                             match_rc@ranges@width)) %>%
    dplyr::mutate(end = start + width - 1) %>%
    dplyr::bind_cols(strand = c(rep("+", length(match_fw)),
                                rep("-", length(match_rc))))

  # create tibble containing all information which are returned
  matches <-
    paste(toString(match_fw), toString(match_rc), sep = " ") %>%
    # in case there's no match on either forward or reverse complement strand,
    # remove the added whitespaces introduced in the previous line
    trimws("both") %>%
    # matches are either separated with just a whitespace (separates fw and rc)
    # or a comma followed by a whitespace (multiple matches within either fw or rc)
    strsplit(" |, ") %>%
    unlist() %>%
    tibble::as_tibble_col(column_name = "matched") %>%
    dplyr::bind_cols(match_ranges) %>%
    dplyr::mutate(seqID = seqID,
                  pattern = pattern) %>%
    dplyr::select(seqID,
                  pattern,
                  strand,
                  start,
                  end,
                  matched)

  return(matches)
}
