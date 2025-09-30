# OpenPrescribing JupyterLab Notebook

Welcome to this JupyterLab Notebook from the Bennett Institute. We hope you find this notebook both informative and useful. This Notebook is designed as a template for those wishing to learn and/or practice the access and data analyse of data from the OpenPrescribing. For those wishing to learn about how to use this Notebook from scratch (or even a reminder), then please start [here](https://bennett.wiki/) `url needs updating`. Currently, this notebook is only available for Bennett Institute staff, as you need credentials to access the OpenPrescribing data.

## Getting started

1. Create a new repository and use this repo `openprescribing-template` as a template.
2. If you have not already, create a `BQ_CREDENTIALS` Codespace secret at [https://github.com/settings/codespaces/secrets/new](https://github.com/settings/codespaces/secrets/new)
   - Name: BQ_CREDENTIALS
   - Value: Your BigQuery service account JSON
   - Grant access to `this` new repository
3. Otherwise, if you already have a BQ_CREDENTIALS secret, ensure this repository has been granted access
   - Go to [https://github.com/settings/codespaces/secrets/BQ_CREDENTIALS/edit](https://github.com/settings/codespaces/secrets/BQ_CREDENTIALS/edit)
   - Grant access to `this` new repository
4. Open Codespace by clicking on `<> Code ▼` button above
6. Click on the `Codespace` tab
7. Click on the `Create Codespace on master` button
8. Wait 2-3 minutes for Codespace to build (this can look like nothing is happening, but be patient)

## Don't need BigQuery access just yet?

If you don't need Google BigQuery access just yet (or you don't have the credentials), you can bypass the credentials check by running:

```bash
export BYPASS_CREDENTIALS_CHECK=true
```

and then start JupyterLabs with:

```bash
bash ./src/jupyter-lab-start.sh
```

## Open JupyterLabs

Once Codespace has finished building, the terminal will start to output text. When you see something like the below, press CTRL or CMD and click on the hyperlink. This should start your JupyterLabs Notebook session.

<!-- prettier-ignore-start -->
```markdown
************************************************************************************

You can access JupyterLab via the link below (CTRL or CMD and click)

https://opulent-trout-7xj795qv5qqhr9x7-59459.app.github.dev/?token=E8HYgdstcE8DqCLW

We will try and open the above url for you, but your pop-up blocker may stop this.

************************************************************************************
```
<!-- prettier-ignore-end -->

## Batteries included

To help you within Codespace, we have added the below features (but not included in live JupyterLab sessions):

1. Spell checker
2. Markdown linting (basically a grammar checker for markdown)

## How to cite

XXX Please change to either a paper (if published) or the repo. You may find it helpful to use Zenodo DOI (see [`DEVELOPERS.md`](dev/Developers.md#how-to-invite-people-to-cite) for further information).

You might want to delete the `lessons` folder when you reference this repository in articles.
