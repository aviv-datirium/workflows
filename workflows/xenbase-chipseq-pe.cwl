cwlVersion: v1.0
class: Workflow


requirements:
  - class: SubworkflowFeatureRequirement


inputs:

  sra_input_file:
    type: File
    format: "http://edamontology.org/format_3698"
  illumina_adapters_file:
    type: File
    format: "http://edamontology.org/format_1929"
  bowtie2_indices_folder:
    type: Directory
  chr_length_file:
    type: File
    format: "http://edamontology.org/format_2330"
  threads:
    type: int?

outputs:

  bowtie2_log:
    type: File
    outputSource: fastq_to_bigwig/bowtie2_log
  picard_metrics:
    type: File
    outputSource: fastq_to_bigwig/picard_metrics
  bam_file:
    type: File
    outputSource: fastq_to_bigwig/bam_file
  bamtools_log:
    type: File
    outputSource: fastq_to_bigwig/bamtools_log
  bed:
    type: File
    outputSource: fastq_to_bigwig/bed
  bigwig:
    type: File
    outputSource: fastq_to_bigwig/bigwig


steps:

  sra_to_fastq:
    run: ../subworkflows/xenbase-sra-to-fastq-pe.cwl
    in:
      sra_input_file: sra_input_file
      illumina_adapters_file: illumina_adapters_file
      threads: threads
    out:
      - upstream_fastq
      - downstream_fastq

  fastq_to_bigwig:
    run: ../subworkflows/xenbase-fastq-bowtie-bigwig-se-pe.cwl
    in:
      upstream_fastq: sra_to_fastq/upstream_fastq
      downstream_fastq: sra_to_fastq/downstream_fastq
      bowtie2_indices_folder: bowtie2_indices_folder
      chr_length_file: chr_length_file
      paired:
        default: true
      threads: threads
    out:
    - bowtie2_log
    - picard_metrics
    - bam_file
    - bamtools_log
    - bed
    - bigwig


$namespaces:
  s: http://schema.org/

$schemas:
- http://schema.org/docs/schema_org_rdfa.html

s:name: "Xenbase ChIP-Seq pipeline paired-end"
label: "Xenbase ChIP-Seq pipeline paired-end"
s:alternateName: "XenBase workflow for analysing ChIP-Seq paired-end data"

s:downloadUrl: https://raw.githubusercontent.com/Barski-lab/workflows/master/workflows/xenbase-chipseq-pe.cwl
s:codeRepository: https://github.com/Barski-lab/workflows
s:license: http://www.apache.org/licenses/LICENSE-2.0

s:isPartOf:
  class: s:CreativeWork
  s:name: Common Workflow Language
  s:url: http://commonwl.org/

s:creator:
- class: s:Organization
  s:legalName: "Cincinnati Children's Hospital Medical Center"
  s:location:
  - class: s:PostalAddress
    s:addressCountry: "USA"
    s:addressLocality: "Cincinnati"
    s:addressRegion: "OH"
    s:postalCode: "45229"
    s:streetAddress: "3333 Burnet Ave"
    s:telephone: "+1(513)636-4200"
  s:logo: "https://www.cincinnatichildrens.org/-/media/cincinnati%20childrens/global%20shared/childrens-logo-new.png"
  s:department:
  - class: s:Organization
    s:legalName: "Allergy and Immunology"
    s:department:
    - class: s:Organization
      s:legalName: "Barski Research Lab"
      s:member:
      - class: s:Person
        s:name: Michael Kotliar
        s:email: mailto:misha.kotliar@gmail.com
        s:sameAs:
        - id: http://orcid.org/0000-0002-6486-3898

doc: |
  1. Convert input SRA file into pair of upsrtream and downstream FASTQ files (run fastq-dump)
  2. Analyze quality of FASTQ files (run fastqc with each of the FASTQ files)
  3. If any of the following fields in fastqc generated report is marked as failed for at least one of input FASTQ files:
        "Per base sequence quality",
        "Per sequence quality scores",
        "Overrepresented sequences",
        "Adapter Content",
    - trim adapters (run trimmomatic)
  4. Align original or trimmed FASTQ files to reference genome (run Bowtie2)
  5. Sort and index generated by Bowtie2 BAM file (run samtools sort, samtools index)
  6. Remove duplicates in sorted BAM file (run picard)
  7. Sort and index BAM file after duplicates removing (run samtools sort, samtools index)
  8. Count mapped reads number in sorted BAM file (run bamtools stats)
  9. Generate genome coverage BED file (run bedtools genomecov)
  10. Sort genearted BED file (run sort)
  11. Generate genome coverage bigWig file from BED file (run bedGraphToBigWig)
