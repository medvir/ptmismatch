#' Summarize primer-template matches
#'
#' @param pattern A string consisting of the pattern (primer sequence) to look for.
#'    IUPAC ambiguity codes are supported (e.g. "R" matches "A" and "G"). "I" are
#'    not supported, replace them with "N" instead.
#' @param subject_filepath A file path to a fasta or fastq file containing one
#'    or multiple DNA sequences in which the pattern is searched.
#' @param subject_format A string, either "fasta" or "fastq".
#' @param max.mismatch The maximum number of mismatching letters
#'    (maximum edit distance) allowed as integer.
#' @param with.indels A boolean, if TRUE then indels are allowed.
#'
#' @return A tibble containing a summary of the primer-template matches found.
#' @export
#'
#' @examples
#'
#' # prepare pattern and subject
#' EV_fwd <- "GCTGCGYTGGCGGCC"
#'
#' EV_sequences_fasta <- system.file("extdata", "Enterovirus_12059.fasta", package="ptmismatch")
#'
#' summarize_matches(pattern = EV_fwd, subject_filepath = EV_sequences_fasta,
#'                   subject_format = "fasta", max.mismatch = 1, with.indels = TRUE)
#'
summarize_matches <- function(pattern, subject_filepath, subject_format,
                              max.mismatch, with.indels = TRUE) {

  # loading msa is currently required as described here:
  # https://support.bioconductor.org/p/133439/
  # this can be removed once msa is updated and this issue is fixed
  library(msa)

  subject <- Biostrings::readDNAStringSet(subject_filepath, format = subject_format)

  future::plan("future::multisession")

  matches_summary <-
    furrr::future_map_dfr(1:length(subject),
                          function(x) find_matches(pattern, subject, subject_index = x,
                                                   max.mismatch, with.indels))

  future::plan("future::sequential")

  if (nrow(matches_summary) < 2) {

    matches_summary <-
      matches_summary %>%
      dplyr::mutate(matched_aligned = matched)

  } else if (!with.indels) {

    matches_summary <-
      matches_summary %>%
      dplyr::mutate(matched_aligned = matched)

  } else if (with.indels) {

    matches_summary <-
      matches_summary %>%
      # perform multiple sequence alignment on the matches
      dplyr::mutate(matched_aligned =
                      msa::msaConvert(msa::msa(matched, method = "ClustalOmega",
                                               type = "dna", order = "input"))$seq)

  }

  return(matches_summary)
}
