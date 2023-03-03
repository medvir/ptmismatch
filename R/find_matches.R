#' Find primer-template matches
#'
#' @param pattern A string consisting of the pattern (primer sequence) to look for.
#'    IUPAC ambiguity codes are supported (e.g. "R" matches "A" and "G"). "I" are
#'    not supported, replace them with "N" instead.
#' @param subject A DNAStringSet (Biostrings class) containing one or multiple
#'    DNA sequences in which the pattern is searched.
#' @param subject_index An integer of the DNAString index within the DNAStringSet.
#' @param max.mismatch The maximum number of mismatching letters
#'    (maximum edit distance) allowed as integer.
#' @param with.indels A boolean, if TRUE then indels are allowed.
#'
#' @return A tibble containing the information of the primer-template matches found.
#' @export
#'
#' @examples
#'
#' # prepare pattern and subject
#' EV_fwd <- "GCTGCGYTGGCGGCC"
#'
#' EV_sequences_fasta <- system.file("extdata", "Enterovirus_12059.fasta", package="ptmismatch")
#'
#' EV_sequences <- Biostrings::readDNAStringSet(EV_sequences_fasta)
#'
#' # search either just one specific sequence...
#' find_matches(pattern = EV_fwd, subject = EV_sequences, subject_index = 1,
#'              max.mismatch = 1, with.indels = TRUE)
#'
#' # ...or all sequences within a fasta file
#'
#' future::plan("future::multisession")
#' furrr::future_map_dfr(1:length(EV_sequences),
#'                       function(x) find_matches(pattern = EV_fwd,
#'                                                subject = EV_sequences,
#'                                                subject_index = x,
#'                                                max.mismatch = 1,
#'                                                with.indels = TRUE))
#' future::plan("future::sequential")
#'
find_matches <- function(pattern, subject, subject_index,
                         max.mismatch, with.indels = TRUE) {

  pattern <- toupper(pattern)
  pattern_dna <- Biostrings::DNAString(pattern)

  # pad subject sequence with a junk letter ("+") so there's no error
  # subsetting matches which overlap the beginning or end
  subject_paded <-
    Biostrings::xscat(stringr::str_dup("+", max.mismatch),
                      subject[[subject_index]],
                      stringr::str_dup("+", max.mismatch)) %>%
    # replace Ns inside the sequence with a junk letter ("+") so they
    # wouldn't match our pattern
    # this is especially an issue with long stretches of Ns
    Biostrings::chartr(old = "N", new = "+")

  # get the sequence ID
  # (everything up until the first whitespace of the sequence name)
  seqID <- strsplit(subject@ranges@NAMES[[subject_index]], " ")[[1]][1]

  # find matches on both strands of the subject
  match_fw <-
    Biostrings::matchPattern(pattern_dna,
                             subject_paded,
                             max.mismatch,
                             with.indels = with.indels,
                             fixed = FALSE)

  # search the minus strand of the subject
  # follow the documentation here:
  # https://rdrr.io/bioc/Biostrings/man/reverseComplement.html
  match_rc <-
    Biostrings::matchPattern(Biostrings::reverseComplement(pattern_dna),
                             subject_paded,
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
    paste(toString(match_fw),
          toString(Biostrings::reverseComplement(match_rc)),
          sep = " ") %>%
    # revert junk letters back to Ns
    stringr::str_replace_all("\\+", "N") %>%
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
