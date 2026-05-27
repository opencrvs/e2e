import { Choice } from 'prompts';
import { input, select } from '@inquirer/prompts';


export function getIndexFromChoices(choices: Choice[], value: string) {
  let idx = 0
  for (const choice of choices as Choice[]) {
    if (choice.value === value) {
      return idx
    }
    idx++
  }
  return 0
}

type SelectWithCustomOptions = {
    message: string;
    choices: readonly { name: string; value: string }[];
    customLabel?: string;
    customInputMessage?: string;
    initial?: string;
};

export async function selectWithCustom(
    config: SelectWithCustomOptions
): Promise<string> {
    const {
        message,
        choices,
        initial = undefined,
        customLabel = 'Other...',
        customInputMessage = 'Enter custom value:',
    } = config;

    const CUSTOM = '__custom__' as const;

    const selected = await select<string>({
        message,
        choices: [
            ...choices,
            {
                value: CUSTOM,
                name: customLabel,
            },
        ],
        default: initial,
    });

    if (selected === CUSTOM) {
        const customValue = await input({
            message: customInputMessage,
            validate: value =>
                value.trim().length > 0 ? true : 'Value cannot be empty',
        });

        return customValue;
    }

    return selected;
}
