# Copyright (c) 2019-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#

#
# Usage: ./get-data-wiki.sh $lg
#

set -e

lg=$1  # input language

# data path
MAIN_PATH=$PWD
MONO_PATH=$PWD/data/mono

# tools paths
TOOLS_PATH=$PWD/tools

# moses
MOSES=$TOOLS_PATH/mosesdecoder
REPLACE_UNICODE_PUNCT=$MOSES/scripts/tokenizer/replace-unicode-punctuation.perl
NORM_PUNC=$MOSES/scripts/tokenizer/normalize-punctuation.perl
REM_NON_PRINT_CHAR=$MOSES/scripts/tokenizer/remove-non-printing-char.perl
TOKENIZER=$MOSES/scripts/tokenizer/tokenizer.perl
INPUT_FROM_SGM=$MOSES/scripts/ems/support/input-from-sgm.perl

# raw and tokenized files
lg_RAW=$MONO_PATH/$lg/all.$lg
lg_TOK=$lg_RAW.tok

#
# Download monolingual data
#

cd $MONO_PATH

if [ "$lg" == "de" ]; then
  echo "Downloading German monolingual data ..."
  mkdir -p $MONO_PATH/de
  cd $MONO_PATH/de
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.de.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2010.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2011.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2012.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2013.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt15/training-monolingual-news-crawl-v2/news.2014.de.shuffled.v2.gz
  # wget -c http://data.statmt.org/wmt16/translation-task/news.2015.de.shuffled.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2016.de.shuffled.gz
  # wget -c http://data.statmt.org/wmt18/translation-task/news.2017.de.shuffled.deduped.gz
fi

if [ "$lg" == "en" ]; then
  echo "Downloading English monolingual data ..."
  mkdir -p $MONO_PATH/en
  cd $MONO_PATH/en
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2010.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2011.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2012.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2013.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt15/training-monolingual-news-crawl-v2/news.2014.en.shuffled.v2.gz
  # wget -c http://data.statmt.org/wmt16/translation-task/news.2015.en.shuffled.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2016.en.shuffled.gz
  # wget -c http://data.statmt.org/wmt18/translation-task/news.2017.en.shuffled.deduped.gz
fi

if [ "$lg" == "fr" ]; then
  echo "Downloading French monolingual data ..."
  mkdir -p $MONO_PATH/fr
  cd $MONO_PATH/fr
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.fr.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.fr.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2010.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2011.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2012.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2013.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt15/training-monolingual-news-crawl-v2/news.2014.fr.shuffled.v2.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2015.fr.shuffled.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2016.fr.shuffled.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2017.fr.shuffled.gz
fi

cd $MONO_PATH

# decompress monolingual data
for FILENAME in $lg/news*gz; do
  OUTPUT="${FILENAME::-3}"
  if [ ! -f "$OUTPUT" ]; then
    echo "Decompressing $FILENAME..."
    gunzip $FILENAME
  else
    echo "$OUTPUT already decompressed."
  fi
done

# concatenate monolingual data files
if ! [[ -f "$lg_RAW" ]]; then
  echo "Concatenating $lg monolingual data..."
  cat $(ls $lg/news*$lg* | grep -v gz) | head -n $N_MONO > $lg_RAW
fi
echo "$lg monolingual data concatenated in: $lg_RAW"

lg_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $lg | $REM_NON_PRINT_CHAR | $NORMALIZE_ROMANIAN | $REMOVE_DIACRITICS | $TOKENIZER -l $lg -no-escape -threads $N_THREADS"

# tokenize data
if ! [[ -f "$lg_TOK" ]]; then
  echo "Tokenize $lg monolingual data..."
  eval "cat $lg_RAW | $lg_PREPROCESSING > $lg_TOK"
fi

# split into train / valid / test
echo "*** Split into train / valid / test ***"
split_data() {
    get_seeded_random() {
        seed="$1"; openssl enc -aes-256-ctr -pass pass:"$seed" -nosalt </dev/zero 2>/dev/null
    };
    NLINES=`wc -l $1  | awk -F " " '{print $1}'`;
    NTRAIN=$((NLINES - 10000));
    NVAL=$((NTRAIN + 5000));
    shuf --random-source=<(get_seeded_random 42) $1 | head -$NTRAIN             > $2;
    shuf --random-source=<(get_seeded_random 42) $1 | head -$NVAL | tail -5000  > $3;
    shuf --random-source=<(get_seeded_random 42) $1 | tail -5000                > $4;
}
split_data $lg_RAW $MONO_PATH/$lg/$lg.train $MONO_PATH/$lg/$lg.valid $MONO_PATH/$lg/$lg.test

