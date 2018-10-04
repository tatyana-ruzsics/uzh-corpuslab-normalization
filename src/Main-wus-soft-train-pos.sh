#!/bin/bash
# Usage Main-wus-soft-train-pos.sh model_file_name data_folder data_prefix use_aux_loss
# ./Main-wus-soft-train-pos.sh norm_soft wus/phase2/treetagger wus
# ./Main-wus-soft-train-pos.sh norm_soft_pos wus/phase2/treetagger wus
# ./Main-wus-soft-train-pos.sh norm_soft_context wus/phase2/treetagger wus
# ./Main-wus-soft-train-pos.sh norm_soft_context wus/phase2/treetagger wus aux
# ./Main-wus-soft-train-pos.sh norm_soft_char_context wus/phase2/treetagger wus
# ./Main-wus-soft-train-pos.sh norm_soft_char_context wus/phase2/treetagger wus aux
##########################################################################################


export TRAIN=$2/train_silverpos.txt
export DEV=$2/dev_autopos.txt
export TEST=$2/test_autopos.txt

export MODEL=$1
if [[ $4 == "aux" ]]; then
export PR="$3_aux"
else
export PR=$3
fi
echo "$PR"

########### SEED 1 + eval
if [[ $4 == "aux" ]]; then
PYTHONIOENCODING=utf8 python ${MODEL}.py train --dynet-seed 1 --train_path=$TRAIN --dev_path=$DEV ${PR}_${MODEL}_1  --epochs=40 --lowercase --aux_pos_task
elif [[ $1 == "norm_soft_pos" ]]; then
PYTHONIOENCODING=utf8 python ${MODEL}.py train --dynet-seed 1 --train_path=$TRAIN --dev_path=$DEV ${PR}_${MODEL}_1  --epochs=40 --lowercase
else
PYTHONIOENCODING=utf8 python ${MODEL}.py train --dynet-seed 1 --train_path=$TRAIN --dev_path=$DEV ${PR}_${MODEL}_1  --epochs=40 --lowercase
fi

PYTHONIOENCODING=utf8 python ${MODEL}.py test ${PR}_${MODEL}_1 --test_path=$DEV --beam=3 --pred_path=best.dev.3  --lowercase &

PYTHONIOENCODING=utf8 python ${MODEL}.py test ${PR}_${MODEL}_1 --test_path=$TEST --beam=3 --pred_path=best.test.3  --lowercase


########### SEED >1 + eval
## the vocabulary of SEED 1 is used for other models in ensemble
for (( k=2; k<=5; k++ ))
do
(
if [[ $4 == "aux" ]]; then
PYTHONIOENCODING=utf8 python ${MODEL}.py train --dynet-seed $k --train_path=$TRAIN --dev_path=$DEV ${PR}_${MODEL}_$k  --epochs=40 --lowercase --aux_pos_task --char_vocab_path=${PR}_${MODEL}_1/char_vocab.txt --word_vocab_path=${PR}_${MODEL}_1/word_vocab.txt --feat_vocab_path=${PR}_${MODEL}_1/feat_vocab.txt
elif [[ $1 == "norm_soft_pos" ]]; then
PYTHONIOENCODING=utf8 python ${MODEL}.py train --dynet-seed $k --train_path=$TRAIN --dev_path=$DEV ${PR}_${MODEL}_$k  --epochs=40 --lowercase --pos_split_space --vocab_path=${PR}_${MODEL}_1/vocab.txt
else
PYTHONIOENCODING=utf8 python ${MODEL}.py train --dynet-seed $k --train_path=$TRAIN --dev_path=$DEV ${PR}_${MODEL}_$k  --epochs=40 --lowercase --char_vocab_path=${PR}_${MODEL}_1/char_vocab.txt --word_vocab_path=${PR}_${MODEL}_1/word_vocab.txt --feat_vocab_path=${PR}_${MODEL}_1/feat_vocab.txt
fi

PYTHONIOENCODING=utf8 python ${MODEL}.py test ${PR}_${MODEL}_$k --test_path=$DEV --beam=3 --pred_path=best.dev.3  --lowercase &
PYTHONIOENCODING=utf8 python ${MODEL}.py test ${PR}_${MODEL}_$k --test_path=$TEST --beam=3 --pred_path=best.test.3  --lowercase
) &
done


############ Evaluate ensemble 5

PYTHONIOENCODING=utf8 python ${MODEL}.py ensemble_test ${PR}_${MODEL}_1,${PR}_${MODEL}_2,${PR}_${MODEL}_3,${PR}_${MODEL}_4,${PR}_${MODEL}_5 --test_path=$DEV --beam=3 --pred_path=best.dev.3 ${PR}_${MODEL}_ens5  --lowercase
PYTHONIOENCODING=utf8 python ${MODEL}.py ensemble_test ${PR}_${MODEL}_1,${PR}_${MODEL}_2,${PR}_${MODEL}_3,${PR}_${MODEL}_4,${PR}_${MODEL}_5 --test_path=$TEST --beam=3 --pred_path=best.test.3 ${PR}_${MODEL}_ens5  --lowercase

